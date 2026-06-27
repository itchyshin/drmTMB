#!/usr/bin/env Rscript
#
# Q4-location coverage grid runner
#
# Cluster-ready, SLURM-array-friendly runner for the 16-target q4-location
# coverage grid: direct-SD targets for mu1:(Intercept), mu1:x, mu2:(Intercept),
# and mu2:x, across four providers (phylo, spatial, animal, relmat).
#
# SHARD MAP (--shard=N selects one row):
#   1  phylo   mu1:(Intercept)
#   2  phylo   mu1:x
#   3  phylo   mu2:(Intercept)
#   4  phylo   mu2:x
#   5  spatial mu1:(Intercept)
#   6  spatial mu1:x
#   7  spatial mu2:(Intercept)
#   8  spatial mu2:x
#   9  animal  mu1:(Intercept)
#  10  animal  mu1:x
#  11  animal  mu2:(Intercept)
#  12  animal  mu2:x
#  13  relmat  mu1:(Intercept)
#  14  relmat  mu1:x
#  15  relmat  mu2:(Intercept)
#  16  relmat  mu2:x
#
# CLAIM BOUNDARY: direct-SD targets only (16 shards).  Derived-correlation
# targets (24 endpoints, reconstruction design not yet complete) are NOT in
# this grid.  No coverage claims until MCSE <= 0.01 is verified on the full
# run.
#
# Providers and covariance construction:
#   phylo   -- balanced binary tree (8 tips, equal branch lengths 1);
#              K = drmTMB:::drm_phylo_tip_covariance(tree)
#   spatial -- 8 sites on a circular arc; precision built from
#              drmTMB:::drm_spatial_coords_precision(), K = solve(precision)
#   animal  -- AR(1)-ish K (rho=0.32, +0.18 on diagonal); used as A matrix
#   relmat  -- AR(1)-ish K (rho=0.35, +0.15 on diagonal)
#
# True parameter values (phase18_biv_gaussian_q4_location_conditions):
#   mu1 fixed effects:  beta_mu1_intercept =  0.15,  beta_mu1_x =  0.42
#   mu2 fixed effects:  beta_mu2_intercept = -0.18,  beta_mu2_x = -0.32
#   residual log-scale: log_sigma1 = log(0.36),  log_sigma2 = log(0.43)
#   RE SDs:  sd_mu1_intercept = 0.46,  sd_mu1_x = 0.18
#            sd_mu2_intercept = 0.50,  sd_mu2_x = 0.18
#   RE correlations:    all 0.08 (see map)
#   residual rho12:     0.08
#
# Design: 8 groups, 20 obs/group = 160 obs total.
# Formula: mu1 = y1 ~ x + <provider>(1 + x | p | <group>, ...),
#          mu2 = y2 ~ x + <provider>(1 + x | p | <group>, ...),
#          sigma1 = ~1, sigma2 = ~1, rho12 = ~1
#
# Intervals: Wald (primary) + endpoint-profile (primary).
#   Bootstrap optional via --bootstrap=N (default 0 = off).
#
# DGP-vs-model alignment: K passed to both DGP and model from the same package
# helpers with the same inputs.  The fit formula uses the same (1 + x | p | ...)
# structure as the DGP's correlated_effects() draw.
#
# Resumability: per-rep TSV rows are written incrementally; seeds already in
#   the file with attempt_status == "fit_ok" are skipped on restart.
#
# Outputs per shard (in --out_dir):
#   <shard>-<provider>-<target_token>-replicates.tsv   (one row per rep)
#   <shard>-<provider>-<target_token>-summary.tsv      (aggregate)

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
`%||%` <- function(x, y) if (is.null(x)) y else x

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

append_tsv <- function(x, path) {
  file_existed <- file.exists(path)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA",
    append = file_existed,
    col.names = !file_existed
  )
}

# ---------------------------------------------------------------------------
# Shard map  (16 direct-SD targets)
# ---------------------------------------------------------------------------
SHARD_MAP <- data.frame(
  shard = 1:16,
  provider = c(
    "phylo",   "phylo",   "phylo",   "phylo",
    "spatial", "spatial", "spatial", "spatial",
    "animal",  "animal",  "animal",  "animal",
    "relmat",  "relmat",  "relmat",  "relmat"
  ),
  target = c(
    "mu1:(Intercept)", "mu1:x", "mu2:(Intercept)", "mu2:x",
    "mu1:(Intercept)", "mu1:x", "mu2:(Intercept)", "mu2:x",
    "mu1:(Intercept)", "mu1:x", "mu2:(Intercept)", "mu2:x",
    "mu1:(Intercept)", "mu1:x", "mu2:(Intercept)", "mu2:x"
  ),
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# CLI parsing
# ---------------------------------------------------------------------------
parse_args <- function(args) {
  out <- list(
    shard             = NA_integer_,
    n_rep             = 475L,
    seed_start        = 850001L,
    n_each            = 20L,
    out_dir           = NA_character_,
    bootstrap         = 0L,
    attempt_temp_install = FALSE
  )
  for (arg in args) {
    if      (startsWith(arg, "--shard="))       out$shard    <- as.integer(sub("^--shard=", "", arg))
    else if (startsWith(arg, "--n_rep="))        out$n_rep    <- as.integer(sub("^--n_rep=", "", arg))
    else if (startsWith(arg, "--seed_start="))   out$seed_start <- as.integer(sub("^--seed_start=", "", arg))
    else if (startsWith(arg, "--n_each="))       out$n_each   <- as.integer(sub("^--n_each=", "", arg))
    else if (startsWith(arg, "--out_dir="))      out$out_dir  <- sub("^--out_dir=", "", arg)
    else if (startsWith(arg, "--bootstrap="))    out$bootstrap <- as.integer(sub("^--bootstrap=", "", arg))
    else if (identical(arg, "--attempt-temp-install")) out$attempt_temp_install <- TRUE
  }
  out
}

# ---------------------------------------------------------------------------
# Package loading (identical pattern to sigma-slope grid)
# ---------------------------------------------------------------------------
script_file <- sub(
  "^--file=", "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

installed_drmTMB_r_version_matches <- function() {
  ip <- tryCatch(
    installed.packages()[, c("Package", "Built"), drop = FALSE],
    error = function(e) NULL
  )
  if (is.null(ip)) return(FALSE)
  row <- ip[ip[, "Package"] == "drmTMB", "Built", drop = TRUE]
  if (length(row) == 0L || is.na(row[[1L]])) return(FALSE)
  running_ver <- paste(
    R.Version()$major,
    strsplit(R.Version()$minor, "\\.")[[1L]][[1L]],
    sep = "."
  )
  pkg_ver_match <- regmatches(
    row[[1L]],
    regexpr("(?<=R )\\d+\\.\\d+", row[[1L]], perl = TRUE)
  )
  if (length(pkg_ver_match) == 0L || !nzchar(pkg_ver_match)) return(FALSE)
  identical(running_ver, pkg_ver_match[[1L]])
}

try_load_drmTMB <- function(attempt_temp_install) {
  version_ok <- installed_drmTMB_r_version_matches()
  if (version_ok && requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(list(ok = TRUE, status = "installed_namespace_loaded", detail = "loaded"))
  }
  if (!attempt_temp_install) {
    return(list(
      ok     = FALSE,
      status = "package_not_installed_or_version_mismatch",
      detail = paste("drmTMB not loadable (version match:", version_ok, ")",
                     "and --attempt-temp-install not requested")
    ))
  }
  temp_lib <- tempfile("drmTMB-local-lib-")
  dir.create(temp_lib, recursive = TRUE, showWarnings = FALSE)
  cmd    <- file.path(R.home("bin"), "R")
  output <- tryCatch(
    system2(cmd,
            c("CMD", "INSTALL", "--no-init-file", "--preclean",
              shQuote(paste0("--library=", temp_lib)), shQuote(repo_root)),
            stdout = TRUE, stderr = TRUE),
    error = function(e) conditionMessage(e)
  )
  if (!requireNamespace("drmTMB", lib.loc = temp_lib, quietly = TRUE)) {
    return(list(ok = FALSE, status = "temp_install_failed",
                detail = clean_text(paste(tail(output, 12L), collapse = " "))))
  }
  .libPaths(c(temp_lib, .libPaths()))
  suppressPackageStartupMessages(library(drmTMB))
  list(ok = TRUE, status = "temp_install_loaded",
       detail = "temporary_library_current_source")
}

# ---------------------------------------------------------------------------
# True parameter values  (phase18_biv_gaussian_q4_location_conditions)
# ---------------------------------------------------------------------------
TRUTH <- list(
  # fixed effects
  beta_mu1_intercept =  0.15,
  beta_mu1_x         =  0.42,
  beta_mu2_intercept = -0.18,
  beta_mu2_x         = -0.32,
  # residual log-scale intercepts
  log_sigma1 = log(0.36),
  log_sigma2 = log(0.43),
  # RE SDs (direct-SD targets)
  sd_mu1_intercept = 0.46,
  sd_mu1_x         = 0.18,
  sd_mu2_intercept = 0.50,
  sd_mu2_x         = 0.18,
  # residual correlation
  rho12 = 0.08
)

# ---------------------------------------------------------------------------
# Covariance helpers
# ---------------------------------------------------------------------------

# Balanced binary tree: 8 tips, equal branch lengths 1
balanced_tree <- function(n_tip = 8L) {
  edges       <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node   <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
    node       <- next_node
    next_node <<- next_node + 1L
    mid        <- length(tips) / 2L
    left       <- build(tips[seq_len(mid)])
    right      <- build(tips[seq.int(mid + 1L, length(tips))])
    edges       <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }
  build(seq_len(n_tip))
  structure(
    list(edge        = edges,
         edge.length = edge_lengths,
         tip.label   = paste0("sp_", seq_len(n_tip)),
         Nnode       = n_tip - 1L),
    class = "phylo"
  )
}

# Spatial: 8 sites on a circular arc
spatial_coords_and_K <- function(n = 8L) {
  labels <- paste0("site_", seq_len(n))
  theta  <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(
    x = cos(theta) + seq_len(n) / (3 * n),
    y = sin(theta)
  )
  rownames(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = labels, group = "site"
  )
  K <- solve(as.matrix(precision$precision))
  list(labels = labels, coords = coords, K = K)
}

# Animal: AR(1)-ish K (rho=0.32, +0.18 diagonal) -- used as A matrix
animal_K <- function(n = 8L) {
  labels <- paste0("id", seq_len(n))
  K      <- outer(seq_len(n), seq_len(n), function(i, j) 0.32^abs(i - j))
  diag(K) <- diag(K) + 0.18
  dimnames(K) <- list(labels, labels)
  K
}

# Relmat: AR(1)-ish K (rho=0.35, +0.15 diagonal)
relmat_K <- function(n = 8L) {
  labels <- paste0("id", seq_len(n))
  K      <- outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(labels, labels)
  K
}

# Draw correlated RE effects from K-structured multivariate normal
# sds: named numeric vector with all 4 location endpoints
make_endpoint_covariance <- function(sds) {
  p       <- length(sds)
  cor_mat <- diag(p)
  cor_mat[lower.tri(cor_mat)] <- TRUTH$rho12   # 0.08 for all pairs
  cor_mat[upper.tri(cor_mat)] <- t(cor_mat)[upper.tri(cor_mat)]
  diag(sds) %*% cor_mat %*% diag(sds)
}

correlated_effects <- function(K, sds) {
  endpoint_cov <- make_endpoint_covariance(sds)
  base <- t(chol(K)) %*%
    matrix(stats::rnorm(nrow(K) * ncol(endpoint_cov)),
           nrow(K), ncol(endpoint_cov))
  out <- base %*% chol(endpoint_cov)
  colnames(out) <- names(sds)
  out
}

# ---------------------------------------------------------------------------
# Data-generating process
# ---------------------------------------------------------------------------
make_q4_location_data <- function(provider, seed, n_each = 20L) {
  set.seed(seed)
  n_groups <- 8L

  if (identical(provider, "phylo")) {
    tree   <- balanced_tree(n_groups)
    labels <- tree$tip.label
    K      <- drmTMB:::drm_phylo_tip_covariance(tree)
    group  <- "species"
    extra  <- list(tree = tree)
  } else if (identical(provider, "spatial")) {
    sp     <- spatial_coords_and_K(n_groups)
    labels <- sp$labels
    K      <- sp$K
    group  <- "site"
    extra  <- list(coords = sp$coords)
  } else if (identical(provider, "animal")) {
    K      <- animal_K(n_groups)
    labels <- rownames(K)
    group  <- "id"
    extra  <- list(A = K)
  } else if (identical(provider, "relmat")) {
    K      <- relmat_K(n_groups)
    labels <- rownames(K)
    group  <- "id"
    extra  <- list(K = K)
  } else {
    stop("Unknown provider: ", provider, call. = FALSE)
  }

  # All four location-axis RE SDs
  sds <- c(
    mu1_intercept = TRUTH$sd_mu1_intercept,
    mu1_x         = TRUTH$sd_mu1_x,
    mu2_intercept = TRUTH$sd_mu2_intercept,
    mu2_x         = TRUTH$sd_mu2_x
  )
  effects  <- correlated_effects(K, sds)
  rownames(effects) <- labels

  endpoint <- rep(labels, each = n_each)
  x        <- rep(seq(-1, 1, length.out = n_each), times = n_groups)

  # Bivariate linear predictors
  eta_mu1 <- TRUTH$beta_mu1_intercept + TRUTH$beta_mu1_x * x +
    effects[endpoint, "mu1_intercept"] +
    effects[endpoint, "mu1_x"] * x

  eta_mu2 <- TRUTH$beta_mu2_intercept + TRUTH$beta_mu2_x * x +
    effects[endpoint, "mu2_intercept"] +
    effects[endpoint, "mu2_x"] * x

  # Residual bivariate normal (constant sigma, rho12)
  rho12   <- TRUTH$rho12
  sigma1  <- exp(TRUTH$log_sigma1)
  sigma2  <- exp(TRUTH$log_sigma2)
  L       <- chol(matrix(c(1, rho12, rho12, 1), 2L, 2L))
  N       <- length(endpoint)
  eps_raw <- matrix(stats::rnorm(N * 2L), N, 2L) %*% L
  y1      <- eta_mu1 + sigma1 * eps_raw[, 1L]
  y2      <- eta_mu2 + sigma2 * eps_raw[, 2L]

  dat        <- data.frame(y1 = y1, y2 = y2, x = x, stringsAsFactors = FALSE)
  dat[[group]] <- endpoint
  c(list(data = dat, group = group, K = K, labels = labels), extra)
}

# ---------------------------------------------------------------------------
# Fitting
# NOTE: sigma1 = ~1, sigma2 = ~1, rho12 = ~1 (intercept-only) keeps the
# model free of sigma-axis RE so that the q4-location DGP matches the
# fitted model exactly.  The K passed to the provider is the same K used
# to draw effects, ensuring DGP-vs-model alignment by construction.
# ---------------------------------------------------------------------------
fit_q4_location <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      mu1   = y1 ~ x + phylo(1 + x | p | species, tree = tree),
      mu2   = y2 ~ x + phylo(1 + x | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12  = ~1
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      mu1   = y1 ~ x + spatial(1 + x | p | site, coords = coords),
      mu2   = y2 ~ x + spatial(1 + x | p | site, coords = coords),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12  = ~1
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      mu1   = y1 ~ x + animal(1 + x | p | id, A = A),
      mu2   = y2 ~ x + animal(1 + x | p | id, A = A),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12  = ~1
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      mu1   = y1 ~ x + relmat(1 + x | p | id, K = K),
      mu2   = y2 ~ x + relmat(1 + x | p | id, K = K),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12  = ~1
    )
  }

  drmTMB(
    form,
    family  = biv_gaussian(),
    data    = sim$data,
    control = drm_control(
      fallback_optimizer = "BFGS",
      optimizer = list(eval.max = 1600, iter.max = 1600)
    )
  )
}

# ---------------------------------------------------------------------------
# Parameter name helpers
# ---------------------------------------------------------------------------
mu_group <- function(provider) {
  switch(provider,
    phylo   = "species",
    spatial = "site",
    animal  = "id",
    relmat  = "id"
  )
}

# parm name as used in confint() (from diagnostic plan):
#   "sd:mu:mu1:phylo(1 | p | species)"  for mu1:(Intercept)
#   "sd:mu:mu1:phylo(0 + x | p | species)" for mu1:x
mu_parm_name <- function(provider, endpoint_member) {
  response <- sub(":.*", "", endpoint_member)          # "mu1" or "mu2"
  grp      <- mu_group(provider)
  coef     <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) "1" else "0 + x"
  paste0("sd:mu:", response, ":", provider, "(", coef, " | p | ", grp, ")")
}

# sdpars$mu key: provider(coef | p | group)
sd_label_in_sdpars <- function(provider, endpoint_member) {
  grp  <- mu_group(provider)
  coef <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) "1" else "0 + x"
  paste0(provider, "(", coef, " | p | ", grp, ")")
}

target_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  out <- gsub("+", "_", out, fixed = TRUE)
  out <- gsub("_+", "_", out)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

truth_for <- function(endpoint_member) {
  if (grepl("mu1", endpoint_member, fixed = TRUE)) {
    if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
      TRUTH$sd_mu1_intercept
    } else {
      TRUTH$sd_mu1_x
    }
  } else {
    if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
      TRUTH$sd_mu2_intercept
    } else {
      TRUTH$sd_mu2_x
    }
  }
}

# ---------------------------------------------------------------------------
# Interval computation (identical to sigma-slope grid)
# ---------------------------------------------------------------------------
run_wald <- function(fit, parm_name) {
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(fit, parm = parm_name, method = "wald", level = 0.95),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(lower = NA_real_, upper = NA_real_, status = "error",
                message = clean_text(conditionMessage(result)),
                warnings = clean_text(paste(warnings_cap, collapse = "; "))))
  }
  # Guard: confint returns an empty data.frame when parm is not matched
  if (is.data.frame(result) && nrow(result) == 0L) {
    return(list(lower = NA_real_, upper = NA_real_, status = "parm_not_found",
                message = paste0("wald: parm not in profile_targets: ", parm_name),
                warnings = clean_text(paste(warnings_cap, collapse = "; "))))
  }
  lower <- if (is.data.frame(result)) result$lower[[1L]] else result$lower[[1L]]
  upper <- if (is.data.frame(result)) result$upper[[1L]] else result$upper[[1L]]
  list(lower = lower, upper = upper,
       status = if (is.finite(lower) && is.finite(upper)) "finite" else "nonfinite",
       message = NA_character_,
       warnings = clean_text(paste(warnings_cap, collapse = "; ")))
}

run_profile <- function(fit, parm_name) {
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(fit, parm = parm_name, method = "profile",
                     level = 0.95, profile_engine = "endpoint",
                     trace = FALSE, profile_endpoint_max_eval = 90L),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(lower = NA_real_, upper = NA_real_, status = "error",
                message = clean_text(conditionMessage(result)),
                warnings = clean_text(paste(warnings_cap, collapse = "; ")),
                conf_status = NA_character_))
  }
  # Guard: empty table when parm not matched
  if (is.data.frame(result) && nrow(result) == 0L) {
    return(list(lower = NA_real_, upper = NA_real_, status = "parm_not_found",
                conf_status = NA_character_,
                message = paste0("profile: parm not in profile_targets: ", parm_name),
                warnings = clean_text(paste(warnings_cap, collapse = "; "))))
  }
  lower <- if (is.data.frame(result)) result$lower[[1L]] else result$lower[[1L]]
  upper <- if (is.data.frame(result)) result$upper[[1L]] else result$upper[[1L]]
  finite <- is.finite(lower) && is.finite(upper)
  conf_status <- if ("conf.status" %in% names(result)) {
    clean_text(as.character(result$conf.status[[1L]]))
  } else {
    NA_character_
  }
  list(lower = lower, upper = upper,
       status = if (finite) "finite" else "nonfinite",
       conf_status = conf_status,
       message = if ("profile.message" %in% names(result)) {
         clean_text(as.character(result$profile.message[[1L]]))
       } else {
         NA_character_
       },
       warnings = clean_text(paste(warnings_cap, collapse = "; ")))
}

run_bootstrap <- function(fit, parm_name, R) {
  if (R <= 0L) {
    return(list(lower = NA_real_, upper = NA_real_, status = "skipped",
                message = "bootstrap_off", warnings = NA_character_))
  }
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(fit, parm = parm_name, method = "bootstrap",
                     level = 0.95, R = R, seed = 42L),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(lower = NA_real_, upper = NA_real_, status = "error",
                message = clean_text(conditionMessage(result)),
                warnings = clean_text(paste(warnings_cap, collapse = "; "))))
  }
  # Guard: empty table when parm not matched
  if (is.data.frame(result) && nrow(result) == 0L) {
    return(list(lower = NA_real_, upper = NA_real_, status = "parm_not_found",
                message = paste0("bootstrap: parm not in profile_targets: ", parm_name),
                warnings = clean_text(paste(warnings_cap, collapse = "; "))))
  }
  lower <- if (is.data.frame(result)) result$lower[[1L]] else result$lower[[1L]]
  upper <- if (is.data.frame(result)) result$upper[[1L]] else result$upper[[1L]]
  list(lower = lower, upper = upper,
       status = if (is.finite(lower) && is.finite(upper)) "finite" else "nonfinite",
       message = NA_character_,
       warnings = clean_text(paste(warnings_cap, collapse = "; ")))
}

# Coverage helper (NA if non-finite interval)
covers <- function(truth, lower, upper) {
  if (is.finite(lower) && is.finite(upper)) truth >= lower & truth <= upper
  else NA
}

# ---------------------------------------------------------------------------
# Empty row (errors / not-attempted)
# ---------------------------------------------------------------------------
empty_row <- function(seed, rep_id, provider, endpoint_member, status, msg) {
  parm_name <- mu_parm_name(provider, endpoint_member)
  truth_sd  <- truth_for(endpoint_member)
  data.frame(
    replicate_id       = rep_id,
    seed               = seed,
    provider           = provider,
    endpoint_member    = endpoint_member,
    target_parm        = parm_name,
    truth_sd           = truth_sd,
    attempt_status     = status,
    message            = clean_text(msg),
    convergence        = NA_integer_,
    pdHess             = NA,
    is_boundary        = NA,
    estimate_sd        = NA_real_,
    wald_lower         = NA_real_,
    wald_upper         = NA_real_,
    wald_status        = NA_character_,
    wald_warnings      = NA_character_,
    wald_contains      = NA,
    profile_lower      = NA_real_,
    profile_upper      = NA_real_,
    profile_status     = NA_character_,
    profile_conf_status = NA_character_,
    profile_message    = NA_character_,
    profile_warnings   = NA_character_,
    profile_contains   = NA,
    bootstrap_lower    = NA_real_,
    bootstrap_upper    = NA_real_,
    bootstrap_status   = NA_character_,
    bootstrap_warnings = NA_character_,
    bootstrap_contains = NA,
    elapsed_sec        = NA_real_,
    stringsAsFactors   = FALSE
  )
}

# ---------------------------------------------------------------------------
# Per-replicate runner
# ---------------------------------------------------------------------------
run_one_rep <- function(seed, rep_id, provider, endpoint_member,
                        n_each, bootstrap_R) {
  parm_name <- mu_parm_name(provider, endpoint_member)
  truth_sd  <- truth_for(endpoint_member)
  sd_label  <- sd_label_in_sdpars(provider, endpoint_member)

  sim <- tryCatch(
    make_q4_location_data(provider, seed, n_each),
    error = function(e) e
  )
  if (inherits(sim, "error")) {
    return(empty_row(seed, rep_id, provider, endpoint_member,
                     "sim_error", conditionMessage(sim)))
  }

  warnings_fit <- character()
  t_elapsed <- system.time({
    fit <- withCallingHandlers(
      tryCatch(fit_q4_location(provider, sim), error = function(e) e),
      warning = function(w) {
        warnings_fit <<- c(warnings_fit, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })

  if (inherits(fit, "error")) {
    return(empty_row(seed, rep_id, provider, endpoint_member,
                     "fit_error", conditionMessage(fit)))
  }

  # Safely extract convergence and pdHess
  conv     <- tryCatch(fit$opt$convergence, error = function(e) NA_integer_)
  if (is.null(conv) || length(conv) == 0L) conv <- NA_integer_
  pd_hess  <- tryCatch(isTRUE(fit$sdr$pdHess), error = function(e) FALSE)
  is_bdry  <- is.na(conv) || (isTRUE(conv != 0L)) || !pd_hess

  # Point estimate from sdpars$mu
  sdpars_mu <- tryCatch(fit$sdpars$mu, error = function(e) NULL)
  est_sd    <- if (is.null(sdpars_mu)) NA_real_ else {
    tryCatch(unname(sdpars_mu[[sd_label]]), error = function(e) NA_real_)
  }

  # Intervals
  wi <- run_wald(fit, parm_name)
  pi <- run_profile(fit, parm_name)
  bi <- run_bootstrap(fit, parm_name, bootstrap_R)

  data.frame(
    replicate_id        = rep_id,
    seed                = seed,
    provider            = provider,
    endpoint_member     = endpoint_member,
    target_parm         = parm_name,
    truth_sd            = truth_sd,
    attempt_status      = "fit_ok",
    message             = clean_text(paste(warnings_fit, collapse = "; ")),
    convergence         = conv,
    pdHess              = pd_hess,
    is_boundary         = is_bdry,
    estimate_sd         = if (is.null(est_sd)) NA_real_ else est_sd,
    wald_lower          = wi$lower,
    wald_upper          = wi$upper,
    wald_status         = wi$status,
    wald_warnings       = wi$warnings,
    wald_contains       = covers(truth_sd, wi$lower, wi$upper),
    profile_lower       = pi$lower,
    profile_upper       = pi$upper,
    profile_status      = pi$status,
    profile_conf_status = if (!is.null(pi$conf_status)) pi$conf_status else NA_character_,
    profile_message     = pi$message,
    profile_warnings    = pi$warnings,
    profile_contains    = covers(truth_sd, pi$lower, pi$upper),
    bootstrap_lower     = bi$lower,
    bootstrap_upper     = bi$upper,
    bootstrap_status    = bi$status,
    bootstrap_warnings  = bi$warnings,
    bootstrap_contains  = covers(truth_sd, bi$lower, bi$upper),
    elapsed_sec         = unname(t_elapsed[["elapsed"]]),
    stringsAsFactors    = FALSE
  )
}

# ---------------------------------------------------------------------------
# Summary for a shard
# ---------------------------------------------------------------------------
make_summary <- function(rows, shard, provider, endpoint_member,
                         truth_sd, planned_reps, bootstrap_R) {
  parm_name   <- mu_parm_name(provider, endpoint_member)
  fit_ok_rows <- rows[rows$attempt_status == "fit_ok", , drop = FALSE]
  n_fit_ok    <- nrow(fit_ok_rows)
  n_converged <- sum(!is.na(fit_ok_rows$convergence) &
                       fit_ok_rows$convergence == 0L, na.rm = TRUE)
  n_pdhess    <- sum(!is.na(fit_ok_rows$pdHess) & fit_ok_rows$pdHess,
                     na.rm = TRUE)
  n_boundary  <- sum(!is.na(fit_ok_rows$is_boundary) &
                       fit_ok_rows$is_boundary, na.rm = TRUE)

  # Wald
  wald_finite <- fit_ok_rows[
    !is.na(fit_ok_rows$wald_lower) &
      is.finite(fit_ok_rows$wald_lower) &
      is.finite(fit_ok_rows$wald_upper), , drop = FALSE]
  n_wald_fin  <- nrow(wald_finite)
  n_wald_cov  <- sum(!is.na(wald_finite$wald_contains) &
                       wald_finite$wald_contains, na.rm = TRUE)
  wald_cov    <- if (n_wald_fin > 0L) n_wald_cov / n_wald_fin else NA_real_
  wald_mcse   <- if (!is.na(wald_cov) && n_wald_fin > 0L) {
    sqrt(wald_cov * (1 - wald_cov) / n_wald_fin)
  } else NA_real_

  # Profile
  prof_finite <- fit_ok_rows[
    !is.na(fit_ok_rows$profile_lower) &
      is.finite(fit_ok_rows$profile_lower) &
      is.finite(fit_ok_rows$profile_upper), , drop = FALSE]
  n_prof_fin  <- nrow(prof_finite)
  n_prof_cov  <- sum(!is.na(prof_finite$profile_contains) &
                       prof_finite$profile_contains, na.rm = TRUE)
  prof_cov    <- if (n_prof_fin > 0L) n_prof_cov / n_prof_fin else NA_real_
  prof_mcse   <- if (!is.na(prof_cov) && n_prof_fin > 0L) {
    sqrt(prof_cov * (1 - prof_cov) / n_prof_fin)
  } else NA_real_

  # Bootstrap (may be all skipped)
  boot_finite <- fit_ok_rows[
    !is.na(fit_ok_rows$bootstrap_lower) &
      is.finite(fit_ok_rows$bootstrap_lower) &
      is.finite(fit_ok_rows$bootstrap_upper), , drop = FALSE]
  n_boot_fin  <- nrow(boot_finite)
  n_boot_cov  <- sum(!is.na(boot_finite$bootstrap_contains) &
                       boot_finite$bootstrap_contains, na.rm = TRUE)
  boot_cov    <- if (n_boot_fin > 0L) n_boot_cov / n_boot_fin else NA_real_

  mean_est <- mean(fit_ok_rows$estimate_sd, na.rm = TRUE)

  data.frame(
    shard               = shard,
    provider            = provider,
    endpoint_member     = endpoint_member,
    target_parm         = parm_name,
    truth_sd            = truth_sd,
    planned_reps        = planned_reps,
    n_fit_ok            = n_fit_ok,
    n_fit_error         = sum(rows$attempt_status == "fit_error"),
    n_sim_error         = sum(rows$attempt_status == "sim_error"),
    n_converged         = n_converged,
    n_pdhess            = n_pdhess,
    n_boundary          = n_boundary,
    n_wald_finite       = n_wald_fin,
    n_wald_covered      = n_wald_cov,
    wald_coverage       = round(wald_cov, 4L),
    wald_mcse           = round(wald_mcse, 4L),
    n_profile_finite    = n_prof_fin,
    n_profile_covered   = n_prof_cov,
    profile_coverage    = round(prof_cov, 4L),
    profile_mcse        = round(prof_mcse, 4L),
    n_bootstrap_finite  = n_boot_fin,
    n_bootstrap_covered = n_boot_cov,
    bootstrap_coverage  = round(boot_cov, 4L),
    bootstrap_R         = bootstrap_R,
    mean_est_sd         = round(mean_est, 4L),
    bias_mean_est       = round(mean_est - truth_sd, 4L),
    mcse_threshold_met  = if (!is.na(wald_mcse)) wald_mcse <= 0.01 else NA,
    denominator_status  = "grid_shard_local_or_cluster",
    coverage_evaluable  = "pending_mcse_check",
    claim_boundary      = paste(
      provider, "q4-location coverage grid shard only;",
      "direct-SD targets only (derived-correlation intervals deferred);",
      "no coverage claims until MCSE<=0.01 on full run;",
      "n_rep =", n_fit_ok, "of planned", planned_reps
    ),
    stringsAsFactors    = FALSE
  )
}

# ===========================================================================
# MAIN
# ===========================================================================
args        <- parse_args(commandArgs(TRUE))
load_result <- try_load_drmTMB(args$attempt_temp_install)

# Print shard map (useful reference in cluster logs)
message("[grid] Shard map:")
for (i in seq_len(nrow(SHARD_MAP))) {
  message(sprintf("  shard %2d: provider=%-8s  target=%s",
                  SHARD_MAP$shard[i], SHARD_MAP$provider[i], SHARD_MAP$target[i]))
}
message("[grid] 16 direct-SD shards; derived correlations (24 targets) NOT in this grid.")

# Validate shard arg
if (is.na(args$shard) || args$shard < 1L || args$shard > 16L) {
  stop(sprintf(
    "Invalid --shard=%s. Must be an integer 1..16. Use --shard=N.",
    args$shard
  ), call. = FALSE)
}

shard_row      <- SHARD_MAP[SHARD_MAP$shard == args$shard, , drop = FALSE]
provider       <- shard_row$provider
endpoint_mem   <- shard_row$target
truth_sd       <- truth_for(endpoint_mem)
parm_name      <- mu_parm_name(provider, endpoint_mem)
tok            <- target_token(endpoint_mem)

message(sprintf(
  "[grid] shard=%d  provider=%s  target=%s  truth_sd=%.2f",
  args$shard, provider, endpoint_mem, truth_sd
))
message(sprintf(
  "[grid] n_rep=%d  seed_start=%d  bootstrap=%d",
  args$n_rep, args$seed_start, args$bootstrap
))

# Out directory
out_dir <- if (!is.na(args$out_dir)) {
  args$out_dir
} else {
  file.path(repo_root, "docs", "dev-log", "simulation-artifacts",
            sprintf("q4-location-coverage-grid-shard%02d", args$shard))
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

rep_file_stem <- sprintf("%02d-%s-%s", args$shard, provider, tok)
rep_path      <- file.path(out_dir, paste0(rep_file_stem, "-replicates.tsv"))
sum_path      <- file.path(out_dir, paste0(rep_file_stem, "-summary.tsv"))

# Resumability: find already-completed seeds
done_seeds <- integer(0L)
if (file.exists(rep_path)) {
  prev <- tryCatch(
    utils::read.delim(rep_path, sep = "\t", quote = "",
                      check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) NULL
  )
  if (!is.null(prev) && "seed" %in% names(prev)) {
    done_seeds <- as.integer(prev$seed[prev$attempt_status == "fit_ok"])
    done_seeds <- done_seeds[!is.na(done_seeds)]
    message(sprintf("[grid] Resume: %d seeds already completed.", length(done_seeds)))
  }
}

all_seeds    <- seq.int(args$seed_start, length.out = args$n_rep)
todo_seeds   <- setdiff(all_seeds, done_seeds)
todo_rep_ids <- match(todo_seeds, all_seeds)

message(sprintf("[grid] Seeds to run: %d (of %d total).",
                length(todo_seeds), args$n_rep))

if (!load_result$ok) {
  message("[grid] drmTMB load failed: ", load_result$detail)
  rows <- do.call(rbind,
    Map(function(seed, i) {
      empty_row(seed, i, provider, endpoint_mem, "not_attempted", load_result$detail)
    }, todo_seeds, todo_rep_ids))
  append_tsv(rows, rep_path)
  summary_out <- make_summary(rows, args$shard, provider, endpoint_mem,
                              truth_sd, args$n_rep, args$bootstrap)
  write_tsv(summary_out, sum_path)
  message("[grid] wrote ", rep_path)
  message("[grid] wrote ", sum_path)
  quit(status = 1L)
}

message(sprintf("[grid] drmTMB loaded (%s).", load_result$status))

grid_start <- proc.time()[["elapsed"]]
n_done     <- 0L

for (k in seq_along(todo_seeds)) {
  seed   <- todo_seeds[[k]]
  rep_id <- todo_rep_ids[[k]]

  row <- tryCatch(
    run_one_rep(seed, rep_id, provider, endpoint_mem, args$n_each, args$bootstrap),
    error = function(e) {
      empty_row(seed, rep_id, provider, endpoint_mem, "fit_error", conditionMessage(e))
    }
  )

  # Sanitise character columns before writing
  char_cols      <- vapply(row, is.character, logical(1L))
  row[char_cols] <- lapply(row[char_cols], clean_text)

  append_tsv(row, rep_path)
  n_done <- n_done + 1L

  if (n_done %% 10L == 0L || n_done == length(todo_seeds)) {
    elapsed <- proc.time()[["elapsed"]] - grid_start
    rate    <- if (elapsed > 0) n_done / elapsed else NA_real_
    message(sprintf(
      "[grid] rep %d/%d (seed %d): status=%s  wald=%s  profile=%s  %.1fs  (%.2f rep/s)",
      n_done, length(todo_seeds), seed,
      row$attempt_status,
      row$wald_status    %||% "NA",
      row$profile_status %||% "NA",
      elapsed, if (!is.na(rate)) rate else 0
    ))
  }
}

# Re-read all rows for summary (includes previously completed)
all_rows <- tryCatch(
  utils::read.delim(rep_path, sep = "\t", quote = "",
                    check.names = FALSE, stringsAsFactors = FALSE),
  error = function(e) NULL
)
if (is.null(all_rows)) {
  message("[grid] WARNING: could not re-read rep file for summary.")
  all_rows <- do.call(rbind,
    lapply(todo_seeds, function(s) {
      empty_row(s, match(s, all_seeds), provider, endpoint_mem, "read_error", "")
    }))
}

summary_out <- make_summary(all_rows, args$shard, provider, endpoint_mem,
                            truth_sd, args$n_rep, args$bootstrap)
char_cols              <- vapply(summary_out, is.character, logical(1L))
summary_out[char_cols] <- lapply(summary_out[char_cols], clean_text)
write_tsv(summary_out, sum_path)

total_elapsed <- proc.time()[["elapsed"]] - grid_start
message("[grid] wrote ", rep_path)
message("[grid] wrote ", sum_path)
message(sprintf("[grid] DONE: shard=%d  provider=%s  target=%s",
                args$shard, provider, endpoint_mem))
message(sprintf(
  "[grid] n_fit_ok=%d  n_boundary=%d  n_wald_fin=%d  wald_cov=%.3f  wald_mcse=%.4f",
  summary_out$n_fit_ok, summary_out$n_boundary, summary_out$n_wald_finite,
  summary_out$wald_coverage, summary_out$wald_mcse
))
message(sprintf(
  "[grid] n_profile_fin=%d  prof_cov=%.3f  prof_mcse=%.4f",
  summary_out$n_profile_finite, summary_out$profile_coverage, summary_out$profile_mcse
))
message(sprintf("[grid] total elapsed %.1f s  (%.2f s/rep)",
                total_elapsed, total_elapsed / max(n_done, 1L)))

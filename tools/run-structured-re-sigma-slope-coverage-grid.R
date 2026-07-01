#!/usr/bin/env Rscript
#
# SR475 sigma-slope coverage grid runner
#
# Cluster-ready, SLURM-array-friendly runner for the 7-target sigma-slope
# coverage grid.  One shard = one (provider, target) combination.
#
# SHARD MAP (--shard=N selects one row):
#   1  phylo   sigma:(Intercept)
#   2  phylo   sigma:x
#   3  spatial sigma:(Intercept)
#   4  spatial sigma:x
#   5  animal  sigma:(Intercept)          <- admitted
#   6  relmat  sigma:(Intercept)
#   7  relmat  sigma:x
#
# animal sigma:x is an EXCLUDED holdout (profile failure).
# It is not listed and --shard=5 points to animal sigma:(Intercept) only.
#
# Providers and covariance construction:
#   phylo   -- star tree (8 tips, equal branch length 1);
#              K = drmTMB:::drm_phylo_tip_covariance(tree)
#   spatial -- 8 sites on a circular arc; precision built from
#              drmTMB:::drm_spatial_coords_precision(), K = solve(precision)
#   animal  -- fixed 8-animal pedigree (half-sib structure);
#              K = drmTMB:::drm_pedigree_additive_relationship(pedigree)
#   relmat  -- AR(1)-ish K (rho=0.35 off-diag, +0.15 on diag)
#
# True parameter values (consistent with pilot, smoke, and stability-probe):
#   mu_intercept        =  0.40
#   mu_x                =  0.25
#   log_sigma_intercept = -0.90
#   sd_sigma_intercept  =  0.50   (truth for sigma:(Intercept) SD target)
#   sd_sigma_x          =  0.38   (truth for sigma:x SD target)
#
# Design: 8 groups, 20 obs/group = 160 obs total.
#
# Intervals: Wald (primary) + endpoint-profile (primary).
#   Bootstrap optional via --bootstrap=N (default 0 = off).
#
# Resumability: per-rep TSV rows are written incrementally; if the file
#   already exists and has rows for some seeds, those seeds are skipped.
#
# Outputs per shard (in --out_dir):
#   <shard>-<provider>-<target_token>-replicates.tsv   (one row per rep)
#   <shard>-<provider>-<target_token>-summary.tsv      (aggregate)
#
# CLAIM BOUNDARY: cluster-ready coverage grid runner.  No coverage claims
# until MCSE <= 0.01 is verified on the full SR475 run.

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
# Shard map
# ---------------------------------------------------------------------------
SHARD_MAP <- data.frame(
  shard = 1:7,
  provider = c(
    "phylo",
    "phylo",
    "spatial",
    "spatial",
    "animal",
    "relmat",
    "relmat"
  ),
  target = c(
    "sigma:(Intercept)",
    "sigma:x",
    "sigma:(Intercept)",
    "sigma:x",
    "sigma:(Intercept)",
    "sigma:(Intercept)",
    "sigma:x"
  ),
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# CLI parsing
# ---------------------------------------------------------------------------
parse_args <- function(args) {
  out <- list(
    shard = NA_integer_,
    n_rep = 475L,
    seed_start = 740001L,
    n_each = 20L,
    out_dir = NA_character_,
    bootstrap = 0L,
    attempt_temp_install = FALSE
  )
  for (arg in args) {
    if (startsWith(arg, "--shard=")) {
      out$shard <- as.integer(sub("^--shard=", "", arg))
    } else if (startsWith(arg, "--n_rep=")) {
      out$n_rep <- as.integer(sub("^--n_rep=", "", arg))
    } else if (startsWith(arg, "--seed_start=")) {
      out$seed_start <- as.integer(sub("^--seed_start=", "", arg))
    } else if (startsWith(arg, "--n_each=")) {
      out$n_each <- as.integer(sub("^--n_each=", "", arg))
    } else if (startsWith(arg, "--out_dir=")) {
      out$out_dir <- sub("^--out_dir=", "", arg)
    } else if (startsWith(arg, "--bootstrap=")) {
      out$bootstrap <- as.integer(sub("^--bootstrap=", "", arg))
    } else if (identical(arg, "--attempt-temp-install")) {
      out$attempt_temp_install <- TRUE
    }
  }
  out
}

# ---------------------------------------------------------------------------
# Package loading (same mechanism as coverage pilot)
# ---------------------------------------------------------------------------
script_file <- sub(
  "^--file=",
  "",
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
  if (is.null(ip)) {
    return(FALSE)
  }
  row <- ip[ip[, "Package"] == "drmTMB", "Built", drop = TRUE]
  if (length(row) == 0L || is.na(row[[1L]])) {
    return(FALSE)
  }
  running_ver <- paste(
    R.Version()$major,
    strsplit(R.Version()$minor, "\\.")[[1L]][[1L]],
    sep = "."
  )
  pkg_ver_match <- regmatches(
    row[[1L]],
    regexpr("(?<=R )\\d+\\.\\d+", row[[1L]], perl = TRUE)
  )
  if (length(pkg_ver_match) == 0L || !nzchar(pkg_ver_match)) {
    return(FALSE)
  }
  identical(running_ver, pkg_ver_match[[1L]])
}

try_load_drmTMB <- function(attempt_temp_install) {
  version_ok <- installed_drmTMB_r_version_matches()
  if (requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(list(
      ok = TRUE,
      status = if (version_ok) {
        "installed_namespace_loaded"
      } else {
        "installed_namespace_loaded_version_unchecked"
      },
      detail = if (version_ok) {
        "loaded"
      } else {
        "loaded; installed package Built field did not match running R major.minor"
      }
    ))
  }
  if (!attempt_temp_install) {
    return(list(
      ok = FALSE,
      status = "package_not_installed_or_version_mismatch",
      detail = paste(
        "drmTMB not loadable (version match:",
        version_ok,
        ")",
        "and --attempt-temp-install not requested"
      )
    ))
  }
  temp_lib <- tempfile("drmTMB-local-lib-")
  dir.create(temp_lib, recursive = TRUE, showWarnings = FALSE)
  cmd <- file.path(R.home("bin"), "R")
  output <- tryCatch(
    system2(
      cmd,
      c(
        "CMD",
        "INSTALL",
        "--no-init-file",
        "--preclean",
        shQuote(paste0("--library=", temp_lib)),
        shQuote(repo_root)
      ),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(e) conditionMessage(e)
  )
  if (!requireNamespace("drmTMB", lib.loc = temp_lib, quietly = TRUE)) {
    return(list(
      ok = FALSE,
      status = "temp_install_failed",
      detail = clean_text(paste(tail(output, 12L), collapse = " "))
    ))
  }
  .libPaths(c(temp_lib, .libPaths()))
  suppressPackageStartupMessages(library(drmTMB))
  list(
    ok = TRUE,
    status = "temp_install_loaded",
    detail = "temporary_library_current_source"
  )
}

# ---------------------------------------------------------------------------
# True parameter values
# ---------------------------------------------------------------------------
TRUTH <- list(
  mu_intercept = 0.40,
  mu_x = 0.25,
  log_sigma_intercept = -0.90,
  sd_sigma_intercept = 0.50,
  sd_sigma_x = 0.38
)

# ---------------------------------------------------------------------------
# Covariance helpers
# ---------------------------------------------------------------------------

# Star tree: 8 tips, all connected to root, equal branch length 1
star_tree <- function(n_tip = 8L) {
  root_node <- n_tip + 1L
  tips <- seq_len(n_tip)
  edge_mat <- cbind(from = rep(root_node, n_tip), to = tips)
  structure(
    list(
      edge = edge_mat,
      edge.length = rep(1, n_tip),
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = 1L
    ),
    class = "phylo"
  )
}

# Spatial: 8 sites on a circular arc
# Precision built via drm_spatial_coords_precision(); K = solve(precision).
# NOTE: the coords object is passed directly to spatial() in the formula.
spatial_coords_and_K <- function(n = 8L) {
  labels <- paste0("site_", seq_len(n))
  theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(
    x = cos(theta) + seq_len(n) / (3 * n),
    y = sin(theta)
  )
  rownames(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = labels,
    group = "site"
  )
  K <- solve(as.matrix(precision$precision))
  list(labels = labels, coords = coords, K = K)
}

# Animal: fixed 8-animal pedigree (half-sib structure, same as smoke/probe)
animal_K <- function() {
  pedigree <- data.frame(
    id = paste0("id", seq_len(8L)),
    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  K <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  labels <- rownames(K)
  list(K = K, labels = labels)
}

# AR(1)-ish K for relmat
relmat_K <- function(n_level = 8L) {
  labels <- paste0("id", seq_len(n_level))
  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(labels, labels)
  K
}

# Draw RE effects from K-structured multivariate normal
scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`)
  colnames(out) <- names(sds)
  out
}

# ---------------------------------------------------------------------------
# Data-generating process
# ---------------------------------------------------------------------------
make_sigma_slope_data <- function(provider, seed, n_each = 20L) {
  set.seed(seed)
  # g-sweep hook: GSWEEP_N_GROUPS overrides the default 8 groups (phylo/spatial/
  # relmat scale with it; animal is a fixed 8-pedigree -- do not sweep animal).
  n_groups <- as.integer(Sys.getenv("GSWEEP_N_GROUPS", "8"))

  if (identical(provider, "phylo")) {
    tree <- star_tree(n_groups)
    labels <- tree$tip.label
    K <- drmTMB:::drm_phylo_tip_covariance(tree)
    group <- "species"
    extra <- list(tree = tree)
  } else if (identical(provider, "spatial")) {
    sp <- spatial_coords_and_K(n_groups)
    labels <- sp$labels
    K <- sp$K
    group <- "site"
    extra <- list(coords = sp$coords)
  } else if (identical(provider, "animal")) {
    ak <- animal_K()
    K <- ak$K
    labels <- ak$labels
    group <- "id"
    extra <- list(A = K)
  } else if (identical(provider, "relmat")) {
    K <- relmat_K(n_groups)
    labels <- rownames(K)
    group <- "id"
    extra <- list(K = K)
  } else {
    stop("Unknown provider: ", provider, call. = FALSE)
  }

  sds <- c(
    sigma_intercept = TRUTH$sd_sigma_intercept,
    sigma_x = TRUTH$sd_sigma_x
  )
  effects <- scaled_effects(K, sds)
  rownames(effects) <- labels

  endpoint <- rep(labels, each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_groups)
  eta_mu <- TRUTH$mu_intercept + TRUTH$mu_x * x
  eta_sigma <- TRUTH$log_sigma_intercept +
    effects[endpoint, "sigma_intercept"] +
    effects[endpoint, "sigma_x"] * x
  y <- eta_mu + exp(eta_sigma) * stats::rnorm(length(x))

  dat <- data.frame(y = y, x = x, stringsAsFactors = FALSE)
  dat[[group]] <- endpoint
  c(list(data = dat, group = group, K = K, labels = labels), extra)
}

# ---------------------------------------------------------------------------
# Fitting
# ---------------------------------------------------------------------------
fit_sigma_slope <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(y ~ x, sigma ~ phylo(1 + x | species, tree = tree))
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords))
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(y ~ x, sigma ~ animal(1 + x | id, A = A))
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(y ~ x, sigma ~ relmat(1 + x | id, K = K))
  }

  drmTMB(
    form,
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400))
  )
}

# ---------------------------------------------------------------------------
# Parameter name helpers
# ---------------------------------------------------------------------------
sigma_group <- function(provider) {
  switch(
    provider,
    phylo = "species",
    spatial = "site",
    animal = "id",
    relmat = "id"
  )
}

sigma_parm_name <- function(provider, endpoint_member) {
  grp <- sigma_group(provider)
  coef <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    "1"
  } else {
    "0 + x"
  }
  paste0("sd:sigma:", provider, "(", coef, " | ", grp, ")")
}

sd_label_in_sdpars <- function(provider, endpoint_member) {
  grp <- sigma_group(provider)
  coef <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    "1"
  } else {
    "0 + x"
  }
  paste0(provider, "(", coef, " | ", grp, ")")
}

target_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

truth_for <- function(endpoint_member) {
  if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    TRUTH$sd_sigma_intercept
  } else {
    TRUTH$sd_sigma_x
  }
}

# ---------------------------------------------------------------------------
# Interval computation
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
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  list(
    lower = lower,
    upper = upper,
    status = if (is.finite(lower) && is.finite(upper)) {
      "finite"
    } else {
      "nonfinite"
    },
    message = NA_character_,
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

run_profile <- function(fit, parm_name) {
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm = parm_name,
        method = "profile",
        level = 0.95,
        profile_engine = "endpoint",
        trace = FALSE,
        profile_endpoint_max_eval = 90L
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  finite <- is.finite(lower) && is.finite(upper)
  conf_status <- if ("conf.status" %in% names(result)) {
    clean_text(as.character(result$conf.status[[1L]]))
  } else {
    NA_character_
  }
  list(
    lower = lower,
    upper = upper,
    status = if (finite) "finite" else "nonfinite",
    conf_status = conf_status,
    message = if ("profile.message" %in% names(result)) {
      clean_text(as.character(result$profile.message[[1L]]))
    } else {
      NA_character_
    },
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

run_bootstrap <- function(fit, parm_name, R) {
  if (R <= 0L) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "skipped",
      message = "bootstrap_off",
      warnings = NA_character_
    ))
  }
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm = parm_name,
        method = "bootstrap",
        level = 0.95,
        R = R,
        seed = 42L
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  list(
    lower = lower,
    upper = upper,
    status = if (is.finite(lower) && is.finite(upper)) {
      "finite"
    } else {
      "nonfinite"
    },
    message = NA_character_,
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

# Coverage helper (NA if non-finite)
covers <- function(truth, lower, upper) {
  if (is.finite(lower) && is.finite(upper)) {
    truth >= lower & truth <= upper
  } else {
    NA
  }
}

# ---------------------------------------------------------------------------
# Empty row (for errors/not-attempted)
# ---------------------------------------------------------------------------
empty_row <- function(seed, rep_id, provider, endpoint_member, status, msg) {
  parm_name <- sigma_parm_name(provider, endpoint_member)
  truth_sd <- truth_for(endpoint_member)
  data.frame(
    replicate_id = rep_id,
    seed = seed,
    provider = provider,
    endpoint_member = endpoint_member,
    target_parm = parm_name,
    truth_sd = truth_sd,
    attempt_status = status,
    message = clean_text(msg),
    convergence = NA_integer_,
    pdHess = NA,
    is_boundary = NA,
    estimate_sd = NA_real_,
    wald_lower = NA_real_,
    wald_upper = NA_real_,
    wald_status = NA_character_,
    wald_warnings = NA_character_,
    wald_contains = NA,
    profile_lower = NA_real_,
    profile_upper = NA_real_,
    profile_status = NA_character_,
    profile_conf_status = NA_character_,
    profile_message = NA_character_,
    profile_warnings = NA_character_,
    profile_contains = NA,
    bootstrap_lower = NA_real_,
    bootstrap_upper = NA_real_,
    bootstrap_status = NA_character_,
    bootstrap_warnings = NA_character_,
    bootstrap_contains = NA,
    elapsed_sec = NA_real_,
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Per-replicate runner
# ---------------------------------------------------------------------------
run_one_rep <- function(
  seed,
  rep_id,
  provider,
  endpoint_member,
  n_each,
  bootstrap_R
) {
  parm_name <- sigma_parm_name(provider, endpoint_member)
  truth_sd <- truth_for(endpoint_member)
  sd_label <- sd_label_in_sdpars(provider, endpoint_member)

  sim <- tryCatch(
    make_sigma_slope_data(provider, seed, n_each),
    error = function(e) e
  )
  if (inherits(sim, "error")) {
    return(empty_row(
      seed,
      rep_id,
      provider,
      endpoint_member,
      "sim_error",
      conditionMessage(sim)
    ))
  }

  warnings_fit <- character()
  t_elapsed <- system.time({
    fit <- withCallingHandlers(
      tryCatch(
        fit_sigma_slope(provider, sim),
        error = function(e) e
      ),
      warning = function(w) {
        warnings_fit <<- c(warnings_fit, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })

  if (inherits(fit, "error")) {
    return(empty_row(
      seed,
      rep_id,
      provider,
      endpoint_member,
      "fit_error",
      conditionMessage(fit)
    ))
  }

  # Detect boundary: convergence != 0 or pdHess FALSE
  conv <- fit$opt$convergence
  pd_hess <- isTRUE(fit$sdr$pdHess)
  is_bdry <- (conv != 0L) || !pd_hess

  # Point estimate
  sdpars_sigma <- fit$sdpars$sigma
  est_sd <- unname(sdpars_sigma[[sd_label]])

  # Intervals
  t_wald_start <- proc.time()[["elapsed"]]
  wi <- run_wald(fit, parm_name)
  t_wald_end <- proc.time()[["elapsed"]]

  t_prof_start <- proc.time()[["elapsed"]]
  pi <- run_profile(fit, parm_name)
  t_prof_end <- proc.time()[["elapsed"]]

  bi <- run_bootstrap(fit, parm_name, bootstrap_R)

  data.frame(
    replicate_id = rep_id,
    seed = seed,
    provider = provider,
    endpoint_member = endpoint_member,
    target_parm = parm_name,
    truth_sd = truth_sd,
    attempt_status = "fit_ok",
    message = clean_text(paste(warnings_fit, collapse = "; ")),
    convergence = conv,
    pdHess = pd_hess,
    is_boundary = is_bdry,
    estimate_sd = if (is.null(est_sd)) NA_real_ else est_sd,
    wald_lower = wi$lower,
    wald_upper = wi$upper,
    wald_status = wi$status,
    wald_warnings = wi$warnings,
    wald_contains = covers(truth_sd, wi$lower, wi$upper),
    profile_lower = pi$lower,
    profile_upper = pi$upper,
    profile_status = pi$status,
    profile_conf_status = if (!is.null(pi$conf_status)) {
      pi$conf_status
    } else {
      NA_character_
    },
    profile_message = pi$message,
    profile_warnings = pi$warnings,
    profile_contains = covers(truth_sd, pi$lower, pi$upper),
    bootstrap_lower = bi$lower,
    bootstrap_upper = bi$upper,
    bootstrap_status = bi$status,
    bootstrap_warnings = bi$warnings,
    bootstrap_contains = covers(truth_sd, bi$lower, bi$upper),
    elapsed_sec = unname(t_elapsed[["elapsed"]]),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Summary for a shard
# ---------------------------------------------------------------------------
make_summary <- function(
  rows,
  shard,
  provider,
  endpoint_member,
  truth_sd,
  planned_reps,
  bootstrap_R
) {
  parm_name <- sigma_parm_name(provider, endpoint_member)
  fit_ok_rows <- rows[rows$attempt_status == "fit_ok", , drop = FALSE]
  n_fit_ok <- nrow(fit_ok_rows)
  n_converged <- sum(
    !is.na(fit_ok_rows$convergence) &
      fit_ok_rows$convergence == 0L,
    na.rm = TRUE
  )
  n_pdhess <- sum(isTRUE(fit_ok_rows$pdHess) | fit_ok_rows$pdHess, na.rm = TRUE)
  n_boundary <- sum(
    !is.na(fit_ok_rows$is_boundary) &
      fit_ok_rows$is_boundary,
    na.rm = TRUE
  )

  # Wald
  wald_finite <- fit_ok_rows[
    !is.na(fit_ok_rows$wald_lower) &
      is.finite(fit_ok_rows$wald_lower) &
      is.finite(fit_ok_rows$wald_upper),
    ,
    drop = FALSE
  ]
  n_wald_fin <- nrow(wald_finite)
  n_wald_cov <- sum(
    !is.na(wald_finite$wald_contains) &
      wald_finite$wald_contains,
    na.rm = TRUE
  )
  wald_cov <- if (n_wald_fin > 0L) n_wald_cov / n_wald_fin else NA_real_
  wald_mcse <- if (!is.na(wald_cov) && n_wald_fin > 0L) {
    sqrt(wald_cov * (1 - wald_cov) / n_wald_fin)
  } else {
    NA_real_
  }

  # Profile
  prof_finite <- fit_ok_rows[
    !is.na(fit_ok_rows$profile_lower) &
      is.finite(fit_ok_rows$profile_lower) &
      is.finite(fit_ok_rows$profile_upper),
    ,
    drop = FALSE
  ]
  n_prof_fin <- nrow(prof_finite)
  n_prof_cov <- sum(
    !is.na(prof_finite$profile_contains) &
      prof_finite$profile_contains,
    na.rm = TRUE
  )
  prof_cov <- if (n_prof_fin > 0L) n_prof_cov / n_prof_fin else NA_real_
  prof_mcse <- if (!is.na(prof_cov) && n_prof_fin > 0L) {
    sqrt(prof_cov * (1 - prof_cov) / n_prof_fin)
  } else {
    NA_real_
  }

  # Bootstrap (may be all skipped)
  boot_finite <- fit_ok_rows[
    !is.na(fit_ok_rows$bootstrap_lower) &
      is.finite(fit_ok_rows$bootstrap_lower) &
      is.finite(fit_ok_rows$bootstrap_upper),
    ,
    drop = FALSE
  ]
  n_boot_fin <- nrow(boot_finite)
  n_boot_cov <- sum(
    !is.na(boot_finite$bootstrap_contains) &
      boot_finite$bootstrap_contains,
    na.rm = TRUE
  )
  boot_cov <- if (n_boot_fin > 0L) n_boot_cov / n_boot_fin else NA_real_

  mean_est <- mean(fit_ok_rows$estimate_sd, na.rm = TRUE)

  data.frame(
    shard = shard,
    provider = provider,
    endpoint_member = endpoint_member,
    target_parm = parm_name,
    truth_sd = truth_sd,
    planned_reps = planned_reps,
    n_fit_ok = n_fit_ok,
    n_fit_error = sum(rows$attempt_status == "fit_error"),
    n_sim_error = sum(rows$attempt_status == "sim_error"),
    n_converged = n_converged,
    n_pdhess = n_pdhess,
    n_boundary = n_boundary,
    n_wald_finite = n_wald_fin,
    n_wald_covered = n_wald_cov,
    wald_coverage = round(wald_cov, 4L),
    wald_mcse = round(wald_mcse, 4L),
    n_profile_finite = n_prof_fin,
    n_profile_covered = n_prof_cov,
    profile_coverage = round(prof_cov, 4L),
    profile_mcse = round(prof_mcse, 4L),
    n_bootstrap_finite = n_boot_fin,
    n_bootstrap_covered = n_boot_cov,
    bootstrap_coverage = round(boot_cov, 4L),
    bootstrap_R = bootstrap_R,
    mean_est_sd = round(mean_est, 4L),
    bias_mean_est = round(mean_est - truth_sd, 4L),
    # SR475 denominator floor + non-degenerate guard: a saturated-coverage MCSE
    # of exactly 0 (p in {0,1}) must not fake a threshold pass, and a sub-475
    # smoke denominator is never coverage-evaluable. NA = "not assessable".
    mcse_threshold_met = if (!is.na(wald_mcse) && planned_reps >= 475L && wald_mcse > 0) wald_mcse <= 0.01 else NA,
    denominator_status = "grid_shard_local_or_cluster",
    coverage_evaluable = "pending_mcse_check",
    claim_boundary = paste(
      provider,
      "sigma-slope coverage grid shard only;",
      "no coverage claims until MCSE<=0.01 on full SR475 run;",
      "n_rep =",
      n_fit_ok,
      "of planned",
      planned_reps
    ),
    stringsAsFactors = FALSE
  )
}

# ===========================================================================
# MAIN
# ===========================================================================
args <- parse_args(commandArgs(TRUE))
load_result <- try_load_drmTMB(args$attempt_temp_install)

# Print shard map always (useful for reference in cluster logs)
message("[grid] Shard map:")
for (i in seq_len(nrow(SHARD_MAP))) {
  message(sprintf(
    "  shard %d: provider=%-8s  target=%s",
    SHARD_MAP$shard[i],
    SHARD_MAP$provider[i],
    SHARD_MAP$target[i]
  ))
}
message(
  "[grid] animal sigma:x is an EXCLUDED holdout (profile failure) -- not in this map."
)

# Validate shard arg
if (is.na(args$shard) || args$shard < 1L || args$shard > 7L) {
  stop(
    sprintf(
      "Invalid --shard=%s. Must be an integer 1..7. Use --shard=N.",
      args$shard
    ),
    call. = FALSE
  )
}

shard_row <- SHARD_MAP[SHARD_MAP$shard == args$shard, , drop = FALSE]
provider <- shard_row$provider
endpoint_mem <- shard_row$target
truth_sd <- truth_for(endpoint_mem)
parm_name <- sigma_parm_name(provider, endpoint_mem)
tok <- target_token(endpoint_mem)

message(sprintf(
  "[grid] shard=%d  provider=%s  target=%s  truth_sd=%.2f",
  args$shard,
  provider,
  endpoint_mem,
  truth_sd
))
message(sprintf(
  "[grid] n_rep=%d  seed_start=%d  bootstrap=%d",
  args$n_rep,
  args$seed_start,
  args$bootstrap
))

# Out directory
out_dir <- if (!is.na(args$out_dir)) {
  args$out_dir
} else {
  file.path(
    repo_root,
    "docs",
    "dev-log",
    "simulation-artifacts",
    sprintf("sigma-slope-coverage-grid-shard%02d", args$shard)
  )
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

rep_file_stem <- sprintf("%02d-%s-%s", args$shard, provider, tok)
rep_path <- file.path(out_dir, paste0(rep_file_stem, "-replicates.tsv"))
sum_path <- file.path(out_dir, paste0(rep_file_stem, "-summary.tsv"))

# Resumability: find already-completed seeds
done_seeds <- integer(0L)
if (file.exists(rep_path)) {
  prev <- tryCatch(
    utils::read.delim(
      rep_path,
      sep = "\t",
      quote = "",
      check.names = FALSE,
      stringsAsFactors = FALSE
    ),
    error = function(e) NULL
  )
  if (!is.null(prev) && "seed" %in% names(prev)) {
    done_seeds <- as.integer(prev$seed[prev$attempt_status == "fit_ok"])
    done_seeds <- done_seeds[!is.na(done_seeds)]
    message(sprintf(
      "[grid] Resume: %d seeds already completed.",
      length(done_seeds)
    ))
  }
}

all_seeds <- seq.int(args$seed_start, length.out = args$n_rep)
todo_seeds <- setdiff(all_seeds, done_seeds)
todo_rep_ids <- match(todo_seeds, all_seeds)

message(sprintf(
  "[grid] Seeds to run: %d (of %d total).",
  length(todo_seeds),
  args$n_rep
))

if (!load_result$ok) {
  message("[grid] drmTMB load failed: ", load_result$detail)
  rows <- do.call(
    rbind,
    Map(
      function(seed, i) {
        empty_row(
          seed,
          i,
          provider,
          endpoint_mem,
          "not_attempted",
          load_result$detail
        )
      },
      todo_seeds,
      todo_rep_ids
    )
  )
  append_tsv(rows, rep_path)
  summary_out <- make_summary(
    rows,
    args$shard,
    provider,
    endpoint_mem,
    truth_sd,
    args$n_rep,
    args$bootstrap
  )
  write_tsv(summary_out, sum_path)
  message("[grid] wrote ", rep_path)
  message("[grid] wrote ", sum_path)
  quit(status = 1L)
}

message(sprintf("[grid] drmTMB loaded (%s).", load_result$status))

grid_start <- proc.time()[["elapsed"]]
n_done <- 0L

for (k in seq_along(todo_seeds)) {
  seed <- todo_seeds[[k]]
  rep_id <- todo_rep_ids[[k]]

  row <- tryCatch(
    run_one_rep(
      seed,
      rep_id,
      provider,
      endpoint_mem,
      args$n_each,
      args$bootstrap
    ),
    error = function(e) {
      empty_row(
        seed,
        rep_id,
        provider,
        endpoint_mem,
        "fit_error",
        conditionMessage(e)
      )
    }
  )

  # Clean character columns before writing
  char_cols <- vapply(row, is.character, logical(1L))
  row[char_cols] <- lapply(row[char_cols], clean_text)

  append_tsv(row, rep_path)
  n_done <- n_done + 1L

  if (n_done %% 10L == 0L || n_done == length(todo_seeds)) {
    elapsed <- proc.time()[["elapsed"]] - grid_start
    rate <- if (elapsed > 0) n_done / elapsed else NA_real_
    message(sprintf(
      "[grid] rep %d/%d (seed %d): status=%s  wald=%s  profile=%s  %.1fs  (%.2f rep/s)",
      n_done,
      length(todo_seeds),
      seed,
      row$attempt_status,
      row$wald_status %||% "NA",
      row$profile_status %||% "NA",
      elapsed,
      if (!is.na(rate)) rate else 0
    ))
  }
}

# Re-read all rows for summary (includes previously completed)
all_rows <- tryCatch(
  utils::read.delim(
    rep_path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  ),
  error = function(e) NULL
)
if (is.null(all_rows)) {
  message("[grid] WARNING: could not re-read rep file for summary.")
  all_rows <- do.call(
    rbind,
    lapply(todo_seeds, function(s) {
      empty_row(
        s,
        match(s, all_seeds),
        provider,
        endpoint_mem,
        "read_error",
        ""
      )
    })
  )
}

summary_out <- make_summary(
  all_rows,
  args$shard,
  provider,
  endpoint_mem,
  truth_sd,
  args$n_rep,
  args$bootstrap
)

# Clean summary
char_cols <- vapply(summary_out, is.character, logical(1L))
summary_out[char_cols] <- lapply(summary_out[char_cols], clean_text)
write_tsv(summary_out, sum_path)

total_elapsed <- proc.time()[["elapsed"]] - grid_start

message("[grid] wrote ", rep_path)
message("[grid] wrote ", sum_path)
message(sprintf(
  "[grid] DONE: shard=%d  provider=%s  target=%s",
  args$shard,
  provider,
  endpoint_mem
))
message(sprintf(
  "[grid] n_fit_ok=%d  n_boundary=%d  n_wald_fin=%d  wald_cov=%.3f  wald_mcse=%.4f",
  summary_out$n_fit_ok,
  summary_out$n_boundary,
  summary_out$n_wald_finite,
  summary_out$wald_coverage,
  summary_out$wald_mcse
))
message(sprintf(
  "[grid] n_profile_fin=%d  prof_cov=%.3f  prof_mcse=%.4f",
  summary_out$n_profile_finite,
  summary_out$profile_coverage,
  summary_out$profile_mcse
))
message(sprintf(
  "[grid] total elapsed %.1f s  (%.2f s/rep)",
  total_elapsed,
  total_elapsed / max(n_done, 1L)
))

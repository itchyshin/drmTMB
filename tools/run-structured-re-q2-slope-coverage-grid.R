#!/usr/bin/env Rscript
#
# SR475 q2-slope coverage grid runner
#
# Cluster-ready, SLURM-array-friendly runner for the 10-target q2-slope
# bivariate location-slope coverage grid.  One shard = one (provider, target)
# combination.
#
# SHARD MAP (--shard=N selects one row):
#   1  phylo   mu1:x            sd:mu:mu1:phylo(0 + x | p | species)
#   2  phylo   mu2:x            sd:mu:mu2:phylo(0 + x | p | species)
#   3  phylo   mu1:x+mu2:x      cor:phylo:cor(mu1:x,mu2:x | p | species)
#   4  spatial mu1:x            sd:mu:mu1:spatial(0 + x | p | site)
#   5  spatial mu2:x            sd:mu:mu2:spatial(0 + x | p | site)
#   6  spatial mu1:x+mu2:x      cor:spatial:cor(mu1:x,mu2:x | p | site)
#   7  animal  mu1:x            sd:mu:mu1:animal(0 + x | p | id)
#   8  animal  mu2:x            sd:mu:mu2:animal(0 + x | p | id)
#   9  relmat  mu1:x            sd:mu:mu1:relmat(0 + x | p | id)
#  10  relmat  mu2:x            sd:mu:mu2:relmat(0 + x | p | id)
#
# EXCLUDED HOLDOUTS (NOT in shard map; profile failures in smoke diagnostics):
#   animal  mu1:x+mu2:x   cor:animal:cor(mu1:x,mu2:x | p | id)
#   relmat  mu1:x+mu2:x   cor:relmat:cor(mu1:x,mu2:x | p | id)
# These two targets remain excluded until endpoint-profile failures are
# diagnosed (see structured-re-q2-slope-denominator-admission.tsv).
#
# Providers and covariance construction (DGP == model covariance by design):
#   phylo   -- balanced tree (8 tips, equal branch length 1);
#              K = drmTMB:::drm_phylo_tip_covariance(tree)
#              DGP uses same K via chol(K) draws; model passes same tree/K.
#   spatial -- 8 sites on a circular arc; fixed-covariance only;
#              precision = drmTMB:::drm_spatial_coords_precision();
#              K = solve(precision)
#              DGP uses same K; model receives same coords -> same precision.
#   animal  -- fixed 8-animal pedigree (half-sib);
#              K = drmTMB:::drm_pedigree_additive_relationship(pedigree)
#              DGP uses same K; model passes same A matrix.
#   relmat  -- AR(1)-ish K (rho=0.35 off-diag, +0.15 on diag);
#              K constructed identically in DGP and model.
#
# True parameter values (extension_seed_a variant, from denominator-extension):
#   mu1_intercept     = 0.30    mu1_x_fixef      = 0.35
#   mu2_intercept     = -0.15   mu2_x_fixef      = 0.25
#   sigma1            = 0.20    sigma2            = 0.22
#   rho12             = 0.0     (fixed; not a coverage target)
#   sd_mu1_x          = 1.05    (truth for mu1:x SD target)
#   sd_mu2_x          = 0.90    (truth for mu2:x SD target)
#   cor_mu1_mu2_x     = 0.20    (truth for correlation target)
#
# Design: 8 groups, 20 obs/group = 160 obs total (each of y1, y2).
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
# 10 executable shards: 4 providers x 2 SD targets + 2 providers x 1 cor target.
# animal/cor and relmat/cor are EXCLUDED holdouts (profile failure in smoke).
SHARD_MAP <- data.frame(
  shard = 1:10,
  provider = c(
    "phylo",
    "phylo",
    "phylo",
    "spatial",
    "spatial",
    "spatial",
    "animal",
    "animal",
    "relmat",
    "relmat"
  ),
  target = c(
    "mu1:x",
    "mu2:x",
    "mu1:x+mu2:x",
    "mu1:x",
    "mu2:x",
    "mu1:x+mu2:x",
    "mu1:x",
    "mu2:x",
    "mu1:x",
    "mu2:x"
  ),
  target_kind = c(
    "direct_sd",
    "direct_sd",
    "direct_correlation",
    "direct_sd",
    "direct_sd",
    "direct_correlation",
    "direct_sd",
    "direct_sd",
    "direct_sd",
    "direct_sd"
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
    seed_start = 730001L,
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
# Package loading
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
  if (version_ok && requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(list(
      ok = TRUE,
      status = "installed_namespace_loaded",
      detail = "loaded"
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
# True parameter values (extension_seed_a variant)
# ---------------------------------------------------------------------------
TRUTH <- list(
  mu1_intercept    =  0.30,
  mu1_x_fixef      =  0.35,
  mu2_intercept    = -0.15,
  mu2_x_fixef      =  0.25,
  sigma1           =  0.20,
  sigma2           =  0.22,
  rho12            =  0.00,
  sd_mu1_x         =  1.05,   # truth for mu1:x SD target
  sd_mu2_x         =  0.90,   # truth for mu2:x SD target
  cor_mu1_mu2_x    =  0.20    # truth for correlation target
)

# ---------------------------------------------------------------------------
# Covariance helpers
# Covariance construction is IDENTICAL in DGP and model for all providers.
# The same package functions (drm_phylo_tip_covariance, drm_spatial_coords_precision,
# drm_pedigree_additive_relationship) are used in both DGP and model formula,
# so DGP covariance == model covariance by construction.
# ---------------------------------------------------------------------------

# Balanced tree: 8 tips, equal branch length 1
balanced_tree <- function(n_tip = 8L) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

# Spatial: 8 sites on a circular arc
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

# Animal: fixed 8-animal pedigree (half-sib)
animal_K <- function() {
  pedigree <- data.frame(
    id   = paste0("id", seq_len(8L)),
    dam  = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  K <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  list(K = K, labels = rownames(K))
}

# AR(1)-ish K for relmat
relmat_K <- function(n_level = 8L) {
  labels <- paste0("id", seq_len(n_level))
  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(labels, labels)
  K
}

# Draw correlated bivariate slope effects from K-structured MVN.
# DGP covariance = K (x) Sigma_endpoint where Sigma_endpoint has the
# intended SDs and correlation.  This is exactly what the biv_gaussian
# model with (0 + x | p | group) random effects estimates.
correlated_slope_effects <- function(K, sd1, sd2, cor12) {
  endpoint_cov <- matrix(
    c(sd1^2, cor12 * sd1 * sd2, cor12 * sd1 * sd2, sd2^2),
    nrow = 2L
  )
  # base: n x 2 standard normals rotated by chol(K)
  base <- t(chol(K)) %*% matrix(stats::rnorm(nrow(K) * 2L), nrow(K), 2L)
  # scale by chol of endpoint covariance
  out <- base %*% chol(endpoint_cov)
  colnames(out) <- c("mu1_x", "mu2_x")
  out
}

# ---------------------------------------------------------------------------
# Data-generating process
# ---------------------------------------------------------------------------
make_q2_slope_data <- function(provider, seed, n_each = 20L) {
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
    ak     <- animal_K()
    K      <- ak$K
    labels <- ak$labels
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

  effects <- correlated_slope_effects(
    K,
    sd1   = TRUTH$sd_mu1_x,
    sd2   = TRUTH$sd_mu2_x,
    cor12 = TRUTH$cor_mu1_mu2_x
  )
  rownames(effects) <- labels

  endpoint <- rep(labels, each = n_each)
  x        <- rep(seq(-1.25, 1.25, length.out = n_each), times = n_groups)

  eta1 <- TRUTH$mu1_intercept + TRUTH$mu1_x_fixef * x +
    effects[endpoint, "mu1_x"] * x
  eta2 <- TRUTH$mu2_intercept + TRUTH$mu2_x_fixef * x +
    effects[endpoint, "mu2_x"] * x

  # Bivariate residual covariance (rho12 = 0; sigma1/sigma2 are fixed effects)
  res_cov <- matrix(
    c(
      TRUTH$sigma1^2,
      TRUTH$rho12 * TRUTH$sigma1 * TRUTH$sigma2,
      TRUTH$rho12 * TRUTH$sigma1 * TRUTH$sigma2,
      TRUTH$sigma2^2
    ),
    nrow = 2L
  )
  residual <- matrix(stats::rnorm(length(x) * 2L), ncol = 2L) %*% chol(res_cov)

  dat <- data.frame(
    y1 = eta1 + residual[, 1L],
    y2 = eta2 + residual[, 2L],
    x  = x,
    stringsAsFactors = FALSE
  )
  dat[[group]] <- endpoint

  c(list(data = dat, group = group, K = K, labels = labels), extra)
}

# ---------------------------------------------------------------------------
# Fitting
# The same package covariance functions that build K for the DGP also drive
# the model:
#   phylo  : model receives same `tree`; engine calls drm_phylo_tip_covariance
#   spatial: model receives same `coords`; engine calls drm_spatial_coords_precision
#   animal : model receives same `A` matrix
#   relmat : model receives same `K` matrix
# DGP covariance == model covariance by construction.
# ---------------------------------------------------------------------------
fit_q2_slope <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      mu1    = y1 ~ x + phylo(0 + x | p | species, tree = tree),
      mu2    = y2 ~ x + phylo(0 + x | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12  = ~1
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      mu1    = y1 ~ x + spatial(0 + x | p | site, coords = coords),
      mu2    = y2 ~ x + spatial(0 + x | p | site, coords = coords),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12  = ~1
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      mu1    = y1 ~ x + animal(0 + x | p | id, A = A),
      mu2    = y2 ~ x + animal(0 + x | p | id, A = A),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12  = ~1
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      mu1    = y1 ~ x + relmat(0 + x | p | id, K = K),
      mu2    = y2 ~ x + relmat(0 + x | p | id, K = K),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12  = ~1
    )
  }

  drmTMB(
    form,
    family  = biv_gaussian(),
    data    = sim$data,
    control = drm_control(optimizer = list(eval.max = 1600, iter.max = 1600))
  )
}

# ---------------------------------------------------------------------------
# Parameter name and truth helpers
# ---------------------------------------------------------------------------
group_for <- function(provider) {
  switch(
    provider,
    phylo   = "species",
    spatial = "site",
    animal  = "id",
    relmat  = "id"
  )
}

parm_name_for <- function(provider, target) {
  grp <- group_for(provider)
  if (identical(target, "mu1:x")) {
    return(paste0("sd:mu:mu1:", provider, "(0 + x | p | ", grp, ")"))
  }
  if (identical(target, "mu2:x")) {
    return(paste0("sd:mu:mu2:", provider, "(0 + x | p | ", grp, ")"))
  }
  # correlation target
  paste0("cor:", provider, ":cor(mu1:x,mu2:x | p | ", grp, ")")
}

sd_label_in_sdpars <- function(provider, target) {
  grp <- group_for(provider)
  if (identical(target, "mu1:x")) {
    return(paste0(provider, "(0 + x | p | ", grp, ")"))
  }
  if (identical(target, "mu2:x")) {
    return(paste0(provider, "(0 + x | p | ", grp, ")"))
  }
  # correlation: return NULL (extracted differently)
  NULL
}

truth_for <- function(target) {
  if (identical(target, "mu1:x"))       return(TRUTH$sd_mu1_x)
  if (identical(target, "mu2:x"))       return(TRUTH$sd_mu2_x)
  if (identical(target, "mu1:x+mu2:x")) return(TRUTH$cor_mu1_mu2_x)
  stop("Unknown target: ", target)
}

target_token <- function(target) {
  switch(
    target,
    "mu1:x"       = "mu1_x",
    "mu2:x"       = "mu2_x",
    "mu1:x+mu2:x" = "cor_mu1_mu2_x"
  )
}

# Extract the point estimate for the target from a fitted model.
# For biv_gaussian q2-slope fits:
#   fit$sdpars$mu  -- named vector, keys like "mu1:phylo(0 + x | p | species)"
#   fit$corpars    -- list keyed by provider ("phylo","spatial","animal","relmat"),
#                    each a named vector with key "cor(mu1:x,mu2:x | p | group)"
extract_estimate <- function(fit, provider, target) {
  grp <- group_for(provider)

  tryCatch(
    {
      sdp_mu <- fit$sdpars$mu   # single named vector for both mu1 and mu2
      if (identical(target, "mu1:x")) {
        key <- paste0("mu1:", provider, "(0 + x | p | ", grp, ")")
        return(unname(sdp_mu[[key]]))
      }
      if (identical(target, "mu2:x")) {
        key <- paste0("mu2:", provider, "(0 + x | p | ", grp, ")")
        return(unname(sdp_mu[[key]]))
      }
      # correlation target: fit$corpars is a list keyed by provider
      cp <- fit$corpars[[provider]]
      if (!is.null(cp)) {
        # Standard key: "cor(mu1:x,mu2:x | p | <group>)"
        cor_key <- paste0("cor(mu1:x,mu2:x | p | ", grp, ")")
        if (cor_key %in% names(cp)) {
          return(unname(cp[[cor_key]]))
        }
        # Fallback: first element
        if (length(cp) >= 1L) {
          return(unname(cp[[1L]]))
        }
      }
      NA_real_
    },
    error = function(e) NA_real_
  )
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
      lower    = NA_real_,
      upper    = NA_real_,
      status   = "error",
      message  = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  list(
    lower    = lower,
    upper    = upper,
    status   = if (is.finite(lower) && is.finite(upper)) "finite" else "nonfinite",
    message  = NA_character_,
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

run_profile <- function(fit, parm_name) {
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm                      = parm_name,
        method                    = "profile",
        level                     = 0.95,
        profile_engine            = "endpoint",
        trace                     = FALSE,
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
      lower       = NA_real_,
      upper       = NA_real_,
      status      = "error",
      conf_status = NA_character_,
      message     = clean_text(conditionMessage(result)),
      warnings    = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower  <- result$lower[[1L]]
  upper  <- result$upper[[1L]]
  finite <- is.finite(lower) && is.finite(upper)
  list(
    lower       = lower,
    upper       = upper,
    status      = if (finite) "finite" else "nonfinite",
    conf_status = if ("conf.status" %in% names(result)) {
      clean_text(as.character(result$conf.status[[1L]]))
    } else {
      NA_character_
    },
    message     = if ("profile.message" %in% names(result)) {
      clean_text(as.character(result$profile.message[[1L]]))
    } else {
      NA_character_
    },
    warnings    = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

run_bootstrap <- function(fit, parm_name, R) {
  if (R <= 0L) {
    return(list(
      lower    = NA_real_,
      upper    = NA_real_,
      status   = "skipped",
      message  = "bootstrap_off",
      warnings = NA_character_
    ))
  }
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm   = parm_name,
        method = "bootstrap",
        level  = 0.95,
        R      = R,
        seed   = 42L
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
      lower    = NA_real_,
      upper    = NA_real_,
      status   = "error",
      message  = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  list(
    lower    = lower,
    upper    = upper,
    status   = if (is.finite(lower) && is.finite(upper)) "finite" else "nonfinite",
    message  = NA_character_,
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

covers <- function(truth, lower, upper) {
  if (is.finite(lower) && is.finite(upper)) truth >= lower & truth <= upper
  else NA
}

# ---------------------------------------------------------------------------
# Empty row (for errors/not-attempted)
# ---------------------------------------------------------------------------
empty_row <- function(seed, rep_id, provider, target, status, msg) {
  parm  <- parm_name_for(provider, target)
  truth <- truth_for(target)
  data.frame(
    replicate_id         = rep_id,
    seed                 = seed,
    provider             = provider,
    target               = target,
    target_parm          = parm,
    truth_value          = truth,
    attempt_status       = status,
    message              = clean_text(msg),
    convergence          = NA_integer_,
    pdHess               = NA,
    is_boundary          = NA,
    estimate             = NA_real_,
    wald_lower           = NA_real_,
    wald_upper           = NA_real_,
    wald_status          = NA_character_,
    wald_warnings        = NA_character_,
    wald_contains        = NA,
    profile_lower        = NA_real_,
    profile_upper        = NA_real_,
    profile_status       = NA_character_,
    profile_conf_status  = NA_character_,
    profile_message      = NA_character_,
    profile_warnings     = NA_character_,
    profile_contains     = NA,
    bootstrap_lower      = NA_real_,
    bootstrap_upper      = NA_real_,
    bootstrap_status     = NA_character_,
    bootstrap_warnings   = NA_character_,
    bootstrap_contains   = NA,
    elapsed_sec          = NA_real_,
    stringsAsFactors     = FALSE
  )
}

# ---------------------------------------------------------------------------
# Per-replicate runner
# ---------------------------------------------------------------------------
run_one_rep <- function(seed, rep_id, provider, target, n_each, bootstrap_R) {
  parm  <- parm_name_for(provider, target)
  truth <- truth_for(target)

  sim <- tryCatch(
    make_q2_slope_data(provider, seed, n_each),
    error = function(e) e
  )
  if (inherits(sim, "error")) {
    return(empty_row(seed, rep_id, provider, target, "sim_error",
                     conditionMessage(sim)))
  }

  warnings_fit <- character()
  t_elapsed <- system.time({
    fit <- withCallingHandlers(
      tryCatch(
        fit_q2_slope(provider, sim),
        error = function(e) e
      ),
      warning = function(w) {
        warnings_fit <<- c(warnings_fit, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })

  if (inherits(fit, "error")) {
    return(empty_row(seed, rep_id, provider, target, "fit_error",
                     conditionMessage(fit)))
  }

  conv     <- fit$opt$convergence
  pd_hess  <- isTRUE(fit$sdr$pdHess)
  is_bdry  <- (conv != 0L) || !pd_hess

  est      <- extract_estimate(fit, provider, target)

  wi <- run_wald(fit, parm)
  pi <- run_profile(fit, parm)
  bi <- run_bootstrap(fit, parm, bootstrap_R)

  data.frame(
    replicate_id         = rep_id,
    seed                 = seed,
    provider             = provider,
    target               = target,
    target_parm          = parm,
    truth_value          = truth,
    attempt_status       = "fit_ok",
    message              = clean_text(paste(warnings_fit, collapse = "; ")),
    convergence          = conv,
    pdHess               = pd_hess,
    is_boundary          = is_bdry,
    estimate             = if (is.null(est) || length(est) == 0L) NA_real_ else est,
    wald_lower           = wi$lower,
    wald_upper           = wi$upper,
    wald_status          = wi$status,
    wald_warnings        = wi$warnings,
    wald_contains        = covers(truth, wi$lower, wi$upper),
    profile_lower        = pi$lower,
    profile_upper        = pi$upper,
    profile_status       = pi$status,
    profile_conf_status  = if (!is.null(pi$conf_status)) pi$conf_status else NA_character_,
    profile_message      = pi$message,
    profile_warnings     = pi$warnings,
    profile_contains     = covers(truth, pi$lower, pi$upper),
    bootstrap_lower      = bi$lower,
    bootstrap_upper      = bi$upper,
    bootstrap_status     = bi$status,
    bootstrap_warnings   = bi$warnings,
    bootstrap_contains   = covers(truth, bi$lower, bi$upper),
    elapsed_sec          = unname(t_elapsed[["elapsed"]]),
    stringsAsFactors     = FALSE
  )
}

# ---------------------------------------------------------------------------
# Summary for a shard
# ---------------------------------------------------------------------------
make_summary <- function(rows, shard, provider, target, truth, planned_reps,
                         bootstrap_R) {
  parm         <- parm_name_for(provider, target)
  fit_ok_rows  <- rows[rows$attempt_status == "fit_ok", , drop = FALSE]
  n_fit_ok     <- nrow(fit_ok_rows)
  n_converged  <- sum(
    !is.na(fit_ok_rows$convergence) & fit_ok_rows$convergence == 0L,
    na.rm = TRUE
  )
  n_pdhess     <- sum(isTRUE(fit_ok_rows$pdHess) | fit_ok_rows$pdHess,
                      na.rm = TRUE)
  n_boundary   <- sum(
    !is.na(fit_ok_rows$is_boundary) & fit_ok_rows$is_boundary,
    na.rm = TRUE
  )

  # Wald
  wald_fin <- fit_ok_rows[
    !is.na(fit_ok_rows$wald_lower) &
      is.finite(fit_ok_rows$wald_lower) &
      is.finite(fit_ok_rows$wald_upper), , drop = FALSE
  ]
  n_wald_fin <- nrow(wald_fin)
  n_wald_cov <- sum(!is.na(wald_fin$wald_contains) & wald_fin$wald_contains,
                    na.rm = TRUE)
  wald_cov   <- if (n_wald_fin > 0L) n_wald_cov / n_wald_fin else NA_real_
  wald_mcse  <- if (!is.na(wald_cov) && n_wald_fin > 0L) {
    sqrt(wald_cov * (1 - wald_cov) / n_wald_fin)
  } else {
    NA_real_
  }

  # Profile
  prof_fin <- fit_ok_rows[
    !is.na(fit_ok_rows$profile_lower) &
      is.finite(fit_ok_rows$profile_lower) &
      is.finite(fit_ok_rows$profile_upper), , drop = FALSE
  ]
  n_prof_fin <- nrow(prof_fin)
  n_prof_cov <- sum(!is.na(prof_fin$profile_contains) & prof_fin$profile_contains,
                    na.rm = TRUE)
  prof_cov   <- if (n_prof_fin > 0L) n_prof_cov / n_prof_fin else NA_real_
  prof_mcse  <- if (!is.na(prof_cov) && n_prof_fin > 0L) {
    sqrt(prof_cov * (1 - prof_cov) / n_prof_fin)
  } else {
    NA_real_
  }

  # Bootstrap
  boot_fin <- fit_ok_rows[
    !is.na(fit_ok_rows$bootstrap_lower) &
      is.finite(fit_ok_rows$bootstrap_lower) &
      is.finite(fit_ok_rows$bootstrap_upper), , drop = FALSE
  ]
  n_boot_fin <- nrow(boot_fin)
  n_boot_cov <- sum(!is.na(boot_fin$bootstrap_contains) & boot_fin$bootstrap_contains,
                    na.rm = TRUE)
  boot_cov   <- if (n_boot_fin > 0L) n_boot_cov / n_boot_fin else NA_real_

  mean_est   <- mean(fit_ok_rows$estimate, na.rm = TRUE)

  data.frame(
    shard                    = shard,
    provider                 = provider,
    target                   = target,
    target_parm              = parm,
    truth_value              = truth,
    planned_reps             = planned_reps,
    n_fit_ok                 = n_fit_ok,
    n_fit_error              = sum(rows$attempt_status == "fit_error"),
    n_sim_error              = sum(rows$attempt_status == "sim_error"),
    n_converged              = n_converged,
    n_pdhess                 = n_pdhess,
    n_boundary               = n_boundary,
    n_wald_finite            = n_wald_fin,
    n_wald_covered           = n_wald_cov,
    wald_coverage            = round(wald_cov, 4L),
    wald_mcse                = round(wald_mcse, 4L),
    n_profile_finite         = n_prof_fin,
    n_profile_covered        = n_prof_cov,
    profile_coverage         = round(prof_cov, 4L),
    profile_mcse             = round(prof_mcse, 4L),
    n_bootstrap_finite       = n_boot_fin,
    n_bootstrap_covered      = n_boot_cov,
    bootstrap_coverage       = round(boot_cov, 4L),
    bootstrap_R              = bootstrap_R,
    mean_estimate            = round(mean_est, 4L),
    bias_mean_estimate       = round(mean_est - truth, 4L),
    # SR475 denominator floor + non-degenerate guard: a saturated-coverage MCSE
    # of exactly 0 (p in {0,1}) must not fake a threshold pass, and a sub-475
    # smoke denominator is never coverage-evaluable. NA = "not assessable".
    # Wald-only; profile_mcse is reported but not gated -- see after-task note.
    mcse_threshold_met       = if (!is.na(wald_mcse) && planned_reps >= 475L && wald_mcse > 0) wald_mcse <= 0.01 else NA,
    denominator_status       = "grid_shard_local_or_cluster",
    coverage_evaluable       = "pending_mcse_check",
    claim_boundary           = paste(
      provider, "q2-slope coverage grid shard only;",
      "no coverage claims until MCSE<=0.01 on full SR475 run;",
      "n_rep =", n_fit_ok, "of planned", planned_reps
    ),
    stringsAsFactors = FALSE
  )
}

# ===========================================================================
# MAIN
# ===========================================================================
args        <- parse_args(commandArgs(TRUE))
load_result <- try_load_drmTMB(args$attempt_temp_install)

# Print shard map
message("[grid] Shard map:")
for (i in seq_len(nrow(SHARD_MAP))) {
  message(sprintf(
    "  shard %d: provider=%-8s  target=%-20s  kind=%s",
    SHARD_MAP$shard[i],
    SHARD_MAP$provider[i],
    SHARD_MAP$target[i],
    SHARD_MAP$target_kind[i]
  ))
}
message(
  "[grid] EXCLUDED HOLDOUTS (not in map; profile failures):",
  " animal cor(mu1:x,mu2:x) and relmat cor(mu1:x,mu2:x)"
)

# Validate shard arg
if (is.na(args$shard) || args$shard < 1L || args$shard > 10L) {
  stop(
    sprintf(
      "Invalid --shard=%s. Must be an integer 1..10. Use --shard=N.",
      args$shard
    ),
    call. = FALSE
  )
}

shard_row    <- SHARD_MAP[SHARD_MAP$shard == args$shard, , drop = FALSE]
provider     <- shard_row$provider
target       <- shard_row$target
truth        <- truth_for(target)
parm         <- parm_name_for(provider, target)
tok          <- target_token(target)

message(sprintf(
  "[grid] shard=%d  provider=%s  target=%s  truth=%.3f",
  args$shard, provider, target, truth
))
message(sprintf(
  "[grid] parm_name=%s", parm
))
message(sprintf(
  "[grid] n_rep=%d  seed_start=%d  bootstrap=%d",
  args$n_rep, args$seed_start, args$bootstrap
))

# Out directory
out_dir <- if (!is.na(args$out_dir)) {
  args$out_dir
} else {
  file.path(
    repo_root,
    "docs", "dev-log", "simulation-artifacts",
    sprintf("q2-slope-coverage-grid-shard%02d", args$shard)
  )
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

rep_file_stem <- sprintf("%02d-%s-%s", args$shard, provider, tok)
rep_path      <- file.path(out_dir, paste0(rep_file_stem, "-replicates.tsv"))
sum_path      <- file.path(out_dir, paste0(rep_file_stem, "-summary.tsv"))

# Resumability: find already-completed seeds
done_seeds <- integer(0L)
if (file.exists(rep_path)) {
  prev <- tryCatch(
    utils::read.delim(
      rep_path, sep = "\t", quote = "", check.names = FALSE,
      stringsAsFactors = FALSE
    ),
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

message(sprintf(
  "[grid] Seeds to run: %d (of %d total).",
  length(todo_seeds), args$n_rep
))

if (!load_result$ok) {
  message("[grid] drmTMB load failed: ", load_result$detail)
  rows <- do.call(rbind, Map(
    function(seed, i) {
      empty_row(seed, i, provider, target, "not_attempted", load_result$detail)
    },
    todo_seeds, todo_rep_ids
  ))
  append_tsv(rows, rep_path)
  summary_out <- make_summary(
    rows, args$shard, provider, target, truth, args$n_rep, args$bootstrap
  )
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
    run_one_rep(seed, rep_id, provider, target, args$n_each, args$bootstrap),
    error = function(e) {
      empty_row(seed, rep_id, provider, target, "fit_error", conditionMessage(e))
    }
  )

  char_cols    <- vapply(row, is.character, logical(1L))
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
      row$wald_status   %||% "NA",
      row$profile_status %||% "NA",
      elapsed,
      if (!is.na(rate)) rate else 0
    ))
  }
}

# Re-read all rows for summary
all_rows <- tryCatch(
  utils::read.delim(
    rep_path, sep = "\t", quote = "", check.names = FALSE,
    stringsAsFactors = FALSE
  ),
  error = function(e) NULL
)
if (is.null(all_rows)) {
  message("[grid] WARNING: could not re-read rep file for summary.")
  all_rows <- do.call(rbind, lapply(todo_seeds, function(s) {
    empty_row(s, match(s, all_seeds), provider, target, "read_error", "")
  }))
}

summary_out <- make_summary(
  all_rows, args$shard, provider, target, truth, args$n_rep, args$bootstrap
)
char_cols              <- vapply(summary_out, is.character, logical(1L))
summary_out[char_cols] <- lapply(summary_out[char_cols], clean_text)
write_tsv(summary_out, sum_path)

total_elapsed <- proc.time()[["elapsed"]] - grid_start

message("[grid] wrote ", rep_path)
message("[grid] wrote ", sum_path)
message(sprintf(
  "[grid] DONE: shard=%d  provider=%s  target=%s",
  args$shard, provider, target
))
message(sprintf(
  "[grid] n_fit_ok=%d  n_boundary=%d  n_wald_fin=%d  wald_cov=%.3f  wald_mcse=%.4f",
  summary_out$n_fit_ok, summary_out$n_boundary, summary_out$n_wald_finite,
  summary_out$wald_coverage, summary_out$wald_mcse
))
message(sprintf(
  "[grid] n_profile_fin=%d  prof_cov=%.3f  prof_mcse=%.4f",
  summary_out$n_profile_finite, summary_out$profile_coverage,
  summary_out$profile_mcse
))
message(sprintf(
  "[grid] total elapsed %.1f s  (%.2f s/rep)",
  total_elapsed, total_elapsed / max(n_done, 1L)
))

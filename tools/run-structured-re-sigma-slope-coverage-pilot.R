#!/usr/bin/env Rscript
#
# Local coverage pilot: Gaussian structured-RE sigma one-slope direct-SD target
#
# Providers:   phylo (star tree, 8 tips) and relmat (AR(1)-ish K, 8 groups)
# Targets:     sigma:(Intercept) SD  and  sigma:x SD
# Family:      gaussian()
# Formula:     y ~ x, sigma ~ <provider>(1 + x | <group>, ...)
# Replicates:  100 per provider/target pair  (seeds 820001:820100)
# Interval:    Wald, 95% level, computed by confint(fit, parm = ..., method = "wald")
#              The SD lives on the response scale; confint back-transforms from
#              log(SD) +/- z*se_log via exp().
# Coverage:    fraction of 100 Wald intervals that contain the known true SD.
#
# Truth values (constant across all seeds):
#   mu_intercept         =  0.40  (fixed)
#   mu_x                 =  0.25  (fixed)
#   log_sigma_intercept  = -0.90  (fixed log residual SD intercept)
#   sd_sigma_intercept   =  0.50  (true SD of random sigma intercept)
#   sd_sigma_x           =  0.38  (true SD of random sigma x slope)
#
# These truth values are taken directly from the existing interval-smoke
# and stability-probe scripts (run-structured-re-sigma-slope-interval-smoke.R
# and run-structured-re-sigma-slope-interval-stability-probe.R).
#
# Design note: 8 groups, 20 obs per group = 160 observations total.
# That is slightly larger than the smoke (n_each = 16) but well within local
# budget.  Coverage at 100 reps has an MCSE of sqrt(0.95*0.05/100) = 0.0218.
#
# Claim boundary:  LOCAL PILOT ONLY.  No Totoro / DRAC submission.
# No denominator accounting, no MCSE <= 0.01 threshold met, no SR150.

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

parse_args <- function(args) {
  out <- list(
    n_rep = 100L,
    seed_start = 820001L,
    n_each = 20L,
    attempt_temp_install = FALSE
  )
  for (arg in args) {
    if (startsWith(arg, "--n_rep=")) {
      out$n_rep <- as.integer(sub("^--n_rep=", "", arg))
    } else if (startsWith(arg, "--seed_start=")) {
      out$seed_start <- as.integer(sub("^--seed_start=", "", arg))
    } else if (startsWith(arg, "--n_each=")) {
      out$n_each <- as.integer(sub("^--n_each=", "", arg))
    } else if (identical(arg, "--attempt-temp-install")) {
      out$attempt_temp_install <- TRUE
    }
  }
  out
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

args <- parse_args(commandArgs(TRUE))

artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-27-sigma-slope-coverage-pilot"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

replicate_path <- file.path(
  artifact_dir,
  "sigma-slope-coverage-pilot-replicates.tsv"
)
summary_path <- file.path(
  artifact_dir,
  "sigma-slope-coverage-pilot-summary.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "sigma-slope-coverage-pilot-run-log.tsv"
)

# -------------------------------------------------------------------------
# Utilities
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# Package loading (mirrors micro-shard runners; uses --attempt-temp-install)
#
# Modification vs. the standard micro-shard pattern: the installed drmTMB may
# have been compiled for a different R version and will segfault on dyn.load.
# We detect this by checking whether the installed package's Built field
# matches the running R x.y version; if not we skip the installed copy and go
# straight to temp install from source.  This is transparent when the versions
# match (the installed copy is used) and safe when they don't.
# -------------------------------------------------------------------------
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
  # Built field looks like "R 4.6.0; aarch64-apple-darwin...; ..."
  # Extract major.minor from the running R and from the Built string.
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
  if (version_ok) {
    if (requireNamespace("drmTMB", quietly = TRUE)) {
      suppressPackageStartupMessages(library(drmTMB))
      return(list(
        ok = TRUE,
        status = "installed_namespace_loaded",
        detail = "loaded"
      ))
    }
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

# -------------------------------------------------------------------------
# True parameter values (sourced from interval-smoke / stability-probe)
# -------------------------------------------------------------------------
TRUTH <- list(
  mu_intercept = 0.40,
  mu_x = 0.25,
  log_sigma_intercept = -0.90,
  sd_sigma_intercept = 0.50, # TRUE sd for sigma:(Intercept) RE
  sd_sigma_x = 0.38 # TRUE sd for sigma:x RE
)

# -------------------------------------------------------------------------
# Covariance helpers (mirrors interval-smoke pattern exactly)
# -------------------------------------------------------------------------

# Star tree for phylo: all n_tip tips connect to one root; equal branch length 1
star_tree <- function(n_tip = 8L) {
  root_node <- n_tip + 1L
  tips <- seq_len(n_tip)
  edge_mat <- cbind(
    from = rep(root_node, n_tip),
    to = tips
  )
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

# AR(1)-ish K for relmat (identical to all other relmat fixtures in this repo)
relmat_K <- function(n_level = 8L) {
  labels <- paste0("id", seq_len(n_level))
  K <- outer(
    seq_len(n_level),
    seq_len(n_level),
    function(i, j) 0.35^abs(i - j)
  )
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(labels, labels)
  K
}

# Draw scaled RE effects using the upper Cholesky factor of K
scaled_effects <- function(K, sds) {
  z <- replicate(
    length(sds),
    as.vector(t(chol(K)) %*% stats::rnorm(nrow(K)))
  )
  out <- sweep(z, 2L, sds, `*`)
  colnames(out) <- names(sds)
  out
}

# -------------------------------------------------------------------------
# Data-generating process
# -------------------------------------------------------------------------
make_sigma_slope_data <- function(provider, seed, n_each = 20L) {
  set.seed(seed)
  n_groups <- 8L

  if (identical(provider, "phylo")) {
    tree <- star_tree(n_groups)
    labels <- tree$tip.label
    K <- drmTMB:::drm_phylo_tip_covariance(tree)
    group <- "species"
    extra <- list(tree = tree)
  } else if (identical(provider, "relmat")) {
    K <- relmat_K(n_groups)
    labels <- rownames(K)
    group <- "id"
    extra <- list(K = K)
  } else {
    stop("Unknown provider: ", provider, call. = FALSE)
  }

  # Draw random sigma slopes from K-structured multivariate normal
  sds <- c(
    sigma_intercept = TRUTH$sd_sigma_intercept,
    sigma_x = TRUTH$sd_sigma_x
  )
  effects <- scaled_effects(K, sds)
  rownames(effects) <- labels

  endpoint <- rep(labels, each = n_each)
  x <- rep(
    seq(-1.2, 1.2, length.out = n_each),
    times = n_groups
  )

  # Fixed mu predictor (identity link on observed y, residuals are Gaussian)
  eta_mu <- TRUTH$mu_intercept + TRUTH$mu_x * x

  # Sigma log-linear predictor
  eta_sigma <- TRUTH$log_sigma_intercept +
    effects[endpoint, "sigma_intercept"] +
    effects[endpoint, "sigma_x"] * x

  y <- eta_mu + exp(eta_sigma) * stats::rnorm(length(x))

  dat <- data.frame(y = y, x = x, stringsAsFactors = FALSE)
  dat[[group]] <- endpoint

  c(list(data = dat, group = group, K = K, labels = labels), extra)
}

# -------------------------------------------------------------------------
# Fitting
# -------------------------------------------------------------------------
fit_sigma_slope <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      y ~ x,
      sigma ~ phylo(1 + x | species, tree = tree)
    )
  } else {
    K <- sim$K
    form <- bf(
      y ~ x,
      sigma ~ relmat(1 + x | id, K = K)
    )
  }
  drmTMB(
    form,
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400))
  )
}

# -------------------------------------------------------------------------
# Wald interval for a named parm and coverage check
# -------------------------------------------------------------------------
wald_interval <- function(fit, parm_name) {
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm = parm_name,
        method = "wald",
        level = 0.95
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

# parm name convention for sigma SD targets (matches profile.R line 1214):
#   "sd:sigma:<provider>(1 | <group>)"    for sigma:(Intercept)
#   "sd:sigma:<provider>(0 + x | <group>)" for sigma:x
sigma_parm_name <- function(provider, endpoint_member) {
  group <- if (identical(provider, "phylo")) "species" else "id"
  coefficient <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    "1"
  } else {
    "0 + x"
  }
  paste0("sd:sigma:", provider, "(", coefficient, " | ", group, ")")
}

# -------------------------------------------------------------------------
# Per-replicate runner
# -------------------------------------------------------------------------
empty_row <- function(seed, rep_id, provider, endpoint_member, status, msg) {
  data.frame(
    replicate_id = rep_id,
    seed = seed,
    provider = provider,
    endpoint_member = endpoint_member,
    target_parm = sigma_parm_name(provider, endpoint_member),
    truth_sd = if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
      TRUTH$sd_sigma_intercept
    } else {
      TRUTH$sd_sigma_x
    },
    attempt_status = status,
    message = clean_text(msg),
    convergence = NA_integer_,
    pdHess = NA,
    estimate_sd = NA_real_,
    ci_lower = NA_real_,
    ci_upper = NA_real_,
    ci_status = NA_character_,
    ci_warnings = NA_character_,
    contains_truth = NA,
    elapsed_sec = NA_real_,
    stringsAsFactors = FALSE
  )
}

run_one_rep <- function(seed, rep_id, provider, endpoint_member, n_each) {
  truth_sd <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    TRUTH$sd_sigma_intercept
  } else {
    TRUTH$sd_sigma_x
  }
  parm_name <- sigma_parm_name(provider, endpoint_member)

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

  # Extract point estimate for this target from sdpars
  sdpars_sigma <- fit$sdpars$sigma
  # The label in sdpars is the term name used inside the RE: e.g.,
  #   "relmat(1 | id)"   for sigma:(Intercept)
  #   "relmat(0 + x | id)" for sigma:x
  # Build the label directly
  group <- if (identical(provider, "phylo")) "species" else "id"
  coeff_label <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    "1"
  } else {
    "0 + x"
  }
  sd_label <- paste0(provider, "(", coeff_label, " | ", group, ")")
  est_sd <- unname(sdpars_sigma[[sd_label]])

  ci <- wald_interval(fit, parm_name)

  contains <- if (is.finite(ci$lower) && is.finite(ci$upper)) {
    truth_sd >= ci$lower & truth_sd <= ci$upper
  } else {
    NA
  }

  data.frame(
    replicate_id = rep_id,
    seed = seed,
    provider = provider,
    endpoint_member = endpoint_member,
    target_parm = parm_name,
    truth_sd = truth_sd,
    attempt_status = "fit_ok",
    message = clean_text(paste(warnings_fit, collapse = "; ")),
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    estimate_sd = if (is.null(est_sd)) NA_real_ else est_sd,
    ci_lower = ci$lower,
    ci_upper = ci$upper,
    ci_status = ci$status,
    ci_warnings = ci$warnings,
    contains_truth = contains,
    elapsed_sec = unname(t_elapsed[["elapsed"]]),
    stringsAsFactors = FALSE
  )
}

# -------------------------------------------------------------------------
# Summary by provider x endpoint_member
# -------------------------------------------------------------------------
summarise_group <- function(rows, provider, endpoint_member, truth_sd) {
  parm_name <- sigma_parm_name(provider, endpoint_member)
  fit_ok_rows <- rows[rows$attempt_status == "fit_ok", , drop = FALSE]
  n_fit_ok <- nrow(fit_ok_rows)
  n_converged <- if (n_fit_ok > 0L) {
    sum(!is.na(fit_ok_rows$convergence) & fit_ok_rows$convergence == 0L)
  } else {
    0L
  }
  n_pdhess <- if (n_fit_ok > 0L) {
    sum(!is.na(fit_ok_rows$pdHess) & fit_ok_rows$pdHess)
  } else {
    0L
  }
  finite_ci_rows <- fit_ok_rows[
    !is.na(fit_ok_rows$ci_lower) &
      is.finite(fit_ok_rows$ci_lower) &
      is.finite(fit_ok_rows$ci_upper),
    ,
    drop = FALSE
  ]
  n_finite_ci <- nrow(finite_ci_rows)
  n_covered <- if (n_finite_ci > 0L) {
    sum(!is.na(finite_ci_rows$contains_truth) & finite_ci_rows$contains_truth)
  } else {
    0L
  }
  coverage_rate <- if (n_finite_ci > 0L) n_covered / n_finite_ci else NA_real_
  mean_est <- if (n_fit_ok > 0L && any(!is.na(fit_ok_rows$estimate_sd))) {
    mean(fit_ok_rows$estimate_sd, na.rm = TRUE)
  } else {
    NA_real_
  }
  mcse_at_n <- if (!is.na(coverage_rate) && n_finite_ci > 0L) {
    sqrt(coverage_rate * (1 - coverage_rate) / n_finite_ci)
  } else {
    NA_real_
  }

  data.frame(
    provider = provider,
    endpoint_member = endpoint_member,
    target_parm = parm_name,
    truth_sd = truth_sd,
    planned_reps = nrow(rows),
    n_fit_ok = n_fit_ok,
    n_fit_error = sum(rows$attempt_status == "fit_error"),
    n_sim_error = sum(rows$attempt_status == "sim_error"),
    n_converged = n_converged,
    n_pdhess = n_pdhess,
    n_finite_ci = n_finite_ci,
    n_covered = n_covered,
    coverage_rate = round(coverage_rate, 4L),
    mcse = round(mcse_at_n, 4L),
    mean_est_sd = round(mean_est, 4L),
    bias_mean_est = round(mean_est - truth_sd, 4L),
    denominator_status = "pilot_local_only",
    coverage_evaluable = "pilot_diagnostic",
    mcse_threshold_met = "FALSE",
    claim_boundary = paste(
      provider,
      "sigma one-slope Wald coverage pilot only;",
      "local 100-rep pilot, no Totoro/DRAC submission,",
      "no SR150 denominator, no MCSE<=0.01 met,",
      "no public support promoted."
    ),
    stringsAsFactors = FALSE
  )
}

# =========================================================================
# MAIN
# =========================================================================
load_result <- try_load_drmTMB(args$attempt_temp_install)
seeds <- seq.int(args$seed_start, length.out = args$n_rep)

providers <- c("phylo", "relmat")
endpoint_members <- c("sigma:(Intercept)", "sigma:x")

all_results <- list()
pilot_start <- proc.time()[["elapsed"]]

if (!load_result$ok) {
  # Fill with not_attempted rows for every combination
  for (provider in providers) {
    for (em in endpoint_members) {
      rows <- do.call(
        rbind,
        Map(
          function(seed, i) {
            empty_row(
              seed,
              i,
              provider,
              em,
              "not_attempted",
              load_result$detail
            )
          },
          seeds,
          seq_along(seeds)
        )
      )
      all_results[[paste(provider, em, sep = ":")]] <- rows
    }
  }
} else {
  message(sprintf(
    "[pilot] drmTMB loaded (%s). Running %d reps x 2 providers x 2 targets ...",
    load_result$status,
    args$n_rep
  ))
  for (provider in providers) {
    for (em in endpoint_members) {
      key <- paste(provider, em, sep = ":")
      message(sprintf("  [pilot] %s | %s", provider, em))
      rows <- do.call(
        rbind,
        Map(
          function(seed, i) {
            tryCatch(
              run_one_rep(seed, i, provider, em, args$n_each),
              error = function(e) {
                empty_row(
                  seed,
                  i,
                  provider,
                  em,
                  "fit_error",
                  conditionMessage(e)
                )
              }
            )
          },
          seeds,
          seq_along(seeds)
        )
      )
      n_ok <- sum(rows$attempt_status == "fit_ok")
      n_cov <- sum(
        !is.na(rows$contains_truth) & rows$contains_truth,
        na.rm = TRUE
      )
      message(sprintf(
        "    fit_ok=%d/%d  covered=%d/%d (%.1f%%)",
        n_ok,
        args$n_rep,
        n_cov,
        n_ok,
        100 * if (n_ok > 0) n_cov / n_ok else NA_real_
      ))
      all_results[[key]] <- rows
    }
  }
}

pilot_elapsed <- proc.time()[["elapsed"]] - pilot_start
replicates <- do.call(rbind, all_results)

# Build summary
summary_rows <- list()
for (provider in providers) {
  for (em in endpoint_members) {
    key <- paste(provider, em, sep = ":")
    rows <- all_results[[key]]
    t_sd <- if (grepl("Intercept", em, fixed = TRUE)) {
      TRUTH$sd_sigma_intercept
    } else {
      TRUTH$sd_sigma_x
    }
    summary_rows[[key]] <- summarise_group(rows, provider, em, t_sd)
  }
}
summary_out <- do.call(rbind, summary_rows)

run_log <- data.frame(
  run_id = "sigma_slope_coverage_pilot_2026_06_27",
  pilot_script = "tools/run-structured-re-sigma-slope-coverage-pilot.R",
  providers = paste(providers, collapse = ";"),
  endpoint_members = paste(endpoint_members, collapse = ";"),
  n_rep = args$n_rep,
  n_each = args$n_each,
  n_groups = 8L,
  seed_start = min(seeds),
  seed_end = max(seeds),
  interval_method = "wald_0.95",
  interval_scale = "log_SD_backxform_exp",
  truth_mu_intercept = TRUTH$mu_intercept,
  truth_mu_x = TRUTH$mu_x,
  truth_log_sigma_intercept = TRUTH$log_sigma_intercept,
  truth_sd_sigma_intercept = TRUTH$sd_sigma_intercept,
  truth_sd_sigma_x = TRUTH$sd_sigma_x,
  phylo_structure = "star_tree_8tips_equal_branch_length_1",
  relmat_structure = "AR1ish_K_rho0.35_diag_plus_0.15",
  total_elapsed_sec = round(pilot_elapsed, 1L),
  package_load_status = load_result$status,
  compute_status = if (load_result$ok) "local_pilot_completed" else "blocked",
  denominator_status = "pilot_local_only",
  coverage_evaluable = "pilot_diagnostic",
  mcse_threshold_met = "FALSE",
  claim_boundary = paste(
    "Local 100-rep coverage pilot only;",
    "no Totoro/DRAC submission, no SR150 denominator,",
    "no MCSE<=0.01 met, no public interval support promoted."
  ),
  next_gate = paste(
    "If coverage near-nominal (0.91-0.99) for both providers and both targets,",
    "proceed to full SR475 cluster grid with shard manifests."
  ),
  stringsAsFactors = FALSE
)

# Clean character columns
for (obj_name in c("replicates", "summary_out", "run_log")) {
  obj <- get(obj_name)
  char_cols <- vapply(obj, is.character, logical(1L))
  obj[char_cols] <- lapply(obj[char_cols], clean_text)
  assign(obj_name, obj)
}

write_tsv(replicates, replicate_path)
write_tsv(summary_out, summary_path)
write_tsv(run_log, run_log_path)

message("wrote ", replicate_path)
message("wrote ", summary_path)
message("wrote ", run_log_path)
message(sprintf(
  "[pilot] total elapsed %.1f s",
  pilot_elapsed
))

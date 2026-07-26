#!/usr/bin/env Rscript
# Paired scalar A1 ML-versus-REML smoke runner.  This is plumbing evidence
# only; it must not be used as coverage evidence or to launch a Totoro job.
# Usage: Rscript a1_ml_reml_smoke.R <cell_index> <n_rep> <out_dir> [offset]

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3L || length(args) > 4L) {
  stop("Usage: a1_ml_reml_smoke.R <cell_index> <n_rep> <out_dir> [offset]", call. = FALSE)
}
cell_index <- as.integer(args[[1L]])
n_rep <- as.integer(args[[2L]])
out_dir <- args[[3L]]
offset <- if (length(args) == 4L) as.integer(args[[4L]]) else 0L
if (is.na(cell_index) || is.na(n_rep) || is.na(offset) || n_rep < 1L || offset < 0L) {
  stop("cell_index, n_rep, and offset must be valid integers.", call. = FALSE)
}
file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_path <- if (length(file_arg)) normalizePath(sub("^--file=", "", file_arg[[1L]])) else NA_character_
script_dir <- if (is.na(script_path)) getwd() else dirname(script_path)
source(file.path(script_dir, "a1_ml_reml_common.R"))
suppressPackageStartupMessages(library(drmTMB))

sha256 <- function(path) {
  tool <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else if (nzchar(Sys.which("shasum"))) "shasum" else NA_character_
  if (is.na(tool) || !file.exists(path)) return(NA_character_)
  args <- if (identical(tool, "shasum")) c("-a", "256", path) else path
  strsplit(system2(tool, args, stdout = TRUE)[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

cells <- a1_ml_reml_cells()
if (cell_index < 1L || cell_index > nrow(cells)) stop("Unknown cell index.", call. = FALSE)
cell <- cells[cell_index, , drop = FALSE]
target <- "sd:mu:(1 | g)"
source_hash <- sha256(script_path)
helper_hash <- sha256(file.path(script_dir, "a1_ml_reml_common.R"))
tarball_hash <- Sys.getenv("DRMTMB_TARBALL_SHA256", unset = NA_character_)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
rows <- vector("list", n_rep * 2L)
index <- 0L

for (r in seq_len(n_rep)) {
  seed <- 20260728L + 100000L * cell_index + offset + r
  set.seed(seed)
  g <- factor(rep(seq_len(cell$n_groups), each = cell$n_per_group))
  x <- rnorm(length(g))
  u <- rnorm(cell$n_groups, 0, cell$truth_sd)
  y <- 1 + 0.5 * x + u[as.integer(g)] + rnorm(length(g), 0, 0.7)
  dat <- data.frame(y = y, x = x, g = g)
  for (estimator in c("ML", "REML")) {
    index <- index + 1L
    reml <- identical(estimator, "REML")
    started <- Sys.time()
    fit <- suppressWarnings(try(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), gaussian(), dat, REML = reml), silent = TRUE))
    fit_sec <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    common <- list(
      study_id = "a1_scalar_ml_reml_smoke", cell_id = cell$cell_id, seed = seed,
      attempt_id = offset + r, estimator = estimator, truth_sd = cell$truth_sd,
      n_groups = cell$n_groups, n_per_group = cell$n_per_group,
      source_hash = source_hash, runner_hash = source_hash, helper_hash = helper_hash,
      package_tarball_sha256 = tarball_hash, host = unname(Sys.info()[["nodename"]]),
      timestamp = format(Sys.time(), tz = "UTC", usetz = TRUE), elapsed_fit_sec = fit_sec,
      elapsed_profile_sec = NA_real_, oracle_status = "not_run", oracle_logLik_delta = NA_real_,
      oracle_estimate_delta = NA_real_, oracle_profile_lower_delta = NA_real_, oracle_profile_upper_delta = NA_real_
    )
    if (inherits(fit, "try-error")) {
      rows[[index]] <- as.data.frame(c(common, list(
        fit_converged = FALSE, gradient_status = "fit_error", pdHess = NA, estimate_sd = NA_real_,
        profile_status = "not_run", profile_engine = NA_character_, profile_boundary = NA,
        profile_lower = NA_real_, profile_upper = NA_real_, profile_width = NA_real_, profile_covers = NA,
        profile_miss_direction = NA_character_, wald_status = "not_run", wald_lower = NA_real_,
        wald_upper = NA_real_, wald_width = NA_real_, wald_covers = NA, wald_miss_direction = NA_character_
      )), stringsAsFactors = FALSE)
      next
    }
    estimate <- summary(fit)$parameters
    estimate_sd <- estimate$estimate[estimate$parm == target]
    if (length(estimate_sd) != 1L) estimate_sd <- NA_real_
    began <- Sys.time()
    profile_ci <- suppressWarnings(try(stats::confint(fit, parm = "variance_components", method = "profile", profile_engine = "auto"), silent = TRUE))
    profile_sec <- as.numeric(difftime(Sys.time(), began, units = "secs"))
    wald_ci <- suppressWarnings(try(stats::confint(fit, parm = "variance_components", method = "wald", small_sample_df = "none", bias_correct = "none"), silent = TRUE))
    profile <- a1_ml_reml_interval_row(profile_ci, target, cell$truth_sd, "profile")
    wald <- a1_ml_reml_interval_row(wald_ci, target, cell$truth_sd, "wald")
    rows[[index]] <- as.data.frame(c(common, list(
      fit_converged = isTRUE(fit$opt$convergence == 0L), gradient_status = as.character(fit$opt$convergence),
      pdHess = isTRUE(fit$sdr$pdHess), estimate_sd = estimate_sd,
      profile_status = profile$status, profile_engine = profile$profile_engine, profile_boundary = profile$profile_boundary,
      profile_lower = profile$lower, profile_upper = profile$upper, profile_width = profile$width,
      profile_covers = profile$covers, profile_miss_direction = profile$miss_direction,
      wald_status = wald$status, wald_lower = wald$lower, wald_upper = wald$upper,
      wald_width = wald$width, wald_covers = wald$covers, wald_miss_direction = wald$miss_direction
    )), stringsAsFactors = FALSE)
    rows[[index]]$elapsed_profile_sec <- profile_sec
  }
}

out <- do.call(rbind, rows)
a1_ml_reml_validate_pairs(out)
out_file <- file.path(out_dir, sprintf("a1_ml_reml_%s_o%04d.csv", cell$cell_id, offset))
write.csv(out, out_file, row.names = FALSE)
cat("WROTE", out_file, "rows", nrow(out), "\n")

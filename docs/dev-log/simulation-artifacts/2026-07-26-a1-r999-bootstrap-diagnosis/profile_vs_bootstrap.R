#!/usr/bin/env Rscript
# Fresh paired scalar-A1 profile-versus-bootstrap runner.  This is a smoke and
# full-campaign harness only; do not launch the full 3,000-attempt campaign
# without the separate written compute approval recorded in the protocol.
#
# Usage:
#   Rscript profile_vs_bootstrap.R <cell_index> <n_rep> <R_boot> <out_dir> [offset] [shard]

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4L) {
  stop("Usage: profile_vs_bootstrap.R <cell_index> <n_rep> <R_boot> <out_dir> [offset] [shard]", call. = FALSE)
}
cell_i <- as.integer(args[[1L]])
n_rep <- as.integer(args[[2L]])
R_boot <- as.integer(args[[3L]])
out_dir <- args[[4L]]
rep_off <- if (length(args) >= 5L) as.integer(args[[5L]]) else 0L
shard <- if (length(args) >= 6L) args[[6L]] else "s00"
if (anyNA(c(cell_i, n_rep, R_boot, rep_off)) || n_rep < 1L || R_boot < 2L || rep_off < 0L) {
  stop("Cell, replication count, bootstrap count, and offset must be valid positive integers (offset >= 0).", call. = FALSE)
}

file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_path <- if (length(file_arg)) normalizePath(sub("^--file=", "", file_arg[[1L]])) else NA_character_
script_dir <- if (!is.na(script_path)) dirname(script_path) else getwd()
source(file.path(script_dir, "a1_profile_common.R"))

.libPaths(c(file.path(Sys.getenv("HOME"), "drm_work", "lib"), .libPaths()))
suppressPackageStartupMessages(library(drmTMB))
confint_formals <- names(formals(getS3method("confint", "drmTMB")))
if (!"refit_control" %in% confint_formals) {
  stop(
    "The loaded drmTMB does not expose `refit_control`; use the authenticated campaign build rather than silently changing refit controls.",
    call. = FALSE
  )
}
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

GRID <- data.frame(
  n_groups = c(10L, 25L, 50L),
  n_per = 10L,
  sd_mu = 0.5,
  cell_id = c("g10_n10_sd05", "g25_n10_sd05", "g50_n10_sd05"),
  stringsAsFactors = FALSE
)
if (cell_i < 1L || cell_i > nrow(GRID)) stop("Unknown cell index.", call. = FALSE)
cell <- GRID[cell_i, , drop = FALSE]

script_sha256 <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else if (nzchar(Sys.which("shasum"))) "shasum" else NA_character_
  if (is.na(cmd)) return(NA_character_)
  args <- if (identical(cmd, "shasum")) c("-a", "256", path) else path
  out <- suppressWarnings(system2(cmd, args, stdout = TRUE, stderr = FALSE))
  if (length(out)) strsplit(out[[1L]], "[[:space:]]+")[[1L]][[1L]] else NA_character_
}

TRUE_BETA <- 0.5
TRUE_SIGMA <- 0.7
TARGET <- "sd:mu:(1 | g)"
SOURCE_HASH <- if (!is.na(script_path)) script_sha256(script_path) else NA_character_
HELPER_HASH <- script_sha256(file.path(script_dir, "a1_profile_common.R"))
PACKAGE_COMMIT <- Sys.getenv("DRMTMB_COMMIT", unset = NA_character_)
if (identical(Sys.getenv("A1_REQUIRE_PROVENANCE"), "1") &&
    (is.na(PACKAGE_COMMIT) || !nzchar(PACKAGE_COMMIT))) {
  stop("Full campaign requires DRMTMB_COMMIT to be set and recorded.", call. = FALSE)
}
PACKAGE_VERSION <- as.character(utils::packageVersion("drmTMB"))
rows <- vector("list", n_rep)

for (r in seq_len(n_rep)) {
  seed <- 20260727L + 100000L * cell_i + rep_off + r
  set.seed(seed)
  g <- factor(rep(seq_len(cell$n_groups), each = cell$n_per))
  x <- rnorm(length(g))
  u <- rnorm(cell$n_groups, 0, cell$sd_mu)
  y <- 1 + TRUE_BETA * x + u[as.integer(g)] + rnorm(length(g), 0, TRUE_SIGMA)
  dat <- data.frame(y = y, x = x, g = g)
  started <- Sys.time()
  fit <- try(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat), silent = TRUE)
  fit_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))

  common <- list(
    study_id = "a1_scalar_profile_vs_bootstrap", cell_id = cell$cell_id,
    seed = seed, attempt_id = rep_off + r, truth_sd = cell$sd_mu,
    n_groups = cell$n_groups, n_per_group = cell$n_per,
    package_commit = PACKAGE_COMMIT, package_version = PACKAGE_VERSION,
    source_hash = SOURCE_HASH, helper_hash = HELPER_HASH,
    host = unname(Sys.info()[["nodename"]]), timestamp = format(Sys.time(), tz = "UTC", usetz = TRUE),
    elapsed_fit_sec = fit_seconds, elapsed_bootstrap_sec = NA_real_, elapsed_profile_sec = NA_real_, elapsed_wald_sec = NA_real_
  )
  if (inherits(fit, "try-error")) {
    rows[[r]] <- as.data.frame(c(common, list(
      fit_converged = FALSE, pdHess = NA,
      estimate_sd = NA_real_, bootstrap_status = "not_run", bootstrap_message = NA_character_, bootstrap_lower = NA_real_, bootstrap_upper = NA_real_, bootstrap_width = NA_real_, bootstrap_covers = NA, bootstrap_miss_direction = NA_character_,
      profile_status = "not_run", profile_engine = NA_character_, profile_boundary = NA, profile_conf_status = NA_character_, profile_message = NA_character_, profile_lower = NA_real_, profile_upper = NA_real_, profile_width = NA_real_, profile_covers = NA, profile_miss_direction = NA_character_,
      wald_status = "not_run", wald_message = NA_character_, wald_lower = NA_real_, wald_upper = NA_real_, wald_width = NA_real_, wald_covers = NA, wald_miss_direction = NA_character_, outer_status = "outer_fit_failed"
    )), stringsAsFactors = FALSE)
    next
  }
  fit_converged <- isTRUE(fit$opt$convergence == 0L)
  pd_hess <- isTRUE(fit$sdr$pdHess)
  began <- Sys.time()
  estimate_ci <- suppressWarnings(try(stats::confint(fit, parm = "variance_components", method = "wald"), silent = TRUE))
  wald_seconds <- as.numeric(difftime(Sys.time(), began, units = "secs"))
  estimate_row <- a1_interval_row(estimate_ci, TARGET, cell$sd_mu, "wald")
  parameters <- summary(fit)$parameters
  estimate_sd <- parameters$estimate[parameters$parm == TARGET]
  if (length(estimate_sd) != 1L) estimate_sd <- NA_real_

  began <- Sys.time()
  boot_ci <- suppressWarnings(try(stats::confint(
    fit, parm = "variance_components", method = "bootstrap", R = R_boot,
    seed = seed + 7L, bootstrap_re_form = NULL, refit_control = drm_control(se = FALSE)
  ), silent = TRUE))
  boot_seconds <- as.numeric(difftime(Sys.time(), began, units = "secs"))
  boot <- a1_interval_row(boot_ci, TARGET, cell$sd_mu, "bootstrap")

  began <- Sys.time()
  profile_ci <- suppressWarnings(try(stats::confint(
    fit, parm = "variance_components", method = "profile", profile_engine = "auto"
  ), silent = TRUE))
  profile_seconds <- as.numeric(difftime(Sys.time(), began, units = "secs"))
  profile <- a1_interval_row(profile_ci, TARGET, cell$sd_mu, "profile")

  rows[[r]] <- as.data.frame(c(common, list(
    fit_converged = fit_converged, pdHess = pd_hess, estimate_sd = estimate_sd,
    bootstrap_status = boot$status, bootstrap_message = boot$profile_message, bootstrap_lower = boot$lower, bootstrap_upper = boot$upper, bootstrap_width = boot$width, bootstrap_covers = boot$covers, bootstrap_miss_direction = boot$miss_direction,
    profile_status = profile$status, profile_engine = profile$profile_engine, profile_boundary = profile$profile_boundary, profile_conf_status = profile$profile_conf_status, profile_message = profile$profile_message, profile_lower = profile$lower, profile_upper = profile$upper, profile_width = profile$width, profile_covers = profile$covers, profile_miss_direction = profile$miss_direction,
    wald_status = estimate_row$status, wald_message = estimate_row$profile_message, wald_lower = estimate_row$lower, wald_upper = estimate_row$upper, wald_width = estimate_row$width, wald_covers = estimate_row$covers, wald_miss_direction = estimate_row$miss_direction,
    outer_status = if (fit_converged) "ok" else "outer_not_converged"
  )), stringsAsFactors = FALSE)
  rows[[r]]$elapsed_bootstrap_sec <- boot_seconds
  rows[[r]]$elapsed_profile_sec <- profile_seconds
  rows[[r]]$elapsed_wald_sec <- wald_seconds
}

out <- do.call(rbind, rows)
out_file <- file.path(out_dir, sprintf("%s_%s.csv", cell$cell_id, shard))
write.csv(out, out_file, row.names = FALSE)
cat("WROTE", out_file, "rows", nrow(out), "\n")

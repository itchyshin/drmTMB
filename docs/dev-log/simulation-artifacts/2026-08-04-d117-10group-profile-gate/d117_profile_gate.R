#!/usr/bin/env Rscript
# D-117 -- the 10-group profile RE-SD coverage gate.
#
# Measures the THREE unmeasured cells of the A1 10-group corner, plus a
# reproduction check of the one cell already banked on 2026-07-26. The decision
# rule was frozen in PREREGISTRATION.md and committed BEFORE this ran.
#
# Deliberately profile + Wald only: the R=999 bootstrap is ~99% of the compute,
# its 10-group behaviour is already measured (0.829), and D-117 asks about the
# PROFILE route.
#
# Usage:
#   Rscript --no-init-file d117_profile_gate.R --cell=4 --nrep=1000 --cores=24 \
#           --outdir=OUT [--repo=/path/to/drmTMB]
#
# Env: OPENBLAS_NUM_THREADS=1 is set below regardless -- TMB fits oversubscribe
# threads badly under mclapply and the box is shared.

Sys.setenv(OPENBLAS_NUM_THREADS = "1", OMP_NUM_THREADS = "1", MKL_NUM_THREADS = "1")

args <- commandArgs(trailingOnly = TRUE)
arg_of <- function(flag, default = NULL) {
  hit <- grep(paste0("^--", flag, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", flag, "="), "", hit[[1L]])
}

cell_i  <- as.integer(arg_of("cell"))
n_rep   <- as.integer(arg_of("nrep", "1000"))
n_cores <- as.integer(arg_of("cores", "1"))
out_dir <- arg_of("outdir", ".")
repo    <- arg_of("repo", NA_character_)

if (is.na(cell_i)) stop("--cell is required.", call. = FALSE)
if (n_cores > 100L) stop("Totoro etiquette: <= 100 cores.", call. = FALSE)

script_dir <- {
  f <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(f)) dirname(normalizePath(sub("^--file=", "", f[[1L]]))) else getwd()
}
source(file.path(script_dir, "a1_profile_common.R"))

if (!is.na(repo)) {
  if (!requireNamespace("pkgload", quietly = TRUE)) stop("pkgload required.", call. = FALSE)
  pkgload::load_all(repo, quiet = TRUE)
} else {
  library(drmTMB)
}

# --- the grid -------------------------------------------------------------
# Cells 1-3 are the ORIGINAL 2026-07-26 indices; reusing index 1 with the same
# seed family reproduces that cell rather than colliding with it. The new cells
# take indices 4-6 so their seeds cannot collide with any banked attempt.
GRID <- data.frame(
  cell_i   = c(1L, 4L, 5L, 6L),
  n_groups = c(10L, 10L, 10L, 10L),
  n_per    = c(10L, 4L, 4L, 10L),
  sd_mu    = c(0.5, 0.5, 1.0, 1.0),
  cell_id  = c("g10_n10_sd05", "g10_n04_sd05", "g10_n04_sd10", "g10_n10_sd10"),
  kind     = c("reproduction", "new", "new", "new"),
  stringsAsFactors = FALSE
)
cell <- GRID[GRID$cell_i == cell_i, , drop = FALSE]
if (nrow(cell) != 1L) stop("Unknown cell index: ", cell_i, call. = FALSE)

TRUE_BETA  <- 0.5
TRUE_SIGMA <- 0.7
TARGET     <- "sd:mu:(1 | g)"

sha256_of <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else if (nzchar(Sys.which("shasum"))) "shasum" else NA_character_
  if (is.na(cmd) || !file.exists(path)) return(NA_character_)
  a <- if (identical(cmd, "shasum")) c("-a", "256", path) else path
  o <- suppressWarnings(system2(cmd, a, stdout = TRUE, stderr = FALSE))
  if (length(o)) strsplit(o[[1L]], "[[:space:]]+")[[1L]][[1L]] else NA_character_
}
SOURCE_HASH <- sha256_of(file.path(script_dir, "d117_profile_gate.R"))
HELPER_HASH <- sha256_of(file.path(script_dir, "a1_profile_common.R"))
PKG_COMMIT  <- Sys.getenv("DRMTMB_COMMIT", unset = NA_character_)
PKG_VERSION <- as.character(utils::packageVersion("drmTMB"))

one_rep <- function(r) {
  seed <- 20260727L + 100000L * cell$cell_i + r
  set.seed(seed)
  g <- factor(rep(seq_len(cell$n_groups), each = cell$n_per))
  x <- rnorm(length(g))
  u <- rnorm(cell$n_groups, 0, cell$sd_mu)
  y <- 1 + TRUE_BETA * x + u[as.integer(g)] + rnorm(length(g), 0, TRUE_SIGMA)
  dat <- data.frame(y = y, x = x, g = g)

  base <- list(
    study_id = "d117_10group_profile_gate", cell_id = cell$cell_id,
    cell_kind = cell$kind, seed = seed, attempt_id = r, truth_sd = cell$sd_mu,
    n_groups = cell$n_groups, n_per_group = cell$n_per,
    package_commit = PKG_COMMIT, package_version = PKG_VERSION,
    source_hash = SOURCE_HASH, helper_hash = HELPER_HASH,
    host = unname(Sys.info()[["nodename"]]),
    timestamp = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
  na_row <- c(base, list(
    fit_converged = FALSE, pdHess = NA, estimate_sd = NA_real_,
    profile_status = "not_run", profile_engine = NA_character_,
    profile_boundary = NA, profile_conf_status = NA_character_,
    profile_message = NA_character_, profile_lower = NA_real_,
    profile_upper = NA_real_, profile_width = NA_real_, profile_covers = NA,
    profile_miss_direction = NA_character_,
    wald_status = "not_run", wald_lower = NA_real_, wald_upper = NA_real_,
    wald_width = NA_real_, wald_covers = NA, wald_miss_direction = NA_character_,
    outer_status = "outer_fit_failed", elapsed_sec = NA_real_
  ))

  t0 <- Sys.time()
  fit <- try(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat), silent = TRUE)
  if (inherits(fit, "try-error")) return(as.data.frame(na_row, stringsAsFactors = FALSE))

  fit_conv <- isTRUE(fit$opt$convergence == 0L)
  pd_hess  <- isTRUE(fit$sdr$pdHess)

  pars <- summary(fit)$parameters
  est  <- pars$estimate[pars$parm == TARGET]
  est  <- if (length(est) == 1L) est else NA_real_

  wald_ci <- suppressWarnings(try(
    stats::confint(fit, parm = "variance_components", method = "wald"), silent = TRUE))
  wald <- a1_interval_row(wald_ci, TARGET, cell$sd_mu, "wald")

  prof_ci <- suppressWarnings(try(
    stats::confint(fit, parm = "variance_components", method = "profile",
                   profile_engine = "auto"), silent = TRUE))
  prof <- a1_interval_row(prof_ci, TARGET, cell$sd_mu, "profile")

  as.data.frame(c(base, list(
    fit_converged = fit_conv, pdHess = pd_hess, estimate_sd = est,
    profile_status = prof$status, profile_engine = prof$profile_engine,
    profile_boundary = prof$profile_boundary,
    profile_conf_status = prof$profile_conf_status,
    profile_message = prof$profile_message,
    profile_lower = prof$lower, profile_upper = prof$upper,
    profile_width = prof$width, profile_covers = prof$covers,
    profile_miss_direction = prof$miss_direction,
    wald_status = wald$status, wald_lower = wald$lower, wald_upper = wald$upper,
    wald_width = wald$width, wald_covers = wald$covers,
    wald_miss_direction = wald$miss_direction,
    outer_status = if (fit_conv) "ok" else "outer_not_converged",
    elapsed_sec = as.numeric(difftime(Sys.time(), t0, units = "secs"))
  )), stringsAsFactors = FALSE)
}

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
res <- if (n_cores > 1L) {
  parallel::mclapply(seq_len(n_rep), one_rep, mc.cores = n_cores, mc.preschedule = TRUE)
} else {
  lapply(seq_len(n_rep), one_rep)
}
bad <- vapply(res, function(z) !is.data.frame(z), logical(1))
if (any(bad)) stop(sprintf("%d replicate(s) returned a non-data.frame (mclapply error).", sum(bad)), call. = FALSE)

out <- do.call(rbind, res)
f <- file.path(out_dir, sprintf("%s.csv", cell$cell_id))
write.csv(out, f, row.names = FALSE)
cat("WROTE", f, "rows", nrow(out), "\n")
cat("  coverage(profile, all-attempt) =",
    sprintf("%.4f", mean(!is.na(out$profile_covers) & out$profile_covers)), "\n")
cat("  finite intervals =", sum(out$profile_status == "valid"), "/", nrow(out), "\n")
cat("  estimate_sd < 1e-3 (boundary) =", sum(!is.na(out$estimate_sd) & out$estimate_sd < 1e-3), "\n")

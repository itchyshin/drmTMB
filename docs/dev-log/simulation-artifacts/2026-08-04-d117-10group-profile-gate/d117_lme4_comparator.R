#!/usr/bin/env Rscript
# D-117 follow-up: is the boundary-conditional coverage collapse UNIVERSAL, or
# specific to drmTMB's profile root-finder?
#
# The D-43 panel withheld the PASS because, conditional on drmTMB's own
# `profile.boundary` flag, coverage falls to 0.8566 / 0.0732 / 0.2540. Two very
# different explanations:
#   (a) universal small-sample GLMM behaviour near a variance-component boundary
#   (b) something specific to drmTMB's `endpoint` profile root-finder
# This settles it by running lme4 on the SAME DGP with the SAME SEEDS, so the
# comparison is PAIRED, not independent.
#
# Matching decisions that matter:
#   * REML = FALSE. drmTMB's default is ML (R/drmTMB.R:184); lmer's default is
#     REML = TRUE. Comparing ML to REML would confound the estimator with the
#     interval method, which is exactly the confound the panel flagged.
#   * .sig01 is lmer's RE SD for a single scalar random intercept -- the same
#     estimand as drmTMB's `sd:mu:(1 | g)`.
#   * lme4's analogue of `profile.boundary` is a singular fit, so coverage is
#     also reported conditional on isSingular().
#
# Usage:
#   Rscript --no-init-file d117_lme4_comparator.R --cell=4 --nrep=1000 --cores=90 --outdir=OUT

Sys.setenv(OPENBLAS_NUM_THREADS = "1", OMP_NUM_THREADS = "1", MKL_NUM_THREADS = "1")
suppressPackageStartupMessages(library(lme4))

args <- commandArgs(trailingOnly = TRUE)
arg_of <- function(f, d = NULL) {
  h <- grep(paste0("^--", f, "="), args, value = TRUE)
  if (!length(h)) return(d)
  sub(paste0("^--", f, "="), "", h[[1L]])
}
cell_i  <- as.integer(arg_of("cell"))
n_rep   <- as.integer(arg_of("nrep", "1000"))
n_cores <- as.integer(arg_of("cores", "1"))
out_dir <- arg_of("outdir", ".")
if (is.na(cell_i)) stop("--cell required", call. = FALSE)
if (n_cores > 100L) stop("Totoro etiquette: <= 100 cores.", call. = FALSE)

# Identical grid and cell indices to d117_profile_gate.R, so seeds line up 1:1.
GRID <- data.frame(
  cell_i   = c(1L, 4L, 5L, 6L),
  n_groups = c(10L, 10L, 10L, 10L),
  n_per    = c(10L, 4L, 4L, 10L),
  sd_mu    = c(0.5, 0.5, 1.0, 1.0),
  cell_id  = c("g10_n10_sd05", "g10_n04_sd05", "g10_n04_sd10", "g10_n10_sd10"),
  stringsAsFactors = FALSE
)
cell <- GRID[GRID$cell_i == cell_i, , drop = FALSE]
if (nrow(cell) != 1L) stop("unknown cell", call. = FALSE)

TRUE_BETA <- 0.5
TRUE_SIGMA <- 0.7

one_rep <- function(r) {
  seed <- 20260727L + 100000L * cell$cell_i + r   # SAME seed family as drmTMB run
  set.seed(seed)
  g <- factor(rep(seq_len(cell$n_groups), each = cell$n_per))
  x <- rnorm(length(g))
  u <- rnorm(cell$n_groups, 0, cell$sd_mu)
  y <- 1 + TRUE_BETA * x + u[as.integer(g)] + rnorm(length(g), 0, TRUE_SIGMA)
  dat <- data.frame(y = y, x = x, g = g)

  base <- list(engine = "lme4", cell_id = cell$cell_id, seed = seed, attempt_id = r,
               truth_sd = cell$sd_mu, n_groups = cell$n_groups, n_per_group = cell$n_per)
  na_row <- c(base, list(fit_ok = FALSE, singular = NA, est_sd = NA_real_,
                         lower = NA_real_, upper = NA_real_, width = NA_real_,
                         covers = NA, miss_direction = NA_character_,
                         status = "fit_failed", lower_at_zero = NA))

  fit <- try(suppressMessages(suppressWarnings(
    lmer(y ~ x + (1 | g), data = dat, REML = FALSE))), silent = TRUE)
  if (inherits(fit, "try-error")) return(as.data.frame(na_row, stringsAsFactors = FALSE))

  sing <- isSingular(fit, tol = 1e-4)
  est  <- as.data.frame(VarCorr(fit))
  est_sd <- est$sdcor[est$grp == "g" & is.na(est$var2)][1]

  # NOTE: keep lme4's default oldNames = TRUE. With oldNames = FALSE the row is
  # named `sd_(Intercept)|g`, so parm = ".sig01" silently matches nothing and the
  # whole run returns NA. The smoke caught exactly that.
  ci <- try(suppressMessages(suppressWarnings(
    confint(fit, parm = ".sig01", method = "profile", quiet = TRUE))),
    silent = TRUE)

  if (inherits(ci, "try-error") || !is.matrix(ci) || nrow(ci) < 1L) {
    row <- na_row; row$fit_ok <- TRUE; row$singular <- sing; row$est_sd <- est_sd
    row$status <- "ci_failed"
    return(as.data.frame(row, stringsAsFactors = FALSE))
  }
  lo <- as.numeric(ci[1L, 1L]); hi <- as.numeric(ci[1L, 2L])
  fin <- is.finite(lo) && is.finite(hi)
  cov <- if (fin) (lo <= cell$sd_mu && cell$sd_mu <= hi) else NA
  md  <- if (!fin) "nonfinite" else if (cell$sd_mu < lo) "lower" else if (cell$sd_mu > hi) "upper" else "covered"

  as.data.frame(c(base, list(
    fit_ok = TRUE, singular = sing, est_sd = est_sd,
    lower = lo, upper = hi, width = if (fin) hi - lo else NA_real_,
    covers = cov, miss_direction = md,
    status = if (fin) "valid" else "nonfinite",
    lower_at_zero = if (is.finite(lo)) lo <= 1e-8 else NA
  )), stringsAsFactors = FALSE)
}

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
res <- if (n_cores > 1L) {
  parallel::mclapply(seq_len(n_rep), one_rep, mc.cores = n_cores)
} else {
  lapply(seq_len(n_rep), one_rep)
}
bad <- vapply(res, function(z) !is.data.frame(z), logical(1))
if (any(bad)) stop(sprintf("%d replicate(s) returned non-data.frame", sum(bad)), call. = FALSE)

out <- do.call(rbind, res)
f <- file.path(out_dir, sprintf("lme4_%s.csv", cell$cell_id))
write.csv(out, f, row.names = FALSE)
cat("WROTE", f, "rows", nrow(out), "\n")
cat("  coverage(all-attempt) =", sprintf("%.4f", mean(out$covers %in% TRUE)), "\n")
cat("  singular fits        =", sum(out$singular %in% TRUE), "/", nrow(out), "\n")
cat("  lower bound at zero  =", sum(out$lower_at_zero %in% TRUE), "\n")
if (any(out$singular %in% TRUE)) {
  cat("  coverage | singular   =", sprintf("%.4f", mean(out$covers[out$singular %in% TRUE] %in% TRUE)), "\n")
  cat("  coverage | non-sing   =", sprintf("%.4f", mean(out$covers[!(out$singular %in% TRUE)] %in% TRUE)), "\n")
}

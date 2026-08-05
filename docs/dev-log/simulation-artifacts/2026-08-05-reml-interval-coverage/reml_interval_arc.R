# REML vs ML interval coverage for an ordinary sigma-axis random-effect SD.
# Design fixed in PREREGISTRATION.md, committed at 041905883 BEFORE any fit here.
#
# Usage:
#   Rscript --no-init-file reml_interval_arc.R --cell=4 --nrep=1000 --cores=16 --out=results/cell4.csv

suppressMessages(library(drmTMB))
suppressMessages(library(parallel))

arg_of <- function(k) {
  a <- grep(paste0("^--", k, "="), commandArgs(TRUE), value = TRUE)
  if (length(a) == 0L) return(NA_character_)
  sub(paste0("^--", k, "="), "", a[[1L]])
}
cell_i <- as.integer(arg_of("cell"))
nrep   <- as.integer(arg_of("nrep"))
cores  <- as.integer(arg_of("cores")); if (is.na(cores)) cores <- 1L
outf   <- arg_of("out")

SD_SIGMA <- 0.5     # truth: the estimand
B0       <- -0.3
BETA     <- 0.5
TARGET   <- "sd:sigma:(1 | id)"

GRID <- data.frame(
  cell_i  = 1:6,
  n_id    = c(10L, 20L, 40L, 10L, 20L, 40L),
  n_each  = c( 3L,  3L,  3L, 10L, 10L, 10L),
  stringsAsFactors = FALSE
)
GRID$cell_id <- sprintf("g%02d_ne%02d", GRID$n_id, GRID$n_each)
cell <- GRID[GRID$cell_i == cell_i, , drop = FALSE]
stopifnot(nrow(cell) == 1L)

# ss_floor from tools/gate-inference-ready.R (the repo's own convention)
ss_floor <- function(g, nominal = 0.95) nominal - 0.04 * (8 / max(g, 1))

pull <- function(ci, target) {
  if (inherits(ci, "try-error") || is.null(ci)) {
    return(list(lo = NA_real_, hi = NA_real_, bnd = NA, st = NA_character_))
  }
  hit <- ci[ci$parm == target, , drop = FALSE]
  if (nrow(hit) != 1L) {
    return(list(lo = NA_real_, hi = NA_real_, bnd = NA, st = NA_character_))
  }
  list(lo = as.numeric(hit$lower[[1L]]), hi = as.numeric(hit$upper[[1L]]),
       bnd = if ("profile.boundary" %in% names(hit)) as.logical(hit$profile.boundary[[1L]]) else NA,
       st  = if ("conf.status" %in% names(hit)) as.character(hit$conf.status[[1L]]) else NA_character_)
}

fit_arm <- function(dat, reml) {
  out <- list(ok = FALSE, conv = NA, pd = NA, est = NA_real_,
              w_lo = NA_real_, w_hi = NA_real_,
              p_lo = NA_real_, p_hi = NA_real_, p_bnd = NA, p_st = NA_character_)
  fit <- try(drmTMB(bf(y ~ x, sigma ~ 1 + (1 | id)), family = gaussian(),
                    data = dat, REML = reml), silent = TRUE)
  if (inherits(fit, "try-error")) return(out)
  out$ok   <- TRUE
  out$conv <- isTRUE(fit$opt$convergence == 0L)
  out$pd   <- isTRUE(fit$sdr$pdHess)
  pars <- try(summary(fit)$parameters, silent = TRUE)
  if (!inherits(pars, "try-error")) {
    e <- pars$estimate[pars$parm == TARGET]
    if (length(e) == 1L) out$est <- e
  }
  w <- suppressWarnings(try(stats::confint(fit, parm = TARGET, method = "wald"), silent = TRUE))
  wv <- pull(w, TARGET); out$w_lo <- wv$lo; out$w_hi <- wv$hi
  p <- suppressWarnings(try(stats::confint(fit, parm = TARGET, method = "profile",
                                           profile_engine = "auto"), silent = TRUE))
  pv <- pull(p, TARGET)
  out$p_lo <- pv$lo; out$p_hi <- pv$hi; out$p_bnd <- pv$bnd; out$p_st <- pv$st
  out
}

one <- function(r) {
  seed <- 20260805L + 1000000L * cell$cell_i + r
  set.seed(seed)
  id <- factor(rep(seq_len(cell$n_id), each = cell$n_each))
  n  <- cell$n_id * cell$n_each
  x  <- rnorm(n)
  v  <- rnorm(cell$n_id, 0, SD_SIGMA)
  y  <- 1 + BETA * x + rnorm(n, 0, exp(B0 + v[as.integer(id)]))
  dat <- data.frame(y = y, x = x, id = id)

  # PAIRED: identical data to both arms; only the estimator differs.
  a <- fit_arm(dat, reml = FALSE)
  b <- fit_arm(dat, reml = TRUE)

  data.frame(
    cell_id = cell$cell_id, n_id = cell$n_id, n_each = cell$n_each,
    rep = r, seed = seed, truth = SD_SIGMA,
    ml_ok = a$ok, ml_conv = a$conv, ml_pd = a$pd, ml_est = a$est,
    ml_w_lo = a$w_lo, ml_w_hi = a$w_hi, ml_p_lo = a$p_lo, ml_p_hi = a$p_hi,
    ml_p_bnd = a$p_bnd, ml_p_st = a$p_st,
    re_ok = b$ok, re_conv = b$conv, re_pd = b$pd, re_est = b$est,
    re_w_lo = b$w_lo, re_w_hi = b$w_hi, re_p_lo = b$p_lo, re_p_hi = b$p_hi,
    re_p_bnd = b$p_bnd, re_p_st = b$p_st,
    stringsAsFactors = FALSE
  )
}

res <- if (cores > 1L) mclapply(seq_len(nrep), one, mc.cores = cores) else lapply(seq_len(nrep), one)
bad <- vapply(res, function(z) !is.data.frame(z), logical(1))
if (any(bad)) stop(sprintf("%d replicate(s) failed", sum(bad)), call. = FALSE)
out <- do.call(rbind, res)

cov_of <- function(lo, hi, truth) is.finite(lo) & is.finite(hi) & lo <= truth & truth <= hi
out$ml_p_cov <- cov_of(out$ml_p_lo, out$ml_p_hi, SD_SIGMA)
out$re_p_cov <- cov_of(out$re_p_lo, out$re_p_hi, SD_SIGMA)
out$ml_w_cov <- cov_of(out$ml_w_lo, out$ml_w_hi, SD_SIGMA)
out$re_w_cov <- cov_of(out$re_w_lo, out$re_w_hi, SD_SIGMA)
out$ml_p_wid <- out$ml_p_hi - out$ml_p_lo
out$re_p_wid <- out$re_p_hi - out$re_p_lo

if (!is.na(outf) && nzchar(outf)) {
  dir.create(dirname(outf), showWarnings = FALSE, recursive = TRUE)
  write.csv(out, outf, row.names = FALSE)
}

# ---- pre-registered scoring (PREREGISTRATION.md §5) ----
use <- out$ml_ok & out$re_ok &
  is.finite(out$ml_p_lo) & is.finite(out$re_p_lo)
n <- sum(use)
cml <- out$ml_p_cov[use]; cre <- out$re_p_cov[use]
d <- as.integer(cre) - as.integer(cml)
delta <- mean(d); se <- stats::sd(d) / sqrt(n)
cov_ml <- mean(cml); cov_re <- mean(cre)
mcse_re <- sqrt(cov_re * (1 - cov_re) / n)
flo <- ss_floor(cell$n_id)
helps <- (delta - 2 * se > 0) && (cov_re + 2 * mcse_re >= flo)
hurts <- (delta + 2 * se < 0)
verdict <- if (helps) "REML_HELPS" else if (hurts) "REML_HURTS" else "INCONCLUSIVE"

cat(sprintf("\n=== %s (n_id=%d, n_each=%d) n_usable=%d / %d ===\n",
            cell$cell_id, cell$n_id, cell$n_each, n, nrow(out)))
cat(sprintf("ss_floor(g=%d) = %.4f\n", cell$n_id, flo))
cat(sprintf("PROFILE coverage  ML=%.4f  REML=%.4f\n", cov_ml, cov_re))
cat(sprintf("paired delta = %+.4f  SE = %.4f  -> %s\n", delta, se, verdict))
cat(sprintf("WALD    coverage  ML=%.4f  REML=%.4f\n",
            mean(out$ml_w_cov[use]), mean(out$re_w_cov[use])))
cat(sprintf("point bias        ML=%+.4f REML=%+.4f  (truth %.2f)\n",
            mean(out$ml_est[use], na.rm = TRUE) - SD_SIGMA,
            mean(out$re_est[use], na.rm = TRUE) - SD_SIGMA, SD_SIGMA))
cat(sprintf("mean prof width   ML=%.4f  REML=%.4f  ratio=%.4f\n",
            mean(out$ml_p_wid[use], na.rm = TRUE), mean(out$re_p_wid[use], na.rm = TRUE),
            mean(out$re_p_wid[use], na.rm = TRUE) / mean(out$ml_p_wid[use], na.rm = TRUE)))
cat(sprintf("boundary rate     ML=%.4f  REML=%.4f\n",
            mean(out$ml_p_bnd[use], na.rm = TRUE), mean(out$re_p_bnd[use], na.rm = TRUE)))
cat(sprintf("conv&pdHess rate  ML=%.4f  REML=%.4f\n",
            mean(out$ml_conv & out$ml_pd, na.rm = TRUE),
            mean(out$re_conv & out$re_pd, na.rm = TRUE)))
cat("=== END ===\n")

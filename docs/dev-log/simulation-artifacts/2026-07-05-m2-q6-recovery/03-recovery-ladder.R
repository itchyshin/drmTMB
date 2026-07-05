# M2 q6 recovery-vs-n ladder (STREAMING; append+flush per fit; heartbeat).
# Question: does the q6 two-slope location block (6 SD + 15 corr) recover its
# known among-endpoint Sigma at Santi-scale, and does pdHess reach TRUE (q6 is
# lower-dimensional than the q8 block whose pdHess stays FALSE)?
#
# Arg-driven so the fast-first discipline is explicit per invocation:
#   Rscript 03-recovery-ladder.R <provider> <n1,n2,...> <n_each> <seed>
# e.g. one timing fit first:
#   ... 03-recovery-ladder.R phylo 256 6 20260705
# then a ladder:
#   ... 03-recovery-ladder.R phylo 64,256,512,1024 6 20260705
#
# Run with:
#   R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 \
#     OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
#     Rscript --no-init-file 03-recovery-ladder.R ...

suppressMessages(devtools::load_all(".", quiet = TRUE))
art <- "docs/dev-log/simulation-artifacts/2026-07-05-m2-q6-recovery"
source(file.path(art, "00-helpers.R"))

argv <- commandArgs(trailingOnly = TRUE)
provider <- if (length(argv) >= 1L) argv[[1L]] else "phylo"
n_grid <- if (length(argv) >= 2L) {
  as.integer(strsplit(argv[[2L]], ",", fixed = TRUE)[[1L]])
} else {
  c(64L, 256L, 512L)
}
n_each <- if (length(argv) >= 3L) as.integer(argv[[3L]]) else 6L
seed0 <- if (length(argv) >= 4L) as.integer(argv[[4L]]) else 20260705L

tsv <- file.path(art, "03-recovery-results.tsv")
logf <- file.path(art, "03-recovery.log")
hb <- function(...) {
  cat(sprintf(...), file = logf, append = TRUE)
  cat(sprintf(...))
}
cols <- c(
  "provider", "n_group", "n_each", "n_obs", "seed", "conv", "pdHess",
  "se_finite", "max_abs_rho_hat", "cap_saturated", "rmse", "frobenius",
  "elapsed_s", "error"
)
if (!file.exists(tsv)) {
  cat(paste(cols, collapse = "\t"), "\n", file = tsv)
}
hb("start %s | provider=%s n=%s n_each=%d seed=%d\n",
   format(Sys.time()), provider, paste(n_grid, collapse = ","), n_each, seed0)
CTRL <- drm_control(se = TRUE, optimizer = list(eval.max = 4000, iter.max = 4000))

do_one <- function(provider, n_group, n_each, seed) {
  sim <- simulate_q6_location(seed, provider, n_group, n_each)
  t0 <- Sys.time()
  fit <- tryCatch(fit_q6(sim, provider, CTRL), error = function(e) e)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  if (inherits(fit, "error")) {
    row <- c(provider, n_group, n_each, nrow(sim$data), seed,
             NA, NA, NA, NA, NA, NA, NA, round(el, 1),
             gsub("\t", " ", conditionMessage(fit)))
    hb("[%s] ng=%4d ERROR %s (%.1fs)\n",
       provider, n_group, conditionMessage(fit), el)
  } else {
    rho_hat <- unname(fit$corpars[[provider]])
    rho_true <- unname(upper_tri_vec(sim$truth$corr))
    m <- recovery_metrics(rho_hat, rho_true)
    fro <- frobenius_corr(corr_from_upper(rho_hat, 6L), sim$truth$corr)
    se <- suppressWarnings(sqrt(diag(fit$sdr$cov.fixed)))
    row <- c(provider, n_group, n_each, nrow(sim$data), seed,
             fit$opt$convergence, isTRUE(fit$sdr$pdHess),
             all(is.finite(se)), round(m$max_abs_rho_hat, 4), m$cap_saturated,
             round(m$rmse, 4), round(fro, 4), round(el, 1), NA)
    hb("[%s] ng=%4d conv=%s pdHess=%s max|rho|=%.3f rmse=%.3f frob=%.3f (%.1fs)\n",
       provider, n_group, fit$opt$convergence, isTRUE(fit$sdr$pdHess),
       m$max_abs_rho_hat, m$rmse, fro, el)
  }
  cat(paste(row, collapse = "\t"), "\n", file = tsv, append = TRUE)
  flush(stdout())
}

for (ng in n_grid) {
  do_one(provider, ng, n_each, seed0)
}
hb("done %s | provider=%s\n", format(Sys.time()), provider)

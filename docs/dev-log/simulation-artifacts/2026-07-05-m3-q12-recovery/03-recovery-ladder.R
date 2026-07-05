# M3 q12 recovery-vs-n ladder (STREAMING; per-provider TSV for safe parallelism).
# q12 two-slope all-four (12 SD + 66 corr). pdHess expected FALSE (profile/bootstrap).
#   Rscript 03-recovery-ladder.R <provider> <n1,n2,...> <n_each> <seed1,seed2,...>
# Each provider writes 03-<provider>-results.tsv so four jobs can run concurrently.

suppressMessages(devtools::load_all(".", quiet = TRUE))
art <- "docs/dev-log/simulation-artifacts/2026-07-05-m3-q12-recovery"
source(file.path(art, "00-helpers.R"))

argv <- commandArgs(trailingOnly = TRUE)
provider <- if (length(argv) >= 1L) argv[[1L]] else "phylo"
n_grid <- if (length(argv) >= 2L) {
  as.integer(strsplit(argv[[2L]], ",", fixed = TRUE)[[1L]])
} else c(128L, 256L)
n_each <- if (length(argv) >= 3L) as.integer(argv[[3L]]) else 8L
seeds <- if (length(argv) >= 4L) {
  as.integer(strsplit(argv[[4L]], ",", fixed = TRUE)[[1L]])
} else 20260705L

tsv <- file.path(art, sprintf("03-%s-results.tsv", provider))
logf <- file.path(art, "03-recovery.log")
hb <- function(...) { cat(sprintf(...), file = logf, append = TRUE); cat(sprintf(...)) }
cols <- c("provider", "n_group", "n_each", "n_obs", "seed", "conv", "pdHess",
          "se_finite", "max_abs_rho_hat", "cap_saturated", "rmse", "frobenius",
          "elapsed_s", "error")
cat(paste(cols, collapse = "\t"), "\n", file = tsv)
hb("start %s | provider=%s n=%s seeds=%s\n", format(Sys.time()), provider,
   paste(n_grid, collapse = ","), paste(seeds, collapse = ","))
CTRL <- drm_control(se = TRUE, optimizer = list(eval.max = 6000, iter.max = 6000))

do_one <- function(n_group, seed) {
  sim <- simulate_q12_all_four(seed, provider, n_group, n_each)
  t0 <- Sys.time()
  fit <- tryCatch(fit_q12(sim, provider, CTRL), error = function(e) e)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  if (inherits(fit, "error")) {
    row <- c(provider, n_group, n_each, nrow(sim$data), seed, NA, NA, NA, NA, NA,
             NA, NA, round(el, 1), gsub("\t", " ", conditionMessage(fit)))
    hb("[%s] ng=%4d seed=%d ERROR %s (%.0fs)\n", provider, n_group, seed,
       conditionMessage(fit), el)
  } else {
    rho_hat <- unname(fit$corpars[[provider]])
    rho_true <- unname(upper_tri_vec(sim$truth$corr))
    m <- recovery_metrics(rho_hat, rho_true)
    fro <- frobenius_corr(corr_from_upper(rho_hat, 12L), sim$truth$corr)
    se <- suppressWarnings(sqrt(diag(fit$sdr$cov.fixed)))
    row <- c(provider, n_group, n_each, nrow(sim$data), seed,
             fit$opt$convergence, isTRUE(fit$sdr$pdHess), all(is.finite(se)),
             round(m$max_abs_rho_hat, 4), m$cap_saturated, round(m$rmse, 4),
             round(fro, 4), round(el, 1), NA)
    hb("[%s] ng=%4d seed=%d conv=%s pdHess=%s max|rho|=%.3f rmse=%.3f (%.0fs)\n",
       provider, n_group, seed, fit$opt$convergence, isTRUE(fit$sdr$pdHess),
       m$max_abs_rho_hat, m$rmse, el)
  }
  cat(paste(row, collapse = "\t"), "\n", file = tsv, append = TRUE)
  flush(stdout())
}

for (ng in n_grid) for (s in seeds) do_one(ng, s)
hb("done %s | provider=%s\n", format(Sys.time()), provider)

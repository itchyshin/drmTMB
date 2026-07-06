# One-off double-check: is the n_lvl=20 sigma_nb2 bias bump (+0.019, ~2.6
# MC-SE from zero in 01-results.tsv) a genuine rung-specific effect or Monte
# Carlo noise? 30 FRESH seeds (disjoint from the primary ladder's
# 2026090001:2026090030) at n_lvl=20 only, written to its own TSV so the
# primary 01-results.tsv is never touched by this side-check.

suppressMessages(devtools::load_all(".", quiet = TRUE))
art <- "docs/dev-log/simulation-artifacts/2026-07-05-m5-row105-recovery"
source(file.path(art, "00-helpers.R"))

tsv <- file.path(art, "03-n20-doublecheck.tsv")
cols <- c("seed", "sd_spatial_hat", "sd_relmat_hat", "sigma_nb2_hat", "conv", "pdHess")
cat(paste(cols, collapse = "\t"), "\n", file = tsv)

CTRL <- drm_control(se = TRUE, optimizer = list(eval.max = 1000, iter.max = 1000))
seeds <- 202691001:202691030  # disjoint from the primary 2026090001:30 block, within int32

run_one <- function(seed) {
  sim <- r105_crossed_data(n_lvl = 20L, n_rep = 2L, seed = seed, crossed = TRUE)
  fit <- suppressWarnings(r105_fit(sim, control = CTRL))
  c(
    seed = seed,
    sd_spatial_hat = unname(fit$sdpars$mu[["spatial(1 | site)"]]),
    sd_relmat_hat = unname(fit$sdpars$mu[["relmat(1 | id)"]]),
    sigma_nb2_hat = unname(sigma(fit)[[1L]]),
    conv = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess)
  )
}

res <- parallel::mclapply(seeds, function(s) tryCatch(run_one(s), error = function(e) NULL), mc.cores = 20L)
for (row in res) {
  if (!is.null(row)) cat(paste(round(row, 5), collapse = "\t"), "\n", file = tsv, append = TRUE)
}

d <- utils::read.delim(tsv)
truth_sigma <- 0.35
err <- d$sigma_nb2_hat - truth_sigma
cat(sprintf(
  "n=%d mean_sigma_hat=%.4f bias=%+.4f MC-SE=%.4f |bias|/MC-SE=%.2f\n",
  nrow(d), mean(d$sigma_nb2_hat), mean(err), sd(err) / sqrt(length(err)),
  abs(mean(err)) / (sd(err) / sqrt(length(err)))
))

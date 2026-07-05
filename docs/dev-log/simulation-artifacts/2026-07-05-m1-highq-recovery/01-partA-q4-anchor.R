# PART A: q4 all-four phylo location-scale ANCHOR (the "don't break what works"
# gate). Simulate a q4 dataset with a KNOWN among-endpoint correlation, fit at
# a decent n, and confirm convergence / pdHess / finite SEs / recovery.
#
# Run with:
#   R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 \
#     OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
#     Rscript --no-init-file 01-partA-q4-anchor.R

suppressMessages(devtools::load_all("."))
art_dir <- "docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery"
source(file.path(art_dir, "00-helpers.R"))

# Decent n: 256 tips, 6 obs/tip = 1536 obs. Rich off-diagonal q4 structure.
n_tip <- 256L
n_each <- 6L
seeds <- 20260701:20260710  # 10 seeds

results <- vector("list", length(seeds))
for (k in seq_along(seeds)) {
  seed <- seeds[[k]]
  sim <- simulate_q4_all_four(seed = seed, n_tip = n_tip, n_each = n_each)
  tree <- sim$tree
  dat <- sim$data
  t0 <- Sys.time()
  fit <- tryCatch(
    suppressWarnings(drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ z + phylo(1 | p | species, tree = tree),
        sigma2 = ~ z + phylo(1 | p | species, tree = tree),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = list(eval.max = 1500, iter.max = 1500)
    )),
    error = function(e) e
  )
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  if (inherits(fit, "error")) {
    results[[k]] <- data.frame(
      part = "A_q4_anchor", seed = seed, n_tip = n_tip, n_each = n_each,
      n_obs = nrow(dat), convergence = NA_integer_, pdHess = NA,
      se_finite = NA, max_abs_rho_hat = NA, cap_saturated = NA,
      rmse = NA, max_abs_err = NA, mean_bias = NA, frobenius = NA,
      elapsed_s = elapsed, error = conditionMessage(fit),
      stringsAsFactors = FALSE
    )
    next
  }
  rho_hat <- unname(fit$corpars$phylo)
  rho_true <- unname(upper_tri_vec(sim$truth$corr))
  m <- recovery_metrics(rho_hat, rho_true)
  fro <- frobenius_corr(corr_from_upper(rho_hat, 4L), sim$truth$corr)
  se <- suppressWarnings(sqrt(diag(fit$sdr$cov.fixed)))
  results[[k]] <- data.frame(
    part = "A_q4_anchor", seed = seed, n_tip = n_tip, n_each = n_each,
    n_obs = nrow(dat),
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    se_finite = all(is.finite(se)),
    max_abs_rho_hat = m$max_abs_rho_hat,
    cap_saturated = m$cap_saturated,
    rmse = m$rmse, max_abs_err = m$max_abs_err, mean_bias = m$mean_bias,
    frobenius = fro, elapsed_s = elapsed, error = NA_character_,
    stringsAsFactors = FALSE
  )
  cat(sprintf(
    "seed %d: conv=%s pdHess=%s SEok=%s max|rho|=%.3f rmse=%.3f frob=%.3f (%.1fs)\n",
    seed, fit$opt$convergence, isTRUE(fit$sdr$pdHess), all(is.finite(se)),
    m$max_abs_rho_hat, m$rmse, fro, elapsed
  ))
}

out <- do.call(rbind, results)
write.table(
  out,
  file = file.path(art_dir, "partA-q4-anchor-results.tsv"),
  sep = "\t", row.names = FALSE, quote = FALSE
)
cat("\n=== PART A SUMMARY ===\n")
cat("converged (conv==0):", sum(out$convergence == 0, na.rm = TRUE),
    "/", nrow(out), "\n")
cat("pdHess TRUE:", sum(out$pdHess, na.rm = TRUE), "/", nrow(out), "\n")
cat("SEs finite:", sum(out$se_finite, na.rm = TRUE), "/", nrow(out), "\n")
cat("median rmse:", round(median(out$rmse, na.rm = TRUE), 3), "\n")
cat("median frobenius:", round(median(out$frobenius, na.rm = TRUE), 3), "\n")
cat("any cap-saturated:", any(out$cap_saturated, na.rm = TRUE), "\n")

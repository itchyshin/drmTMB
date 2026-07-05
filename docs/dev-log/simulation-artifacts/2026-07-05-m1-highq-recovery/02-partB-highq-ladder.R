# PART B: high-q recovery vs n (THE CRUX).
# Fit a KNOWN among-endpoint covariance Sigma at a LADDER of sample sizes and
# record convergence, pdHess, cap-saturation (max|rho|>0.99), and recovery error
# (per-pair bias/RMSE + Frobenius vs truth). Two blocks:
#   q4 all-four intercept-only  -> 4 SDs + 6 correlations
#   q8 all-four one-slope       -> 8 SDs + 28 correlations
# The worst-case n is then re-run with qgt2_corr_parameterization = 1L
# (partial-correlation Cholesky) to test whether it reduces cap-saturation /
# improves convergence vs the default UNSTRUCTURED_CORR (0L).
#
# Designed to FINISH locally: modest fit counts. q4 ladder is the primary CRUX
# curve; q8 ladder is coarser (fewer seeds) because each fit is expensive.
#
# Run with:
#   R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 \
#     OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
#     Rscript --no-init-file 02-partB-highq-ladder.R

suppressMessages(devtools::load_all("."))
art_dir <- "docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery"
source(file.path(art_dir, "00-helpers.R"))

fit_q4 <- function(dat, tree, control) {
  suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~ z + phylo(1 | p | species, tree = tree),
      sigma2 = ~ z + phylo(1 | p | species, tree = tree),
      rho12 = ~1
    ),
    family = biv_gaussian(), data = dat, control = control
  ))
}

fit_q8 <- function(dat, tree, control) {
  suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 + x | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 + x | p | species, tree = tree),
      sigma1 = ~ z + phylo(1 + x | p | species, tree = tree),
      sigma2 = ~ z + phylo(1 + x | p | species, tree = tree),
      rho12 = ~1
    ),
    family = biv_gaussian(), data = dat, control = control
  ))
}

run_cell <- function(block, seed, n_tip, n_each, param, control) {
  old <- getOption("drmTMB.internal.qgt2_corr_parameterization", 0L)
  options(drmTMB.internal.qgt2_corr_parameterization = param)
  on.exit(options(drmTMB.internal.qgt2_corr_parameterization = old), add = TRUE)
  if (block == "q4") {
    sim <- simulate_q4_all_four(seed = seed, n_tip = n_tip, n_each = n_each)
    q <- 4L
    fitter <- fit_q4
  } else {
    sim <- simulate_q8_all_four_one_slope(seed = seed, n_tip = n_tip, n_each = n_each)
    q <- 8L
    fitter <- fit_q8
  }
  tree <- sim$tree
  dat <- sim$data
  t0 <- Sys.time()
  fit <- tryCatch(fitter(dat, tree, control), error = function(e) e)
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  base <- data.frame(
    block = block, param = param, seed = seed, n_tip = n_tip,
    n_each = n_each, n_obs = nrow(dat), q = q, stringsAsFactors = FALSE
  )
  if (inherits(fit, "error")) {
    return(cbind(base, data.frame(
      convergence = NA_integer_, pdHess = NA, se_finite = NA,
      max_abs_rho_hat = NA, cap_saturated = NA, rmse = NA,
      max_abs_err = NA, mean_bias = NA, frobenius = NA,
      elapsed_s = elapsed, error = conditionMessage(fit),
      stringsAsFactors = FALSE
    )))
  }
  rho_hat <- unname(fit$corpars$phylo)
  rho_true <- unname(upper_tri_vec(sim$truth$corr))
  m <- recovery_metrics(rho_hat, rho_true)
  fro <- frobenius_corr(corr_from_upper(rho_hat, q), sim$truth$corr)
  se <- suppressWarnings(sqrt(diag(fit$sdr$cov.fixed)))
  cbind(base, data.frame(
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    se_finite = all(is.finite(se)),
    max_abs_rho_hat = m$max_abs_rho_hat,
    cap_saturated = m$cap_saturated,
    rmse = m$rmse, max_abs_err = m$max_abs_err, mean_bias = m$mean_bias,
    frobenius = fro, elapsed_s = elapsed, error = NA_character_,
    stringsAsFactors = FALSE
  ))
}

all_rows <- list()
push <- function(row) {
  all_rows[[length(all_rows) + 1L]] <<- row
  cat(sprintf(
    "[%s p%d] n_tip=%4d seed=%d conv=%s pdHess=%s max|rho|=%.3f rmse=%.3f frob=%.3f (%.1fs)\n",
    row$block, row$param, row$n_tip, row$seed,
    ifelse(is.na(row$convergence), "ERR", row$convergence),
    ifelse(is.na(row$pdHess), "NA", row$pdHess),
    ifelse(is.na(row$max_abs_rho_hat), NA_real_, row$max_abs_rho_hat),
    ifelse(is.na(row$rmse), NA_real_, row$rmse),
    ifelse(is.na(row$frobenius), NA_real_, row$frobenius),
    row$elapsed_s
  ))
}

ctrl_small <- list(eval.max = 1500, iter.max = 1500)
ctrl_big <- list(eval.max = 2500, iter.max = 2500)

## ---- q4 ladder (primary CRUX curve), default param 0 --------------------
q4_seeds <- 20260801:20260812  # 12 seeds
q4_ladder <- list(
  list(n_tip = 32L,  n_each = 6L, ctrl = ctrl_small),
  list(n_tip = 64L,  n_each = 6L, ctrl = ctrl_small),
  list(n_tip = 128L, n_each = 6L, ctrl = ctrl_small),
  list(n_tip = 512L, n_each = 6L, ctrl = ctrl_big),
  list(n_tip = 1024L, n_each = 4L, ctrl = ctrl_big)
)
cat("\n===== q4 ladder (param 0, UNSTRUCTURED_CORR) =====\n")
for (rung in q4_ladder) {
  for (seed in q4_seeds) {
    push(run_cell("q4", seed, rung$n_tip, rung$n_each, 0L, rung$ctrl))
  }
}

## ---- q4 worst-case n re-run with param 1 (partial-correlation) ----------
cat("\n===== q4 worst-case n_tip=32 (param 1, partial-corr Cholesky) =====\n")
for (seed in q4_seeds) {
  push(run_cell("q4", seed, 32L, 6L, 1L, ctrl_small))
}

## ---- q8 coarse ladder (param 0) -----------------------------------------
q8_seeds <- 20260901:20260906  # 6 seeds (each fit expensive)
q8_ladder <- list(
  list(n_tip = 64L,  n_each = 8L, ctrl = ctrl_big),
  list(n_tip = 256L, n_each = 8L, ctrl = ctrl_big),
  list(n_tip = 1024L, n_each = 6L, ctrl = ctrl_big)
)
cat("\n===== q8 ladder (param 0, UNSTRUCTURED_CORR) =====\n")
for (rung in q8_ladder) {
  for (seed in q8_seeds) {
    push(run_cell("q8", seed, rung$n_tip, rung$n_each, 0L, rung$ctrl))
  }
}

## ---- q8 worst-case n re-run with param 1 --------------------------------
cat("\n===== q8 worst-case n_tip=64 (param 1, partial-corr Cholesky) =====\n")
for (seed in q8_seeds) {
  push(run_cell("q8", seed, 64L, 8L, 1L, ctrl_big))
}

out <- do.call(rbind, all_rows)
write.table(
  out,
  file = file.path(art_dir, "partB-highq-ladder-results.tsv"),
  sep = "\t", row.names = FALSE, quote = FALSE
)

## ---- summary tables ------------------------------------------------------
summarise_curve <- function(df) {
  agg <- do.call(rbind, lapply(split(df, list(df$block, df$param, df$n_tip), drop = TRUE), function(g) {
    data.frame(
      block = g$block[1], param = g$param[1], n_tip = g$n_tip[1],
      n_obs = g$n_obs[1], n_seed = nrow(g),
      pct_conv0 = mean(g$convergence == 0, na.rm = TRUE),
      pct_pdHess = mean(g$pdHess, na.rm = TRUE),
      pct_cap_sat = mean(g$cap_saturated, na.rm = TRUE),
      median_max_abs_rho = median(g$max_abs_rho_hat, na.rm = TRUE),
      median_rmse = median(g$rmse, na.rm = TRUE),
      median_frob = median(g$frobenius, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
  agg[order(agg$block, agg$param, agg$n_tip), ]
}
curve <- summarise_curve(out)
write.table(
  curve,
  file = file.path(art_dir, "partB-recovery-vs-n-curve.tsv"),
  sep = "\t", row.names = FALSE, quote = FALSE
)
cat("\n=== PART B recovery-vs-n curve ===\n")
print(curve, row.names = FALSE)

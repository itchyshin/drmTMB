#!/usr/bin/env Rscript

devtools::load_all(quiet = TRUE)
library(testthat)
source("tests/testthat/test-zero-one-beta.R")
dir.create("docs/dev-log/implementation-recovery/2026-07-29-lane-c-zob-phylo-q1-local", recursive = TRUE, showWarnings = FALSE)
out <- lapply(2026072901:2026072904, function(seed) {
  sim <- new_zero_one_beta_phylo_data(seed); tree <- sim$tree
  started <- proc.time()[[3L]]
  fit <- tryCatch(drmTMB::drmTMB(
    drmTMB::bf(y ~ x + phylo(1 | species, tree = tree)),
    family = drmTMB::zero_one_beta(), data = sim$data
  ), error = identity)
  if (inherits(fit, "error")) return(data.frame(seed, status = "fit_error", convergence = NA, pdHess = NA, tau_hat = NA, beta0_hat = NA, beta1_hat = NA, elapsed_sec = proc.time()[[3L]] - started, message = conditionMessage(fit)))
  data.frame(seed, status = "fit_ok", convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess), tau_hat = fit$sdpars$mu[["phylo(1 | species)"]], beta0_hat = fit$coefficients$mu[["(Intercept)"]], beta1_hat = fit$coefficients$mu[["x"]], elapsed_sec = proc.time()[[3L]] - started, message = "")
})
out <- do.call(rbind, out)
utils::write.table(out, "docs/dev-log/implementation-recovery/2026-07-29-lane-c-zob-phylo-q1-local/raw-attempts.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
ok <- out$status == "fit_ok" & out$convergence == 0 & out$pdHess & is.finite(out$tau_hat) & out$tau_hat > .1 & out$tau_hat < 1.5
summary <- data.frame(attempted = nrow(out), passed = sum(ok), mean_tau_hat = mean(out$tau_hat[ok]), decision = if (all(ok) && abs(mean(out$tau_hat[ok])/.55-1) <= .4) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE")
utils::write.table(summary, "docs/dev-log/implementation-recovery/2026-07-29-lane-c-zob-phylo-q1-local/summary.tsv", sep = "\t", row.names = FALSE, quote = FALSE)

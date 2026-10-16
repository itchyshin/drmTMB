## F7-twin-flag-semantics, minimal repro (drmTMB side). Three t4 datasets on which both twins reach the
## same optimum (|dlogLik| <= 2.5e-7) yet is_converged() differs. Data are generated inline with the
## lane DGP (t4_gen_data.R) and written next to this script for the Julia half (f7_min_DRModels.jl).
##   cd sweep-oct16/t4/repro/F7-twin-flag-semantics && Rscript f7_min_drmTMB.R > f7_min_drmTMB.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
cat("drmTMB", format(packageVersion("drmTMB")), "(installed from itchyshin/drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a)\n\n")
rseed <- function(k, r) as.integer((20261016400 + 100 * (k - 1) + (r - 1)) %% 2^31)
set_rng <- function(k, r) { RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(rseed(k, r)) }
## k = 8, rep 1: quasi-complete separation (no finite MLE for the slope)
set_rng(8, 1); x <- rnorm(50); y <- as.integer(x > 0); x[1:10] <- 0; y[1:10] <- c(0L, 1L, rbinom(8, 1, 0.5))
d_quasi <- data.frame(y = y, x = x)
## k = 9, rep 1: Poisson data fitted as NB2 (MLE at the Poisson limit, sigma -> 0)
set_rng(9, 1); x <- rnorm(100); d_nb2 <- data.frame(y = rpois(100, exp(1 + 0.5 * x)), x = x)
## k = 14, rep 1: near-collinear sigma design, z = x + 1e-6 N(0,1) (interior but weakly identified MLE)
set_rng(14, 1); x <- rnorm(100); y <- 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(100)
d_near <- data.frame(y = y, x = x, z = x + 1e-6 * rnorm(100))
sets <- list(bin_quasi_r01 = d_quasi, nb2_poisdata_r01 = d_nb2, collin_sigma_near_r01 = d_near)
for (nm in names(sets)) {
  f <- paste0("f7_", nm, ".csv"); write.csv(sets[[nm]], f, row.names = FALSE)
  lane <- file.path("../../data", paste0(nm, ".csv"))
  if (file.exists(lane)) cat(sprintf("%-24s identical to lane CSV %s: %s\n", f, lane,
                                     identical(unname(tools::md5sum(f)), unname(tools::md5sum(lane)))))
}
fits <- list(
  bin_quasi_r01 = drmTMB(bf(y ~ x), family = binomial(), data = d_quasi),
  nb2_poisdata_r01 = drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d_nb2),
  collin_sigma_near_r01 = drmTMB(bf(y ~ x, sigma ~ x + z), family = gaussian(), data = d_near))
for (nm in names(fits)) {
  fit <- fits[[nm]]
  cat("\n====", nm, "====\n")
  cat(sprintf("opt$convergence = %d (%s); logLik = %.10f\n", fit$opt$convergence, fit$opt$message, as.numeric(logLik(fit))))
  cat(sprintf("is_converged() = %s; convergence_status() = \"%s\"; pdHess = %s\n",
              is_converged(fit), convergence_status(fit), fit$sdr$pdHess))
  se <- sqrt(diag(vcov(fit)))
  print(data.frame(estimate = unlist(fixef(fit)), se = se[seq_along(unlist(fixef(fit)))]), digits = 6)
  chk <- check_drm(fit)
  bad <- as.data.frame(chk)[chk$status != "ok", c("check", "status", "value")]; rownames(bad) <- NULL; print(bad)
}
cat("\n"); print(sessionInfo())

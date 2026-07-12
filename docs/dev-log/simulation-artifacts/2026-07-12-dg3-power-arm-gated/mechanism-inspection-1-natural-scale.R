# Direct mechanism-inspection (Curie, 2026-07-12): for zi_nbinom2,
# hurdle_nbinom2, zero_one_beta/zoi, beta_binomial's "nuisance-absorbable
# weak" mis-spec cells, fit the correctly-specified (fit_true) and
# mis-specified (fit_wrong) models on the SAME dataset (n=1000, seed=1 for
# stable estimates) and report the absorbing parameter's before/after
# estimate, directly confirming (not by analogy) that the constant-nuisance
# fit settles near the TRUE DGP's average level of the x-varying mechanism --
# the same "dispersion/nuisance absorption" pattern already verified for
# student/nu, nbinom2/sigma, biv/sigma1 in the toy pass.
if (!identical(Sys.getenv("NOT_CRAN"), "true")) stop("Set NOT_CRAN=true")
suppressMessages(devtools::load_all(".", quiet = TRUE))
source("inst/dg3-power-arm/harness.R")
source("inst/dg3-power-arm/families.R")

n <- 1000L
seed <- 1L

report <- function(label, dat, fit_true, fit_wrong, dpar, natural_fn, true_avg_fn) {
  ft <- fit_true(dat)
  fw <- fit_wrong(dat)
  ct <- coef(ft, dpar = dpar)
  cw <- coef(fw, dpar = dpar)
  wrong_natural <- natural_fn(unname(cw[["(Intercept)"]]))
  true_avg <- true_avg_fn(dat)
  cat(sprintf("\n--- %s (dpar=%s) ---\n", label, dpar))
  cat(sprintf("  fit_true coefs:  %s\n", paste(sprintf("%s=%.4f", names(ct), ct), collapse = ", ")))
  cat(sprintf("  fit_wrong coefs: %s\n", paste(sprintf("%s=%.4f", names(cw), cw), collapse = ", ")))
  cat(sprintf("  wrong constant on natural scale:      %.4f\n", wrong_natural))
  cat(sprintf("  TRUE DGP average natural-scale level:  %.4f\n", true_avg))
  cat(sprintf("  |diff| = %.4f\n", abs(wrong_natural - true_avg)))
  invisible(list(fit_true = ft, fit_wrong = fw))
}

# ---- 1. zi_nbinom2 / zi_mechanism_misset_constant_vs_x -- absorbing param: zi
ms <- dg3_spec_zi_nbinom2$mis_specs[[2]]
dat <- ms$dgp(seed, n)
report("zi_nbinom2 zi_mechanism_misset_constant_vs_x", dat, ms$fit_true, ms$fit_wrong,
  dpar = "zi", natural_fn = plogis,
  true_avg_fn = function(d) mean(plogis(-0.5 + 1.2 * d$x)))

# ---- 2. hurdle_nbinom2 / hurdle_mechanism_misset_constant_vs_x -- absorbing param: hu
ms <- dg3_spec_hurdle_nbinom2$mis_specs[[2]]
dat <- ms$dgp(seed, n)
report("hurdle_nbinom2 hurdle_mechanism_misset_constant_vs_x", dat, ms$fit_true, ms$fit_wrong,
  dpar = "hu", natural_fn = plogis,
  true_avg_fn = function(d) mean(plogis(-0.5 + 1.2 * d$x)))

# ---- 3. zero_one_beta / zoi_mechanism_misset_constant_vs_x -- absorbing param: zoi
ms <- dg3_spec_zero_one_beta$mis_specs[[2]]
dat <- ms$dgp(seed, n)
report("zero_one_beta zoi_mechanism_misset_constant_vs_x", dat, ms$fit_true, ms$fit_wrong,
  dpar = "zoi", natural_fn = plogis,
  true_avg_fn = function(d) mean(plogis(-0.5 + 1.0 * d$x)))

# ---- 4. beta_binomial / dispersion_varying_mean_only_SUBSTITUTE -- absorbing param: sigma
ms <- dg3_spec_beta_binomial$mis_specs[[2]]
dat <- ms$dgp(seed, n)
report("beta_binomial dispersion_varying_mean_only_SUBSTITUTE", dat, ms$fit_true, ms$fit_wrong,
  dpar = "sigma", natural_fn = exp,
  true_avg_fn = function(d) mean(pmin(exp(-1.1 + 0.5 * d$z), 1.0)))

cat("\n=== mechanism inspection done ===\n")

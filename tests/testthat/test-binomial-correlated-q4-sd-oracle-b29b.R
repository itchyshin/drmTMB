# Batch 29 (lane b) companion to test-binomial-correlated-q4-nonlogit-sd.R (evidence ids
# native-binomial-correlated-q4-{probit,cloglog}-{I,x1-to-xp}-20261027-m26).
#
# Reviewer deficiency closed: those tests check recovery of each SD slope to
# within 0.35 and the SD prediction against exp(coef) only; there is no
# likelihood oracle and no emulated-bug sensitivity. Here a dense per-group
# Laplace marginal (base R, observed information) is evaluated at the fitted
# parameters for a probit or cloglog Bernoulli (1 + x + z [+ t] | id) block with
# an sd() formula on every coefficient, each with its own group-level selector.
# The SD vectors are built by hand from the coefficients and the correlation
# matrix R is parsed from the fitted `cor(a,b | id)` names by coefficient name
# (public correlations are marginal). logLik tolerance 1e-4 absolute. Emulated
# bugs (SD coefficient sets rotated one position, reversed SD vector for each
# coefficient, flipped sign of the first correlation, R = identity) must each
# move the oracle by more than 0.1. Scope: likelihood assembly and selector
# alignment at one seed; no calibration, coverage or parity claim.

test_that("Bernoulli correlated q4 block with sd() on every coefficient (probit, cloglog): dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    b29b_corr_block_check(4L, link, 29960L + match(link, c("probit", "cloglog")),
                          groups = 64L, repeats = 26L)
  }
})

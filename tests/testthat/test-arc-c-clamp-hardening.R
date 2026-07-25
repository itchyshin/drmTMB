# Arc C: regression test for Arc B finding A5.
#
# A5 -- the beta mi() leaf was called with UNCLAMPED log_sigma while the main
#       loop used the clamped value, so the two halves of one likelihood
#       disagreed about the dispersion. The clamp now runs once, at the top of
#       the model_type == 10 branch, before the mi() 2-point sum.
#
# F5 (the unguarded exp() of a regression-predicted log-SD) was ATTEMPTED in
# this arc and DELIBERATELY REVERTED. Clamping the `sd(g) ~ x` predictor made
# the Arc 7B dense-LSS negative control go green for the wrong reason: at K=12
# it turned a genuinely non-identified heterogeneity slope into a finite but
# vacuous profile interval of [-4.14, 27.79], and widening the band to
# c(-200, 200) restored `profile_failed`. The finite endpoint was an artifact
# of the bound, not information from the data -- and it is more dangerous than
# the [0, Inf] it replaced, because it would pass a finite-interval gate. See
# docs/design/245-f5-sd-regression-clamp-and-identifiability.md.
#
# FALSIFICATION STATUS. This test does NOT falsify: it passes against the
# pre-repair kernel too, checked by rebuilding. The mi() branch is provably
# live in this fixture (model_type == 10, has_mi == 1, mi_family == 1), yet the
# objective is identical to 15 significant digits at beta_sigma = 30 and = 1000
# both before and after the repair -- the beta density saturates the same way
# whether it receives the raw or the clamped dispersion, so the defect is real
# in the source but not observable in any reported quantity or in the objective
# through this route. The A5 repair therefore rests on a STRUCTURAL argument:
# of the three mi()-capable families, model_type 1 clamps before mi() and
# model_type 7 clamps before mi(); beta alone did not. What follows guards the
# reported quantities and pins that the mi() branch is actually exercised. It
# is NOT proof the defect is gone. Finding an input that separates the two
# orderings is open follow-up work.

test_that("A5: beta with a live mi() branch keeps log_sigma inside the clamp band", {
  skip_on_cran()

  set.seed(20260725)
  n <- 200
  x <- rnorm(n)
  z <- rnorm(n)
  mu <- 1 / (1 + exp(-(0.3 + 0.6 * x)))
  phi <- 12
  y <- pmin(pmax(rbeta(n, mu * phi, (1 - mu) * phi), 1e-6), 1 - 1e-6)
  xm <- rbinom(n, 1, 0.5)
  xm[sample.int(n, 40)] <- NA_real_
  dat <- data.frame(y = y, x = x, z = z, xm = xm)

  lo <- -2
  hi <- 2
  margin <- 1
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + mi(xm), sigma ~ z),
    family = beta(), data = dat,
    impute = list(xm = impute_model(xm ~ z, family = binomial())),
    missing = miss_control(predictor = "model"),
    control = drm_control(
      logsigma_clamp = c(lo, hi), logsigma_clamp_margin = margin, se = FALSE
    )
  ))

  # Confirm this really is the beta mi() branch, so a future refactor that
  # silently stops exercising it makes this test fail rather than quietly pass.
  d <- fit$obj$env$data
  expect_identical(as.integer(d$model_type), 10L)
  expect_identical(as.integer(d$has_mi), 1L)
  expect_identical(as.integer(d$mi_family), 1L)

  p <- fit$obj$env$last.par.best
  idx <- which(names(p) == "beta_sigma")
  expect_gt(length(idx), 0L)

  # Drive log_sigma far outside the band with the mi() sum live: the objective
  # must stay finite and the reported scale must respect the band.
  p[idx] <- 30
  expect_true(is.finite(fit$obj$fn(p)))
  rp <- fit$obj$report(p)
  expect_true(all(is.finite(rp$log_sigma)))
  expect_lte(max(rp$log_sigma), hi + margin + 1e-6)
  expect_true(all(is.finite(rp$sigma)))
  expect_lte(max(rp$sigma), exp(hi + margin) * (1 + 1e-6))
})

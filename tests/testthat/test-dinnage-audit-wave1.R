# Wave 1 of Russell Dinnage's independent evaluation of drmTMB 0.7.0
# (rdinnager/drmTMB_eval, pinned at 945da24f, report dated 2026-08-29).
# One test block per finding fixed in this lane.

test_that("M1: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  # weights(i) previously multiplied each leaf density BEFORE logspace_add()
  # combined them inside the mi() two-point mixture (mi_family == 1), which
  # computes log(p1*f1^w + p0*f0^w) instead of the correct
  # w*log(p1*f1 + p0*f0) -- a constant weight moved the MLE on the mi(x)
  # coefficient. Reproduces Russell's illustrative shape: a Bernoulli-imputed
  # binary covariate, missing at random, in a plain Gaussian mean model
  # (model_type == 1, the simplest mi() route).
  set.seed(42)
  n <- 200
  z <- stats::rnorm(n)
  x <- stats::rbinom(n, 1, stats::plogis(0.3 * z))
  y <- 1 + 0.8 * x + stats::rnorm(n, 0, 0.6)
  xm <- x
  miss <- sample(seq_len(n), 30)
  xm[miss] <- NA
  dat <- data.frame(y = y, x = xm, z = z)

  fit_coef <- function(data, weights = NULL) {
    fit <- allow_nonconvergence(drmTMB(
      bf(y ~ mi(x)),
      family = gaussian(),
      data = data,
      impute = list(x = impute_model(x ~ z, family = binomial())),
      missing = miss_control(predictor = "model"),
      weights = weights
    ))
    coef(fit)$mu
  }

  coef_w1 <- fit_coef(dat, rep(1, n))
  coef_w2 <- fit_coef(dat, rep(2, n))
  # The pre-fix code drifts by ~0.03 on the mi(x) slope across this weight
  # range (see the negative control in this finding's commit message);
  # post-fix the two must agree to a tight tolerance.
  expect_equal(coef_w1, coef_w2, tolerance = 1e-6)

  # weights = 2 must also match literal row duplication (the general weight
  # contract the report confirms holds everywhere except inside mi()).
  coef_dup <- fit_coef(rbind(dat, dat))
  expect_equal(coef_dup, coef_w2, tolerance = 1e-5)
})

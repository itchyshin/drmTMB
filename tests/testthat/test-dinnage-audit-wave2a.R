# Regression tests for three Major findings from Russell Dinnage's independent
# evaluation of drmTMB 0.7.0 (https://github.com/rdinnager/drmTMB_eval,
# REPORT.md pinned at commit 945da24f, 2026-08-29), Wave 2a (M3, S1, S3).
# See .unlazy/dinnage-wave2a/gates/leaf-A4a.md for the ledger.

fast_control <- drm_control(se = FALSE)

# ---- M3: check_drm()'s fixed_gradient row on correct, large-n fits --------
#
# Dinnage's report measured `fixed_gradient` (an ABSOLUTE `max|g| <=
# gradient_tolerance = 1e-3` criterion, R/check.R) warning on 19/20 correct
# Gaussian location-scale fits at n = 1000 and 20/20 at n = 4000, so
# `attr(check_drm(fit), "ok")` carried no information at realistic n.
#
# On this checkout that failure mode does not reproduce: `drm_newton_polish()`
# (issue #1130, `drm_control(newton_polish = TRUE)` by default, R/drmTMB.R)
# lands between the report's pin and this checkout and Newton-polishes every
# fit's outer gradient below `grad_tol = 1e-8` -- two orders of magnitude
# under `check_drm()`'s default `gradient_tolerance = 1e-3` -- before
# `check_drm()` ever evaluates it. Scanning Gaussian location-scale fits at
# n = 2000 (20 seeds), a weighted n = 300 Gaussian fit (10 seeds), and a
# skew-normal location-scale fit at n = 4000 (5 seeds) found no firing case
# (see ledger EVIDENCE). M3 is therefore recorded ABANDON in the ledger
# (already fixed on main by an orthogonal change) rather than reworked here;
# this test is the regression guard that keeps it that way.
test_that("fixed_gradient does not fire on a correct Gaussian fit at n = 2000 (Dinnage audit M3)", {
  skip_on_cran()
  set.seed(20260913)
  n <- 2000
  dat <- data.frame(x = stats::rnorm(n))
  dat$y <- 1 + 2 * dat$x + stats::rnorm(n, sd = exp(0.3 * dat$x))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = TRUE)
  )
  chk <- check_drm(fit)
  expect_true(attr(chk, "ok"))
  fg <- chk[chk$check == "fixed_gradient", ]
  expect_identical(nrow(fg), 1L)
  expect_identical(fg$status, "ok")
})


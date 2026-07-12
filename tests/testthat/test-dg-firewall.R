# DO-T4 closeout: the distributional output & adequacy layer's firewall
# (Rose's guard, concurrent-gliding-zebra.md, "Done" criterion 4). A
# distributional-output/adequacy (DG) tick -- drm_family_dpq()$status ==
# "reference", fitted_distribution()/residuals(type = "quantile") succeeding
# -- lives on a SEPARATE axis from a family/fit's own inference-tier status
# (check_drm()'s per-row diagnostics, e.g. skew-normal's `diagnostic_hold`
# fit-quality narrative). This test asserts the firewall holds mechanically:
# exercising the DG-axis surface has zero effect on check_drm()'s output for
# the same fit.

test_that("skew_normal: computing DG-axis outputs does not alter check_drm()'s output", {
  set.seed(20260723)
  n <- 80
  x <- stats::rnorm(n)
  mu_true <- 0.5 + 0.4 * x
  y <- rskew_normal_public(n, mu = mu_true, sigma = 1.1, nu = 3)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  # drm_family_dpq() status is the distributional-output-axis tick; it says
  # nothing about the family's own fit-quality gate (check_skew_normal_nu(),
  # which is what carries the "diagnostic_hold" narrative in the mission-
  # control ledger -- see R/family-dpq.R's firewall comment above
  # drm_family_dpq_skew_normal()).
  expect_identical(drm_family_dpq(fit)$status, "reference")

  before <- check_drm(fit)
  expect_true("skew_normal_nu" %in% before$check)

  # Exercise every DG-axis surface this arc shipped.
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  r <- residuals(fit, type = "quantile")
  expect_length(r, n)
  expect_true(all(is.finite(r)))

  after <- check_drm(fit)

  # The firewall: check_drm()'s status fields (including the
  # "skew_normal_nu" row that carries the diagnostic_hold narrative) are
  # byte-identical whether or not the DG surface was ever touched.
  expect_identical(before, after)
})

test_that("gaussian: the same DG-axis exercise leaves check_drm() untouched", {
  set.seed(20260712)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.3 + 0.6 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_identical(drm_family_dpq(fit)$status, "reference")

  before <- check_drm(fit)
  fd <- fitted_distribution(fit)
  r <- residuals(fit, type = "quantile")
  q <- predict(fit, type = "quantile", prob = c(0.1, 0.5, 0.9))
  ex <- exceedance(fit, threshold = mean(dat$y))
  after <- check_drm(fit)

  expect_identical(fd$status, "reference")
  expect_length(r, n)
  expect_identical(dim(q), c(as.integer(n), 3L))
  expect_identical(attr(ex, "calibrated"), FALSE)
  expect_identical(before, after)
})

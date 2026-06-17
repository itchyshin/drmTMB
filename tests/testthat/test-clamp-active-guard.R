# Wave 1 honesty guard 4 (raised by Hao Qin): when the log(sigma) soft-clamp is
# active at the optimum, the scale ran to the clamp and the fit may have
# "converged" artificially -- the objective is flat in the saturated tail, so the
# gradient is ~0 and nlminb can return convergence = 0 falsely, with estimates
# and SEs that reflect the clamp rather than the data. Previously nothing warned.
# A detector reads the reported log_sigma against the clamp band; the fit path
# warns. The detector is unit-tested with synthetic reports (deterministic); a
# fit with a narrow band forces the clamp active without a platform-dependent
# overshoot.

test_that("drm_logsigma_clamp_active flags saturation, ignores healthy and disabled", {
  band <- c(-12, 12, 3)
  on <- list(use_logsigma_clamp = 1L, logsigma_clamp = band)
  off <- list(use_logsigma_clamp = 0L, logsigma_clamp = band)
  expect_null(drm_logsigma_clamp_active(list(log_sigma = c(-0.5, 0.2)), on))
  expect_null(drm_logsigma_clamp_active(list(log_sigma = 14), off))
  info <- drm_logsigma_clamp_active(list(log_sigma = c(0.1, 14.2)), on)
  expect_false(is.null(info))
  expect_equal(info$value, 14.2)
  # bivariate scale fields are both checked
  info2 <- drm_logsigma_clamp_active(
    list(log_sigma1 = 0.1, log_sigma2 = 13.5),
    on
  )
  expect_false(is.null(info2))
  expect_equal(info2$value, 13.5)
})

test_that("drm_logsigma_clamp_active ignores the lower (scale -> 0) boundary", {
  on <- list(use_logsigma_clamp = 1L, logsigma_clamp = c(-12, 12, 3))
  # A scale at the lower clamp (e.g. meta-analysis tau -> 0) is a legitimate
  # variance-zero boundary, not a runaway; it must not trip the clamp warning.
  expect_null(drm_logsigma_clamp_active(list(log_sigma = -13.2), on))
})

test_that("drm_logsigma_clamp_active is robust to missing fields and non-finite values", {
  on <- list(use_logsigma_clamp = 1L, logsigma_clamp = c(-12, 12, 3))
  expect_null(drm_logsigma_clamp_active(list(), on))
  expect_null(drm_logsigma_clamp_active(list(log_sigma = numeric(0)), on))
  expect_null(drm_logsigma_clamp_active(list(log_sigma = c(NA_real_, 0.2)), on))
})

test_that("drm_logsigma_clamp_active ignores unclamped _mi imputation scales", {
  on <- list(use_logsigma_clamp = 1L, logsigma_clamp = c(-12, 12, 3))
  # The missing-predictor imputation scale is not clamped, so an out-of-band
  # log_sigma_mi must not be read as a clamp-active main scale.
  expect_null(drm_logsigma_clamp_active(list(log_sigma_mi = 14), on))
  expect_false(is.null(
    drm_logsigma_clamp_active(list(log_sigma = 14, log_sigma_mi = 14), on)
  ))
})

test_that("a fit with the clamp active at the optimum warns", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.6), x = x)
  # A band whose upper bound sits below the true log(sigma) (~ -0.5) forces the
  # UPPER clamp active for a normal-scale fit, so the detector fires
  # deterministically (no reliance on a pathological overshoot).
  expect_warning(
    allow_nonconvergence(
      drmTMB(
        bf(y ~ x, sigma ~ 1),
        family = gaussian(),
        data = dat,
        control = drm_control(logsigma_clamp = c(-3, -0.8))
      )
    ),
    class = "drmTMB_clamp_active_warning"
  )
})

test_that("a clean fit does not emit a clamp-active warning", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.6), x = x)
  expect_no_warning(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  )
})

test_that("the clamp-active warning now covers non-Gaussian scale families", {
  # Wave 2 extended the clamp to all scale families, so the detector must flag a
  # non-Gaussian (gamma) scale that runs to the upper clamp.
  set.seed(2)
  n <- 120
  x <- stats::rnorm(n)
  dat <- data.frame(
    y = stats::rgamma(n, shape = 3, rate = 3 / exp(0.4 + 0.3 * x)),
    x = x
  )
  expect_warning(
    allow_nonconvergence(
      drmTMB(
        bf(y ~ x, sigma ~ 1),
        family = stats::Gamma(link = "log"),
        data = dat,
        control = drm_control(logsigma_clamp = c(-3, -0.8))
      )
    ),
    class = "drmTMB_clamp_active_warning"
  )
})

test_that("check_drm() reports a clamp-active row (warning when active, ok when not)", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.6), x = x)

  clean <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  chk_clean <- check_drm(clean)
  row_clean <- chk_clean[chk_clean$check == "logsigma_clamp_active", ]
  expect_equal(nrow(row_clean), 1L)
  expect_equal(row_clean$status, "ok")

  active <- allow_nonconvergence(drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(logsigma_clamp = c(-3, -0.8))
  ))
  chk_active <- check_drm(active)
  row_active <- chk_active[chk_active$check == "logsigma_clamp_active", ]
  expect_equal(row_active$status, "warning")
})

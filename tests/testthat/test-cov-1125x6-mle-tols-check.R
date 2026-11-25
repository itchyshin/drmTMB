# Separation tolerances and check_mle_existence() in R/mle-existence.R.

test_that("drm_sep tolerance getters return positive scalars", {
  expect_gt(drmTMB:::drm_sep_obj_tol(), 0)
  expect_gt(drmTMB:::drm_sep_coef_tol(), 0)
  expect_gt(drmTMB:::drm_sep_rank_tol(), 0)
  expect_gt(drmTMB:::drm_sep_resid_tol(), 0)
  expect_equal(drmTMB:::drm_sep_max_iter(5L), 20L * 5L + 200L)
})

test_that("check_mle_existence() reports ok on a well-behaved Gaussian fit", {
  set.seed(7)
  dat <- data.frame(y = rnorm(16), x = rnorm(16))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  row <- check_mle_existence(fit)
  expect_equal(row$check, "mle_existence")
  expect_equal(row$status, "ok")
  expect_equal(row$value, "finite")
})

test_that("check_mle_existence() warns on binomial quasi-separation", {
  dat <- data.frame(
    y = rep(c(0L, 1L), each = 8),
    x = c(rep(-3, 8), rep(3, 8))
  )
  fit <- drmTMB(
    bf(y ~ x),
    family = binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  row <- check_mle_existence(fit)
  expect_equal(row$status, "warning")
  expect_equal(row$value, "binomial_separation")
  expect_match(row$message, "separation")
})

test_that("drm_mle_nonexistent_is_true() reflects separation state", {
  dat <- data.frame(y = rep(c(0L, 1L), each = 6), x = c(rep(-2, 6), rep(2, 6)))
  fit <- drmTMB(bf(y ~ x), family = binomial(), data = dat, control = drm_control(se = FALSE))
  expect_true(drmTMB:::drm_mle_nonexistent_is_true(fit))
})
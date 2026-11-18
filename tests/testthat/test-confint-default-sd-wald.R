# #1558 (partly reverted): confint() with no `method` stays Wald for every row;
# a near-boundary ordinary (1 | g) SD Wald row is labelled unreliable, and
# method = "profile" profiles the SD on request.

sd_profile_fit <- function(seed, sd_g = 0.1, keep_tmb_object = TRUE) {
  set.seed(seed)
  n_g <- 10L
  n_per <- 10L
  g <- factor(rep(seq_len(n_g), each = n_per))
  u <- stats::rnorm(n_g, 0, sd_g)
  x <- stats::rnorm(n_g * n_per)
  y <- 1 + 0.5 * x + u[g] + stats::rnorm(n_g * n_per)
  drmTMB(
    bf(y ~ x + (1 | g), sigma ~ 1),
    data = data.frame(y = y, x = x, g = g),
    control = drm_control(keep_tmb_object = keep_tmb_object)
  )
}

test_that("default confint() is Wald for every row, including the (1 | g) SD", {
  fit <- sd_profile_fit(3, sd_g = 0.8)
  ci <- stats::confint(fit)
  expect_true(all(ci$method == "wald"))
  wald <- stats::confint(fit, method = "wald")
  expect_identical(ci$parm, wald$parm)
  expect_equal(ci$lower, wald$lower)
  expect_equal(ci$upper, wald$upper)
})

test_that("explicit method = \"profile\" profiles the (1 | g) SD", {
  fit <- sd_profile_fit(3, sd_g = 0.8)
  prof <- stats::confint(fit, parm = "sd:mu:(1 | g)", method = "profile")
  expect_identical(prof$method, "profile")
  expect_true(all(is.finite(c(prof$lower, prof$upper))))
  expect_true(all(stats::confint(fit, parm = "sd:mu:(1 | g)")$method == "wald"))
})

test_that("a Wald (1 | g) SD interval with a huge log-scale SE is labelled unreliable", {
  # Estimate ~0.097, so it is above the 1e-4 sd_boundary threshold, yet the
  # Wald interval spans [0.0013, 7.1].
  fit <- sd_profile_fit(21)
  expect_gt(unname(fit$sdpars$mu[["(1 | g)"]]), 1e-4)
  ci <- NULL
  expect_warning(
    ci <- stats::confint(fit, method = "wald"),
    class = "drmTMB_wald_boundary_warning"
  )
  expect_identical(ci$conf.status[ci$parm == "sd:mu:(1 | g)"], "wald_at_boundary")
  # The interval is kept, not discarded.
  expect_true(all(is.finite(unlist(ci[ci$parm == "sd:mu:(1 | g)", c("lower", "upper")]))))
  # Other rows are not relabelled.
  expect_true(all(ci$conf.status[ci$parm != "sd:mu:(1 | g)"] == "wald"))
})

test_that("a well-identified Wald (1 | g) SD interval is not labelled", {
  fit <- sd_profile_fit(3, sd_g = 0.8)
  expect_no_warning(ci <- stats::confint(fit, method = "wald"))
  expect_identical(ci$conf.status[ci$parm == "sd:mu:(1 | g)"], "wald")
})

test_that("explicit profile keeps the profile boundary warning for a boundary SD", {
  fit <- sd_profile_fit(1)
  expect_warning(
    ci <- stats::confint(fit, parm = "sd:mu:(1 | g)", method = "profile"),
    class = "drmTMB_profile_boundary_warning"
  )
  expect_identical(ci$method, "profile")
})

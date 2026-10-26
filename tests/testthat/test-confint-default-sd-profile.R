# #1558: confint() with no `method` profiles ordinary (1 | g) SD rows, because a
# Wald SD interval undercovers near the boundary; explicit method = "wald" keeps
# Wald but labels a near-boundary ordinary SD row as unreliable.

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

test_that("default confint() profiles the ordinary (1 | g) SD and keeps other rows Wald", {
  fit <- sd_profile_fit(3, sd_g = 0.8)
  ci <- stats::confint(fit)
  expect_identical(
    ci$parm,
    c(
      "fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
      "sigma", "sd:mu:(1 | g)"
    )
  )
  expect_identical(ci$method[ci$parm == "sd:mu:(1 | g)"], "profile")
  expect_false(is.na(ci$profile.engine[ci$parm == "sd:mu:(1 | g)"]))
  expect_true(all(ci$method[ci$parm != "sd:mu:(1 | g)"] == "wald"))
  # The Wald rows are the same numbers an explicit Wald call returns.
  wald <- stats::confint(fit, method = "wald")
  keep <- ci$parm != "sd:mu:(1 | g)"
  expect_equal(ci$lower[keep], wald$lower[wald$parm %in% ci$parm[keep]])
  expect_equal(ci$upper[keep], wald$upper[wald$parm %in% ci$parm[keep]])
})

test_that("default confint() on an SD-only parm matches the explicit profile call", {
  fit <- sd_profile_fit(3, sd_g = 0.8)
  ci <- stats::confint(fit, parm = "sd:mu:(1 | g)")
  prof <- stats::confint(fit, parm = "sd:mu:(1 | g)", method = "profile")
  expect_identical(ci$method, "profile")
  expect_equal(ci$lower, prof$lower)
  expect_equal(ci$upper, prof$upper)
})

test_that("a call that does not touch an ordinary SD, or asks for Wald, stays Wald", {
  fit <- sd_profile_fit(3, sd_g = 0.8)
  expect_true(all(stats::confint(fit, parm = "fixef:mu:x")$method == "wald"))
  expect_true(all(stats::confint(fit, method = "wald")$method == "wald"))
  # A Wald-only argument is a request for the Wald table.
  expect_true(
    all(stats::confint(fit, small_sample_df = "none")$method == "wald")
  )
  expect_true(
    all(stats::confint(fit, bias_correct = "none")$method == "wald")
  )
})

test_that("default confint() falls back to Wald when the TMB object was not kept", {
  fit <- sd_profile_fit(3, sd_g = 0.8, keep_tmb_object = FALSE)
  ci <- stats::confint(fit)
  expect_true(all(ci$method == "wald"))
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

test_that("default confint() keeps the profile boundary warning for a boundary SD", {
  fit <- sd_profile_fit(1)
  expect_warning(
    ci <- stats::confint(fit),
    class = "drmTMB_profile_boundary_warning"
  )
  expect_identical(ci$method[ci$parm == "sd:mu:(1 | g)"], "profile")
})

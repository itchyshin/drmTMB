# R/profile.R bootstrap bookkeeping and Wald boundary row selection.

test_that("bootstrap_uses_link_percentiles() flags exp targets only", {
  f <- drmTMB:::bootstrap_uses_link_percentiles
  exp_row <- data.frame(transformation = I(list("exp")))
  lin_row <- data.frame(transformation = I(list("linear_predictor")))
  expect_true(f(exp_row))
  expect_false(f(lin_row))
})

test_that("bootstrap_restore_response_mask() restores masked missing values", {
  f <- drmTMB:::bootstrap_restore_response_mask
  values <- c(1, 2, 3, 4)
  mask <- c(FALSE, TRUE, FALSE, TRUE)
  expect_identical(f(values, mask), c(1, NA, 3, NA))
  expect_identical(f(values, c(TRUE, TRUE)), values)
  expect_identical(f(1:2, c(FALSE, FALSE, FALSE)), 1:2)
})

test_that("profile_sd_boundary_rows() marks SD and MI structured targets", {
  f <- drmTMB:::profile_sd_boundary_rows
  targets <- data.frame(
    target_class = c(
      "random-effect-sd",
      "fixed-effect",
      "random-effect-correlation",
      "fixed-effect"
    ),
    tmb_parameter = c("log_sd_mu", "log_sd_mi_group", "eta_cor", "beta_mu"),
    stringsAsFactors = FALSE
  )
  expect_equal(f(targets), c(TRUE, TRUE, FALSE, FALSE))
})

test_that("drm_ordinary_sd_rows() picks direct mu or sigma intercept SDs", {
  f <- drmTMB:::drm_ordinary_sd_rows
  targets <- data.frame(
    target_class = rep("random-effect-sd", 4L),
    target_type = rep("direct", 4L),
    tmb_parameter = c("log_sd_mu", "log_sd_sigma", "log_sd_phylo", "log_sd_mu"),
    term = c("(1 | g)", "(1 | g)", "phylo(1 | species)", "(1 + x | g)"),
    stringsAsFactors = FALSE
  )
  expect_equal(f(targets), c(TRUE, TRUE, FALSE, FALSE))
  expect_identical(f(targets[0, , drop = FALSE]), logical())
})

test_that("wald_ordinary_sd_near_boundary() flags huge log-scale SEs", {
  targets <- data.frame(
    target_class = "random-effect-sd",
    target_type = "direct",
    tmb_parameter = "log_sd_mu",
    term = "(1 | g)",
    stringsAsFactors = FALSE
  )
  rows <- drmTMB:::drm_ordinary_sd_rows(targets)
  expect_true(rows)
  expect_false(drmTMB:::wald_ordinary_sd_near_boundary(targets, se = 0.5))
  expect_true(drmTMB:::wald_ordinary_sd_near_boundary(targets, se = 2))
})

test_that("wald_boundary_targets() marks SD and correlation boundaries", {
  f <- drmTMB:::wald_boundary_targets
  expect_identical(f(drmTMB:::empty_profile_targets()), logical())
  targets <- data.frame(
    target_class = c("random-effect-sd", "random-effect-correlation", "fixed-effect"),
    estimate = c(1e-5, 0.99, 0.2),
    tmb_parameter = c("log_sd_mu", "eta_cor", "beta_mu"),
    stringsAsFactors = FALSE
  )
  hit <- f(targets, sd_boundary = 1e-4, rho_boundary = 0.98)
  expect_equal(hit, c(TRUE, TRUE, FALSE))
})

test_that("bootstrap_percentile_interval() pools estimate draws on the response scale", {
  draws <- data.frame(
    target = "mu",
    estimate = c(0.8, 1, 1.2, 1.4),
    link_estimate = log(c(0.8, 1, 1.2, 1.4)),
    bootstrap = 1:4,
    stringsAsFactors = FALSE
  )
  target <- list(
    parm = "mu",
    transformation = "linear_predictor",
    scale = "beta"
  )
  interval <- drmTMB:::bootstrap_percentile_interval(draws, target, probs = c(0.25, 0.75))
  expect_length(interval, 2L)
  expect_true(interval[[1L]] < interval[[2L]])
  expect_equal(
    unname(interval),
    unname(stats::quantile(draws$estimate, c(0.25, 0.75), type = 8, names = FALSE))
  )
})

test_that("bootstrap_percentile_interval() back-transforms exp targets on the link", {
  draws <- data.frame(
    estimate = exp(c(0, 0.1, 0.2, 0.3)),
    link_estimate = c(0, 0.1, 0.2, 0.3),
    bootstrap = 1:4,
    stringsAsFactors = FALSE
  )
  target <- list(
    parm = "sigma",
    transformation = "exp",
    scale = "sd"
  )
  interval <- drmTMB:::bootstrap_percentile_interval(
    draws,
    target,
    probs = c(0.025, 0.975)
  )
  link_q <- stats::quantile(draws$link_estimate, c(0.025, 0.975), type = 8, names = FALSE)
  expect_equal(unname(interval), exp(link_q))
})
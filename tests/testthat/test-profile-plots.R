new_profile_plot_data <- function(seed = 20260527, n = 80) {
  set.seed(seed)
  x <- stats::rnorm(n)
  data.frame(
    y = 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.7),
    x = x
  )
}

new_profile_plot_curve <- function(compare = FALSE) {
  if (isTRUE(compare)) {
    out <- data.frame(
      parm = rep("sigma", 6L),
      target_class = "distributional-scale",
      dpar = "sigma",
      term = "(Intercept)",
      level = 0.80,
      profile_value = rep(c(0.55, 0.70, 0.85), times = 2L),
      profile_value_link = log(rep(c(0.55, 0.70, 0.85), times = 2L)),
      objective = c(12.8, 11.0, 12.2, 12.6, 11.0, 12.1),
      delta_objective = c(1.8, 0, 1.2, 1.6, 0, 1.1),
      delta_deviance = c(3.6, 0, 2.4, 3.2, 0, 2.2),
      estimate = 0.70,
      link_estimate = log(0.70),
      profile_pass = rep(c("coarse", "dense"), each = 3L),
      elapsed = rep(c(0.02, 0.04), each = 3L),
      profile_controls = rep(c("ystep=0.5, ytol=2", "TMB defaults"), each = 3L),
      profile_source = "TMB::tmbprofile via stats::profile.drmTMB",
      conf.low = 0.56,
      conf.high = 0.84,
      conf.status = "profile",
      profile.message = "ok",
      scale = "response",
      transformation = "exp",
      tmb_parameter = "beta_sigma",
      index = 1L
    )
  } else {
    out <- data.frame(
      parm = "sigma",
      target_class = "distributional-scale",
      dpar = "sigma",
      term = "(Intercept)",
      level = 0.80,
      profile_value = c(0.55, 0.70, 0.85),
      profile_value_link = log(c(0.55, 0.70, 0.85)),
      objective = c(12.8, 11.0, 12.2),
      delta_objective = c(1.8, 0, 1.2),
      delta_deviance = c(3.6, 0, 2.4),
      estimate = 0.70,
      link_estimate = log(0.70),
      profile_pass = "profile",
      elapsed = 0.02,
      profile_controls = "ystep=0.5, ytol=2",
      profile_source = "TMB::tmbprofile via stats::profile.drmTMB",
      conf.low = 0.56,
      conf.high = 0.84,
      conf.status = "profile",
      profile.message = "ok",
      scale = "response",
      transformation = "exp",
      tmb_parameter = "beta_sigma",
      index = 1L
    )
  }
  class(out) <- c("profile.drmTMB", class(out))
  out
}

expect_profile_extends_beyond_cutoff <- function(prof) {
  level <- unique(prof$level)
  expect_length(level, 1L)
  cutoff <- stats::qchisq(level, df = 1)

  lower_support <- prof$profile_value < prof$conf.low &
    prof$delta_deviance > cutoff
  upper_support <- prof$profile_value > prof$conf.high &
    prof$delta_deviance > cutoff

  expect_gt(sum(lower_support, na.rm = TRUE), 0L)
  expect_gt(sum(upper_support, na.rm = TRUE), 0L)
  invisible(prof)
}

test_that("profile.drmTMB returns full curve data for a fitted sigma target", {
  dat <- new_profile_plot_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  prof <- stats::profile(
    fit,
    parm = "sigma",
    level = 0.95,
    trace = FALSE,
    profile_precision = "fast"
  )

  expect_s3_class(prof, "profile.drmTMB")
  expect_equal(unique(prof$parm), "sigma")
  expect_equal(unique(prof$target_class), "distributional-scale")
  expect_equal(unique(prof$level), 0.95)
  expect_equal(unique(prof$scale), "response")
  expect_equal(unique(prof$transformation), "exp")
  expect_equal(unique(prof$tmb_parameter), "beta_sigma")
  expect_equal(unique(prof$conf.status), "profile")
  expect_equal(unique(prof$profile_pass), "profile")
  expect_equal(unique(prof$profile_controls), "ystep=0.5, ytol=2")
  expect_equal(
    unique(prof$profile_source),
    "TMB::tmbprofile via stats::profile.drmTMB"
  )
  expect_true(all(is.finite(prof$profile_value)))
  expect_true(all(prof$profile_value > 0))
  expect_true(all(is.finite(prof$objective)))
  expect_true(all(is.finite(prof$conf.low)))
  expect_true(all(is.finite(prof$conf.high)))
  expect_equal(min(prof$delta_deviance), 0, tolerance = 1e-10)
  expect_equal(
    unique(prof$estimate),
    mean(stats::sigma(fit)),
    tolerance = 1e-12
  )
  expect_true(all(is.finite(prof$elapsed)))
  expect_profile_extends_beyond_cutoff(prof)
})

test_that("profile target matching accepts character names and numeric rows", {
  dat <- new_profile_plot_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  targets <- profile_targets(fit)
  sigma_row <- match("sigma", targets$parm)

  by_name <- drmTMB:::profile_match_targets(targets, "sigma")
  by_index <- drmTMB:::profile_match_targets(targets, sigma_row)

  expect_equal(by_name, by_index)
  expect_equal(by_index$parm, "sigma")
  expect_error(
    drmTMB:::profile_match_targets(targets, 0L),
    "numeric values"
  )
  expect_error(
    drmTMB:::profile_match_targets(targets, list("sigma")),
    "character or integer"
  )
})

test_that("plot.profile.drmTMB returns a ggplot for profile curves", {
  testthat::skip_if_not_installed("ggplot2")
  prof <- new_profile_plot_curve()

  out <- plot(prof)

  expect_s3_class(out, "ggplot")
  expect_equal(out$labels$x, "Profiled target value")
  expect_equal(out$labels$y, "Likelihood-ratio distance")
  expect_null(out$labels$colour)
  expect_null(out$labels$linetype)
  expect_match(out$labels$caption, "TMB::tmbprofile")
  expect_length(out$layers, 6L)
  built <- ggplot2::ggplot_build(out)
  expect_equal(nrow(built$data[[5L]]), nrow(prof))
  expect_equal(nrow(built$data[[6L]]), nrow(prof))
  expect_equal(unique(built$data[[1L]]$yintercept), stats::qchisq(0.80, df = 1))
})

test_that("plot.profile.drmTMB separates coarse and dense passes", {
  testthat::skip_if_not_installed("ggplot2")
  prof <- new_profile_plot_curve(compare = TRUE)

  out <- plot(prof)

  expect_s3_class(out, "ggplot")
  expect_equal(out$labels$colour, "Profile pass")
  expect_equal(out$labels$linetype, "Profile pass")
  expect_match(out$labels$caption, "coarse")
  expect_match(out$labels$caption, "dense")
  built <- ggplot2::ggplot_build(out)
  expect_equal(length(unique(built$data[[5L]]$group)), 2L)
})

test_that("profile and plot methods validate inputs", {
  testthat::skip_if_not_installed("ggplot2")
  dat <- new_profile_plot_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  no_tmb <- fit
  no_tmb$obj <- NULL
  prof <- new_profile_plot_curve()

  expect_error(stats::profile(fit), "parm")
  expect_error(stats::profile(fit, parm = "missing-target"), "Unknown")
  expect_error(stats::profile(no_tmb, parm = "sigma"), "TMB object")
  expect_error(
    stats::profile(fit, parm = "sigma", compare = NA),
    "compare"
  )
  not_profile_data <- list()
  class(not_profile_data) <- "profile.drmTMB"
  expect_error(plot(not_profile_data), "profile.drmTMB")
  expect_error(plot(prof[setdiff(names(prof), "profile_value")]), "missing")
  bad_profile_value <- prof
  bad_profile_value$profile_value <- "0.7"
  expect_error(plot(bad_profile_value), "profile_value")
  expect_error(plot(prof, interval = NA), "interval")
  expect_error(plot(prof, unknown = TRUE), "reserved")
})

test_that("plot.profile.drmTMB reports missing ggplot2 clearly", {
  prof <- new_profile_plot_curve()
  testthat::local_mocked_bindings(
    plot_profile_require_ggplot2 = function() {
      cli::cli_abort("ggplot2 unavailable")
    }
  )

  expect_error(plot(prof), "ggplot2 unavailable")
})

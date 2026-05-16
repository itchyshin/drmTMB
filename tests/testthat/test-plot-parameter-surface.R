test_that("plot_parameter_surface() returns a ggplot for prediction tables", {
  testthat::skip_if_not_installed("ggplot2")
  set.seed(20260525)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80),
    habitat = factor(rep(c("reef", "kelp"), length.out = 80))
  )
  fit <- drmTMB(bf(y ~ x + habitat, sigma ~ x), data = dat)
  grid <- prediction_grid(
    fit,
    focal = c("x", "habitat"),
    at = list(x = c(-1, 0, 1))
  )
  pred <- predict_parameters(
    fit,
    newdata = grid,
    dpar = c("mu", "sigma")
  )

  out <- plot_parameter_surface(pred, x = "x", colour = "habitat")

  expect_s3_class(out, "ggplot")
  expect_equal(out$labels$x, "x")
  expect_equal(out$labels$y, "Estimate")
  expect_equal(out$labels$colour, "habitat")
  expect_length(out$layers, 2L)
  built <- ggplot2::ggplot_build(out)
  expect_length(built$data, 2L)
})

test_that("plot_parameter_surface() can filter parameters and draw points only", {
  testthat::skip_if_not_installed("ggplot2")
  set.seed(20260526)
  dat <- data.frame(y = stats::rnorm(50), x = stats::rnorm(50))
  fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
  grid <- data.frame(x = c(-1, 0, 1))
  pred <- predict_parameters(fit, newdata = grid, dpar = c("mu", "sigma"))

  out <- plot_parameter_surface(
    pred,
    x = "x",
    dpar = "sigma",
    line = FALSE
  )

  expect_s3_class(out, "ggplot")
  expect_length(out$layers, 1L)
  expect_equal(out$labels$y, "sigma estimate (response scale)")
  built <- ggplot2::ggplot_build(out)
  expect_equal(nrow(built$data[[1L]]), 3L)
})

test_that("plot_parameter_surface() validates inputs", {
  testthat::skip_if_not_installed("ggplot2")
  pred <- data.frame(
    dpar = "mu",
    type = "response",
    estimate = 1,
    conf.status = "not_requested",
    interval_source = "not_available",
    x = 0
  )

  expect_error(plot_parameter_surface(list(), x = "x"), "data frame")
  expect_error(
    plot_parameter_surface(pred[setdiff(names(pred), "conf.status")], x = "x"),
    "missing required"
  )
  expect_error(
    plot_parameter_surface(pred, x = "missing"),
    "must name a column"
  )
  expect_error(
    plot_parameter_surface(pred, x = "x", line = FALSE, point = FALSE),
    "At least one"
  )
  expect_error(
    plot_parameter_surface(pred, x = "x", unknown = TRUE),
    "reserved"
  )
})

test_that("plot_parameter_surface() reports missing ggplot2 clearly", {
  pred <- data.frame(
    dpar = "mu",
    type = "response",
    estimate = 1,
    conf.status = "not_requested",
    interval_source = "not_available",
    x = 0
  )
  testthat::local_mocked_bindings(
    plot_parameter_surface_require_ggplot2 = function() {
      cli::cli_abort("ggplot2 unavailable")
    }
  )

  expect_error(plot_parameter_surface(pred, x = "x"), "ggplot2 unavailable")
})

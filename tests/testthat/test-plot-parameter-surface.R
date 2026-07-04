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

test_that("plot_parameter_surface() draws confidence bands from interval columns", {
  testthat::skip_if_not_installed("ggplot2")
  pred <- data.frame(
    dpar = "mu",
    type = "response",
    estimate = c(1.0, 1.3, 1.6, 1.2, 1.5, 1.8),
    conf.low = c(0.8, 1.0, 1.2, 0.9, 1.1, 1.4),
    conf.high = c(1.2, 1.6, 2.0, 1.5, 1.9, 2.2),
    conf.status = "wald",
    interval_source = "wald",
    x = rep(c(0, 1, 2), times = 2),
    habitat = factor(rep(c("reef", "kelp"), each = 3))
  )

  out <- plot_parameter_surface(pred, x = "x", colour = "habitat")

  expect_s3_class(out, "ggplot")
  expect_length(out$layers, 3L)
  built <- ggplot2::ggplot_build(out)
  expect_true(all(c("ymin", "ymax") %in% names(built$data[[1L]])))
  expect_equal(nrow(built$data[[1L]]), nrow(pred))
})

test_that("plot_parameter_surface() draws confidence bands from prediction tables", {
  testthat::skip_if_not_installed("ggplot2")
  set.seed(20260569)
  dat <- data.frame(y = stats::rnorm(70), x = stats::rnorm(70))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  grid <- data.frame(x = c(-1, 0, 1))
  pred <- predict_parameters(
    fit,
    newdata = grid,
    dpar = "mu",
    conf.int = TRUE
  )

  out <- plot_parameter_surface(pred, x = "x")

  expect_s3_class(out, "ggplot")
  expect_equal(unique(pred$conf.status), "wald")
  expect_length(out$layers, 3L)
  built <- ggplot2::ggplot_build(out)
  expect_true(all(c("ymin", "ymax") %in% names(built$data[[1L]])))
  expect_equal(nrow(built$data[[1L]]), nrow(grid))
})

test_that("plot_parameter_surface() leaves unavailable intervals undrawn", {
  testthat::skip_if_not_installed("ggplot2")
  pred <- data.frame(
    dpar = "mu",
    type = "response",
    estimate = c(1.0, 1.3, 1.6),
    conf.low = c(0.8, 1.0, 1.2),
    conf.high = c(1.2, 1.6, 2.0),
    conf.status = "not_requested",
    interval_source = "not_available",
    x = c(0, 1, 2)
  )

  out <- plot_parameter_surface(pred, x = "x")

  expect_s3_class(out, "ggplot")
  expect_length(out$layers, 2L)
  built <- ggplot2::ggplot_build(out)
  expect_length(built$data, 2L)

  pred$conf.status <- "profile"
  pred$interval_source <- "profile"
  out_no_interval <- plot_parameter_surface(pred, x = "x", interval = FALSE)
  expect_length(out_no_interval$layers, 2L)
})

test_that("plot_parameter_surface() draws interval bars for discrete x columns", {
  testthat::skip_if_not_installed("ggplot2")
  pred <- data.frame(
    dpar = "mu",
    type = "response",
    estimate = c(1.0, 1.4),
    conf.low = c(0.7, 1.1),
    conf.high = c(1.3, 1.7),
    conf.status = "profile",
    interval_source = "profile",
    season = factor(c("dry", "wet"))
  )

  out <- plot_parameter_surface(pred, x = "season", line = FALSE)

  expect_s3_class(out, "ggplot")
  expect_length(out$layers, 2L)
  built <- ggplot2::ggplot_build(out)
  expect_true(all(c("ymin", "ymax") %in% names(built$data[[1L]])))
  expect_equal(nrow(built$data[[1L]]), nrow(pred))
})

test_that("plot_parameter_surface() draws interval bars for factor prediction grids", {
  testthat::skip_if_not_installed("ggplot2")
  set.seed(20260605)
  n <- 90
  dat <- data.frame(
    y = stats::rnorm(n),
    habitat = factor(rep(c("reef", "kelp", "sand"), length.out = n))
  )
  fit <- drmTMB(bf(y ~ habitat, sigma ~ 1), family = gaussian(), data = dat)
  grid <- prediction_grid(fit, focal = "habitat")
  pred <- predict_parameters(
    fit,
    newdata = grid,
    dpar = "mu",
    conf.int = TRUE,
    conf.level = 0.90
  )

  out <- plot_parameter_surface(pred, x = "habitat", line = FALSE)

  expect_s3_class(out, "ggplot")
  expect_equal(class(out$layers[[1L]]$geom)[[1L]], "GeomErrorbar")
  expect_equal(unique(pred$conf.status), "wald")
  expect_equal(unique(pred$interval_source), "wald")
  expect_equal(unique(pred$conf.level), 0.90)
  built <- ggplot2::ggplot_build(out)
  expect_true(all(c("ymin", "ymax") %in% names(built$data[[1L]])))
  expect_equal(nrow(built$data[[1L]]), nrow(grid))
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
  expect_error(
    plot_parameter_surface(transform(pred, conf.low = 0), x = "x"),
    "both"
  )
  expect_error(
    plot_parameter_surface(
      transform(pred, conf.low = "0", conf.high = 1),
      x = "x"
    ),
    "conf.low"
  )
  expect_error(
    plot_parameter_surface(pred, x = "x", interval = NA),
    "interval"
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

test_that("plot_parameter_surface interval filter keeps bootstrap intervals", {
  data <- data.frame(
    conf.status = c("wald", "profile", "bootstrap", "not_requested"),
    interval_source = c("wald", "profile", "bootstrap", "not_available"),
    conf.low = c(0, 0, 0, NA),
    conf.high = c(1, 1, 1, NA),
    stringsAsFactors = FALSE
  )

  available <- drmTMB:::plot_parameter_surface_interval_available(data)
  expect_equal(available, c(TRUE, TRUE, TRUE, FALSE))

  kept <- drmTMB:::plot_parameter_surface_interval_data(data)
  expect_equal(nrow(kept), 3L)
  expect_true("bootstrap" %in% kept$interval_source)
})

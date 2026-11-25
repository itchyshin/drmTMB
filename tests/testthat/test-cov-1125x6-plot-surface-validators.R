# Validators in R/plot-parameter-surface.R (no ggplot build).

surface_row <- function() {
  data.frame(
    dpar = "mu",
    type = "response",
    estimate = 1,
    conf.status = "ok",
    interval_source = "wald",
    conf.low = 0.5,
    conf.high = 1.5,
    stringsAsFactors = FALSE
  )
}

test_that("validate_plot_parameter_surface_data() checks required columns", {
  ok <- drmTMB:::validate_plot_parameter_surface_data(surface_row())
  expect_s3_class(ok, "data.frame")
  bad <- surface_row()
  bad$estimate <- "x"
  expect_error(drmTMB:::validate_plot_parameter_surface_data(bad), "numeric")
  half <- surface_row()
  half$conf.low <- NULL
  expect_error(drmTMB:::validate_plot_parameter_surface_data(half), "conf.low")
})

test_that("validate_plot_parameter_surface_column() resolves names", {
  dat <- surface_row()
  expect_null(drmTMB:::validate_plot_parameter_surface_column(NULL, dat, "colour"))
  expect_error(
    drmTMB:::validate_plot_parameter_surface_column("missing", dat, "colour"),
    "column"
  )
})

test_that("validate_plot_parameter_surface_flag() enforces logical scalars", {
  expect_true(drmTMB:::validate_plot_parameter_surface_flag(TRUE, "ribbon"))
  expect_error(drmTMB:::validate_plot_parameter_surface_flag(c(TRUE, FALSE), "ribbon"))
})

test_that("filter_plot_parameter_surface_data() subsets dpar and type", {
  dat <- rbind(surface_row(), transform(surface_row(), dpar = "sigma", type = "link"))
  sub <- drmTMB:::filter_plot_parameter_surface_data(dat, dpar = "mu", type = "response")
  expect_equal(nrow(sub), 1L)
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(dat, dpar = "shape"),
    "Unknown distributional"
  )
})

test_that("plot_parameter_surface_interval helpers inspect interval columns", {
  dat <- surface_row()
  expect_true(drmTMB:::plot_parameter_surface_interval_available(dat))
  expect_false(drmTMB:::plot_parameter_surface_interval_is_ribbon(dat))
  unavailable <- transform(dat, conf.status = "", interval_source = "not_available")
  expect_false(drmTMB:::plot_parameter_surface_interval_available(unavailable))
})

test_that("plot_parameter_surface_require_ggplot2() errors when ggplot2 is absent", {
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    skip("ggplot2 is installed; cannot test the missing-package branch here")
  }
  expect_error(drmTMB:::plot_parameter_surface_require_ggplot2(), "ggplot2")
})
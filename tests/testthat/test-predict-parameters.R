test_that("predict_parameters() returns a long newdata table", {
  set.seed(20260516)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
  grid <- data.frame(
    x = c(-0.5, 0.5),
    dpar = c("left", "right"),
    conf.status = c("raw", "raw"),
    interval_source = c("field", "field")
  )
  row.names(grid) <- c("low_x", "high_x")

  out <- predict_parameters(
    fit,
    newdata = grid,
    dpar = c("mu", "sigma")
  )

  expect_named(
    out,
    c(
      "row",
      "row_label",
      "dpar",
      "component",
      "type",
      "estimate",
      "conf.status",
      "interval_source",
      "x",
      "newdata_dpar",
      "newdata_conf.status",
      "newdata_interval_source"
    )
  )
  expect_equal(out$row, c(1L, 2L, 1L, 2L))
  expect_equal(out$row_label, rep(c("low_x", "high_x"), 2))
  expect_equal(out$dpar, rep(c("mu", "sigma"), each = 2))
  expect_equal(
    out$component,
    rep(c("location", "distributional-scale"), each = 2)
  )
  expect_equal(
    out$estimate[out$dpar == "mu"],
    predict(fit, newdata = grid, dpar = "mu")
  )
  expect_equal(
    out$estimate[out$dpar == "sigma"],
    predict(fit, newdata = grid, dpar = "sigma")
  )
  expect_equal(out$conf.status, rep("not_requested", 4))
  expect_equal(out$interval_source, rep("not_available", 4))
  expect_equal(out$newdata_conf.status, rep(c("raw", "raw"), 2))
  expect_equal(out$newdata_interval_source, rep(c("field", "field"), 2))

  link <- predict_parameters(
    fit,
    newdata = grid,
    dpar = "sigma",
    type = "link",
    include_newdata = FALSE
  )
  expect_named(
    link,
    c(
      "row",
      "row_label",
      "dpar",
      "component",
      "type",
      "estimate",
      "conf.status",
      "interval_source"
    )
  )
  expect_equal(link$type, rep("link", 2))
  expect_equal(link$conf.status, rep("not_requested", 2))
  expect_equal(link$interval_source, rep("not_available", 2))
  expect_equal(
    link$estimate,
    predict(fit, newdata = grid, dpar = "sigma", type = "link")
  )
})

test_that("predict_parameters() defaults to all fitted distributional parameters", {
  set.seed(20260517)
  dat <- data.frame(
    y = stats::rnorm(70),
    x = stats::rnorm(70)
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)

  out <- predict_parameters(fit)

  expect_setequal(out$dpar, c("mu", "sigma"))
  expect_equal(nrow(out), 2L * nrow(dat))
  expect_equal(unique(out$conf.status), "not_requested")
  expect_equal(unique(out$interval_source), "not_available")
  expect_equal(
    out$estimate[out$dpar == "mu"],
    predict(fit, dpar = "mu")
  )
  expect_equal(
    out$estimate[out$dpar == "sigma"],
    predict(fit, dpar = "sigma")
  )
})

test_that("predict_parameters() reports shape and residual-correlation components", {
  set.seed(20260518)
  n <- 90
  x <- stats::rnorm(n)
  dat_t <- data.frame(
    y = 0.2 + 0.3 * x + stats::rt(n, df = 9),
    x = x
  )
  fit_t <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ x),
    family = student(),
    data = dat_t
  )
  shape <- predict_parameters(fit_t, dpar = "nu")
  expect_equal(unique(shape$component), "shape")
  expect_equal(shape$estimate, predict(fit_t, dpar = "nu"))

  y1 <- stats::rnorm(n)
  y2 <- 0.25 * y1 + sqrt(1 - 0.25^2) * stats::rnorm(n)
  dat_biv <- data.frame(y1 = y1, y2 = y2, x = stats::rnorm(n))
  fit_biv <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~x),
    family = c(gaussian(), gaussian()),
    data = dat_biv
  )
  grid <- data.frame(x = c(-0.2, 0.4))
  rho <- predict_parameters(fit_biv, newdata = grid, dpar = "rho12")
  expect_equal(unique(rho$component), "residual-correlation")
  expect_equal(rho$estimate, rho12(fit_biv, newdata = grid))
})

test_that("predict_parameters() validates arguments", {
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(predict_parameters(fit, dpar = "missing"), "Unknown")
  expect_error(predict_parameters(fit, dpar = NA_character_), "dpar")
  expect_error(predict_parameters(fit, newdata = list(x = 0)), "newdata")
  expect_error(predict_parameters(fit, include_newdata = NA), "include_newdata")
  expect_error(predict_parameters(fit, unknown = TRUE), "reserved")
})

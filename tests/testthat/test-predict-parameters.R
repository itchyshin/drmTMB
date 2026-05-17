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
    interval_source = c("field", "field"),
    conf.low = c(0.1, 0.2),
    conf.level = c(0.8, 0.9)
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
      "newdata_interval_source",
      "newdata_conf.low",
      "newdata_conf.level"
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
  expect_equal(out$newdata_conf.low, rep(c(0.1, 0.2), 2))
  expect_equal(out$newdata_conf.level, rep(c(0.8, 0.9), 2))

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

test_that("predict_parameters() adds Wald intervals for fixed-effect grids", {
  set.seed(20260568)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
  grid <- data.frame(x = c(-0.5, 0.5))

  out <- predict_parameters(
    fit,
    newdata = grid,
    dpar = c("mu", "sigma"),
    conf.int = TRUE
  )

  expect_true(
    all(c("std.error", "conf.low", "conf.high", "conf.level") %in% names(out))
  )
  expect_equal(out$conf.status, rep("wald", nrow(out)))
  expect_equal(out$interval_source, rep("wald", nrow(out)))
  expect_equal(out$conf.level, rep(0.95, nrow(out)))
  expect_true(all(is.finite(out$std.error)))
  expect_true(all(out$conf.low < out$estimate))
  expect_true(all(out$conf.high > out$estimate))

  basis <- drmTMB:::drm_fixed_effect_basis(
    fit,
    newdata = grid,
    dpar = "mu",
    covariance = TRUE
  )
  X <- as.matrix(basis$X)
  V <- as.matrix(basis$V)
  se <- sqrt(rowSums((X %*% V) * X))
  z <- stats::qnorm(0.975)
  mu <- out[out$dpar == "mu", , drop = FALSE]
  expect_equal(mu$std.error, unname(se))
  expect_equal(mu$conf.low, unname(basis$eta - z * se))
  expect_equal(mu$conf.high, unname(basis$eta + z * se))

  link <- predict_parameters(
    fit,
    newdata = grid,
    dpar = "sigma",
    type = "link",
    conf.int = TRUE
  )
  sigma_basis <- drmTMB:::drm_fixed_effect_basis(
    fit,
    newdata = grid,
    dpar = "sigma",
    covariance = TRUE
  )
  X_sigma <- as.matrix(sigma_basis$X)
  V_sigma <- as.matrix(sigma_basis$V)
  se_sigma <- sqrt(rowSums((X_sigma %*% V_sigma) * X_sigma))
  expect_equal(link$std.error, unname(se_sigma))
  expect_equal(link$conf.low, unname(sigma_basis$eta - z * se_sigma))
  expect_equal(link$conf.high, unname(sigma_basis$eta + z * se_sigma))
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

  grid_t <- data.frame(x = c(-0.3, 0.4))
  shape_ci <- predict_parameters(
    fit_t,
    newdata = grid_t,
    dpar = "nu",
    conf.int = TRUE
  )
  expect_equal(shape_ci$component, rep("shape", nrow(grid_t)))
  expect_equal(shape_ci$conf.status, rep("wald", nrow(grid_t)))
  expect_equal(shape_ci$interval_source, rep("wald", nrow(grid_t)))
  expect_true(all(is.finite(shape_ci$conf.low)))
  expect_true(all(shape_ci$conf.low > 2))

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

test_that("predict_parameters() reports random-effect scale model components", {
  sim <- new_gaussian_re_scale_data(n_id = 12, n_each = 4, seed = 20260567)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 120L, iter.max = 120L))
  )
  grid <- data.frame(w = c(-0.2, 0.4), row.names = c("low_w", "high_w"))

  out <- predict_parameters(fit, newdata = grid, dpar = "sd(id)")
  link <- predict_parameters(
    fit,
    newdata = grid,
    dpar = "sd(id)",
    type = "link"
  )

  expect_equal(out$row_label, row.names(grid))
  expect_equal(out$dpar, rep("sd(id)", nrow(grid)))
  expect_equal(out$component, rep("random-effect-sd-model", nrow(grid)))
  expect_equal(out$type, rep("response", nrow(grid)))
  expect_equal(
    out$estimate,
    unname(predict(fit, newdata = grid, dpar = "sd(id)"))
  )
  expect_equal(link$type, rep("link", nrow(grid)))
  expect_equal(
    link$estimate,
    unname(predict(fit, newdata = grid, dpar = "sd(id)", type = "link"))
  )
  expect_equal(out$w, grid$w)
  expect_equal(out$conf.status, rep("not_requested", nrow(grid)))
  expect_equal(out$interval_source, rep("not_available", nrow(grid)))

  out_ci <- predict_parameters(
    fit,
    newdata = grid,
    dpar = "sd(id)",
    conf.int = TRUE
  )
  expect_equal(out_ci$conf.status, rep("wald_unavailable", nrow(grid)))
  expect_equal(out_ci$interval_source, rep("not_available", nrow(grid)))
  expect_equal(out_ci$conf.level, rep(0.95, nrow(grid)))
  expect_true(all(is.na(out_ci$conf.low)))
  expect_true(all(is.na(out_ci$conf.high)))
})

test_that("predict_parameters() validates arguments", {
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(predict_parameters(fit, dpar = "missing"), "Unknown")
  expect_error(predict_parameters(fit, dpar = NA_character_), "dpar")
  expect_error(predict_parameters(fit, newdata = list(x = 0)), "newdata")
  expect_error(predict_parameters(fit, include_newdata = NA), "include_newdata")
  expect_error(predict_parameters(fit, conf.int = NA), "conf.int")
  expect_error(predict_parameters(fit, conf.level = 1), "conf.level")
  expect_error(predict_parameters(fit, unknown = TRUE), "reserved")

  unavailable <- predict_parameters(fit, conf.int = TRUE)
  expect_equal(unique(unavailable$conf.status), "newdata_required")
  expect_equal(unique(unavailable$interval_source), "not_available")
  expect_equal(unique(unavailable$conf.level), 0.95)
  expect_true(all(is.na(unavailable$conf.low)))
  expect_true(all(is.na(unavailable$conf.high)))
})

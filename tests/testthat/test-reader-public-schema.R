test_that("native reader schema has stable diagnostic and summary keys", {
  set.seed(20260814)
  dat <- data.frame(x = seq(-1, 1, length.out = 36L))
  dat$y <- 0.4 + 0.6 * dat$x + stats::rnorm(nrow(dat), sd = 0.3)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), gaussian(), data = dat)

  checks <- check_drm(fit)
  expect_s3_class(checks, "drm_check")
  expect_identical(names(checks), c("check", "status", "value", "message"))
  expect_true(all(vapply(checks, is.character, logical(1))))
  expect_true(all(checks$status %in% c("ok", "note", "warning", "error")))
  expect_identical(
    isTRUE(attr(checks, "ok")),
    !any(checks$status %in% c("warning", "error"))
  )

  report <- summary(fit)
  expect_s3_class(report, "summary.drmTMB")
  expect_true(all(c(
    "coefficients", "parameters", "covariance", "derived", "confint"
  ) %in% names(report)))
  expect_true(all(vapply(
    report[c("coefficients", "parameters", "covariance", "derived")],
    is.data.frame,
    logical(1)
  )))
  expect_null(report$confint)
  expect_s3_class(summary(fit, conf.int = TRUE)$confint, "data.frame")
  expect_true(all(c("sdpars", "corpars", "ordinal", "uncertainty") %in% names(report)))
  expect_equal(report$sdpars, fit$sdpars)
  expect_equal(report$corpars, fit$corpars)
})

test_that("ranef terms are model-scale deviations with actionable errors", {
  set.seed(20260814)
  id <- factor(rep(seq_len(8L), each = 5L))
  dat <- data.frame(id = id, x = rep(seq(-1, 1, length.out = 5L), 8L))
  dat$y <- 0.3 + 0.4 * dat$x +
    rep(stats::rnorm(nlevels(id), sd = 0.35), each = 5L) +
    stats::rnorm(nrow(dat), sd = 0.2)
  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), gaussian(), data = dat)

  random <- ranef(fit, "mu")
  expect_true("terms" %in% names(random))
  expect_named(random$terms, "(1 | id)")
  expect_true(all(is.finite(random$terms[["(1 | id)"]])))
  expect_true("values" %in% names(random))
  expect_true("latent" %in% names(random))

  no_random <- drmTMB(bf(y ~ x, sigma ~ 1), gaussian(), data = dat)
  expect_error(
    ranef(no_random, "mu"),
    "does not contain random effects"
  )
  expect_identical(ranef(no_random), list())
  expect_error(ranef(fit, "sigma"), "Unknown random-effect block.*Available blocks")
})

test_that("predict_parameters preserves its core schema and response distinction", {
  set.seed(20260814)
  dat <- data.frame(x = seq(-1, 1, length.out = 42L))
  dat$y <- exp(0.2 + 0.5 * dat$x + stats::rnorm(nrow(dat), sd = 0.3))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), lognormal(), data = dat)
  core <- c(
    "row", "row_label", "dpar", "component", "type", "estimate",
    "conf.status", "interval_source"
  )

  parameters <- predict_parameters(fit, dpar = "mu")
  expect_identical(names(parameters), core)
  expect_false(any(c("std.error", "conf.low", "conf.high", "conf.level") %in% names(parameters)))
  expect_identical(parameters$conf.status, rep("not_requested", nrow(parameters)))
  expect_identical(parameters$interval_source, rep("not_available", nrow(parameters)))

  grid <- data.frame(
    x = c(-0.5, 0.5),
    row = c("left", "right"),
    newdata_row = c("existing-left", "existing-right")
  )
  with_interval <- predict_parameters(
    fit,
    newdata = grid,
    dpar = "mu",
    conf.int = TRUE
  )
  expect_identical(intersect(names(with_interval), core), core)
  expect_true(all(c("std.error", "conf.low", "conf.high", "conf.level") %in% names(with_interval)))
  expect_true(all(c("x", "newdata_row", "newdata_row_1") %in% names(with_interval)))
  expect_identical(anyDuplicated(names(with_interval)), 0L)
  expect_identical(with_interval$newdata_row, grid$row)
  expect_identical(with_interval$newdata_row_1, grid$newdata_row)
  expect_lt(
    match("interval_source", names(with_interval)),
    match("x", names(with_interval))
  )

  mu <- predict_parameters(fit, dpar = "mu")$estimate
  response_mean <- fitted(fit)
  expect_false(isTRUE(all.equal(mu, response_mean)))
  expect_equal(
    response_mean,
    exp(predict(fit, dpar = "mu", type = "link") + 0.5 * sigma(fit)^2)
  )
})

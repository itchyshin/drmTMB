test_that("summary() reports fitted response-scale parameter ranges", {
  set.seed(20260511)
  n <- 80
  dat <- data.frame(
    x = stats::rnorm(n)
  )
  dat$y <- 0.2 + 0.4 * dat$x + stats::rnorm(n, sd = exp(-0.4 + 0.3 * dat$x))

  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )
  smry <- summary(fit)

  expect_s3_class(smry, "summary.drmTMB")
  expect_named(smry$coefficients, c("estimate", "std_error"))
  expect_true("fitted:sigma" %in% rownames(smry$parameters))
  sigma_row <- smry$parameters["fitted:sigma", ]
  expect_equal(sigma_row$component, "distributional-scale")
  expect_equal(sigma_row$profile_note, "use_confint_newdata")
  expect_lt(sigma_row$minimum, sigma_row$maximum)
  expect_equal(sigma_row$minimum, min(stats::sigma(fit)))
  expect_equal(sigma_row$maximum, max(stats::sigma(fit)))
})

test_that("summary() reports random-effect and correlation parameter tables", {
  set.seed(20260512)
  n_id <- 20
  n_each <- 6
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  u <- stats::rnorm(n_id, sd = 0.45)
  dat <- data.frame(id = id, x = x)
  dat$y <- 0.3 + 0.5 * dat$x + u[dat$id] + stats::rnorm(nrow(dat), sd = 0.35)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  smry <- summary(fit)

  expect_true("sigma" %in% rownames(smry$parameters))
  expect_true("sd:mu:(1 | id)" %in% rownames(smry$parameters))
  expect_equal(
    smry$parameters["sd:mu:(1 | id)", "estimate"],
    unname(fit$sdpars$mu[["(1 | id)"]])
  )

  profiled <- summary(
    fit,
    conf.int = TRUE,
    method = "profile",
    ci_parm = "sd:mu:(1 | id)"
  )
  sd_row <- profiled$parameters["sd:mu:(1 | id)", ]
  expect_true(is.finite(sd_row$conf.low))
  expect_true(is.finite(sd_row$conf.high))
  expect_lt(sd_row$conf.low, sd_row$conf.high)
  expect_true(all(is.na(profiled$coefficients$conf.low)))
})

test_that("summary() reports residual rho12 on the response scale", {
  set.seed(20260513)
  n <- 120
  y1 <- stats::rnorm(n)
  y2 <- 0.35 * y1 + sqrt(1 - 0.35^2) * stats::rnorm(n)
  dat <- data.frame(y1 = y1, y2 = y2, x = stats::rnorm(n))

  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1),
    family = c(gaussian(), gaussian()),
    data = dat
  )
  smry <- summary(fit)

  expect_true("rho12" %in% rownames(smry$parameters))
  expect_equal(smry$parameters["rho12", "component"], "residual-correlation")
  expect_equal(smry$parameters["rho12", "estimate"], unique(rho12(fit)))
})

test_that("summary() reports fitted shape ranges", {
  set.seed(20260515)
  n <- 90
  x <- seq(-1, 1, length.out = n)
  dat <- data.frame(
    y = 0.1 + 0.4 * x + stats::rt(n, df = 8),
    x = x
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ x),
    family = student(),
    data = dat
  )
  smry <- summary(fit)

  expect_true("fitted:nu" %in% rownames(smry$parameters))
  expect_equal(smry$parameters["fitted:nu", "component"], "shape")
  expect_lt(
    smry$parameters["fitted:nu", "minimum"],
    smry$parameters["fitted:nu", "maximum"]
  )
})

test_that("summary() adds Wald intervals to fixed effects only", {
  set.seed(20260514)
  dat <- data.frame(y = stats::rnorm(60), x = stats::rnorm(60))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  smry <- summary(fit, conf.int = TRUE, level = 0.90)

  expect_true(all(c("conf.low", "conf.high") %in% names(smry$coefficients)))
  expect_true(all(is.finite(smry$coefficients$conf.low)))
  expect_true(all(is.finite(smry$coefficients$conf.high)))
  expect_true("conf.low" %in% names(smry$parameters))
  expect_true(all(is.na(smry$parameters$conf.low)))
  expect_equal(smry$conf.method, "wald")
})

test_that("summary() validates confidence interval arguments", {
  dat <- data.frame(y = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ 1), family = gaussian(), data = dat)

  expect_error(summary(fit, conf.int = NA), "conf.int")
  expect_error(summary(fit, trace = NA), "trace")
  expect_error(summary(fit, level = 1), "level")
  expect_error(summary(fit, ci_parm = "sigma"), "ci_parm")
  expect_error(summary(fit, unknown = TRUE), "Additional arguments")
})

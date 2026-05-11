test_that("marginal_parameters() averages mu and sigma over newdata groups", {
  set.seed(20260519)
  dat <- data.frame(
    y = stats::rnorm(90),
    x = stats::rnorm(90),
    habitat = factor(rep(c("reef", "sand", "kelp"), length.out = 90))
  )
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ x),
    family = gaussian(),
    data = dat
  )
  grid <- expand.grid(
    x = c(-0.5, 0.5),
    habitat = levels(dat$habitat)
  )

  out <- marginal_parameters(
    fit,
    newdata = grid,
    dpar = c("mu", "sigma"),
    by = "habitat"
  )

  expect_named(out, c("dpar", "component", "type", "habitat", "estimate", "n"))
  expect_setequal(out$dpar, c("mu", "sigma"))
  expect_equal(unique(out$n), 2L)
  pred <- predict_parameters(
    fit,
    newdata = grid,
    dpar = c("mu", "sigma")
  )
  manual <- aggregate(
    estimate ~ dpar + component + type + habitat,
    data = pred,
    FUN = mean
  )
  manual <- manual[order(manual$dpar, manual$habitat), ]
  out_sorted <- out[order(out$dpar, out$habitat), names(manual)]
  row.names(manual) <- NULL
  row.names(out_sorted) <- NULL
  expect_equal(out_sorted, manual)
})

test_that("marginal_parameters() can average over all fitted rows", {
  set.seed(20260520)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ x),
    family = student(),
    data = dat
  )

  out <- marginal_parameters(fit, dpar = "nu")

  expect_equal(nrow(out), 1L)
  expect_equal(out$dpar, "nu")
  expect_equal(out$component, "shape")
  expect_equal(out$n, nrow(dat))
  expect_equal(out$estimate, mean(predict(fit, dpar = "nu")))
})

test_that("marginal_parameters() averages bivariate rho12 on supplied groups", {
  set.seed(20260521)
  n <- 100
  y1 <- stats::rnorm(n)
  y2 <- 0.3 * y1 + sqrt(1 - 0.3^2) * stats::rnorm(n)
  dat <- data.frame(
    y1 = y1,
    y2 = y2,
    x = stats::rnorm(n),
    period = factor(rep(c("early", "late"), length.out = n))
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ x + period),
    family = c(gaussian(), gaussian()),
    data = dat
  )
  grid <- expand.grid(
    x = c(-0.4, 0.4),
    period = levels(dat$period)
  )

  out <- marginal_parameters(fit, newdata = grid, dpar = "rho12", by = "period")

  expect_equal(unique(out$component), "residual-correlation")
  expect_equal(unique(out$n), 2L)
  expect_equal(
    out$estimate,
    as.vector(tapply(rho12(fit, newdata = grid), grid$period, mean))
  )
})

test_that("marginal_parameters() validates arguments", {
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(marginal_parameters(fit, by = "x"), "newdata")
  expect_error(
    marginal_parameters(fit, newdata = data.frame(x = 0), by = "missing"),
    "not present"
  )
  expect_error(marginal_parameters(fit, newdata = list(x = 0)), "newdata")
  expect_error(
    marginal_parameters(fit, newdata = data.frame(x = 0), by = NA_character_),
    "by"
  )
  expect_error(marginal_parameters(fit, unknown = TRUE), "reserved")
})

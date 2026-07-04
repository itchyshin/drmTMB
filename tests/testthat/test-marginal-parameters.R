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
  grid$conf.status <- rep(c("reef_rows", "sand_rows", "kelp_rows"), each = 2)

  out <- marginal_parameters(
    fit,
    newdata = grid,
    dpar = c("mu", "sigma"),
    by = "habitat"
  )

  expect_named(
    out,
    c(
      "dpar",
      "component",
      "type",
      "habitat",
      "estimate",
      "n",
      "conf.status",
      "interval_source"
    )
  )
  expect_setequal(out$dpar, c("mu", "sigma"))
  expect_equal(unique(out$n), 2L)
  expect_equal(unique(out$conf.status), "not_requested")
  expect_equal(unique(out$interval_source), "not_available")
  pred <- predict_parameters(
    fit,
    newdata = grid,
    dpar = c("mu", "sigma")
  )
  # mu (location) is averaged arithmetically; sigma (an SD) is averaged on the
  # variance scale (RMS) so the summary is a moment-appropriate dispersion.
  group_mean <- function(v, dpar) {
    if (identical(dpar, "sigma")) sqrt(mean(v^2)) else mean(v)
  }
  manual <- aggregate(
    estimate ~ dpar + component + type + habitat,
    data = pred,
    FUN = mean
  )
  for (r in seq_len(nrow(manual))) {
    sub <- pred$estimate[
      pred$dpar == manual$dpar[r] & pred$habitat == manual$habitat[r]
    ]
    manual$estimate[r] <- group_mean(sub, manual$dpar[r])
  }
  manual <- manual[order(manual$dpar, manual$habitat), ]
  out_sorted <- out[order(out$dpar, out$habitat), names(manual)]
  row.names(manual) <- NULL
  row.names(out_sorted) <- NULL
  expect_equal(out_sorted, manual)

  reserved_by <- marginal_parameters(
    fit,
    newdata = grid,
    dpar = "mu",
    by = "conf.status"
  )
  expect_named(
    reserved_by,
    c(
      "dpar",
      "component",
      "type",
      "newdata_conf.status",
      "estimate",
      "n",
      "conf.status",
      "interval_source"
    )
  )
  expect_setequal(
    reserved_by$newdata_conf.status,
    c("reef_rows", "sand_rows", "kelp_rows")
  )
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
  expect_equal(out$conf.status, "not_requested")
  expect_equal(out$interval_source, "not_available")
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
  expect_equal(unique(out$conf.status), "not_requested")
  expect_equal(unique(out$interval_source), "not_available")
  # rho12 is averaged on the Fisher-z scale, not arithmetically, so the pooled
  # correlation stays a valid correlation.
  fisher_z_mean <- function(v) {
    tanh(mean(atanh(pmax(pmin(v, 1 - 1e-12), -(1 - 1e-12)))))
  }
  expect_equal(
    out$estimate,
    as.vector(tapply(rho12(fit, newdata = grid), grid$period, fisher_z_mean))
  )
})

test_that("marginal_parameters() averages random-effect scale model rows", {
  sim <- new_gaussian_re_scale_data(n_id = 12, n_each = 4, seed = 20260568)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 120L, iter.max = 120L))
  )
  grid <- data.frame(
    w = c(-0.2, 0.4, 0.8),
    band = c("low", "low", "high")
  )

  out <- marginal_parameters(fit, newdata = grid, dpar = "sd(id)", by = "band")
  pred <- predict_parameters(fit, newdata = grid, dpar = "sd(id)")
  # sd(id) is a random-effect SD model, averaged on the variance scale (RMS).
  manual <- aggregate(
    estimate ~ dpar + component + type + band,
    data = pred,
    FUN = function(v) sqrt(mean(v^2))
  )
  manual <- manual[order(manual$band), ]
  out_sorted <- out[order(out$band), names(manual)]
  row.names(manual) <- NULL
  row.names(out_sorted) <- NULL

  expect_equal(unique(out$component), "random-effect-sd-model")
  expect_equal(out_sorted, manual)
  expect_equal(out$n[order(out$band)], c(1L, 2L))
  expect_equal(unique(out$conf.status), "not_requested")
  expect_equal(unique(out$interval_source), "not_available")
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

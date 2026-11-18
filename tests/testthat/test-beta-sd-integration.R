beta_sd_regression_dgp <- function(groups = 80L, repeats = 30L, seed = 20261017L) {
  set.seed(seed)
  z_group <- seq(-1, 1, length.out = groups)
  group_sd <- exp(log(0.32) + 0.25 * z_group)
  b_group <- stats::rnorm(groups, sd = group_sd)
  id <- factor(rep(seq_len(groups), each = repeats))
  z <- z_group[as.integer(id)]
  x <- stats::rnorm(length(id))
  mu <- stats::plogis(-0.15 + 0.35 * x + b_group[as.integer(id)])
  sigma <- 0.35
  precision <- 1 / sigma^2
  y <- stats::rbeta(length(mu), mu * precision, (1 - mu) * precision)
  list(
    data = data.frame(y, x, z, id),
    truth = c("(Intercept)" = log(0.32), z = 0.25),
    group_z = z_group
  )
}

test_that("Beta ordinary scalar SD recovers and survives public workflows", {
  sim <- beta_sd_regression_dgp()
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z),
    family = beta_family(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  estimate <- coef(fit, dpar = "sd(id)")
  expect_named(estimate, names(sim$truth))
  expect_equal(unname(estimate), unname(sim$truth), tolerance = 0.12)
  expect_true(all(is.finite(vcov(fit, dpar = "sd(id)"))))

  predicted <- predict(fit, dpar = "sd(id)")
  expect_length(predicted, length(sim$group_z))
  expect_true(all(predicted > 0))
  expect_equal(
    unname(predicted),
    unname(exp(sim$truth[[1L]] + sim$truth[[2L]] * sim$group_z)),
    tolerance = 0.06
  )
  expect_length(simulate(fit, nsim = 1L)[[1L]], nrow(sim$data))

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_equal(
    predict(restored, dpar = "sd(id)"),
    predict(fit, dpar = "sd(id)")
  )
})

test_that("constant Beta SD formula agrees with the legacy random-intercept fit", {
  sim <- beta_sd_regression_dgp(groups = 24L, repeats = 18L, seed = 20261018L)
  legacy <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = beta_family(),
    data = sim$data
  )
  constant <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ 1),
    family = beta_family(),
    data = sim$data
  )

  expect_equal(legacy$opt$convergence, 0)
  expect_equal(constant$opt$convergence, 0)
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(legacy)),
               tolerance = 1e-5)
  expect_equal(unname(coef(constant, dpar = "sd(id)")),
               unname(log(legacy$sdpars$mu)), tolerance = 1e-4)
})

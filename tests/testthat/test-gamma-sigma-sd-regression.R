gamma_sigma_sd_regression_dgp <- function(groups = 120L, repeats = 15L,
                                          seed = 20261022L) {
  set.seed(seed)
  group_w <- seq(-1, 1, length.out = groups)
  tau <- exp(log(0.22) + 0.35 * group_w)
  b <- stats::rnorm(groups, sd = tau)
  id <- factor(rep(seq_len(groups), each = repeats))
  n <- length(id)
  x <- stats::rnorm(n)
  mu <- exp(0.2 + 0.25 * x)
  sigma <- exp(-0.6 + b[as.integer(id)])
  y <- stats::rgamma(n, shape = 1 / sigma^2, scale = mu * sigma^2)
  list(
    data = data.frame(y = y, x = x, w = group_w[as.integer(id)], id = id),
    truth = c("(Intercept)" = log(0.22), w = 0.35),
    group_w = group_w
  )
}

test_that("Gamma sigma random-intercept SD can depend on a group predictor", {
  sim <- gamma_sigma_sd_regression_dgp()
  fit <- drmTMB(
    bf(
      y ~ x,
      sigma ~ 1 + (1 | id),
      sd(id, dpar = "sigma") ~ w
    ),
    family = Gamma(link = "log"),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  estimate <- coef(fit, dpar = 'sd(id, dpar = "sigma")')
  expect_named(estimate, names(sim$truth))
  expect_equal(unname(estimate), unname(sim$truth), tolerance = 0.20)
  sd_prediction <- predict(fit, dpar = 'sd(id, dpar = "sigma")')
  expect_equal(length(sd_prediction), length(sim$group_w))
  expect_equal(
    unname(sd_prediction),
    unname(exp(estimate[[1L]] + estimate[[2L]] * sim$group_w)),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(vcov(fit, dpar = 'sd(id, dpar = "sigma")'))))
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  sigma_contribution <- drmTMB:::sigma_random_effect_contribution(
    fit,
    dpar = "sigma"
  )
  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  expect_equal(
    unname(sigma_link),
    unname(fixed_sigma + sigma_contribution),
    tolerance = 1e-8
  )
  expect_equal(sigma(fit), exp(sigma_link), tolerance = 1e-8)

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  reloaded <- readRDS(path)
  expect_equal(
    predict(reloaded, dpar = 'sd(id, dpar = "sigma")'),
    sd_prediction
  )
})

test_that("constant Gamma sigma SD agrees with the legacy intercept fit", {
  sim <- gamma_sigma_sd_regression_dgp(
    groups = 36L,
    repeats = 12L,
    seed = 20261024L
  )
  legacy <- drmTMB(
    bf(y ~ x, sigma ~ 1 + (1 | id)),
    family = Gamma(link = "log"),
    data = sim$data
  )
  constant <- drmTMB(
    bf(
      y ~ x,
      sigma ~ 1 + (1 | id),
      sd(id, dpar = "sigma") ~ 1
    ),
    family = Gamma(link = "log"),
    data = sim$data
  )

  expect_equal(legacy$opt$convergence, 0)
  expect_equal(constant$opt$convergence, 0)
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(legacy)),
               tolerance = 1e-5)
  expect_equal(
    unname(coef(constant, dpar = 'sd(id, dpar = "sigma")')),
    unname(log(legacy$sdpars$sigma)),
    tolerance = 1e-4
  )
})

test_that("Gamma sigma SD predictors must be constant within group", {
  sim <- gamma_sigma_sd_regression_dgp(groups = 8L, repeats = 3L)
  sim$data$w <- seq_len(nrow(sim$data))

  expect_error(
    drmTMB(
      bf(
        y ~ x,
        sigma ~ 1 + (1 | id),
        sd(id, dpar = "sigma") ~ w
      ),
      family = Gamma(link = "log"),
      data = sim$data
    ),
    "constant within"
  )
})

test_that("Gamma sigma random-slope SD can depend on a group predictor", {
  set.seed(20261025L)
  groups <- 120L
  repeats <- 18L
  group_w <- seq(-1, 1, length.out = groups)
  tau <- exp(log(0.18) + 0.30 * group_w)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  b <- stats::rnorm(groups, sd = tau)
  mu <- exp(0.2 + 0.2 * x)
  sigma <- exp(-0.5 + x * b[as.integer(id)])
  dat <- data.frame(
    y = stats::rgamma(length(id), shape = 1 / sigma^2, scale = mu * sigma^2),
    x = x,
    w = group_w[as.integer(id)],
    id = id
  )

  fit <- drmTMB(
    bf(
      y ~ x,
      sigma ~ 1 + (0 + x | id),
      sd(id, dpar = "sigma", coef = "x") ~ w
    ),
    family = Gamma(link = "log"),
    data = dat
  )

  estimate <- coef(fit, dpar = 'sd(id, dpar = "sigma", coef = "x")')
  expect_equal(fit$opt$convergence, 0)
  expect_named(estimate, c("(Intercept)", "w"))
  expect_equal(unname(estimate), c(log(0.18), 0.30), tolerance = 0.20)
  expect_true(all(is.finite(vcov(
    fit, dpar = 'sd(id, dpar = "sigma", coef = "x")'
  ))))
  expect_equal(
    unname(predict(fit, dpar = 'sd(id, dpar = "sigma", coef = "x")')),
    unname(exp(estimate[[1L]] + estimate[[2L]] * group_w)),
    tolerance = 1e-10
  )
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  sigma_contribution <- drmTMB:::sigma_random_effect_contribution(
    fit,
    dpar = "sigma"
  )
  expect_equal(
    unname(sigma_link),
    unname(fixed_sigma + sigma_contribution),
    tolerance = 1e-8
  )
  expect_equal(sigma(fit), exp(sigma_link), tolerance = 1e-8)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  reloaded <- readRDS(path)
  expect_equal(
    predict(reloaded, dpar = 'sd(id, dpar = "sigma", coef = "x")'),
    predict(fit, dpar = 'sd(id, dpar = "sigma", coef = "x")')
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1 + (0 + x | id)),
      family = Gamma(link = "log"),
      data = dat
    ),
    "random intercepts are implemented"
  )
})

new_gaussian_ls_data <- function(n = 80) {
  x <- seq(-1, 1, length.out = n)
  z <- rep(seq(-0.8, 0.8, length.out = 5), length.out = n)
  mu <- 0.25 + 0.6 * x
  sigma <- exp(-0.3 + 0.25 * z)
  eps <- rep(c(-0.85, -0.1, 0.65, 1.15, -0.45), length.out = n)

  data.frame(
    y = mu + sigma * eps,
    x = x,
    z = z
  )
}

test_that("drmTMB fits fixed-effect Gaussian location-scale models", {
  set.seed(20260506)
  n <- 500
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.4, 0.7)
  beta_sigma <- c(-0.2, 0.35)
  mu <- beta_mu[[1]] + beta_mu[[2]] * dat$x
  sigma <- exp(beta_sigma[[1]] + beta_sigma[[2]] * dat$z)
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(unname(coef(fit, "mu")), beta_mu, tolerance = 0.12)
  expect_equal(unname(coef(fit, "sigma")), beta_sigma, tolerance = 0.12)
  expect_length(predict(fit, dpar = "mu"), n)
  expect_true(all(stats::sigma(fit) > 0))
  expect_s3_class(stats::logLik(fit), "logLik")
})

test_that("drmTMB uses complete cases across Gaussian location-scale terms", {
  dat <- new_gaussian_ls_data(48)
  dat$unused <- NA_real_
  dat$y[4] <- NA_real_
  dat$x[13] <- NA_real_
  dat$z[25] <- NA_real_
  keep <- stats::complete.cases(dat[c("y", "x", "z")])

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_equal(fit$data$y, dat$y[keep])
  expect_equal(fit$data$x, dat$x[keep])
  expect_equal(fit$data$z, dat$z[keep])
  expect_equal(sum(is.na(fit$data[c("y", "x", "z")])), 0)
  expect_length(predict(fit, dpar = "mu"), sum(keep))
  expect_length(predict(fit, dpar = "sigma"), sum(keep))
})

test_that("drmTMB fits explicit intercept-only sigma formulas", {
  dat <- new_gaussian_ls_data(64)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  sigma_coef <- coef(fit, "sigma")
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  sigma_response <- predict(fit, dpar = "sigma")

  expect_equal(fit$opt$convergence, 0)
  expect_equal(names(sigma_coef), "(Intercept)")
  expect_equal(
    sigma_link,
    rep(unname(sigma_coef), nrow(dat)),
    tolerance = 1e-12
  )
  expect_equal(sigma_response, exp(sigma_link), tolerance = 1e-12)
  expect_equal(min(sigma_response), max(sigma_response), tolerance = 1e-12)
})

test_that("predict() uses newdata for Gaussian location-scale fits", {
  dat <- new_gaussian_ls_data(72)
  newdata <- data.frame(
    x = c(-0.75, 0.2, 0.9),
    z = c(0.8, 0, -0.8)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expected_mu <- as.vector(
    stats::model.matrix(~ x, newdata) %*% coef(fit, "mu")
  )
  expected_sigma_link <- as.vector(
    stats::model.matrix(~ z, newdata) %*% coef(fit, "sigma")
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    expected_mu,
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma", type = "link"),
    expected_sigma_link,
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma"),
    exp(expected_sigma_link),
    tolerance = 1e-12
  )
  expect_error(
    predict(fit, newdata = list(x = 0, z = 0), dpar = "mu"),
    "data frame"
  )
})

test_that("drmTMB handles factor predictors and default sigma", {
  set.seed(20260507)
  n <- 240
  dat <- data.frame(
    group = factor(rep(c("control", "treatment"), each = n / 2))
  )
  dat$y <- stats::rnorm(
    n,
    mean = 1 + 0.6 * (dat$group == "treatment"),
    sd = 0.8
  )

  fit <- drmTMB(
    bf(y ~ group),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_length(coef(fit, "mu"), 2)
  expect_length(coef(fit, "sigma"), 1)
  sims <- simulate(fit, nsim = 2, seed = 1)
  expect_s3_class(sims, "data.frame")
  expect_equal(dim(sims), c(n, 2))
})

test_that("Phase 1 rejects unsupported model syntax clearly", {
  dat <- data.frame(
    y = seq(-1, 1, length.out = 10),
    x = seq(1, 2, length.out = 10),
    z = seq(0, 1, length.out = 10),
    id = rep(1:2, each = 5)
  )

  expect_error(
    drmTMB(bf(y ~ x), family = poisson(), data = dat),
    "supported families"
  )
  expect_error(
    drmTMB(bf(mu1 = y ~ x, mu2 = y ~ x), family = gaussian(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(y ~ x, shape ~ x), family = gaussian(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(y ~ x + (x | id)), family = gaussian(), data = dat),
    "Only random intercepts"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 | p | id)), family = gaussian(), data = dat),
    "Correlated-block syntax"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z + (1 | id)), family = gaussian(), data = dat),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(bf(y ~ x, rho12 = ~ x), family = gaussian(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(y ~ x + phylo(id)), family = gaussian(), data = dat),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ gr(id, cov = diag(1))),
      family = gaussian(),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(bf(y ~ x, sd(id) ~ 1), family = gaussian(), data = dat),
    "only support"
  )
})

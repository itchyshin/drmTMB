new_gaussian_ri_data <- function(n_id = 36, n_each = 10, sd_id = 0.7,
                                 seed = 20260507) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u_id <- stats::rnorm(n_id, sd = sd_id)
  u_id <- u_id - mean(u_id)
  beta_mu <- c(0.35, 0.55)
  beta_sigma <- c(-0.25, 0.22)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x + u_id[id]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_id = sd_id
  )
}

test_that("Gaussian location models support random intercepts in mu", {
  sim <- new_gaussian_ri_data()

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.18)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.15)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_id), 0.25)
  expect_equal(length(fit$random_effects$mu$values), nlevels(sim$data$id))
  expect_named(summary(fit)$sdpars, "mu")
  expect_equal(
    length(fit$opt$par),
    length(coef(fit, "mu")) + length(coef(fit, "sigma")) + length(fit$sdpars$mu)
  )
})

test_that("conditional predictions and residuals include mu random intercepts", {
  sim <- new_gaussian_ri_data(n_id = 24, n_each = 8, seed = 20260508)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  fixed_mu <- as.vector(stats::model.matrix(~ x, sim$data) %*% coef(fit, "mu"))
  conditional_mu <- predict(fit, dpar = "mu")
  response_resid <- residuals(fit)

  expect_equal(fit$opt$convergence, 0)
  expect_gt(stats::sd(conditional_mu - fixed_mu), 0.05)
  expect_lt(stats::sd(sim$data$y - conditional_mu), stats::sd(sim$data$y - fixed_mu))
  expect_equal(response_resid, sim$data$y - conditional_mu, tolerance = 1e-12)

  newdata <- data.frame(x = c(-0.2, 0.3), z = c(0, 1), id = sim$data$id[1:2])
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    as.vector(stats::model.matrix(~ x, newdata) %*% coef(fit, "mu")),
    tolerance = 1e-12
  )
})

test_that("multiple Gaussian mu random-intercept terms are supported", {
  set.seed(20260509)
  n_site <- 18
  n_observer <- 9
  n <- 360
  dat <- data.frame(
    site = factor(sample(seq_len(n_site), n, replace = TRUE)),
    observer = factor(sample(seq_len(n_observer), n, replace = TRUE)),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  u_site <- stats::rnorm(n_site, sd = 0.45)
  u_observer <- stats::rnorm(n_observer, sd = 0.3)
  dat$y <- stats::rnorm(
    n,
    mean = 0.2 + 0.5 * dat$x + u_site[dat$site] + u_observer[dat$observer],
    sd = exp(-0.2 + 0.15 * dat$z)
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | site) + (1 | observer), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, c("(1 | site)", "(1 | observer)"))
  expect_equal(length(fit$random_effects$mu$values), n_site + n_observer)
  expect_equal(
    length(fit$opt$par),
    length(coef(fit, "mu")) + length(coef(fit, "sigma")) + length(fit$sdpars$mu)
  )
})

test_that("random-intercept grouping variables participate in missingness", {
  sim <- new_gaussian_ri_data(n_id = 10, n_each = 4, seed = 20260510)
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$z[7] <- NA_real_
  dat$id[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "z", "id")])

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "z", "id")]))
})

test_that("unsupported random-effect cases fail clearly", {
  dat <- data.frame(
    y = stats::rnorm(20),
    y2 = stats::rnorm(20),
    x = stats::rnorm(20),
    id = factor(rep("one", 20))
  )

  expect_error(
    drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = dat),
    "fewer than two levels"
  )
  dat$id <- factor(rep(seq_len(4), each = 5))
  dat$single <- factor(seq_len(nrow(dat)))
  expect_error(
    drmTMB(bf(y ~ x + (1 | single)), family = gaussian(), data = dat),
    "only singleton groups"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y ~ x + (1 | id), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "unsupported model terms"
  )
})

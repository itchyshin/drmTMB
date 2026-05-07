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

new_gaussian_rs_data <- function(n_id = 45, n_each = 9, sd_slope = 0.45,
                                 seed = 20260511) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u_slope <- stats::rnorm(n_id, sd = sd_slope)
  u_slope <- u_slope - mean(u_slope)
  beta_mu <- c(0.25, 0.7)
  beta_sigma <- c(-0.3, 0.2)
  mu <- beta_mu[[1L]] + (beta_mu[[2L]] + u_slope[id]) * x
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
    sd_slope = sd_slope
  )
}

new_gaussian_corr_rs_data <- function(n_id = 36, n_each = 8, sd0 = 0.55,
                                      sd1 = 0.35, rho_re = 0.45,
                                      seed = 20260515) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  u0 <- sd0 * z0
  u1 <- sd1 * (rho_re * z0 + sqrt(1 - rho_re^2) * z1)
  beta_mu <- c(0.25, 0.65)
  beta_sigma <- c(-0.3, 0.18)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x + u0[id] + u1[id] * x
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
    sd = c(`(Intercept)` = sd0, x = sd1),
    rho_re = rho_re
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

test_that("Gaussian location models support simple random slopes in mu", {
  sim <- new_gaussian_rs_data()

  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.16)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.15)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_slope), 0.25)
  expect_named(fit$sdpars$mu, "(0 + x | id)")
  expect_equal(length(fit$random_effects$mu$values), nlevels(sim$data$id))
  expect_equal(
    length(fit$opt$par),
    length(coef(fit, "mu")) + length(coef(fit, "sigma")) + length(fit$sdpars$mu)
  )
})

test_that("Gaussian mu can combine independent random intercept and slope terms", {
  set.seed(20260512)
  n_id <- 36
  n_each <- 9
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u0 <- stats::rnorm(n_id, sd = 0.55)
  u1 <- stats::rnorm(n_id, sd = 0.35)
  dat <- data.frame(
    y = stats::rnorm(
      n,
      mean = 0.1 + 0.6 * x + u0[id] + u1[id] * x,
      sd = exp(-0.25 + 0.12 * z)
    ),
    x = x,
    z = z,
    id = id
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, c("(1 | id)", "(0 + x | id)"))
  expect_equal(length(fit$random_effects$mu$values), 2 * n_id)
  expect_gt(unname(fit$sdpars$mu[["(1 | id)"]]), 0.15)
  expect_gt(unname(fit$sdpars$mu[["(0 + x | id)"]]), 0.1)
})

test_that("Gaussian mu supports correlated random intercept-slope blocks", {
  sim <- new_gaussian_corr_rs_data()

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.18)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.16)
  expect_equal(length(fit$random_effects$mu$values), 2 * nlevels(sim$data$id))
  expect_named(
    fit$sdpars$mu,
    c("(1 + x | id):(Intercept)", "(1 + x | id):x")
  )
  expect_named(fit$corpars$mu, "cor((Intercept),x | id)")
  expect_lt(max(abs(unname(fit$sdpars$mu) - unname(sim$sd))), 0.25)
  expect_lt(abs(unname(fit$corpars$mu) - sim$rho_re), 0.3)
  expect_false(any(grepl("rho12", names(fit$corpars$mu), fixed = TRUE)))
})

test_that("Gaussian mu correlated blocks handle near-zero and negative correlations", {
  cases <- list(
    near_zero = list(rho = 0.02, seed = 20260516),
    negative = list(rho = -0.5, seed = 20260517)
  )

  for (case in cases) {
    sim <- new_gaussian_corr_rs_data(
      n_id = 32,
      n_each = 7,
      rho_re = case$rho,
      seed = case$seed
    )

    fit <- drmTMB(
      bf(y ~ x + (1 + x | id), sigma ~ z),
      family = gaussian(),
      data = sim$data
    )

    cor_est <- unname(fit$corpars$mu)
    expect_equal(fit$opt$convergence, 0)
    expect_true(all(is.finite(fit$sdpars$mu)))
    expect_true(all(is.finite(cor_est)))
    expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.22)
    if (case$rho > -0.1) {
      expect_lt(abs(cor_est), 0.35)
    } else {
      expect_lt(cor_est, -0.15)
      expect_lt(abs(cor_est - case$rho), 0.35)
    }
  }
})

test_that("Gaussian mu correlated blocks remain finite near high correlations", {
  cases <- list(
    positive = list(rho = 0.8, seed = 20260518),
    negative = list(rho = -0.8, seed = 20260519)
  )

  for (case in cases) {
    sim <- new_gaussian_corr_rs_data(
      n_id = 28,
      n_each = 7,
      sd0 = 0.6,
      sd1 = 0.4,
      rho_re = case$rho,
      seed = case$seed
    )

    fit <- drmTMB(
      bf(y ~ x + (1 + x | id), sigma ~ z),
      family = gaussian(),
      data = sim$data
    )

    cor_est <- unname(fit$corpars$mu)
    expect_equal(fit$opt$convergence, 0)
    expect_true(all(is.finite(c(fit$sdpars$mu, cor_est))))
    expect_lt(abs(cor_est), 1)
    expect_equal(sign(cor_est), sign(case$rho))
    expect_true(all(unname(fit$sdpars$mu) > 0))
    expect_true(all(unname(fit$sdpars$mu) < 2))
  }
})

test_that("Gaussian mu correlated blocks handle weak random-slope SDs", {
  sim <- new_gaussian_corr_rs_data(
    sd0 = 0.55,
    sd1 = 0.06,
    rho_re = 0.3,
    seed = 20260520
  )

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(abs(unname(fit$sdpars$mu[[1L]]) - sim$sd[[1L]]), 0.3)
  expect_true(is.finite(unname(fit$sdpars$mu[[2L]])))
  expect_lt(unname(fit$sdpars$mu[[2L]]), 0.3)
  expect_true(is.finite(unname(fit$corpars$mu)))
  expect_lt(abs(unname(fit$corpars$mu)), 1)
})

test_that("Gaussian mu correlated blocks support factor fixed predictors", {
  sim <- new_gaussian_corr_rs_data(n_id = 32, n_each = 8, seed = 20260522)
  dat <- sim$data
  dat$f <- factor(rep(c("control", "treated"), length.out = nrow(dat)))
  dat$y <- dat$y + ifelse(dat$f == "treated", 0.25, 0)

  fit <- drmTMB(
    bf(y ~ x + f + (1 + x | id), sigma ~ z + f),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true("ftreated" %in% names(coef(fit, "mu")))
  expect_true("ftreated" %in% names(coef(fit, "sigma")))
  expect_true(all(is.finite(c(coef(fit, "mu"), coef(fit, "sigma")))))
  expect_true(all(is.finite(c(fit$sdpars$mu, fit$corpars$mu))))
  expect_lt(abs(unname(fit$corpars$mu)), 1)
})

test_that("correlated random-block variables participate in missingness", {
  sim <- new_gaussian_corr_rs_data(n_id = 12, n_each = 5, seed = 20260523)
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$z[7] <- NA_real_
  dat$id[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "z", "id")])

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "z", "id")]))
})

test_that("random-slope variables participate in missingness", {
  sim <- new_gaussian_rs_data(n_id = 12, n_each = 5, seed = 20260513)
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$z[7] <- NA_real_
  dat$id[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "z", "id")])

  fit <- drmTMB(
    bf(y ~ 1 + (0 + x | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "z", "id")]))
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
  expect_error(
    drmTMB(bf(y ~ x + (1 + x + y2 | id)), family = gaussian(), data = dat),
    "Only random intercepts"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 + x | id) + (0 + x | id)), family = gaussian(), data = dat),
    "Overlapping random-effect terms"
  )
  dat$group_label <- factor(rep(letters[1:2], length.out = nrow(dat)))
  expect_error(
    drmTMB(bf(y ~ x + (0 + group_label | id)), family = gaussian(), data = dat),
    "must be numeric"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 + x | p | id)), family = gaussian(), data = dat),
    "planned later"
  )
})

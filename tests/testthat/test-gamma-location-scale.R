new_gamma_data <- function(n = 900, seed = 20260522) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.2, 0.45)
  beta_sigma <- c(-0.75, 0.25)
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$biomass <- stats::rgamma(n, shape = 1 / sigma^2, scale = mu * sigma^2)
  list(data = dat, beta_mu = beta_mu, beta_sigma = beta_sigma)
}

test_that("drmTMB fits fixed-effect Gamma mean-CV models", {
  sim <- new_gamma_data()

  fit <- drmTMB(
    bf(biomass ~ x, sigma ~ z),
    family = stats::Gamma(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "gamma")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.12)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.12)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(sigma(fit) > 0))
  expect_equal(
    predict(fit, dpar = "mu"),
    exp(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
})

test_that("Gamma likelihood matches independent dgamma calculation", {
  sim <- new_gamma_data(n = 260, seed = 20260523)

  fit <- drmTMB(
    bf(biomass ~ x, sigma ~ z),
    family = stats::Gamma(link = "log"),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  mu <- exp(eta_mu)
  sigma <- exp(eta_sigma)
  ll_independent <- sum(stats::dgamma(
    fit$model$y,
    shape = 1 / sigma^2,
    scale = mu * sigma^2,
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("Gamma methods return mean and coefficient-of-variation scales", {
  sim <- new_gamma_data(n = 180, seed = 20260524)
  fit <- drmTMB(
    bf(biomass ~ x, sigma ~ z),
    family = stats::Gamma(link = "log"),
    data = sim$data
  )

  expect_equal(predict(fit, dpar = "mu"), fitted(fit), tolerance = 1e-12)
  expect_equal(predict(fit, dpar = "sigma", type = "response"), sigma(fit))
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted(fit)) / (fitted(fit) * sigma(fit)),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - fitted(fit), tolerance = 1e-12)
  newdata <- data.frame(x = c(0, 1), z = c(0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    exp(as.vector(stats::model.matrix(~x, newdata) %*% coef(fit, "mu"))),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma", type = "link"),
    as.vector(stats::model.matrix(~z, newdata) %*% coef(fit, "sigma")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma"),
    exp(predict(fit, newdata = newdata, dpar = "sigma", type = "link")),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260525)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) > 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260525),
    simulate(fit, nsim = 2, seed = 20260525)
  )
})

test_that("Gamma handles factor predictors and coefficient-of-variation edge cases", {
  n <- 400
  group <- factor(rep(c("control", "treatment"), each = n / 2))
  beta_mu <- c(0.15, 0.35)
  beta_sigma <- c(-0.8, 0.3)
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * (group == "treatment"))
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * (group == "treatment"))
  q <- unlist(lapply(split(seq_len(n), group), function(idx) {
    (seq_along(idx) - 0.5) / length(idx)
  }))
  dat <- data.frame(
    biomass = stats::qgamma(q, shape = 1 / sigma^2, scale = mu * sigma^2),
    group = group
  )

  fit <- drmTMB(
    bf(biomass ~ group, sigma ~ group),
    family = stats::Gamma(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(unname(coef(fit, "mu")), beta_mu, tolerance = 0.01)
  expect_equal(unname(coef(fit, "sigma")), beta_sigma, tolerance = 0.01)

  gamma_case <- function(sigma_value) {
    n <- 240
    dat <- data.frame(
      biomass = stats::qgamma(
        (seq_len(n) - 0.5) / n,
        shape = 1 / sigma_value^2,
        scale = exp(0.25) * sigma_value^2
      )
    )
    drmTMB(
      bf(biomass ~ 1, sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat
    )
  }
  small <- gamma_case(0.22)
  large <- gamma_case(1.10)

  expect_equal(small$opt$convergence, 0)
  expect_equal(large$opt$convergence, 0)
  expect_equal(unname(coef(small, "mu")), 0.25, tolerance = 0.03)
  expect_equal(exp(unname(coef(small, "sigma"))), 0.22, tolerance = 0.03)
  expect_equal(unname(coef(large, "mu")), 0.25, tolerance = 0.03)
  expect_equal(exp(unname(coef(large, "sigma"))), 1.10, tolerance = 0.06)
})

test_that("Gamma supports default sigma and complete-case filtering", {
  sim <- new_gamma_data(n = 120, seed = 20260527)
  fit_default_sigma <- drmTMB(
    bf(biomass ~ x),
    family = stats::Gamma(link = "log"),
    data = sim$data
  )

  expect_equal(fit_default_sigma$opt$convergence, 0)
  expect_length(coef(fit_default_sigma, "sigma"), 1)
  expect_equal(ncol(fit_default_sigma$model$X$sigma), 1)

  n <- 30
  dat <- data.frame(
    x = seq(-1, 1, length.out = n),
    z = rep(c(0, 1), length.out = n)
  )
  mu <- exp(0.2 + 0.3 * dat$x)
  sigma <- exp(-0.4 + 0.15 * dat$z)
  q <- (seq_len(n) - 0.5) / n
  dat$biomass <- stats::qgamma(q, shape = 1 / sigma^2, scale = mu * sigma^2)
  dat$biomass[[1L]] <- 0
  dat$x[[1L]] <- NA
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(biomass ~ x, sigma ~ z),
    family = stats::Gamma(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), n - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y > 0))
})

test_that("Gamma models reject unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x, sigma ~ 1),
      family = stats::Gamma(),
      data = dat
    ),
    "Gamma models currently require"
  )
  expect_error(
    drmTMB(bf(abs(y) + 0.1 ~ x, sigma ~ 1), family = base::gamma, data = dat),
    "Currently supported families"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x, sigma ~ 1),
      family = base::gamma(1),
      data = dat
    ),
    "Currently supported families"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    "positive finite response"
  )
  expect_error(
    drmTMB(
      bf(mu = ~x, sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    "must include a response"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma = ~1, sigma = ~x),
      family = stats::Gamma(link = "log"),
      data = transform(dat, y = abs(y) + 0.1)
    ),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = transform(dat, y = NA_real_)
    ),
    "No complete observations"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x, nu ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    "only support"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x + (1 | id), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x + meta_V(V = rep(0.1, 4)), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    "meta_V"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x, sigma ~ 1, sd(id) ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    "Random-effect scale formulae"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, x) ~ x, sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    "mvbind"
  )
  expect_error(
    drmTMB(
      bf(mu1 = abs(y) + 0.1 ~ x, mu2 = abs(x) + 0.1 ~ x),
      family = c(stats::gaussian(), stats::Gamma(link = "log")),
      data = dat
    ),
    "Mixed-response"
  )
  expect_error(
    drmTMB(
      bf(mu1 = abs(y) + 0.1 ~ x, mu2 = abs(x) + 0.1 ~ x),
      family = c(stats::Gamma(link = "log"), stats::Gamma(link = "log")),
      data = dat
    ),
    "Mixed-response"
  )
})

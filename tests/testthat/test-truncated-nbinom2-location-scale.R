new_truncated_nbinom2_data <- function(n = 1600, seed = 20260618) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.45, x = -0.35)
  beta_sigma <- c(`(Intercept)` = -0.70, z = 0.22)
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  dat$count <- stats::qnbinom(
    p0 + stats::runif(n) * (1 - p0),
    size = 1 / sigma^2,
    mu = mu
  )
  list(data = dat, beta_mu = beta_mu, beta_sigma = beta_sigma)
}

test_that("drmTMB fits fixed-effect truncated nbinom2 models", {
  sim <- new_truncated_nbinom2_data()

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = truncated_nbinom2(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "truncated_nbinom2")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.16)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.22)
  expect_true(all(fit$model$y > 0))
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(sigma(fit) > 0))
  expect_equal(
    predict(fit, dpar = "mu"),
    exp(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, dpar = "sigma"),
    exp(predict(fit, dpar = "sigma", type = "link")),
    tolerance = 1e-12
  )
  expect_true(all(fitted(fit) >= predict(fit, dpar = "mu")))
})

test_that("truncated nbinom2 likelihood matches independent dnbinom calculation", {
  sim <- new_truncated_nbinom2_data(n = 360, seed = 20260619)

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = truncated_nbinom2(),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  mu <- exp(eta_mu)
  sigma <- exp(eta_sigma)
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  ll_independent <- sum(stats::dnbinom(
    fit$model$y,
    size = 1 / sigma^2,
    mu = mu,
    log = TRUE
  ) - log1p(-p0))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("truncated nbinom2 methods return positive-count summaries", {
  sim <- new_truncated_nbinom2_data(n = 260, seed = 20260620)
  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = truncated_nbinom2(),
    data = sim$data
  )

  mu <- predict(fit, dpar = "mu")
  sigma <- sigma(fit)
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  fitted_mean <- mu / (1 - p0)
  component_var <- mu + sigma^2 * mu^2
  positive_var <- (component_var + mu^2) / (1 - p0) - fitted_mean^2

  expect_equal(fitted(fit), fitted_mean, tolerance = 1e-12)
  expect_equal(predict(fit, dpar = "sigma", type = "response"), sigma)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted_mean) / sqrt(positive_var),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - fitted_mean, tolerance = 1e-12)
  newdata <- data.frame(x = c(-1, 0, 1), z = c(-1, 0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    exp(as.vector(stats::model.matrix(~ x, newdata) %*% coef(fit, "mu"))),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma"),
    exp(as.vector(stats::model.matrix(~ z, newdata) %*% coef(fit, "sigma"))),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260621)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) > 0))
  expect_true(all(unlist(sims, use.names = FALSE) %% 1 == 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260621),
    simulate(fit, nsim = 2, seed = 20260621)
  )
})

test_that("truncated nbinom2 supports default sigma and complete-case filtering", {
  sim <- new_truncated_nbinom2_data(n = 120, seed = 20260622)
  fit_default_sigma <- drmTMB(
    bf(count ~ x),
    family = truncated_nbinom2(),
    data = sim$data
  )

  expect_equal(fit_default_sigma$opt$convergence, 0)
  expect_length(coef(fit_default_sigma, "sigma"), 1)
  expect_equal(ncol(fit_default_sigma$model$X$sigma), 1)

  dat <- sim$data[seq_len(40), ]
  dat$count[[1L]] <- 0
  dat$x[[1L]] <- NA
  dat$count[[2L]] <- 1.5
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = truncated_nbinom2(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y > 0))
  expect_true(all(fit$model$y %% 1 == 0))
})

test_that("truncated nbinom2 approaches zero-truncated Poisson as sigma approaches zero", {
  dat <- data.frame(y = c(1, 1, 2, 4, 7))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat
  )

  par <- fit$obj$par
  par[["beta_mu"]] <- 0
  par[["beta_sigma"]] <- -20
  ll_nb <- -fit$obj$fn(par)
  ll_pois <- sum(stats::dpois(dat$y, lambda = 1, log = TRUE) -
    log1p(-stats::dpois(0, lambda = 1)))

  expect_equal(ll_nb, ll_pois, tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("truncated nbinom2 supports factor predictors and scale extremes", {
  n <- 260
  group <- factor(rep(c("control", "treatment"), each = n / 2))
  q <- seq(0.05, 0.95, length.out = n)
  beta_mu <- c(`(Intercept)` = 0.25, grouptreatment = -0.30)
  beta_sigma <- c(`(Intercept)` = -0.8, grouptreatment = 0.35)
  X <- stats::model.matrix(~ group)
  mu <- exp(as.vector(X %*% beta_mu))
  sigma <- exp(as.vector(X %*% beta_sigma))
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  dat <- data.frame(
    count = stats::qnbinom(p0 + q * (1 - p0), size = 1 / sigma^2, mu = mu),
    group = group
  )

  fit <- drmTMB(
    bf(count ~ group, sigma ~ group),
    family = truncated_nbinom2(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_true(all(is.finite(summary(fit)$coefficients[, "estimate"])))
  expect_true(all(sigma(fit) > 0))
})

test_that("truncated nbinom2 rejects unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(1, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(bf(y ~ x, nu ~ 1), family = truncated_nbinom2(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(y ~ x, zi ~ 1), family = truncated_nbinom2(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(y ~ x, hu ~ 1), family = truncated_nbinom2(), data = dat),
    "hurdle"
  )
  expect_error(
    drmTMB(bf(mu = ~ x, sigma ~ 1), family = truncated_nbinom2(), data = dat),
    "must include a response"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sigma ~ x), family = truncated_nbinom2(), data = dat),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = truncated_nbinom2(),
      data = transform(dat, y = c(0, 1, 2, 3))
    ),
    "positive integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = truncated_nbinom2(),
      data = transform(dat, y = c(1, 1.5, 2, 3))
    ),
    "positive integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = truncated_nbinom2(),
      data = transform(dat, y = c(1, -1, 2, 3))
    ),
    "positive integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = truncated_nbinom2(),
      data = transform(dat, y = NA_real_)
    ),
    "No complete observations"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = truncated_nbinom2(), data = dat),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_known_V(V = rep(0.1, 4)), sigma ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sd(id) ~ 1), family = truncated_nbinom2(), data = dat),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(bf(mvbind(y, y) ~ x, sigma ~ 1), family = truncated_nbinom2(), data = dat),
    "mvbind"
  )
  expect_error(
    drmTMB(
      bf(cbind(y, y) ~ x, sigma ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "single positive-count response"
  )
})

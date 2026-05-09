new_nbinom2_data <- function(n = 1200, seed = 20260602) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.35, x = -0.40)
  beta_sigma <- c(`(Intercept)` = -0.65, z = 0.30)
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$count <- stats::rnbinom(n, size = 1 / sigma^2, mu = mu)
  list(data = dat, beta_mu = beta_mu, beta_sigma = beta_sigma)
}

test_that("drmTMB fits fixed-effect nbinom2 mean-dispersion models", {
  sim <- new_nbinom2_data()

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "nbinom2")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.12)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.18)
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
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
})

test_that("nbinom2 likelihood matches independent dnbinom calculation", {
  sim <- new_nbinom2_data(n = 320, seed = 20260603)

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  mu <- exp(eta_mu)
  sigma <- exp(eta_sigma)
  ll_independent <- sum(stats::dnbinom(
    fit$model$y,
    size = 1 / sigma^2,
    mu = mu,
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("nbinom2 likelihood weights scale rows and match row duplication", {
  sim <- new_nbinom2_data(n = 220, seed = 20260607)
  dat <- sim$data

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat
  )
  fit_double <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat,
    weights = rep(2, nrow(dat))
  )

  expect_equal(coef(fit_double, "mu"), coef(fit, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_double, "sigma"), coef(fit, "sigma"), tolerance = 1e-6)
  expect_equal(
    as.numeric(logLik(fit_double)),
    2 * as.numeric(logLik(fit)),
    tolerance = 1e-6
  )
  expect_equal(stats::weights(fit_double), rep(2, nrow(dat)))

  w <- rep(c(0, 1, 2, 3), length.out = nrow(dat))
  fit_weighted <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat,
    weights = w
  )
  dat_expanded <- dat[rep(seq_len(nrow(dat)), w), , drop = FALSE]
  fit_expanded <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat_expanded
  )

  expect_equal(stats::weights(fit_weighted), w)
  expect_equal(coef(fit_weighted, "mu"), coef(fit_expanded, "mu"), tolerance = 1e-4)
  expect_equal(
    coef(fit_weighted, "sigma"),
    coef(fit_expanded, "sigma"),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(logLik(fit_weighted)),
    as.numeric(logLik(fit_expanded)),
    tolerance = 1e-4
  )
})

test_that("nbinom2 methods return mean and overdispersion scales", {
  sim <- new_nbinom2_data(n = 220, seed = 20260604)
  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = sim$data
  )

  mu <- fitted(fit)
  sigma <- sigma(fit)
  expect_equal(predict(fit, dpar = "mu"), mu, tolerance = 1e-12)
  expect_equal(predict(fit, dpar = "sigma", type = "response"), sigma)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - mu) / sqrt(mu + sigma^2 * mu^2),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - mu, tolerance = 1e-12)
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
  sims <- simulate(fit, nsim = 2, seed = 20260605)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) %% 1 == 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260605),
    simulate(fit, nsim = 2, seed = 20260605)
  )
})

test_that("nbinom2 supports default sigma and complete-case filtering", {
  sim <- new_nbinom2_data(n = 120, seed = 20260606)
  fit_default_sigma <- drmTMB(
    bf(count ~ x),
    family = nbinom2(),
    data = sim$data
  )

  expect_equal(fit_default_sigma$opt$convergence, 0)
  expect_length(coef(fit_default_sigma, "sigma"), 1)
  expect_equal(ncol(fit_default_sigma$model$X$sigma), 1)

  dat <- sim$data[seq_len(40), ]
  dat$count[[1L]] <- -1
  dat$x[[1L]] <- NA
  dat$count[[2L]] <- 1.5
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y >= 0))
  expect_true(all(fit$model$y %% 1 == 0))
})

test_that("nbinom2 approaches Poisson likelihood as sigma approaches zero", {
  dat <- data.frame(y = c(0, 1, 2, 4, 7))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat
  )

  par <- fit$obj$par
  par[["beta_mu"]] <- 0
  par[["beta_sigma"]] <- -20
  ll_nb <- -fit$obj$fn(par)
  ll_pois <- sum(stats::dpois(dat$y, lambda = 1, log = TRUE))

  expect_equal(ll_nb, ll_pois, tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))

  par[["beta_sigma"]] <- -400
  expect_equal(-fit$obj$fn(par), ll_pois, tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("nbinom2 rejects unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(bf(y ~ x, nu ~ 1), family = nbinom2(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(mu = ~ x, sigma ~ 1), family = nbinom2(), data = dat),
    "must include a response"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sigma ~ x), family = nbinom2(), data = dat),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = nbinom2(),
      data = transform(dat, y = c(0, 1.5, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = nbinom2(),
      data = transform(dat, y = c(0, -1, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = nbinom2(),
      data = transform(dat, y = NA_real_)
    ),
    "No complete observations"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = nbinom2(), data = dat),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_known_V(V = rep(0.1, 4)), sigma ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sd(id) ~ 1), family = nbinom2(), data = dat),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(bf(mvbind(y, y) ~ x, sigma ~ 1), family = nbinom2(), data = dat),
    "mvbind"
  )
})

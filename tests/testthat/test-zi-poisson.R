new_zi_poisson_data <- function(n = 1800, seed = 20260608) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    habitat = factor(sample(c("open", "edge"), n, replace = TRUE))
  )
  beta_mu <- c(`(Intercept)` = 0.30, x = -0.35, habitatopen = 0.25)
  beta_zi <- c(`(Intercept)` = -0.90, z = 0.55, habitatopen = -0.45)
  X_mu <- stats::model.matrix(~ x + habitat, dat)
  X_zi <- stats::model.matrix(~ z + habitat, dat)
  mu <- exp(as.vector(X_mu %*% beta_mu))
  zi <- stats::plogis(as.vector(X_zi %*% beta_zi))
  dat$count <- ifelse(stats::runif(n) < zi, 0L, stats::rpois(n, lambda = mu))
  list(data = dat, beta_mu = beta_mu, beta_zi = beta_zi)
}

test_that("drmTMB fits zero-inflated Poisson models through a zi formula", {
  sim <- new_zi_poisson_data()

  fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "zi_poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.12)
  expect_lt(max(abs(coef(fit, "zi") - sim$beta_zi)), 0.35)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(predict(fit, dpar = "zi") > 0))
  expect_true(all(predict(fit, dpar = "zi") < 1))
  expect_equal(
    predict(fit, dpar = "mu"),
    exp(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, dpar = "zi"),
    stats::plogis(predict(fit, dpar = "zi", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(
    fitted(fit),
    (1 - predict(fit, dpar = "zi")) * predict(fit, dpar = "mu"),
    tolerance = 1e-12
  )
  expect_equal(sigma(fit), rep(1, nobs(fit)))
})

test_that("zero-inflated Poisson likelihood matches independent calculation", {
  sim <- new_zi_poisson_data(n = 420, seed = 20260609)

  fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_zi <- as.vector(fit$model$X$zi %*% coef(fit, "zi"))
  mu <- exp(eta_mu)
  zi <- stats::plogis(eta_zi)
  ll_independent <- ifelse(
    fit$model$y == 0,
    log(zi + (1 - zi) * stats::dpois(0, lambda = mu)),
    log1p(-zi) + stats::dpois(fit$model$y, lambda = mu, log = TRUE)
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), sum(ll_independent), tolerance = 1e-6)
})

test_that("zero-inflated Poisson methods return count-scale summaries", {
  sim <- new_zi_poisson_data(n = 260, seed = 20260610)
  fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  mu <- predict(fit, dpar = "mu")
  zi <- predict(fit, dpar = "zi")
  response_mean <- (1 - zi) * mu
  expect_equal(fitted(fit), response_mean, tolerance = 1e-12)
  expect_equal(residuals(fit), fit$model$y - response_mean, tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - response_mean) / sqrt((1 - zi) * mu * (1 + zi * mu)),
    tolerance = 1e-12
  )
  newdata <- data.frame(
    x = c(-1, 0, 1),
    z = c(-1, 0, 1),
    habitat = factor(c("edge", "open", "edge"), levels = levels(fit$data$habitat))
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    exp(as.vector(stats::model.matrix(~ x + habitat, newdata) %*% coef(fit, "mu"))),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "zi"),
    stats::plogis(as.vector(stats::model.matrix(~ z + habitat, newdata) %*% coef(fit, "zi"))),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260611)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) %% 1 == 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260611),
    simulate(fit, nsim = 2, seed = 20260611)
  )
})

test_that("zero-inflated Poisson approaches Poisson likelihood as zi approaches zero", {
  dat <- data.frame(y = c(0, 1, 2, 4, 7))
  fit <- drmTMB(
    bf(y ~ 1, zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat
  )

  par <- fit$obj$par
  par[["beta_mu"]] <- 0
  par[["beta_zi"]] <- -30
  ll_zip <- -fit$obj$fn(par)
  ll_pois <- sum(stats::dpois(dat$y, lambda = 1, log = TRUE))

  expect_equal(ll_zip, ll_pois, tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("zero-inflated Poisson likelihood stays finite near certain structural zeros", {
  dat <- data.frame(y = c(0, 0, 1, 2))
  fit <- drmTMB(
    bf(y ~ 1, zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat
  )

  par <- fit$obj$par
  par[["beta_mu"]] <- 0
  par[["beta_zi"]] <- 30
  mu <- rep(1, nrow(dat))
  eta_zi <- rep(30, nrow(dat))
  logspace_add <- function(a, b) {
    m <- pmax(a, b)
    m + log(exp(a - m) + exp(b - m))
  }
  log_zi <- -log1p(exp(-eta_zi))
  log_one_minus_zi <- -log1p(exp(eta_zi))
  ll_zip <- ifelse(
    dat$y == 0,
    logspace_add(log_zi, log_one_minus_zi + stats::dpois(0, lambda = mu, log = TRUE)),
    log_one_minus_zi + stats::dpois(dat$y, lambda = mu, log = TRUE)
  )

  expect_equal(-fit$obj$fn(par), sum(ll_zip), tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("zero-inflated Poisson supports complete-case filtering", {
  sim <- new_zi_poisson_data(n = 80, seed = 20260612)
  dat <- sim$data
  dat$count[[1L]] <- -1
  dat$x[[1L]] <- NA
  dat$count[[2L]] <- 1.5
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y >= 0))
  expect_true(all(fit$model$y %% 1 == 0))
})

test_that("zero-inflated Poisson rejects unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 1, zi ~ x),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi = y ~ x),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "one-sided"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ x + (1 | id)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ offset(rep(1, 4))),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 0),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "zero-column"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_known_V(V = rep(0.1, 4)), zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 1, sd(id) ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y) ~ x, zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "mvbind"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 1),
      family = stats::poisson(link = "log"),
      data = transform(dat, y = c(0, 1.5, 2, 3))
    ),
    "non-negative integer"
  )
  expect_false(exists("zi_poisson", where = asNamespace("drmTMB"), inherits = FALSE))
})

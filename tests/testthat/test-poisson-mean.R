new_poisson_data <- function(n = 900, seed = 20260596) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu <- c(`(Intercept)` = 0.25, x = -0.45)
  lambda <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  dat$count <- stats::rpois(n, lambda = lambda)
  list(data = dat, beta_mu = beta_mu)
}

test_that("drmTMB fits fixed-effect Poisson mean models", {
  sim <- new_poisson_data()

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(coef(fit, "mu")))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.12)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_equal(
    predict(fit, dpar = "mu"),
    exp(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
  expect_equal(sigma(fit), rep(1, nobs(fit)))
})

test_that("Poisson likelihood matches independent dpois calculation", {
  sim <- new_poisson_data(n = 260, seed = 20260597)

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  mu <- exp(eta_mu)
  ll_independent <- sum(stats::dpois(fit$model$y, lambda = mu, log = TRUE))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("Poisson mean model agrees with base glm on an overlapping model", {
  sim <- new_poisson_data(n = 280, seed = 20260598)

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = sim$data
  )
  fit_glm <- stats::glm(
    count ~ x,
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_glm)),
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(logLik(fit)),
    as.numeric(stats::logLik(fit_glm)),
    tolerance = 1e-6
  )
})

test_that("Poisson methods return count-scale summaries", {
  sim <- new_poisson_data(n = 180, seed = 20260599)
  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_equal(predict(fit, dpar = "mu"), fitted(fit), tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted(fit)) / sqrt(fitted(fit)),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - fitted(fit), tolerance = 1e-12)
  newdata <- data.frame(x = c(-1, 0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    exp(as.vector(stats::model.matrix(~ x, newdata) %*% coef(fit, "mu"))),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260600)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) %% 1 == 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260600),
    simulate(fit, nsim = 2, seed = 20260600)
  )
})

test_that("Poisson supports complete-case filtering", {
  sim <- new_poisson_data(n = 40, seed = 20260601)
  dat <- sim$data
  dat$count[[1L]] <- -1
  dat$x[[1L]] <- NA
  dat$count[[2L]] <- 1.5
  dat$x[[2L]] <- NA

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y >= 0))
  expect_true(all(fit$model$y %% 1 == 0))
})

test_that("Poisson models reject unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(bf(y ~ x), family = stats::poisson(link = "identity"), data = dat),
    "Poisson models currently require"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = stats::poisson(link = "log"), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(mu = ~ x), family = stats::poisson(link = "log"), data = dat),
    "must include a response"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::poisson(link = "log"),
      data = transform(dat, y = c(0, 1.5, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::poisson(link = "log"),
      data = transform(dat, y = c(0, -1, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::poisson(link = "log"),
      data = transform(dat, y = NA_real_)
    ),
    "No complete observations"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + offset(rep(1, 4))),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_known_V(V = rep(0.1, 4))),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sd(id) ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y) ~ x),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "mvbind"
  )
})

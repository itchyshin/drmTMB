test_that("Poisson logLik matches density at the fitted mu offset (#1940)", {
  set.seed(271127)
  n <- 60L
  x <- stats::rnorm(n)
  t <- stats::runif(n, min = 0.5, max = 2.5)
  d <- data.frame(
    y = stats::rpois(n, lambda = t * exp(0.1 + 0.3 * x)),
    x = x,
    t = t
  )
  fit <- drmTMB(
    bf(y ~ x + offset(log(t))),
    data = d,
    family = poisson()
  )

  eta_link <- predict(fit, dpar = "mu", type = "link")
  off <- fit$model$offset$mu
  eta_fe <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(eta_link, eta_fe + off, tolerance = 1e-10)

  ll_manual <- sum(stats::dpois(d$y, exp(eta_link), log = TRUE))
  ll_fit <- as.numeric(stats::logLik(fit))
  expect_equal(ll_fit, ll_manual, tolerance = 1e-6)
  expect_equal(ll_fit, -fit$opt$objective, tolerance = 1e-6)
})

test_that("ZI Poisson fitted and predict(type = \"mean\") use the mu offset (#1941)", {
  set.seed(27112702)
  n <- 50L
  x <- stats::rnorm(n)
  t <- stats::runif(n, min = 0.6, max = 2.2)
  d <- data.frame(
    y = stats::rpois(n, lambda = t * exp(0.1 + 0.25 * x)),
    x = x,
    t = t
  )
  fit <- drmTMB(
    bf(y ~ x + offset(log(t)), zi ~ x),
    data = d,
    family = poisson()
  )

  eta_mu <- predict(fit, dpar = "mu", type = "link")
  pzi <- stats::plogis(predict(fit, dpar = "zi", type = "link"))
  ey_true <- (1 - pzi) * exp(eta_mu)

  ft <- fitted(fit)
  ey <- predict(fit, type = "mean")
  expect_equal(ft, ey_true, tolerance = 1e-8)
  expect_equal(ey, ey_true, tolerance = 1e-8)
  expect_equal(ft, ey, tolerance = 1e-12)
})
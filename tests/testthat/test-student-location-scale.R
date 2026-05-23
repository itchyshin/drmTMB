student_test_data <- function(n = 600) {
  set.seed(20260509)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.25, 0.6)
  beta_sigma <- c(-0.3, 0.25)
  beta_nu <- log(6)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  nu <- 2 + exp(beta_nu)
  q <- stats::qt((seq_len(n) - 0.5) / n, df = nu)
  dat$y <- mu + sigma * sample(q)
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    beta_nu = beta_nu,
    nu = nu
  )
}

student_nll <- function(y, mu, sigma, nu) {
  -sum(stats::dt((y - mu) / sigma, df = nu, log = TRUE) - log(sigma))
}

test_that("drmTMB fits fixed-effect Student-t location-scale-shape models", {
  sim <- student_test_data()
  dat <- sim$data

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = student(),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.08)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.08)
  expect_lt(max(abs(unname(coef(fit, "nu")) - sim$beta_nu)), 0.3)
  expect_true(all(predict(fit, dpar = "nu") > 2))
  expect_equal(
    predict(fit, dpar = "nu"),
    2 + exp(predict(fit, dpar = "nu", type = "link")),
    tolerance = 1e-12
  )
  expect_length(predict(fit, dpar = "mu"), nrow(dat))
  expect_length(stats::sigma(fit), nrow(dat))
  expect_s3_class(stats::logLik(fit), "logLik")
  expect_equal(stats::nobs(fit), nrow(dat))
})

test_that("Student-t objective matches an independent R likelihood", {
  sim <- student_test_data(90)
  dat <- sim$data
  dat$w <- rep(seq(-0.5, 0.5, length.out = 9), length.out = nrow(dat))

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ w),
    family = student(),
    data = dat
  )
  mu <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu"))
  sigma <- exp(as.vector(stats::model.matrix(~z, dat) %*% coef(fit, "sigma")))
  nu <- 2 + exp(as.vector(stats::model.matrix(~w, dat) %*% coef(fit, "nu")))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    fit$opt$objective,
    student_nll(dat$y, mu, sigma, nu),
    tolerance = 1e-8
  )
})

test_that("Student-t methods simulate and compute residuals", {
  sim <- student_test_data(120)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = student(),
    data = sim$data
  )

  sims <- simulate(fit, nsim = 2, seed = 1)
  expect_s3_class(sims, "data.frame")
  expect_equal(dim(sims), c(nrow(sim$data), 2))
  expect_length(residuals(fit), nrow(sim$data))
  expect_length(residuals(fit, type = "pearson"), nrow(sim$data))
  expect_true(all(is.finite(residuals(fit, type = "pearson"))))
})

test_that("Student-t models reject unsupported early-phase terms clearly", {
  dat <- data.frame(
    y = stats::rnorm(12),
    x = stats::rnorm(12),
    id = rep(1:3, each = 4),
    V = rep(0.01, 12)
  )

  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = student(), data = dat),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = V), sigma ~ 1),
      family = student(),
      data = dat
    ),
    "not implemented"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sd(id) ~ 1), family = student(), data = dat),
    "Random-effect scale formulae"
  )
})

test_that("Student-t shape random effects have a specific boundary", {
  dat <- data.frame(
    y = stats::rnorm(20),
    x = stats::rnorm(20),
    id = rep(1:5, each = 4)
  )

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ x + (1 | id)),
      family = student(),
      data = dat
    ),
    "Shape random effects are not implemented"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ x + (0 + x | id)),
      family = student(),
      data = dat
    ),
    "future skew-normal and skew-t shape parameters"
  )
})

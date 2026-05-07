test_that("drmTMB fits Gaussian meta-regression with diagonal known V", {
  set.seed(20260508)
  n <- 500
  dat <- data.frame(
    x = stats::rnorm(n),
    vi = stats::runif(n, min = 0.01, max = 0.08)
  )
  beta_mu <- c(0.2, -0.5)
  beta_sigma <- c(log(0.35), 0.25)
  mu <- beta_mu[[1]] + beta_mu[[2]] * dat$x
  sigma <- exp(beta_sigma[[1]] + beta_sigma[[2]] * dat$x)
  dat$yi <- stats::rnorm(n, mean = mu, sd = sqrt(dat$vi + sigma^2))

  fit <- drmTMB(
    bf(
      yi ~ x + meta_known_V(V = vi),
      sigma ~ x
    ),
    family = gaussian(),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(unname(coef(fit, "mu")), beta_mu, tolerance = 0.12)
  expect_equal(unname(coef(fit, "sigma")), beta_sigma, tolerance = 0.18)
  expect_equal(fit$model$V_known, dat$vi)
  expect_true(all(stats::sigma(fit) > 0))
})

test_that("meta_known_V accepts diagonal matrices and rejects full covariance", {
  set.seed(20260509)
  n <- 80
  dat <- data.frame(x = stats::rnorm(n))
  dat$yi <- stats::rnorm(n)
  V_diag <- diag(rep(0.02, n))
  V_full <- V_diag
  V_full[1, 2] <- V_full[2, 1] <- 0.01

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V_diag)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$V_known, rep(0.02, n))
  expect_error(
    drmTMB(
      bf(yi ~ x + meta_known_V(V = V_full)),
      family = gaussian(),
      data = dat
    ),
    "diagonal"
  )
})

test_that("meta_known_V rejects malformed marker calls", {
  dat <- data.frame(
    yi = stats::rnorm(20),
    x = stats::rnorm(20),
    vi = rep(0.02, 20)
  )

  expect_error(
    drmTMB(
      bf(yi ~ x + meta_known_V(bad = vi)),
      family = gaussian(),
      data = dat
    ),
    "exactly one argument"
  )
  expect_error(
    drmTMB(
      bf(yi ~ x + meta_known_V(V = vi, extra = vi)),
      family = gaussian(),
      data = dat
    ),
    "exactly one argument"
  )
  expect_error(
    drmTMB(
      bf(yi ~ x, sigma ~ meta_known_V(V = vi)),
      family = gaussian(),
      data = dat
    ),
    "fixed effects only"
  )
})

test_that("near-zero heterogeneity starts remain numerically workable", {
  set.seed(20260511)
  n <- 180
  dat <- data.frame(
    x = stats::rnorm(n),
    vi = stats::runif(n, min = 0.03, max = 0.08)
  )
  dat$yi <- stats::rnorm(n, mean = 0.1 + 0.4 * dat$x, sd = sqrt(dat$vi + 0.03^2))

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = vi)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true(all(is.finite(coef(fit, "sigma"))))
  expect_true(all(stats::sigma(fit) > 0))
})

test_that("meta_known_V removes missing known variances consistently", {
  set.seed(20260510)
  dat <- data.frame(
    x = stats::rnorm(30),
    vi = rep(0.03, 30)
  )
  dat$yi <- stats::rnorm(30)
  dat$vi[3] <- NA_real_
  dat$x[7] <- NA_real_

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = vi)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$nobs, 28)
  expect_equal(length(fit$model$V_known), 28)
  expect_false(anyNA(fit$model$V_known))
})

mvn_loglik <- function(y, mu, Sigma) {
  U <- chol(Sigma)
  z <- forwardsolve(t(U), y - mu)
  -0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(U))) + sum(z^2))
}

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

test_that("meta_known_V accepts diagonal and full covariance matrices", {
  set.seed(20260509)
  n <- 80
  dat <- data.frame(x = stats::rnorm(n))
  dat$yi <- stats::rnorm(n)
  V_diag <- diag(rep(0.02, n))
  V_full <- V_diag
  V_full <- V_full +
    0.01 * outer(seq_len(n), seq_len(n), function(i, j) 0.7^abs(i - j))

  fit_diag <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V_diag)),
    family = gaussian(),
    data = dat
  )
  fit_full <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V_full)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit_diag$opt$convergence, 0)
  expect_equal(fit_diag$model$V_known, rep(0.02, n))
  expect_equal(fit_diag$model$V_known_type, "diagonal")
  expect_equal(fit_full$opt$convergence, 0)
  expect_equal(fit_full$model$V_known, V_full)
  expect_equal(fit_full$model$V_known_diag, diag(V_full))
  expect_equal(fit_full$model$V_known_type, "matrix")
})

test_that("meta_V is an additive known-V alias", {
  dat <- data.frame(x = c(-1, 0, 1, 2))
  dat$yi <- 0.4 + 0.3 * dat$x + c(-0.1, 0.2, -0.05, 0.1)
  dat$vi <- c(0.04, 0.05, 0.03, 0.06)
  V_full <- diag(dat$vi)
  V_full[1, 2] <- V_full[2, 1] <- 0.01

  fit_meta_v <- drmTMB(
    bf(yi ~ x + meta_V(V = vi)),
    family = gaussian(),
    data = dat
  )
  fit_known_v <- drmTMB(
    bf(yi ~ x + meta_known_V(V = vi)),
    family = gaussian(),
    data = dat
  )
  fit_meta_v_full <- drmTMB(
    bf(yi ~ x + meta_V(V = V_full)),
    family = gaussian(),
    data = dat
  )
  fit_known_v_full <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V_full)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit_meta_v$opt$convergence, 0)
  expect_equal(
    coef(fit_meta_v, "mu"),
    coef(fit_known_v, "mu"),
    tolerance = 1e-8
  )
  expect_equal(
    coef(fit_meta_v, "sigma"),
    coef(fit_known_v, "sigma"),
    tolerance = 1e-8
  )
  expect_equal(
    as.numeric(logLik(fit_meta_v)),
    as.numeric(logLik(fit_known_v)),
    tolerance = 1e-8
  )
  expect_equal(fit_meta_v_full$opt$convergence, 0)
  expect_equal(fit_meta_v_full$model$V_known_type, "matrix")
  expect_equal(fit_meta_v_full$model$V_known, V_full)
  expect_equal(
    coef(fit_meta_v_full, "mu"),
    coef(fit_known_v_full, "mu"),
    tolerance = 1e-8
  )
  expect_equal(
    as.numeric(logLik(fit_meta_v_full)),
    as.numeric(logLik(fit_known_v_full)),
    tolerance = 1e-8
  )
  ci_full <- stats::confint(
    fit_meta_v_full,
    parm = c("mu:(Intercept)", "mu:x")
  )
  expect_equal(ci_full$conf.status, rep("wald", 2L))
  expect_true(all(is.finite(ci_full$lower)))
  expect_true(all(is.finite(ci_full$upper)))
})

test_that("full meta_known_V likelihood matches a base R MVN calculation", {
  set.seed(20260514)
  n <- 45
  dat <- data.frame(x = stats::rnorm(n))
  V <- 0.015 * outer(seq_len(n), seq_len(n), function(i, j) 0.55^abs(i - j))
  beta_mu <- c(0.1, 0.35)
  sigma <- 0.22
  mu <- beta_mu[[1]] + beta_mu[[2]] * dat$x
  Sigma <- V + diag(sigma^2, n)
  dat$yi <- as.vector(mu + t(chol(Sigma)) %*% stats::rnorm(n))

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  mu_hat <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  Sigma_hat <- fit$model$V_known
  diag(Sigma_hat) <- diag(Sigma_hat) + stats::sigma(fit)^2
  expect_equal(
    as.numeric(stats::logLik(fit)),
    mvn_loglik(dat$yi, mu_hat, Sigma_hat),
    tolerance = 1e-6
  )
  sim <- simulate(fit, nsim = 2, seed = 1)
  expect_equal(dim(sim), c(n, 2))
  expect_true(all(is.finite(residuals(fit, type = "pearson"))))
})

test_that("full meta_known_V works with location random intercepts", {
  set.seed(20260516)
  n_group <- 6
  n_per_group <- 6
  n <- n_group * n_per_group
  dat <- data.frame(
    id = factor(rep(seq_len(n_group), each = n_per_group)),
    x = stats::rnorm(n)
  )
  V <- 0.01 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  b <- stats::rnorm(n_group, sd = 0.25)
  mu <- 0.2 + 0.4 * dat$x + b[dat$id]
  dat$yi <- as.vector(mu + t(chol(V + diag(0.2^2, n))) %*% stats::rnorm(n))

  fit <- drmTMB(
    bf(yi ~ x + (1 | id) + meta_known_V(V = V)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$V_known_type, "matrix")
  expect_equal(dim(fit$model$V_known), c(n, n))
  expect_true(all(is.finite(fit$sdpars$mu)))
})

test_that("meta_known_V works with random-effect scale formulas", {
  set.seed(20260601)
  n_id <- 10
  n_each <- 5
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(
    id = id,
    x = stats::rnorm(n),
    vi = stats::runif(n, min = 0.01, max = 0.05)
  )
  w_id <- seq(-0.8, 0.8, length.out = n_id)
  dat$w <- w_id[dat$id]
  beta_mu <- c(`(Intercept)` = 0.1, x = 0.4)
  sigma <- 0.22
  alpha <- c(`(Intercept)` = log(0.35), w = 0.35)
  tau_id <- exp(alpha[[1L]] + alpha[[2L]] * w_id)
  u_id <- stats::rnorm(n_id)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x + tau_id[dat$id] * u_id[dat$id]
  dat$yi <- stats::rnorm(n, mean = mu, sd = sqrt(dat$vi + sigma^2))

  fit <- drmTMB(
    bf(
      yi ~ x + (1 | id) + meta_known_V(V = vi),
      sigma ~ 1,
      sd(id) ~ w
    ),
    family = gaussian(),
    data = dat
  )

  tau_hat <- as.numeric(predict(fit, dpar = "sd(id)"))
  Z <- stats::model.matrix(~ 0 + id, data = fit$data)
  Sigma <- diag(fit$model$V_known + stats::sigma(fit)^2, fit$nobs) +
    Z %*% diag(tau_hat^2, ncol(Z)) %*% t(Z)
  mu_hat <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(length(tau_hat), nlevels(fit$data$id))
  expect_equal(
    as.numeric(stats::logLik(fit)),
    mvn_loglik(fit$model$y, mu_hat, Sigma),
    tolerance = 1e-6
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
      bf(yi ~ x + meta_V(vi)),
      family = gaussian(),
      data = dat
    ),
    "exactly one argument"
  )
  expect_error(
    drmTMB(
      bf(yi ~ x + meta_V(w = vi, scale = "proportional")),
      family = gaussian(),
      data = dat
    ),
    "reserved"
  )
  expect_error(
    drmTMB(
      bf(yi ~ x + meta_V(w = vi)),
      family = gaussian(),
      data = dat
    ),
    "reserved"
  )
  expect_error(
    drmTMB(
      bf(yi ~ x + meta_V(V = vi, scale = "exact")),
      family = gaussian(),
      data = dat
    ),
    "without.*scale"
  )
  expect_error(
    drmTMB(
      bf(yi ~ x, sigma ~ meta_known_V(V = vi)),
      family = gaussian(),
      data = dat
    ),
    "unsupported model terms"
  )
})

test_that("near-zero heterogeneity starts remain numerically workable", {
  set.seed(20260511)
  n <- 180
  dat <- data.frame(
    x = stats::rnorm(n),
    vi = stats::runif(n, min = 0.03, max = 0.08)
  )
  dat$yi <- stats::rnorm(
    n,
    mean = 0.1 + 0.4 * dat$x,
    sd = sqrt(dat$vi + 0.03^2)
  )

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

test_that("meta_V keeps likelihood weights distinct from proportional variance", {
  dat <- data.frame(
    x = c(-1, -0.5, 0, 0.5, 1, 1.5),
    vi = rep(0.03, 6)
  )
  dat$yi <- 0.2 + 0.4 * dat$x + c(-0.1, 0.05, 0.03, -0.02, 0.04, -0.03)

  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = vi)),
    family = gaussian(),
    data = dat
  )
  fit_double <- drmTMB(
    bf(yi ~ x + meta_V(V = vi)),
    family = gaussian(),
    data = dat,
    weights = rep(2, nrow(dat))
  )

  expect_equal(stats::weights(fit_double), rep(2, nrow(dat)))
  expect_equal(coef(fit_double, "mu"), coef(fit, "mu"), tolerance = 1e-5)
  expect_equal(
    as.numeric(stats::logLik(fit_double)),
    2 * as.numeric(stats::logLik(fit)),
    tolerance = 1e-4
  )

  V_full <- diag(dat$vi)
  V_full[1, 2] <- V_full[2, 1] <- 0.005
  expect_error(
    drmTMB(
      bf(yi ~ x + meta_V(V = V_full)),
      family = gaussian(),
      data = dat,
      weights = rep(2, nrow(dat))
    ),
    "full known sampling covariance"
  )
})

test_that("full meta_known_V removes rows and columns consistently", {
  set.seed(20260515)
  n <- 28
  dat <- data.frame(
    x = stats::rnorm(n),
    yi = stats::rnorm(n)
  )
  V <- 0.02 * outer(seq_len(n), seq_len(n), function(i, j) 0.4^abs(i - j))
  dat$x[4] <- NA_real_
  V[4, ] <- NA_real_
  V[, 4] <- NA_real_
  V[4, 4] <- 0.02

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V)),
    family = gaussian(),
    data = dat
  )

  keep <- !is.na(dat$x)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$V_known, V[keep, keep])
  expect_equal(fit$model$V_known_diag, diag(V)[keep])
})

test_that("full meta_known_V rejects invalid covariance matrices", {
  dat <- data.frame(yi = stats::rnorm(4), x = stats::rnorm(4))
  V <- diag(0.01, 4)
  V[1, 2] <- 0.005

  expect_error(
    drmTMB(bf(yi ~ x + meta_known_V(V = V)), family = gaussian(), data = dat),
    "symmetric"
  )

  V_bad <- diag(0.01, 4)
  V_bad[1, 1] <- -0.01
  expect_error(
    drmTMB(
      bf(yi ~ x + meta_known_V(V = V_bad)),
      family = gaussian(),
      data = dat
    ),
    "non-negative"
  )

  V_missing <- diag(0.01, 4)
  V_missing[1, 2] <- V_missing[2, 1] <- NA_real_
  expect_error(
    drmTMB(
      bf(yi ~ x + meta_known_V(V = V_missing)),
      family = gaussian(),
      data = dat
    ),
    "finite"
  )
})

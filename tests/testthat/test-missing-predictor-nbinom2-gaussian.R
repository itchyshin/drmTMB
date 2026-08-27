# S6 A7 / #962 expand-gated cell: nbinom2() response x one gaussian()
# impute_model() x k=1 (model_type 7, mi_family 0). Latent x_miss is
# Laplace-integrated. Not FIML, not impute_joint, not k=2, not group/struct
# on the predictor model.

missing_predictor_nbinom2_gaussian_data <- function() {
  n <- 90
  z <- seq(-1.6, 1.7, length.out = n)
  x <- 0.2 + 0.7 * z + 0.15 * cos(seq_len(n) / 3)
  mu <- exp(0.3 + 0.4 * z + 0.55 * x)
  y <- pmax(0, round(mu + sqrt(mu) * cos(seq_len(n) / 4)))
  dat <- data.frame(y = y, z = z, x = x)
  dat$x[c(8, 19, 31, 46, 57, 70, 83)] <- NA_real_
  dat
}

fit_missing_predictor_nbinom2_gaussian <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    family = nbinom2(),
    impute = list(x = impute_model(x ~ z, family = gaussian())),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_nbinom2_response_gaussian_mi_joint_loglik <- function(fit) {
  model <- fit$model$missing_predictor
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, paste0("mi_", model$variable))
  log_sigma <- as.numeric(coef(fit, "sigma"))
  sigma_mi <- as.numeric(coef(fit, paste0("sigma_mi_", model$variable)))
  size <- exp(-2 * log_sigma)
  par <- fit$obj$env$parList(fit$opt$par)
  x_full <- as.numeric(model$x)
  x_full[!model$observed] <- as.numeric(par$x_miss)
  offset_mu <- if (!is.null(fit$model$offset$mu)) {
    fit$model$offset$mu
  } else {
    rep(0, length(fit$model$y))
  }
  eta_base <- as.vector(offset_mu + fit$model$X$mu %*% beta_mu)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  eta <- eta_base + beta_x * (x_full - x_base)
  yv <- fit$model$y
  ll_y <- stats::dnbinom(yv, size = size, mu = exp(eta), log = TRUE)
  ll_x <- stats::dnorm(
    x_full,
    mean = as.vector(model$X %*% beta_mi),
    sd = sigma_mi,
    log = TRUE
  )
  sum(ll_y + ll_x)
}

tmb_joint_loglik <- function(fit) {
  last <- fit$obj$env$last.par.best
  if (is.null(last) || !length(last)) {
    last <- fit$obj$env$last.par
  }
  -as.numeric(fit$obj$env$f(last, order = 0))
}

test_that("gaussian mi() predictor works with an nbinom2 response joint likelihood", {
  dat <- missing_predictor_nbinom2_gaussian_data()
  fit <- fit_missing_predictor_nbinom2_gaussian(dat)

  expect_equal(fit$missing_data$version, "MD-nbinom2-gaussian-mi")
  expect_equal(fit$missing_data$predictors$x$family, "gaussian")
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_x"))))
  expect_true(all(is.finite(coef(fit, "sigma_mi_x"))))
  expect_equal(
    tmb_joint_loglik(fit),
    manual_nbinom2_response_gaussian_mi_joint_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(nrow(imputed(fit)), sum(is.na(dat$x)))
})

test_that("nbinom2-response gaussian mi() recovers under MCAR", {
  set.seed(27)
  n <- 3000
  z <- rnorm(n)
  x <- 0.3 + 0.8 * z + rnorm(n, sd = 0.40)
  y <- stats::rnbinom(n, size = 3, mu = exp(0.4 + 0.5 * z + 0.7 * x))
  d <- data.frame(y = y, z = z, x = x)
  d$x[sample(n, round(0.2 * n))] <- NA_real_

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = nbinom2(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = gaussian())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.15)
  expect_equal(unname(coef(fit, "sigma")), -0.5 * log(3), tolerance = 0.15)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.15)
  expect_equal(unname(coef(fit, "sigma_mi_x")), 0.40, tolerance = 0.15)
})

test_that("nbinom2-response gaussian mi() recovers under outcome-dependent MAR", {
  set.seed(28)
  n <- 3000
  z <- rnorm(n)
  x <- 0.3 + 0.8 * z + rnorm(n, sd = 0.40)
  y <- stats::rnbinom(n, size = 3, mu = exp(0.4 + 0.5 * z + 0.7 * x))
  d <- data.frame(y = y, z = z, x = x)
  p_miss <- stats::plogis(-0.8 + 0.6 * scale(log(y + 1))[, 1])
  d$x[stats::runif(n) < p_miss] <- NA_real_
  expect_true(mean(is.na(d$x)) > 0.1)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = nbinom2(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = gaussian())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.20)
  expect_equal(unname(coef(fit, "sigma")), -0.5 * log(3), tolerance = 0.20)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.20)
})

test_that("nbinom2-response mi() still refuses unsupported predictor combos", {
  dat <- missing_predictor_nbinom2_gaussian_data()
  dat$count <- pmax(0L, as.integer(round(exp(dat$z))))
  dat$count[c(4, 21)] <- NA_integer_
  dat$site <- factor(rep(seq_len(10), each = 9))
  dat$x2 <- dat$z + 0.1
  dat$x2[c(5, 22)] <- NA_real_

  expect_error(
    drmTMB(
      bf(y ~ z + mi(count), sigma ~ 1),
      data = dat,
      family = nbinom2(),
      impute = list(count = impute_model(count ~ z, family = poisson())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary or one Gaussian missing predictor"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(x) + mi(x2), sigma ~ 1),
      data = dat,
      family = nbinom2(),
      impute = list(
        x = impute_model(x ~ z, family = gaussian()),
        x2 = impute_model(x2 ~ z, family = gaussian())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "Gaussian response"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      family = nbinom2(),
      impute = list(x = impute_model(x ~ z + (1 | site), family = gaussian())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed-effect predictor model only"
  )
})

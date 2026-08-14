missing_predictor_poisson_response_data <- function() {
  n <- 64
  z <- seq(-1.5, 1.8, length.out = n)
  treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  lambda <- exp(0.25 + 0.45 * z + 0.75 * treatment_full)
  y <- pmax(0, round(lambda + sqrt(lambda) * cos(seq_len(n) / 4)))
  dat <- data.frame(
    y = y,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(8, 19, 31, 46, 57)] <- NA
  dat
}

fit_missing_predictor_poisson_response <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(treatment)),
    data = dat,
    family = poisson(),
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_poisson_response_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$treatment$observed
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_treatment")
  eta_x <- as.vector(model$X %*% beta_mi)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  eta_base <- as.vector(fit$model$offset$mu + fit$model$X$mu %*% beta_mu)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  x <- as.numeric(dat$treatment) - 1
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    out[[row]] <- if (x[[row]] == 1) log_p1[[row]] else log_p0[[row]]
    out[[row]] <- out[[row]] +
      stats::dpois(dat$y[[row]], lambda = exp(eta_base[[row]]), log = TRUE)
  }

  missing_rows <- which(!observed_x)
  for (row in missing_rows) {
    eta1 <- eta_base[[row]] + beta_x * (1 - x_base[[row]])
    eta0 <- eta_base[[row]] + beta_x * (0 - x_base[[row]])
    lp1 <- log_p1[[row]] +
      stats::dpois(dat$y[[row]], lambda = exp(eta1), log = TRUE)
    lp0 <- log_p0[[row]] +
      stats::dpois(dat$y[[row]], lambda = exp(eta0), log = TRUE)
    max_log <- max(lp1, lp0)
    out[[row]] <- max_log + log(exp(lp1 - max_log) + exp(lp0 - max_log))
  }

  sum(out)
}

test_that("binary mi() predictor works with a Poisson response likelihood", {
  dat <- missing_predictor_poisson_response_data()
  missing_x <- is.na(dat$treatment)

  fit <- fit_missing_predictor_poisson_response(dat)
  imp <- imputed(fit)

  expect_equal(fit$missing_data$version, "MD9a")
  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(
    fit$missing_data$predictors$treatment$model_row,
    which(missing_x)
  )
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_poisson_response_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_probability", sum(missing_x)))
  expect_true(all(is.finite(imp$estimate)))
  expect_true(all(imp$estimate >= 0 & imp$estimate <= 1))
})

test_that("Poisson-response mi() validates the first non-Gaussian response boundary", {
  dat <- missing_predictor_poisson_response_data()
  dat$count <- c(0, 1)[(seq_len(nrow(dat)) %% 2) + 1]
  dat$count[c(4, 21)] <- NA

  expect_error(
    drmTMB(
      bf(y ~ z + mi(count)),
      data = dat,
      family = poisson(),
      impute = list(count = impute_model(count ~ z, family = poisson())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary missing predictor"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(treatment), zi ~ 1),
      data = dat,
      family = poisson(),
      impute = list(
        treatment = impute_model(treatment ~ z, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "zero inflation"
  )

  dat$z[3] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ z + mi(treatment)),
      data = dat,
      family = poisson(),
      impute = list(
        treatment = impute_model(treatment ~ 1, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "outside explicit"
  )
})

joint_missing_predictor_poisson_data <- function() {
  set.seed(20260813)
  n <- 120L
  z <- rnorm(n)
  e1 <- rnorm(n)
  e2 <- 0.45 * e1 + sqrt(1 - 0.45^2) * rnorm(n)
  x1 <- 0.25 + 0.65 * z + e1
  x2 <- -0.10 - 0.35 * z + 1.10 * e2
  y <- stats::rpois(n, exp(0.15 + 0.25 * z + 0.35 * x1 - 0.20 * x2))
  dat <- data.frame(y = y, z = z, x1 = x1, x2 = x2)
  dat$x1[c(5, 27, 61, 103)] <- NA_real_
  dat$x2[c(12, 39, 77, 114)] <- NA_real_
  dat
}

joint_poisson_observed_nll_1d <- function(fit, dat) {
  model <- fit$model$missing_predictor
  par <- fit$obj$env$parList(fit$opt$par)
  beta_x <- matrix(par$beta_mi, nrow = ncol(model$X))
  sigma_x <- exp(par$log_sigma_mi)
  rho_x <- 0.999999 * tanh(par$eta_cor_mi[[1L]])
  Sigma_x <- diag(sigma_x) %*%
    matrix(c(1, rho_x, rho_x, 1), nrow = 2L) %*%
    diag(sigma_x)
  beta_y <- par$beta_mu
  out <- 0
  for (i in seq_len(nrow(dat))) {
    mean_x <- as.vector(model$X[i, , drop = FALSE] %*% beta_x)
    observed <- model$observed[i, ]
    x <- model$x[i, ]
    log_y <- function(x1, x2) {
      stats::dpois(dat$y[[i]],
        lambda = exp(beta_y[[1L]] + beta_y[[2L]] * dat$z[[i]] +
          beta_y[[3L]] * x1 + beta_y[[4L]] * x2),
        log = TRUE
      )
    }
    if (all(observed)) {
      out <- out + log_y(x[[1L]], x[[2L]]) +
        mvtnorm::dmvnorm(x, mean = mean_x, sigma = Sigma_x, log = TRUE)
    } else if (observed[[2L]] && !observed[[1L]]) {
      conditional_mean <- mean_x[[1L]] + Sigma_x[1L, 2L] / Sigma_x[2L, 2L] *
        (x[[2L]] - mean_x[[2L]])
      conditional_sd <- sqrt(Sigma_x[1L, 1L] - Sigma_x[1L, 2L]^2 / Sigma_x[2L, 2L])
      integral <- stats::integrate(function(x1) {
        exp(log_y(x1, x[[2L]])) * stats::dnorm(x1, conditional_mean, conditional_sd)
      }, lower = -Inf, upper = Inf, subdivisions = 300L)$value
      out <- out + log(integral) + stats::dnorm(x[[2L]], mean_x[[2L]], sqrt(Sigma_x[2L, 2L]), log = TRUE)
    } else if (observed[[1L]] && !observed[[2L]]) {
      conditional_mean <- mean_x[[2L]] + Sigma_x[2L, 1L] / Sigma_x[1L, 1L] *
        (x[[1L]] - mean_x[[1L]])
      conditional_sd <- sqrt(Sigma_x[2L, 2L] - Sigma_x[2L, 1L]^2 / Sigma_x[1L, 1L])
      integral <- stats::integrate(function(x2) {
        exp(log_y(x[[1L]], x2)) * stats::dnorm(x2, conditional_mean, conditional_sd)
      }, lower = -Inf, upper = Inf, subdivisions = 300L)$value
      out <- out + log(integral) + stats::dnorm(x[[1L]], mean_x[[1L]], sqrt(Sigma_x[1L, 1L]), log = TRUE)
    } else {
      stop("This independent one-dimensional oracle requires no doubly-missing row.")
    }
  }
  -out
}

test_that("joint continuous mi() predictor works with a Poisson response", {
  dat <- joint_missing_predictor_poisson_data()
  fit <- drmTMB(
    bf(y ~ z + mi(x1) + mi(x2)),
    family = poisson(),
    data = dat,
    impute = impute_joint(cbind(x1, x2) ~ z),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD9b")
  expect_named(fit$missing_data$predictors, c("x1", "x2"))
  expect_equal(fit$missing_data$predictors$x1$model_row, which(is.na(dat$x1)))
  expect_equal(fit$missing_data$predictors$x2$model_row, which(is.na(dat$x2)))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_x1"))))
  expect_true(all(is.finite(coef(fit, "mi_x2"))))
  expect_true(is.finite(coef(fit)$rho_mi_x1_x2[[1L]]))
  expect_true(all(is.finite(imputed(fit, "x1", se = FALSE)$estimate)))
  expect_true(all(is.finite(imputed(fit, "x2", se = FALSE)$estimate)))
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
  # This is an independent one-dimensional quadrature oracle for the rows
  # with one missing predictor. Laplace is approximate for the Poisson route.
  expect_lt(abs(joint_poisson_observed_nll_1d(fit, dat) - fit$opt$objective), 0.05)
})

test_that("joint continuous Poisson mi() rejects response masks", {
  dat <- joint_missing_predictor_poisson_data()
  dat$y[[3L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x1) + mi(x2)),
      family = poisson(),
      data = dat,
      impute = impute_joint(cbind(x1, x2) ~ z),
      missing = miss_control(response = "include", predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "does not combine"
  )
})

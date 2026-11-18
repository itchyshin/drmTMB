test_that("fixed-effect priors select columns by dpar and assignment", {
  x <- model.matrix(~ x, data.frame(x = 1:4))
  spec <- list(model_type = "gaussian", X = list(mu = x, sigma = x), tmb_data = list())
  p <- drm_priors(
    drm_prior_normal("mu", "all", sd = 2, intercept = "exclude"),
    drm_prior_ridge("sigma", "(Intercept)", lambda = 4)
  )
  resolved <- drmTMB:::drm_apply_fixed_priors_spec(spec, p)$resolved_priors
  expect_equal(resolved$dpar, c("mu", "sigma"))
  expect_equal(resolved$coefficient, c("x", "(Intercept)"))
  expect_equal(resolved$precision, c(0.25, 4))
})

test_that("selectors and numerical inputs fail closed", {
  x <- model.matrix(~ x, data.frame(x = 1:4))
  spec <- list(model_type = "gaussian", X = list(mu = x, sigma = x), tmb_data = list())
  expect_error(drm_prior_normal("mu", "all", sd = 1), "intercept")
  expect_error(drm_prior_normal("mu", "x", sd = 0), "sd")
  expect_error(drm_prior_ridge("mu", "x", lambda = -1), "lambda")
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec, drm_priors(
    drm_prior_normal("mu", "x", sd = 1), drm_prior_ridge("mu", "x", lambda = 1)
  )), "overlap")
})

test_that("resolved priors handle factors, zero ridge and mutated specifications", {
  x <- model.matrix(~ f * z, data.frame(f = factor(rep(c("a", "b"), 3)), z = 1:6))
  spec <- list(model_type = "gaussian", X = list(mu = x, sigma = x), tmb_data = list())
  p <- drm_priors(drm_prior_ridge("mu", "all", lambda = 0, intercept = "exclude"))
  ans <- drmTMB:::drm_apply_fixed_priors_spec(spec, p)
  expect_equal(ans$resolved_priors$coefficient, colnames(x)[-1L])
  expect_length(ans$tmb_data$prior_beta_index, 0L)
  p[[1]]$kind <- "unknown"
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec, p), "kind")
  no_intercept <- model.matrix(~ 0 + f, data.frame(f = factor(c("a", "b"))))
  spec$X$mu <- no_intercept
  p <- drm_priors(drm_prior_ridge("mu", "all", lambda = 1, intercept = "exclude"))
  expect_equal(drmTMB:::drm_apply_fixed_priors_spec(spec, p)$resolved_priors$coefficient, colnames(no_intercept))
})

# Central differences at a common, non-optimal point exercise every parameter.
fixed_prior_central_derivatives <- function(fn, theta, step = 1e-4) {
  n <- length(theta)
  h <- step * pmax(1, abs(theta))
  unit <- diag(n)
  center <- fn(theta)
  gradient <- numeric(n)
  hessian <- matrix(0, n, n)
  for (i in seq_len(n)) {
    delta_i <- unit[, i] * h[i]
    plus <- fn(theta + delta_i)
    minus <- fn(theta - delta_i)
    gradient[i] <- (plus - minus) / (2 * h[i])
    hessian[i, i] <- (plus - 2 * center + minus) / h[i]^2
    if (i < n) for (j in seq.int(i + 1L, n)) {
      delta_j <- unit[, j] * h[j]
      value <- (fn(theta + delta_i + delta_j) - fn(theta + delta_i - delta_j) -
                  fn(theta - delta_i + delta_j) + fn(theta - delta_i - delta_j)) /
        (4 * h[i] * h[j])
      hessian[i, j] <- hessian[j, i] <- value
    }
  }
  list(gradient = gradient, hessian = hessian)
}

test_that("compiled Gaussian and binomial objectives contain exactly the selected terms", {
  dat <- data.frame(x = c(-2, -1, 0, 1, 2, 3), y = c(-1, 0, 0.2, 0.8, 1.1, 2),
                    b = c(0, 1, 0, 1, 0, 1))
  cases <- list(
    list(formula = bf(mu = y ~ x, sigma = ~ x), family = gaussian(),
         prior = drm_priors(drm_prior_normal("mu", "x", mean = 0.3, sd = 2),
                            drm_prior_ridge("sigma", "x", lambda = 4)),
         blocks = c("beta_mu", "beta_sigma"), means = c(0.3, 0), precisions = c(0.25, 4),
         constant = log(2) + 0.5 * log(2 * pi)),
    list(formula = bf(mu = b ~ x), family = binomial(),
         prior = drm_priors(drm_prior_normal("mu", "x", mean = 0.3, sd = 2)),
         blocks = "beta_mu", means = 0.3, precisions = 0.25,
         constant = log(2) + 0.5 * log(2 * pi))
  )
  for (case in cases) {
    plain <- drmTMB(case$formula, data = dat, family = case$family)
    map <- drmTMB(case$formula, data = dat, family = case$family, priors = case$prior)
    theta <- plain$obj$par * 0 + 0.2
    idx <- vapply(case$blocks, function(block) which(names(theta) == block)[2L], integer(1))
    diff <- theta[idx] - case$means
    expected_g <- numeric(length(theta)); expected_g[idx] <- diff * case$precisions
    expected_h <- matrix(0, length(theta), length(theta)); diag(expected_h)[idx] <- case$precisions
    expect_equal(as.numeric(map$obj$fn(theta) - plain$obj$fn(theta)),
                 sum(0.5 * diff^2 * case$precisions) + case$constant, tolerance = 1e-10)
    expect_equal(as.numeric(map$obj$gr(theta) - plain$obj$gr(theta)), expected_g, tolerance = 1e-10)
    expect_equal(unname(map$obj$he(theta) - plain$obj$he(theta)), expected_h, tolerance = 1e-10)
    mu <- drop(model.matrix(~ x, dat) %*% theta[names(theta) == "beta_mu"])
    if (identical(case$family$family, "gaussian")) {
      log_sigma <- drop(model.matrix(~ x, dat) %*% theta[names(theta) == "beta_sigma"])
      data_nll <- -sum(dnorm(dat$y, mu, exp(log_sigma), log = TRUE))
    } else {
      data_nll <- -sum(dbinom(dat$b, size = 1, prob = plogis(mu), log = TRUE))
    }
    expect_equal(as.numeric(map$obj$fn(theta)),
                 data_nll + sum(0.5 * diff^2 * case$precisions) + case$constant,
                 tolerance = 1e-10)
    fd <- fixed_prior_central_derivatives(map$obj$fn, theta)
    expect_lt(max(abs(map$obj$gr(theta) - fd$gradient) / (1 + abs(fd$gradient))), 1e-6)
    expect_lt(max(abs(map$obj$he(theta) - fd$hessian) / (1 + abs(fd$hessian))), 1e-5)
  }
})

test_that("missing and aliased columns cannot receive a prior", {
  x <- model.matrix(~ a + b, data.frame(a = 1:4, b = 1:4))
  spec <- list(X = list(mu = x), tmb_data = list())
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec,
    drm_priors(drm_prior_normal("mu", "a", sd = 1))), "rank deficient")
  spec$X$mu <- x[, 1:2, drop = FALSE]
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec,
    drm_priors(drm_prior_normal("mu", "b", sd = 1))), "Unknown coefficient")
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec,
    drm_priors(drm_prior_normal("sigma", "a", sd = 1))), "unavailable")
})

test_that("Gaussian ridge coefficients match the exact conditional solution", {
  dat <- data.frame(x = c(-2, -1, 0, 1, 2, 3, 4),
                    y = c(-1.2, -0.3, 0.3, 0.8, 0.7, 2.1, 1.9))
  lambda <- 1.7
  fit <- drmTMB(bf(mu = y ~ x, sigma = ~ 1), data = dat,
                priors = drm_priors(drm_prior_ridge("mu", "all", lambda = lambda,
                                                   intercept = "exclude")))
  X <- model.matrix(~ x, dat)
  sigma <- exp(unname(fixef(fit)$sigma[[1L]]))
  precision <- diag(c(0, lambda))
  beta <- drop(solve(crossprod(X) / sigma^2 + precision,
                     crossprod(X, dat$y) / sigma^2))
  expect_equal(unname(fixef(fit)$mu), unname(beta), tolerance = 1e-7)
  theta <- fit$obj$par
  mu_index <- which(names(theta) == "beta_mu")
  theta[mu_index] <- c(0.35, -0.15)
  sigma <- exp(theta[which(names(theta) == "beta_sigma")])
  expected_fn <- -sum(dnorm(dat$y, drop(X %*% theta[mu_index]), sigma, log = TRUE)) +
    0.5 * lambda * theta[mu_index[2L]]^2
  expected_grad <- drop(crossprod(X, drop(X %*% theta[mu_index]) - dat$y) / sigma^2 +
                          precision %*% theta[mu_index])
  expected_hessian <- crossprod(X) / sigma^2 + precision
  expect_equal(as.numeric(fit$obj$fn(theta)), unname(expected_fn), tolerance = 1e-10)
  expect_equal(as.numeric(fit$obj$gr(theta)[mu_index]), unname(expected_grad), tolerance = 1e-10)
  expect_equal(unname(fit$obj$he(theta)[mu_index, mu_index]), unname(expected_hessian), tolerance = 1e-10)
})

test_that("proper coefficient priors yield a finite MAP fit under separation", {
  dat <- data.frame(x = c(-3, -2, -1, 1, 2, 3), b = c(0, 0, 0, 1, 1, 1))
  fit <- drmTMB(bf(mu = b ~ x), family = binomial(), data = dat,
                priors = drm_priors(drm_prior_normal("mu", "all", sd = 2,
                                                    intercept = "include")))
  expect_true(all(is.finite(fixef(fit)$mu)))
  expect_true(is.finite(fit$obj$fn(fit$opt$par)))
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-4)
  expect_gt(unname(fixef(fit)$mu[["x"]]), 0)
})

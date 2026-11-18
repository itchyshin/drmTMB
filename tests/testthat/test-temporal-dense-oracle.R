temporal_oracle_data <- function(with_intercept, seed = 20260908L) {
  set.seed(seed)
  occasion <- c(0L, 1L, 3L, 4L, 7L, 9L)
  ids <- paste0("site_", seq_len(48L))
  dat <- do.call(rbind, lapply(ids, function(id) {
    data.frame(id = id, occasion = occasion, x = stats::rnorm(length(occasion)))
  }))
  beta <- c(`(Intercept)` = 0.2, x = 0.5)
  sd_between <- if (with_intercept) 0.55 else 0
  sd_temporal <- 0.65
  sigma <- 0.7
  phi <- if (with_intercept) -0.35 else 0.45
  dat$y <- NA_real_
  for (id in ids) {
    index <- which(dat$id == id)
    time <- dat$occasion[index]
    R <- phi^abs(outer(time, time, "-"))
    temporal <- as.vector(t(chol(R)) %*% stats::rnorm(length(index))) * sd_temporal
    intercept <- if (with_intercept) stats::rnorm(1L, sd = sd_between) else 0
    dat$y[index] <- beta[[1L]] + beta[[2L]] * dat$x[index] + intercept + temporal +
      stats::rnorm(length(index), sd = sigma)
  }
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

temporal_dense_loglik <- function(fit) {
  temporal <- fit$model$structured$temporal_mu
  beta <- unname(fit$coefficients$mu)
  X <- as.matrix(fit$model$X$mu)
  sigma <- exp(unname(fit$coefficients$sigma[[1L]]))
  sd_temporal <- unname(fit$sdpars$mu[[temporal_mu_sd_label(temporal)]])
  phi <- unname(fit$corpars$temporal[[temporal$label]])
  sd_between <- if ("(1 | id)" %in% names(fit$sdpars$mu)) {
    unname(fit$sdpars$mu[["(1 | id)"]])
  } else {
    0
  }
  data <- fit$data
  out <- 0
  for (id in temporal$series_levels) {
    rows <- which(as.character(data[[temporal$group]]) == id)
    rows <- rows[order(data[[temporal$time]][rows])]
    time <- data[[temporal$time]][rows]
    V <- sd_between^2 + sd_temporal^2 * phi^abs(outer(time, time, "-"))
    diag(V) <- diag(V) + sigma^2
    residual <- fit$model$y[rows] - as.vector(X[rows, , drop = FALSE] %*% beta)
    root <- chol(V)
    out <- out - 0.5 * (
      length(rows) * log(2 * pi) +
        2 * sum(log(diag(root))) +
        sum(forwardsolve(t(root), residual)^2)
    )
  }
  out
}

temporal_dense_nll_at <- function(fit, par) {
  temporal <- fit$model$structured$temporal_mu
  parameter_names <- names(par)
  beta <- unname(par[parameter_names == "beta_mu"])
  sigma <- exp(unname(par[match("beta_sigma", parameter_names)]))
  sd_temporal <- exp(unname(par[match("log_sd_temporal", parameter_names)]))
  phi <- tanh(unname(par[match("theta_temporal", parameter_names)]))
  sd_between <- if ("log_sd_mu" %in% parameter_names) {
    exp(unname(par[match("log_sd_mu", parameter_names)]))
  } else {
    0
  }
  X <- as.matrix(fit$model$X$mu)
  out <- 0
  for (id in temporal$series_levels) {
    rows <- which(as.character(fit$data[[temporal$group]]) == id)
    rows <- rows[order(fit$data[[temporal$time]][rows])]
    time <- fit$data[[temporal$time]][rows]
    V <- sd_between^2 + sd_temporal^2 * phi^abs(outer(time, time, "-"))
    diag(V) <- diag(V) + sigma^2
    root <- chol(V)
    residual <- fit$model$y[rows] - as.vector(X[rows, , drop = FALSE] %*% beta)
    out <- out + 0.5 * (
      length(rows) * log(2 * pi) +
        2 * sum(log(diag(root))) +
        sum(forwardsolve(t(root), residual)^2)
    )
  }
  out
}

test_that("Gaussian temporal likelihood matches a dense marginal covariance oracle", {
  for (with_intercept in c(FALSE, TRUE)) {
    dat <- temporal_oracle_data(with_intercept)
    fit <- if (with_intercept) {
      suppressWarnings(drmTMB(
        bf(y ~ x + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
        data = dat, family = gaussian(), REML = FALSE
      ))
    } else {
      suppressWarnings(drmTMB(
        bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
        data = dat, family = gaussian(), REML = FALSE
      ))
    }
    expect_equal(
      as.numeric(stats::logLik(fit)),
      temporal_dense_loglik(fit),
      tolerance = 1e-7
    )
  }
})

test_that("temporal score, observed Hessian, and coefficient covariance match dense references", {
  for (with_intercept in c(FALSE, TRUE)) {
    dat <- temporal_oracle_data(with_intercept, seed = if (with_intercept) 1L else 2L)
    fit <- if (with_intercept) {
      suppressWarnings(drmTMB(
        bf(y ~ x + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
        data = dat, family = gaussian(), REML = FALSE
      ))
    } else {
      suppressWarnings(drmTMB(
        bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
        data = dat, family = gaussian(), REML = FALSE
      ))
    }
    expect_true(isTRUE(fit$sdr$pdHess))
    objective <- function(par) temporal_dense_nll_at(fit, par)
    opt_par <- fit$opt$par
    score <- numDeriv::grad(objective, opt_par, method.args = list(eps = 1e-6))
    hessian_1 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-4))
    hessian_2 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-5))
    observed_hessian <- solve(fit$sdr$cov.fixed)
    expect_equal(as.numeric(fit$obj$fn(opt_par)), objective(opt_par), tolerance = 1e-7)
    expect_equal(fit$obj$gr(opt_par), score, tolerance = 1e-5)
    expect_equal(hessian_1, hessian_2, tolerance = 1e-4)
    expect_equal(unname(observed_hessian), unname(hessian_1), tolerance = 1e-4)
    beta_index <- which(names(opt_par) == "beta_mu")
    expect_equal(
      unname(stats::vcov(fit)),
      unname(solve(observed_hessian)[beta_index, beta_index, drop = FALSE]),
      tolerance = 1e-7
    )
    near_boundary <- opt_par
    near_boundary[match("theta_temporal", names(near_boundary))] <- 15
    expect_true(is.finite(as.numeric(fit$obj$fn(near_boundary))))
  }
})

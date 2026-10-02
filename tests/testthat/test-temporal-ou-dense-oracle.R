ou_oracle_data <- function(with_intercept, seed = 20260908L) {
  set.seed(seed)
  elapsed <- c(0, 0.5, 1.5, 3, 5, 8)
  ids <- paste0("site_", seq_len(40L))
  dat <- do.call(rbind, lapply(ids, function(id) {
    data.frame(id = id, elapsed = elapsed, x = stats::rnorm(length(elapsed)))
  }))
  beta <- c(`(Intercept)` = 0.2, x = 0.5)
  sd_between <- if (with_intercept) 0.55 else 0
  sd_temporal <- 0.65
  sigma <- 0.7
  decay <- if (with_intercept) 0.9 else 0.55
  dat$y <- NA_real_
  for (id in ids) {
    rows <- which(dat$id == id)
    time <- dat$elapsed[rows]
    covariance <- exp(-decay * abs(outer(time, time, "-")))
    temporal <- as.vector(t(chol(covariance)) %*% stats::rnorm(length(rows))) * sd_temporal
    intercept <- if (with_intercept) stats::rnorm(1L, sd = sd_between) else 0
    dat$y[rows] <- beta[[1L]] + beta[[2L]] * dat$x[rows] + intercept + temporal +
      stats::rnorm(length(rows), sd = sigma)
  }
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

ou_dense_nll_at <- function(fit, par) {
  temporal <- fit$model$structured$temporal_mu
  parameter_names <- names(par)
  beta <- unname(par[parameter_names == "beta_mu"])
  sigma <- exp(unname(par[match("beta_sigma", parameter_names)]))
  sd_temporal <- exp(unname(par[match("log_sd_temporal", parameter_names)]))
  decay <- exp(unname(par[match("theta_temporal", parameter_names)]))
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
    V <- sd_between^2 + sd_temporal^2 * exp(-decay * abs(outer(time, time, "-")))
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

ou_dense_profile_nll <- function(fit, beta_index, beta_value) {
  par <- fit$opt$par
  beta_positions <- which(names(par) == "beta_mu")
  position <- beta_positions[[beta_index]]
  nuisance_positions <- setdiff(seq_along(par), position)
  objective <- function(nuisance) {
    candidate <- par
    candidate[[position]] <- beta_value
    candidate[nuisance_positions] <- nuisance
    ou_dense_nll_at(fit, candidate)
  }
  optimized <- stats::nlminb(
    start = par[nuisance_positions],
    objective = objective,
    control = list(eval.max = 1000L, iter.max = 1000L)
  )
  if (optimized$convergence != 0L || !is.finite(optimized$objective)) {
    stop("Independent dense OU profile optimization failed.", call. = FALSE)
  }
  optimized$objective
}

test_that("Gaussian temporal OU likelihood matches an independent dense covariance oracle", {
  for (with_intercept in c(FALSE, TRUE)) {
    dat <- ou_oracle_data(with_intercept)
    formula <- if (with_intercept) {
      drmTMB::bf(y ~ x + (1 | id) + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1)
    } else {
      drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1)
    }
    fit <- suppressWarnings(drmTMB::drmTMB(formula, data = dat, family = gaussian(), REML = FALSE))
    expect_equal(as.numeric(fit$obj$fn(fit$opt$par)), ou_dense_nll_at(fit, fit$opt$par), tolerance = 1e-7)
    expect_equal(as.numeric(stats::logLik(fit)), -ou_dense_nll_at(fit, fit$opt$par), tolerance = 1e-7)
  }
})

test_that("temporal OU score, Hessian, and coefficient covariance match dense references", {
  for (with_intercept in c(FALSE, TRUE)) {
    dat <- ou_oracle_data(with_intercept, seed = if (with_intercept) 1L else 2L)
    formula <- if (with_intercept) {
      drmTMB::bf(y ~ x + (1 | id) + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1)
    } else {
      drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1)
    }
    fit <- suppressWarnings(drmTMB::drmTMB(formula, data = dat, family = gaussian(), REML = FALSE))
    expect_true(isTRUE(fit$sdr$pdHess))
    objective <- function(par) ou_dense_nll_at(fit, par)
    opt_par <- fit$opt$par
    score <- numDeriv::grad(objective, opt_par, method.args = list(eps = 1e-6))
    hessian_1 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-4))
    hessian_2 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-5))
    observed_hessian <- solve(fit$sdr$cov.fixed)
    expect_equal(fit$obj$gr(opt_par), score, tolerance = 1e-5)
    expect_equal(hessian_1, hessian_2, tolerance = 1e-4)
    expect_equal(unname(observed_hessian), unname(hessian_1), tolerance = 1e-4)
    beta_index <- which(names(opt_par) == "beta_mu")
    expect_equal(
      unname(fit$sdr$cov.fixed[beta_index, beta_index, drop = FALSE]),
      unname(solve(observed_hessian)[beta_index, beta_index, drop = FALSE]),
      tolerance = 1e-7
    )
  }
})

test_that("temporal OU fixed-effect profile curve matches an independent dense profile", {
  fit <- suppressWarnings(drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = ou_oracle_data(with_intercept = FALSE, seed = 20260912L),
    family = gaussian(), REML = FALSE
  ))
  fit$sdr$pdHess <- FALSE
  expect_warning(
    curve <- stats::profile(
      fit,
      parm = "fixef:mu:x",
      ystep = 0.5,
      ytol = 2
    ),
    class = "drmTMB_temporal_profile_hessian_warning"
  )
  beta_x <- unname(fit$opt$par[which(names(fit$opt$par) == "beta_mu")[[2L]]])
  targets <- c(
    beta_x - 0.1,
    beta_x,
    beta_x + 0.1
  )
  rows <- vapply(targets, function(value) {
    which.min(abs(curve$profile_value - value))
  }, integer(1L))
  dense <- vapply(rows, function(row) {
    ou_dense_profile_nll(
      fit,
      beta_index = 2L,
      beta_value = curve$profile_value[[row]]
    )
  }, numeric(1L))
  expect_equal(curve$objective[rows], dense, tolerance = 1e-6)
})

test_that("OU reference mutations detect lost elapsed-time and series structure", {
  series <- c("a", "a", "a", "b", "b", "b")
  elapsed <- c(0, 0.5, 3, 0, 0.5, 3)
  decay <- 0.7
  sd_between <- 0.6
  sd_temporal <- 0.8
  sigma <- 0.4
  covariance <- function(series, elapsed) {
    out <- matrix(0, length(series), length(series))
    for (i in seq_along(series)) for (j in seq_along(series)) {
      if (identical(series[[i]], series[[j]])) {
        out[i, j] <- sd_between^2 + sd_temporal^2 * exp(-decay * abs(elapsed[[i]] - elapsed[[j]]))
      }
    }
    diag(out) <- diag(out) + sigma^2
    out
  }
  correct <- covariance(series, elapsed)
  compressed <- covariance(series, ave(elapsed, series, FUN = rank))
  shared_series <- sd_between^2 + sd_temporal^2 * exp(-decay * abs(outer(elapsed, elapsed, "-")))
  diag(shared_series) <- diag(shared_series) + sigma^2
  expect_false(isTRUE(all.equal(correct, compressed)))
  expect_false(isTRUE(all.equal(correct, shared_series)))

  latent <- c(0.4, -0.2, 0.7)
  gap <- c(0, 0.5, 2.5)
  normalized <- -stats::dnorm(latent[[1L]], log = TRUE)
  unnormalized <- latent[[1L]]^2 / 2
  for (node in 2:3) {
    transition <- exp(-decay * gap[[node]])
    transition_sd <- sqrt(1 - transition^2)
    normalized <- normalized - stats::dnorm(latent[[node]], transition * latent[[node - 1L]], transition_sd, log = TRUE)
    unnormalized <- unnormalized + (latent[[node]] - transition * latent[[node - 1L]])^2 / (2 * transition_sd^2)
  }
  expect_false(isTRUE(all.equal(normalized, unnormalized)))
})

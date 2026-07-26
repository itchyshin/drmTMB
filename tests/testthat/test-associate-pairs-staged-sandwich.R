staged_sandwich_fixture <- function(n = 18L, slope = FALSE) {
  set.seed(20260725)
  x <- seq(-1, 1, length.out = n)
  p <- stats::plogis(-0.15 + 0.25 * x)
  mu <- exp(0.35 + 0.15 * x)
  sigma <- rep(0.6, n)
  a <- if (slope) -0.12 + 0.22 * x else rep(0.22, n)
  eta <- 0.999999 * tanh(a)
  z_b <- stats::rnorm(n)
  z_n <- eta * z_b + sqrt(1 - eta^2) * stats::rnorm(n)
  dat <- data.frame(
    x = x,
    binary = as.integer(z_b > stats::qnorm(p, lower.tail = FALSE)),
    count = drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_n, mu, sigma)
  )
  binary_fit <- drmTMB(bf(mu = binary ~ x), binomial(), dat)
  nbinom2_fit <- drmTMB(bf(mu = count ~ x, sigma = ~1), nbinom2(), dat)
  association_fit <- associate_pairs(
    binary_fit,
    nbinom2_fit,
    kernel = latent_normal(),
    association = if (slope) ~x else ~1
  )
  list(
    binary_fit = binary_fit,
    nbinom2_fit = nbinom2_fit,
    association_fit = association_fit
  )
}

staged_sandwich_oracle_rectangle <- function(
  binary_y,
  count_y,
  lambda_b,
  xi_n,
  tau_n,
  a
) {
  p <- stats::plogis(lambda_b)
  mu <- exp(xi_n)
  sigma <- exp(tau_n)
  size <- sigma^-2
  endpoint <- function(y) {
    cdf <- stats::pnbinom(y, size = size, mu = mu)
    stats::qnorm(cdf)
  }
  threshold <- stats::qnorm(p, lower.tail = FALSE)
  lower <- c(
    if (binary_y == 0L) -Inf else threshold,
    if (count_y == 0L) -Inf else endpoint(count_y - 1L)
  )
  upper <- c(if (binary_y == 0L) threshold else Inf, endpoint(count_y))
  probability <- mvtnorm::pmvnorm(
    lower = lower,
    upper = upper,
    mean = c(0, 0),
    sigma = matrix(c(1, 0.999999 * tanh(a), 0.999999 * tanh(a), 1), 2),
    algorithm = mvtnorm::GenzBretz(
      maxpts = 250000L, abseps = 1e-12, releps = 1e-12
    ),
    keepAttr = TRUE
  )
  list(
    log_probability = log(as.numeric(probability)),
    integration_error = attr(probability, "error"),
    message = attr(probability, "msg")
  )
}

staged_sandwich_oracle_logprob <- function(...) {
  staged_sandwich_oracle_rectangle(...)$log_probability
}

staged_sandwich_f1d_nbinom2_endpoints <- function(y, mu, sigma) {
  size <- sigma^-2
  normal_quantile <- function(count) {
    log_cdf <- stats::pnbinom(count, size = size, mu = mu, log.p = TRUE)
    log_survival <- stats::pnbinom(
      count, size = size, mu = mu, lower.tail = FALSE, log.p = TRUE
    )
    if (log_cdf <= log(0.5)) {
      stats::qnorm(log_cdf, log.p = TRUE)
    } else {
      stats::qnorm(log_survival, lower.tail = FALSE, log.p = TRUE)
    }
  }
  lower <- if (y == 0L) -Inf else normal_quantile(y - 1L)
  upper <- normal_quantile(y)
  if (!is.finite(upper) || (y > 0L && !is.finite(lower)) || lower >= upper) {
    return(NULL)
  }
  list(lower = lower, upper = upper)
}

# F1D's independent route uses neither the production CDF-scale integration
# nor its five-point derivative helper.  Fixed Gauss-Legendre nodes over the
# latent-NB2 interval make the scalar function deterministic under parameter
# perturbation.
staged_sandwich_f1d_latent_z_logprob <- function(
  q,
  binary_y,
  count_y,
  nodes
) {
  p <- stats::plogis(q[[2L]])
  endpoints <- staged_sandwich_f1d_nbinom2_endpoints(
    count_y, exp(q[[3L]]), exp(q[[4L]])
  )
  if (is.null(endpoints) || !is.finite(endpoints$lower) ||
      !is.finite(endpoints$upper)) {
    return(NA_real_)
  }
  eta <- 0.999999 * tanh(q[[1L]])
  s <- sqrt(1 - eta^2)
  threshold <- stats::qnorm(p, lower.tail = FALSE)
  z <- (endpoints$upper - endpoints$lower) / 2 * nodes$nodes +
    (endpoints$upper + endpoints$lower) / 2
  log_conditional <- if (binary_y == 1L) {
    stats::pnorm((eta * z - threshold) / s, log.p = TRUE)
  } else {
    stats::pnorm((threshold - eta * z) / s, log.p = TRUE)
  }
  # dnorm(z) is at most exp(-log(sqrt(2*pi))); this constant scale does not
  # depend on q and avoids a production-style adaptive rescaling path.
  log_scale <- -0.5 * log(2 * pi)
  scaled <- (endpoints$upper - endpoints$lower) / 2 * sum(
    nodes$weights * exp(stats::dnorm(z, log = TRUE) +
      log_conditional - log_scale)
  )
  if (!is.finite(scaled) || scaled <= 0) {
    return(NA_real_)
  }
  log_scale + log(scaled)
}

staged_sandwich_f1d_central_derivatives <- function(fn, q, h) {
  p <- length(q)
  value <- fn(q)
  if (!is.finite(value)) {
    return(list(gradient = rep(NA_real_, p), hessian = matrix(NA_real_, p, p)))
  }
  gradient <- numeric(p)
  hessian <- matrix(0, p, p)
  for (j in seq_len(p)) {
    e_j <- rep(0, p)
    e_j[[j]] <- h
    forward <- fn(q + e_j)
    backward <- fn(q - e_j)
    gradient[[j]] <- (forward - backward) / (2 * h)
    hessian[j, j] <- (forward - 2 * value + backward) / h^2
  }
  for (j in seq_len(p - 1L)) {
    for (k in seq.int(j + 1L, p)) {
      e_j <- rep(0, p)
      e_k <- rep(0, p)
      e_j[[j]] <- h
      e_k[[k]] <- h
      hessian[j, k] <- hessian[k, j] <- (
        fn(q + e_j + e_k) - fn(q + e_j - e_k) -
          fn(q - e_j + e_k) + fn(q - e_j - e_k)
      ) / (4 * h^2)
    }
  }
  list(gradient = gradient, hessian = hessian)
}

staged_sandwich_f1d_stable_derivatives <- function(fn, q) {
  first <- staged_sandwich_f1d_central_derivatives(fn, q, 1.25e-3)
  second <- staged_sandwich_f1d_central_derivatives(fn, q, 6.25e-4)
  if (any(!is.finite(first$gradient)) || any(!is.finite(first$hessian)) ||
      any(!is.finite(second$gradient)) || any(!is.finite(second$hessian))) {
    return(list(status = "independent_derivative_unresolved"))
  }
  difference <- max(abs(c(
    first$gradient - second$gradient,
    first$hessian - second$hessian
  )))
  scale <- max(1, abs(c(
    first$gradient, second$gradient, first$hessian, second$hessian
  )))
  if (difference > 2e-6 * scale) {
    return(list(
      status = "independent_step_unstable",
      diagnostics = list(max_step_difference = difference, scale = scale)
    ))
  }
  list(
    status = "ok",
    gradient = second$gradient,
    hessian = second$hessian,
    diagnostics = list(max_step_difference = difference, scale = scale)
  )
}

staged_sandwich_f1d_status <- function(
  protocol_ok = TRUE,
  endpoint_ok = TRUE,
  point_ok = TRUE,
  production = "ok",
  independent = "ok",
  routes_agree = TRUE
) {
  if (!protocol_ok) return("protocol_or_input_mismatch")
  if (!endpoint_ok) return("endpoint_oracle_unresolved")
  if (!point_ok) return("point_oracle_unresolved")
  if (identical(production, "nonfinite")) return("production_nonfinite_derivative")
  if (identical(production, "unstable")) return("production_step_unstable")
  if (identical(independent, "unresolved")) return("independent_derivative_unresolved")
  if (identical(independent, "unstable")) return("independent_step_unstable")
  if (!routes_agree) return("independent_route_disagreement")
  "F1D_pass"
}

staged_sandwich_f1d_node_ladder <- function(binary_y, count_y, q) {
  if (!requireNamespace("statmod", quietly = TRUE)) {
    return(list(status = "independent_derivative_unresolved"))
  }
  levels <- lapply(c(256L, 512L, 1024L), function(n_nodes) {
    nodes <- statmod::gauss.quad(n_nodes, kind = "legendre")
    fn <- function(x) {
      staged_sandwich_f1d_latent_z_logprob(
        x, binary_y = binary_y, count_y = count_y, nodes = nodes
      )
    }
    derivatives <- staged_sandwich_f1d_stable_derivatives(fn, q)
    list(nodes = n_nodes, point = fn(q), derivatives = derivatives)
  })
  if (any(vapply(levels, function(x) {
    !identical(x$derivatives$status, "ok") || !is.finite(x$point)
  }, logical(1)))) {
    return(list(status = "independent_derivative_unresolved", levels = levels))
  }
  adjacent <- Map(function(left, right) {
    left_values <- c(
      left$point, left$derivatives$gradient, left$derivatives$hessian
    )
    # The node ladder is a coordinate-wise contract: a large tail Hessian must
    # not mask non-convergence in a small score or cross-Hessian coordinate.
    right_values <- c(
      right$point, right$derivatives$gradient, right$derivatives$hessian
    )
    difference <- abs(left_values - right_values)
    tolerance <- pmax(1e-8, 2e-10 * pmax(1, abs(left_values), abs(right_values)))
    labels <- c(
      "point",
      paste0("gradient_", names(q)),
      as.vector(outer(names(q), names(q), paste, sep = "_"))
    )
    failed <- which(difference > tolerance)
    list(
      max_difference = max(difference),
      max_standardized_difference = max(difference / tolerance),
      pass = !length(failed),
      failures = data.frame(
        coordinate = labels[failed],
        difference = difference[failed],
        tolerance = tolerance[failed]
      )
    )
  }, levels[-length(levels)], levels[-1L])
  if (any(vapply(adjacent, function(x) {
    !x$pass
  }, logical(1)))) {
    return(list(
      status = "independent_step_unstable",
      levels = levels,
      diagnostics = adjacent
    ))
  }
  list(
    status = "ok",
    point = levels[[2L]]$point,
    gradient = levels[[2L]]$derivatives$gradient,
    hessian = levels[[2L]]$derivatives$hessian,
    levels = levels,
    diagnostics = adjacent
  )
}

test_that("analytic staged-margin scores and bread agree with numerical derivatives", {
  y <- 4L
  mu <- 2.3
  sigma <- 0.7
  r <- sigma^-2
  xi <- log(mu)
  tau <- log(sigma)
  scalar_loglik <- function(q) {
    stats::dnbinom(y, size = exp(-2 * q[[2L]]), mu = exp(q[[1L]]), log = TRUE)
  }
  numerical_score <- numDeriv::grad(scalar_loglik, c(xi, tau))
  block <- drmTMB:::drm_pair_sandwich_margin_blocks(
    binary_y = 1L,
    nbinom2_y = y,
    p = 0.3,
    mu = mu,
    sigma = sigma,
    x_b = matrix(1),
    x_n = matrix(1),
    z_n = matrix(1)
  )
  expect_equal(
    c(block$score_n, block$score_s),
    numerical_score,
    tolerance = 1e-6
  )
  numerical_hessian <- numDeriv::hessian(scalar_loglik, c(xi, tau))
  expect_equal(
    rbind(
      cbind(block$bread_nn, block$bread_ns),
      cbind(block$bread_ns, block$bread_ss)
    ),
    -numerical_hessian,
    tolerance = 2e-5
  )
})

test_that("staged rectangle score and every mixed derivative match an independent oracle", {
  skip_if_not_installed("mvtnorm")
  q <- c(a = 0.22, lambda_b = -0.35, xi_n = 0.5, tau_n = log(0.62))
  production <- function(x) {
    drmTMB:::drm_pair_sandwich_row_logprob(
      binary_y = 1L,
      nbinom2_y = 3L,
      lambda_b = x[[2L]],
      xi_n = x[[3L]],
      tau_n = x[[4L]],
      a = x[[1L]]
    )
  }
  oracle <- function(x) {
    staged_sandwich_oracle_logprob(
      binary_y = 1L,
      count_y = 3L,
      lambda_b = x[[2L]],
      xi_n = x[[3L]],
      tau_n = x[[4L]],
      a = x[[1L]]
    )
  }
  production_derivatives <- drmTMB:::drm_pair_sandwich_derivatives(
    production,
    q,
    1e-2
  )
  oracle_gradient <- numDeriv::grad(oracle, q)
  oracle_hessian <- numDeriv::hessian(oracle, q)
  expect_equal(
    production_derivatives$gradient,
    oracle_gradient,
    tolerance = 2e-3
  )
  expect_equal(production_derivatives$hessian, oracle_hessian, tolerance = 3e-3)
  expect_gt(max(abs(production_derivatives$hessian[1L, 2:4])), 1e-5)
})

test_that("staged rectangle validated deterministic cases match the pinned numerical oracle", {
  skip_if_not_installed("mvtnorm")
  cases <- list(
    zero = 0,
    sign_negative = -0.35,
    sign_positive = 0.35,
    tail_positive = 4,
    near_boundary_positive = 7
  )
  for (name in names(cases)) {
    q <- c(a = cases[[name]], lambda_b = -0.35, xi_n = 0.5, tau_n = log(0.62))
    production <- function(x) {
      drmTMB:::drm_pair_sandwich_row_logprob(
        binary_y = 1L,
        nbinom2_y = 3L,
        lambda_b = x[[2L]],
        xi_n = x[[3L]],
        tau_n = x[[4L]],
        a = x[[1L]]
      )
    }
    oracle <- function(x) {
      staged_sandwich_oracle_logprob(
        binary_y = 1L,
        count_y = 3L,
        lambda_b = x[[2L]],
        xi_n = x[[3L]],
        tau_n = x[[4L]],
        a = x[[1L]]
      )
    }
    production_derivatives <- drmTMB:::drm_pair_sandwich_stable_derivatives(
      production,
      q,
      drmTMB:::drm_pair_sandwich_control()
    )
    expect_identical(production_derivatives$status, "ok", info = name)
    expect_equal(production(q), oracle(q), tolerance = 1e-12, info = name)
    expect_equal(
      production_derivatives$gradient,
      numDeriv::grad(oracle, q),
      tolerance = 2e-3,
      info = name
    )
    expect_equal(
      production_derivatives$hessian,
      numDeriv::hessian(oracle, q),
      tolerance = 3e-3,
      info = name
    )
  }
})

test_that("legacy Genz finite differences remain non-certifying at the repaired tail", {
  skip_if_not_installed("mvtnorm")
  make_case <- function(a) {
    q <- c(a = a, lambda_b = -0.35, xi_n = 0.5, tau_n = log(0.62))
    production <- function(x) {
      drmTMB:::drm_pair_sandwich_row_logprob(
        binary_y = 1L,
        nbinom2_y = 3L,
        lambda_b = x[[2L]],
        xi_n = x[[3L]],
        tau_n = x[[4L]],
        a = x[[1L]]
      )
    }
    oracle <- function(x) {
      staged_sandwich_oracle_logprob(
        binary_y = 1L,
        count_y = 3L,
        lambda_b = x[[2L]],
        xi_n = x[[3L]],
        tau_n = x[[4L]],
        a = x[[1L]]
      )
    }
    list(q = q, production = production, oracle = oracle)
  }
  tail <- make_case(-4)
  tail_derivatives <- drmTMB:::drm_pair_sandwich_stable_derivatives(
    tail$production,
    tail$q,
    drmTMB:::drm_pair_sandwich_control()
  )
  expect_identical(tail_derivatives$status, "ok")
  expect_equal(tail$production(tail$q), tail$oracle(tail$q), tolerance = 1e-10)
  expect_true(any(!is.finite(numDeriv::hessian(tail$oracle, tail$q))))

  boundary <- make_case(-7)
  boundary_derivatives <- drmTMB:::drm_pair_sandwich_stable_derivatives(
    boundary$production,
    boundary$q,
    drmTMB:::drm_pair_sandwich_control()
  )
  expect_identical(boundary_derivatives$status, "unavailable")
  expect_true(is.na(boundary$production(boundary$q)))
  expect_identical(boundary$oracle(boundary$q), -Inf)
})

test_that("F1D fails tail derivative certification closed when the node ladder is unstable", {
  skip_if_not_installed("mvtnorm")
  expect_true(requireNamespace("statmod", quietly = TRUE))
  cases <- list(
    interior = list(
      a = 0.22, binary_y = 1L, count_y = 3L,
      independent_status = "ok", final_status = "F1D_pass"
    ),
    tail_negative = list(
      a = -4, binary_y = 1L, count_y = 3L,
      independent_status = "independent_step_unstable",
      final_status = "independent_step_unstable"
    ),
    tail_positive_mirror = list(
      a = 4, binary_y = 0L, count_y = 3L,
      independent_status = "independent_step_unstable",
      final_status = "independent_step_unstable"
    )
  )
  for (name in names(cases)) {
    case <- cases[[name]]
    q <- c(a = case$a, lambda_b = -0.35, xi_n = 0.5, tau_n = log(0.62))
    production <- function(x) {
      drmTMB:::drm_pair_sandwich_row_logprob(
        binary_y = case$binary_y,
        nbinom2_y = case$count_y,
        lambda_b = x[[2L]], xi_n = x[[3L]], tau_n = x[[4L]], a = x[[1L]]
      )
    }
    production_derivatives <- drmTMB:::drm_pair_sandwich_stable_derivatives(
      production, q, drmTMB:::drm_pair_sandwich_control()
    )
    independent_derivatives <- staged_sandwich_f1d_node_ladder(
      case$binary_y, case$count_y, q
    )
    expect_identical(production_derivatives$status, "ok", info = name)
    expect_identical(
      independent_derivatives$status, case$independent_status, info = name
    )
    final_status <- staged_sandwich_f1d_status(
      production = if (identical(production_derivatives$status, "ok")) "ok" else "unstable",
      independent = if (identical(independent_derivatives$status, "ok")) "ok" else "unstable",
      routes_agree = isTRUE(all.equal(
        production_derivatives$gradient, independent_derivatives$gradient,
        tolerance = 2e-3
      )) && isTRUE(all.equal(
        production_derivatives$hessian, independent_derivatives$hessian,
        tolerance = 3e-3
      ))
    )
    expect_identical(final_status, case$final_status, info = name)
    if (identical(case$final_status, "F1D_pass")) {
      expect_equal(
        production(q), independent_derivatives$point,
        tolerance = 1e-10, info = name
      )
      expect_equal(
        production_derivatives$gradient,
        independent_derivatives$gradient,
        tolerance = 2e-3,
        info = name
      )
      expect_equal(
        production_derivatives$hessian,
        independent_derivatives$hessian,
        tolerance = 3e-3,
        info = name
      )
    }
    if (identical(name, "tail_negative")) {
      point_oracle <- staged_sandwich_oracle_rectangle(
        binary_y = case$binary_y, count_y = case$count_y,
        lambda_b = q[[2L]], xi_n = q[[3L]], tau_n = q[[4L]], a = q[[1L]]
      )
      expect_true(is.finite(point_oracle$log_probability), info = name)
      expect_true(is.finite(point_oracle$integration_error), info = name)
      expect_lte(point_oracle$integration_error, 1e-12)
      expect_identical(point_oracle$message, "Normal Completion", info = name)
      expect_equal(
        production(q), point_oracle$log_probability,
        tolerance = 1e-10, info = name
      )
    }
  }
})

test_that("F1D status taxonomy is exhaustive and fail closed", {
  expect_identical(staged_sandwich_f1d_status(protocol_ok = FALSE), "protocol_or_input_mismatch")
  expect_identical(staged_sandwich_f1d_status(endpoint_ok = FALSE), "endpoint_oracle_unresolved")
  expect_identical(staged_sandwich_f1d_status(point_ok = FALSE), "point_oracle_unresolved")
  expect_identical(staged_sandwich_f1d_status(production = "nonfinite"), "production_nonfinite_derivative")
  expect_identical(staged_sandwich_f1d_status(production = "unstable"), "production_step_unstable")
  expect_identical(staged_sandwich_f1d_status(independent = "unresolved"), "independent_derivative_unresolved")
  expect_identical(staged_sandwich_f1d_status(independent = "unstable"), "independent_step_unstable")
  expect_identical(staged_sandwich_f1d_status(routes_agree = FALSE), "independent_route_disagreement")
  expect_identical(staged_sandwich_f1d_status(), "F1D_pass")
})

test_that("Bernoulli x NB2 adapter matches the original stacked-score assembly", {
  fixture <- staged_sandwich_fixture()
  result <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit
  )
  routed <- drmTMB:::drm_pair_general_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit
  )
  binary_fit <- fixture$binary_fit
  nbinom2_fit <- fixture$nbinom2_fit
  association_fit <- fixture$association_fit
  x_b <- as.matrix(binary_fit$model$X$mu)
  x_n <- as.matrix(nbinom2_fit$model$X$mu)
  z_n <- as.matrix(nbinom2_fit$model$X$sigma)
  x_a <- as.matrix(association_fit$association_design$matrix)
  beta_b <- unname(binary_fit$coefficients$mu)
  beta_n <- unname(nbinom2_fit$coefficients$mu)
  gamma_n <- unname(nbinom2_fit$coefficients$sigma)
  alpha <- unname(association_fit$association_coefficients)
  lambda_b <- as.vector(x_b %*% beta_b)
  xi_n <- as.vector(x_n %*% beta_n)
  tau_n <- as.vector(z_n %*% gamma_n)
  a <- as.vector(x_a %*% alpha)
  components <- association_fit$components
  marginal <- drmTMB:::drm_pair_sandwich_margin_blocks(
    binary_y = components$binary_y,
    nbinom2_y = components$nbinom2_y,
    p = stats::plogis(lambda_b),
    mu = exp(xi_n),
    sigma = exp(tau_n),
    x_b = x_b,
    x_n = x_n,
    z_n = z_n
  )
  association <- drmTMB:::drm_pair_sandwich_association_blocks(
    binary_y = components$binary_y,
    nbinom2_y = components$nbinom2_y,
    lambda_b = lambda_b,
    xi_n = xi_n,
    tau_n = tau_n,
    a = a,
    x_b = x_b,
    x_n = x_n,
    z_n = z_n,
    x_a = x_a,
    control = drmTMB:::drm_pair_sandwich_control()
  )
  p_b <- ncol(x_b)
  p_n <- ncol(x_n)
  p_s <- ncol(z_n)
  p_a <- ncol(x_a)
  ib <- seq_len(p_b)
  in_mu <- p_b + seq_len(p_n)
  in_sigma <- p_b + p_n + seq_len(p_s)
  ia <- p_b + p_n + p_s + seq_len(p_a)
  bread <- matrix(0, p_b + p_n + p_s + p_a, p_b + p_n + p_s + p_a)
  bread[ib, ib] <- marginal$bread_b
  bread[in_mu, in_mu] <- marginal$bread_nn
  bread[in_mu, in_sigma] <- marginal$bread_ns
  bread[in_sigma, in_mu] <- marginal$bread_ns
  bread[in_sigma, in_sigma] <- marginal$bread_ss
  bread[ia, ib] <- association$bread_ab
  bread[ia, in_mu] <- association$bread_an
  bread[ia, in_sigma] <- association$bread_as
  bread[ia, ia] <- association$bread_aa
  scores <- cbind(
    marginal$score_b,
    marginal$score_n,
    marginal$score_s,
    association$score_a
  )
  colnames(scores) <- c(
    paste0("bernoulli_mu:", colnames(x_b)),
    paste0("nbinom2_mu:", colnames(x_n)),
    paste0("nbinom2_sigma:", colnames(z_n)),
    paste0("association:", colnames(x_a))
  )
  dimnames(bread) <- list(colnames(scores), colnames(scores))
  meat <- crossprod(scores) / nrow(scores)
  covariance <- solve(bread) %*% meat %*% t(solve(bread)) / nrow(scores)
  covariance <- (covariance + t(covariance)) / 2
  dimnames(covariance) <- list(colnames(scores), colnames(scores))
  alpha_covariance <- covariance[ia, ia, drop = FALSE]
  eta_variance <- (0.999999 / cosh(a)^2)^2 * rowSums(
    (x_a %*% alpha_covariance) * x_a
  )
  expect_identical(result$status, "ok")
  expect_equal(routed$covariance, result$covariance, tolerance = 1e-12)
  expect_equal(result$scores, scores, tolerance = 1e-12)
  expect_equal(result$bread, bread, tolerance = 1e-12)
  expect_equal(result$meat, meat, tolerance = 1e-12)
  expect_equal(result$covariance, covariance, tolerance = 1e-12)
  expect_equal(result$alpha_covariance, alpha_covariance, tolerance = 1e-12)
  expect_equal(result$eta_se, sqrt(eta_variance), tolerance = 1e-12)
})

test_that("staged sandwich uses stable row derivatives and retains all score blocks", {
  fixture <- staged_sandwich_fixture()
  result <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit
  )
  reverse_fit <- associate_pairs(
    fixture$nbinom2_fit,
    fixture$binary_fit,
    kernel = latent_normal(),
    association = ~1
  )
  reverse <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$nbinom2_fit,
    fixture$binary_fit,
    reverse_fit
  )
  expect_identical(result$status, "ok")
  expect_identical(reverse$status, "ok")
  expect_equal(ncol(result$scores), 6L)
  expect_equal(dim(result$covariance), c(6L, 6L))
  expect_true(all(is.finite(result$alpha_se)))
  expect_true(all(is.finite(result$eta_se)))
  expect_gt(max(abs(result$bread[5:6, 1:4])), 0)
  expect_equal(result$meat, t(result$meat), tolerance = 1e-12)
  expect_equal(
    result$alpha_covariance,
    reverse$alpha_covariance,
    tolerance = 1e-7
  )
  expect_equal(
    result$meat,
    crossprod(result$scores) / nrow(result$scores),
    tolerance = 1e-12
  )
  expect_equal(
    result$covariance,
    solve(result$bread) %*%
      result$meat %*%
      t(solve(result$bread)) /
      nrow(result$scores),
    tolerance = 1e-12
  )
  expect_equal(
    unname(result$bread[seq_len(5L), 6L]),
    rep(0, 5L),
    tolerance = 1e-14
  )
  expect_gt(abs(result$bread[6L, 1L]), 0)
  expect_gt(abs(result$bread[6L, 3L]), 0)
  expect_gt(abs(result$bread[6L, 5L]), 0)
  expect_true(all(vapply(
    result$derivative_diagnostics,
    function(x) is.finite(x$max_step_difference),
    logical(1)
  )))
})

test_that("staged sandwich supports the one admitted association slope", {
  fixture <- staged_sandwich_fixture(n = 24L, slope = TRUE)
  result <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit
  )
  expect_identical(result$status, "ok")
  expect_named(
    result$alpha_se,
    c("association:(Intercept)", "association:x"),
    ignore.order = FALSE
  )
  expect_length(result$eta, 24L)
  expect_gt(diff(range(result$eta)), 0)
})

test_that("staged sandwich fails closed before any public uncertainty interface", {
  fixture <- staged_sandwich_fixture()
  fixture$association_fit$status <- "boundary_unresolved"
  result <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit
  )
  expect_identical(
    result,
    list(status = "unavailable", reason = "association_unresolved")
  )
  expect_error(vcov(fixture$association_fit), "unavailable")
  expect_error(confint(fixture$association_fit), "unavailable")
})

test_that("staged sandwich guards frozen margins, bounds, derivative stability, and bread rank", {
  fixture <- staged_sandwich_fixture()
  tampered_provenance <- fixture$association_fit
  tampered_provenance$provenance$data_hash <- "not-the-frozen-data-hash"
  expect_identical(
    drmTMB:::drm_pair_staged_eta_sandwich(
      fixture$binary_fit,
      fixture$nbinom2_fit,
      tampered_provenance
    ),
    list(status = "unavailable", reason = "provenance_mismatch")
  )
  tampered_snapshot <- fixture$association_fit
  tampered_snapshot$margins$fit_1$fitted$mu[[1L]] <-
    tampered_snapshot$margins$fit_1$fitted$mu[[1L]] + 0.01
  expect_identical(
    drmTMB:::drm_pair_staged_eta_sandwich(
      fixture$binary_fit,
      fixture$nbinom2_fit,
      tampered_snapshot
    ),
    list(status = "unavailable", reason = "provenance_mismatch")
  )
  mismatched <- fixture$association_fit
  mismatched$components$binary_p[[1L]] <- mismatched$components$binary_p[[1L]] +
    0.01
  expect_identical(
    drmTMB:::drm_pair_staged_eta_sandwich(
      fixture$binary_fit,
      fixture$nbinom2_fit,
      mismatched
    ),
    list(status = "unavailable", reason = "frozen_margin_mismatch")
  )
  bounded <- fixture$association_fit
  bounded$association_coefficients[] <- 8
  expect_identical(
    drmTMB:::drm_pair_staged_eta_sandwich(
      fixture$binary_fit,
      fixture$nbinom2_fit,
      bounded
    ),
    list(status = "unavailable", reason = "association_boundary")
  )
  unstable <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(),
      list(
        derivative_relative_tolerance = 0,
        derivative_absolute_tolerance = 0
      )
    )
  )
  expect_match(unstable$reason, "association_step_unstable")
  rank_failed <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(),
      list(rcond_min = 1)
    )
  )
  expect_identical(
    rank_failed,
    list(status = "unavailable", reason = "bread_or_meat_unstable")
  )
})

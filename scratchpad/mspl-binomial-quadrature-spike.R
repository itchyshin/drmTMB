#!/usr/bin/env Rscript

# Independent Gauss-Hermite receipt for the experimental binomial-logit MSPL
# route. This script evaluates and re-optimizes the exact quadrature MSPL
# criterion; it does not reuse TMB's Laplace implementation.

options(warn = 2)
devtools::load_all(".", quiet = TRUE)

log_sum_exp <- function(x) {
  anchor <- max(x)
  anchor + log(sum(exp(x - anchor)))
}

conditional_group_loglik <- function(y, trials, eta) {
  sum(
    lchoose(trials, y) +
      y * stats::plogis(eta, log.p = TRUE) +
      (trials - y) * stats::plogis(-eta, log.p = TRUE)
  )
}

mspl_native_vector <- function(fit) {
  native <- fit$obj$env$parList(fit$opt$par)
  eta_cor <- if (identical(fit$mspl$q, 2L)) native$eta_cor_mu else numeric()
  eta_named <- if (length(eta_cor)) {
    stats::setNames(as.numeric(eta_cor), paste0("eta_cor", seq_along(eta_cor)))
  } else {
    numeric()
  }
  c(
    stats::setNames(as.numeric(native$beta_mu), paste0("beta", seq_along(native$beta_mu))),
    stats::setNames(as.numeric(native$log_sd_mu), paste0("log_sd", seq_along(native$log_sd_mu))),
    eta_named
  )
}

q1_exact_loglik <- function(par, fit, data, nodes) {
  p <- ncol(fit$model$X$mu)
  quad <- statmod::gauss.quad.prob(nodes, dist = "normal")
  fixed <- drop(fit$model$offset$mu + fit$model$X$mu %*% par[seq_len(p)])
  sd <- exp(par[[p + 1L]])
  groups <- levels(data$group)
  sum(vapply(groups, function(level) {
    take <- data$group == level
    terms <- vapply(seq_along(quad$nodes), function(k) {
      conditional_group_loglik(
        data$successes[take], data$trials[take],
        fixed[take] + sd * quad$nodes[[k]]
      ) + log(quad$weights[[k]])
    }, numeric(1L))
    log_sum_exp(terms)
  }, numeric(1L)))
}

q2_exact_loglik <- function(par, fit, data, nodes) {
  p <- ncol(fit$model$X$mu)
  quad <- statmod::gauss.quad.prob(nodes, dist = "normal")
  fixed <- drop(fit$model$offset$mu + fit$model$X$mu %*% par[seq_len(p)])
  a1 <- par[[p + 1L]]
  a2 <- par[[p + 2L]]
  z <- par[[p + 3L]]
  rho <- tanh(z)
  log_sech <- log(2) - abs(z) - log1p(exp(-2 * abs(z)))
  L11 <- exp(a1)
  L21 <- exp(a2) * rho
  L22 <- exp(a2 + log_sech)
  groups <- levels(data$group)
  sum(vapply(groups, function(level) {
    take <- data$group == level
    terms <- numeric(nodes * nodes)
    cursor <- 0L
    for (a in seq_along(quad$nodes)) {
      for (b in seq_along(quad$nodes)) {
        cursor <- cursor + 1L
        intercept <- L11 * quad$nodes[[a]]
        slope <- L21 * quad$nodes[[a]] + L22 * quad$nodes[[b]]
        eta <- fixed[take] + intercept + data$x[take] * slope
        terms[[cursor]] <- conditional_group_loglik(
          data$successes[take], data$trials[take], eta
        ) + log(quad$weights[[a]]) + log(quad$weights[[b]])
      }
    }
    log_sum_exp(terms)
  }, numeric(1L)))
}

exact_mspl_log_objective <- function(par, fit, data, nodes, q) {
  p <- ncol(fit$model$X$mu)
  exact <- if (q == 1L) {
    q1_exact_loglik(par, fit, data, nodes)
  } else {
    q2_exact_loglik(par, fit, data, nodes)
  }
  eta <- drop(
    fit$model$offset$mu + fit$model$X$mu %*% par[seq_len(p)]
  )
  working_weight <- fit$model$weights * fit$model$trials *
    exp(-pmax(eta, 0) - log1p(exp(-abs(eta)))) *
    exp(-pmax(-eta, 0) - log1p(exp(-abs(eta))))
  information <- crossprod(
    fit$model$X$mu,
    fit$model$X$mu * working_weight
  )
  determinant <- determinant(information, logarithm = TRUE)
  if (determinant$sign <= 0 || !is.finite(determinant$modulus)) return(-Inf)
  jeffreys <- 0.5 * as.numeric(determinant$modulus)
  variance <- par[-seq_len(p)]
  coordinates <- if (q == 1L) {
    variance[[1L]]
  } else {
    z <- variance[[3L]]
    log_sech <- log(2) - abs(z) - log1p(exp(-2 * abs(z)))
    c(variance[[1L]], variance[[2L]] + log_sech, exp(variance[[2L]]) * tanh(z))
  }
  negative_huber <- function(x) {
    ifelse(abs(x) <= 1, -0.5 * x^2, -abs(x) + 0.5)
  }
  n_eff <- sum(fit$model$weights * fit$model$trials)
  c_n <- 2 * sqrt(p / n_eff)
  exact + c_n * (jeffreys + sum(negative_huber(coordinates)))
}

optimize_exact_mspl <- function(fit, data, nodes, q) {
  start <- mspl_native_vector(fit)
  objective <- function(par) -exact_mspl_log_objective(par, fit, data, nodes, q)
  opt <- stats::optim(
    par = start,
    fn = objective,
    method = "BFGS",
    control = list(maxit = 500L, reltol = 1e-11)
  )
  opt$objective <- opt$value
  gradient <- numDeriv::grad(objective, opt$par)
  list(
    opt = opt,
    gradient_max_abs = max(abs(gradient)),
    parameter_linf_from_laplace = max(abs(opt$par - start)),
    exact_gain_over_laplace_point = objective(start) - opt$objective
  )
}

control <- drm_control(
  se = FALSE,
  optimizer_preset = "careful",
  multi_start = 3L
)

set.seed(2026080801)
n_group <- 18L
n_each <- 6L
group <- factor(rep(seq_len(n_group), each = n_each))
x <- rep(seq(-1, 1, length.out = n_each), n_group)
trials <- rep(c(2L, 3L, 4L, 2L, 3L, 4L), n_group)
u <- rnorm(n_group, sd = 0.55)
eta <- -0.25 + 0.85 * x + u[group]
successes <- rbinom(length(x), trials, plogis(eta))
q1_data <- data.frame(successes, failures = trials - successes, trials, x, group)
q1_fit <- drmTMB(
  bf(cbind(successes, failures) ~ x + (1 | group)),
  binomial(), q1_data, estimator = "mspl", control = control
)

set.seed(2026080802)
z1 <- rnorm(n_group)
z2 <- rnorm(n_group)
rho <- -0.35
u1 <- 0.60 * z1
u2 <- 0.30 * (rho * z1 + sqrt(1 - rho^2) * z2)
eta <- -0.15 + 0.70 * x + u1[group] + x * u2[group]
successes <- rbinom(length(x), trials, plogis(eta))
q2_data <- data.frame(successes, failures = trials - successes, trials, x, group)
q2_fit <- drmTMB(
  bf(cbind(successes, failures) ~ x + (1 + x | group)),
  binomial(), q2_data, estimator = "mspl", control = control
)

rows <- list()
for (nodes in c(41L, 81L)) {
  par <- mspl_native_vector(q1_fit)
  exact <- q1_exact_loglik(par, q1_fit, q1_data, nodes)
  rows[[length(rows) + 1L]] <- data.frame(
    q = 1L,
    nodes_per_axis = nodes,
    evaluation = "laplace_mspl_optimum",
    exact_marginal_loglik = exact,
    laplace_loglik = q1_fit$mspl$unpenalized_laplace_logLik,
    exact_mspl_log_objective = exact_mspl_log_objective(
      par, q1_fit, q1_data, nodes, 1L
    ),
    laplace_mspl_log_objective = q1_fit$mspl$penalized_log_objective,
    exact_minus_laplace = exact - q1_fit$mspl$unpenalized_laplace_logLik,
    optimizer_convergence = NA_integer_, exact_gradient_max_abs = NA_real_,
    parameter_linf_from_laplace = 0, exact_gain_over_laplace_point = 0
  )
}
for (nodes in c(21L, 31L, 41L)) {
  par <- mspl_native_vector(q2_fit)
  exact <- q2_exact_loglik(par, q2_fit, q2_data, nodes)
  rows[[length(rows) + 1L]] <- data.frame(
    q = 2L,
    nodes_per_axis = nodes,
    evaluation = "laplace_mspl_optimum",
    exact_marginal_loglik = exact,
    laplace_loglik = q2_fit$mspl$unpenalized_laplace_logLik,
    exact_mspl_log_objective = exact_mspl_log_objective(
      par, q2_fit, q2_data, nodes, 2L
    ),
    laplace_mspl_log_objective = q2_fit$mspl$penalized_log_objective,
    exact_minus_laplace = exact - q2_fit$mspl$unpenalized_laplace_logLik,
    optimizer_convergence = NA_integer_, exact_gradient_max_abs = NA_real_,
    parameter_linf_from_laplace = 0, exact_gain_over_laplace_point = 0
  )
}

q1_exact_opt <- optimize_exact_mspl(q1_fit, q1_data, 81L, 1L)
q2_exact_opt <- optimize_exact_mspl(q2_fit, q2_data, 41L, 2L)
for (item in list(
  list(q = 1L, nodes = 81L, fit = q1_fit, data = q1_data, result = q1_exact_opt),
  list(q = 2L, nodes = 41L, fit = q2_fit, data = q2_data, result = q2_exact_opt)
)) {
  exact <- if (item$q == 1L) {
    q1_exact_loglik(item$result$opt$par, item$fit, item$data, item$nodes)
  } else {
    q2_exact_loglik(item$result$opt$par, item$fit, item$data, item$nodes)
  }
  rows[[length(rows) + 1L]] <- data.frame(
    q = item$q, nodes_per_axis = item$nodes,
    evaluation = "exact_mspl_optimum",
    exact_marginal_loglik = exact,
    laplace_loglik = item$fit$mspl$unpenalized_laplace_logLik,
    exact_mspl_log_objective = -item$result$opt$objective,
    laplace_mspl_log_objective = item$fit$mspl$penalized_log_objective,
    exact_minus_laplace = exact - item$fit$mspl$unpenalized_laplace_logLik,
    optimizer_convergence = item$result$opt$convergence,
    exact_gradient_max_abs = item$result$gradient_max_abs,
    parameter_linf_from_laplace = item$result$parameter_linf_from_laplace,
    exact_gain_over_laplace_point = item$result$exact_gain_over_laplace_point
  )
}

results <- do.call(rbind, rows)
results$quadrature_increment <- NA_real_
for (q in 1:2) {
  take <- results$q == q & results$evaluation == "laplace_mspl_optimum"
  results$quadrature_increment[take] <- c(
    NA_real_, diff(results$exact_marginal_loglik[take])
  )
}

q1_increment <- abs(tail(results$quadrature_increment[
  results$q == 1L & results$evaluation == "laplace_mspl_optimum"
], 1L))
q2_increment <- abs(tail(results$quadrature_increment[
  results$q == 2L & results$evaluation == "laplace_mspl_optimum"
], 1L))
print(list(
  q1_exact_optimizer = q1_exact_opt[c("opt", "gradient_max_abs", "parameter_linf_from_laplace", "exact_gain_over_laplace_point")],
  q2_exact_optimizer = q2_exact_opt[c("opt", "gradient_max_abs", "parameter_linf_from_laplace", "exact_gain_over_laplace_point")]
))
stopifnot(q1_increment < 1e-8, q2_increment < 1e-8)
stopifnot(
  q1_exact_opt$opt$convergence == 0L,
  q2_exact_opt$opt$convergence == 0L,
  q1_exact_opt$gradient_max_abs < 5e-5,
  q2_exact_opt$gradient_max_abs < 5e-5,
  q1_exact_opt$exact_gain_over_laplace_point >= -1e-8,
  q2_exact_opt$exact_gain_over_laplace_point >= -1e-8
)
stopifnot(
  abs(q1_fit$mspl$objective_identity_error) < 1e-7,
  abs(q2_fit$mspl$objective_identity_error) < 1e-7
)

utils::write.table(
  results,
  file = "scratchpad/mspl-binomial-quadrature-results.tsv",
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)
print(results, digits = 12)

binomial_correlated_sd_fixture <- function(groups = 12L, repeats = 6L) {
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- rep(c(-1, 1), length.out = groups)
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  y <- stats::rbinom(length(id), 1L, stats::plogis(0.2 + 0.3 * x))
  data.frame(y, x, w, v, id)
}

binomial_correlated_sd_gh_loglik <- function(data, beta_mu, sd_intercept,
                                             sd_slope, rho, order = 20L,
                                             link = "logit") {
  off_diagonal <- sqrt(seq_len(order - 1L) / 2)
  jacobi <- diag(0, nrow = order)
  jacobi[cbind(seq_len(order - 1L), seq_len(order - 1L) + 1L)] <- off_diagonal
  jacobi[cbind(seq_len(order - 1L) + 1L, seq_len(order - 1L))] <- off_diagonal
  decomposition <- eigen(jacobi, symmetric = TRUE)
  nodes <- sqrt(2) * decomposition$values
  log_weights <- log(decomposition$vectors[1L, ]^2)
  levels <- levels(data$id)
  group_loglik <- vapply(seq_along(levels), function(group) {
    rows <- which(as.integer(data$id) == group)
    tau0 <- sd_intercept[[group]]
    tau1 <- sd_slope[[group]]
    node_loglik <- numeric(order * order)
    position <- 0L
    for (i in seq_len(order)) {
      for (j in seq_len(order)) {
        position <- position + 1L
        b0 <- tau0 * nodes[[i]]
        b1 <- tau1 * (rho * nodes[[i]] + sqrt(1 - rho^2) * nodes[[j]])
        eta <- beta_mu[[1L]] + beta_mu[[2L]] * data$x[rows] +
          b0 + b1 * data$x[rows]
        probability <- switch(
          link,
          logit = stats::plogis(eta),
          probit = stats::pnorm(eta),
          cloglog = -expm1(-exp(eta)),
          stop("Unsupported link in independent quadrature oracle.")
        )
        loglik <- sum(stats::dbinom(
          data$y[rows], size = 1, prob = probability, log = TRUE
        ))
        node_loglik[[position]] <- log_weights[[i]] + log_weights[[j]] + loglik
      }
    }
    max_loglik <- max(node_loglik)
    max_loglik + log(sum(exp(node_loglik - max_loglik)))
  }, numeric(1L))
  sum(group_loglik)
}

binomial_correlated_q3_gh_loglik <- function(data, beta_mu, sd_by_group,
                                             rho, order = 8L) {
  off_diagonal <- sqrt(seq_len(order - 1L) / 2)
  jacobi <- diag(0, nrow = order)
  jacobi[cbind(seq_len(order - 1L), seq_len(order - 1L) + 1L)] <- off_diagonal
  jacobi[cbind(seq_len(order - 1L) + 1L, seq_len(order - 1L))] <- off_diagonal
  decomposition <- eigen(jacobi, symmetric = TRUE)
  nodes <- sqrt(2) * decomposition$values
  log_weights <- log(decomposition$vectors[1L, ]^2)
  node_grid <- expand.grid(
    first = seq_len(order), second = seq_len(order), third = seq_len(order)
  )
  node_log_weight <- log_weights[node_grid$first] +
    log_weights[node_grid$second] + log_weights[node_grid$third]
  partial21 <- rho[[1L]]
  partial31 <- rho[[2L]]
  partial32 <- (rho[[3L]] - partial21 * partial31) /
    (sqrt(1 - partial21^2) * sqrt(1 - partial31^2))
  s21 <- sqrt(1 - partial21^2)
  s31 <- sqrt(1 - partial31^2)
  s32 <- sqrt(1 - partial32^2)
  levels <- levels(data$id)
  group_loglik <- vapply(seq_along(levels), function(group) {
    rows <- which(as.integer(data$id) == group)
    node_ll <- numeric(nrow(node_grid))
    for (node in seq_len(nrow(node_grid))) {
      u0 <- nodes[[node_grid$first[[node]]]]
      u1 <- nodes[[node_grid$second[[node]]]]
      u2 <- nodes[[node_grid$third[[node]]]]
      b0 <- sd_by_group[[1L]][[group]] * u0
      b1 <- sd_by_group[[2L]][[group]] * (partial21 * u0 + s21 * u1)
      b2 <- sd_by_group[[3L]][[group]] *
        (partial31 * u0 + s31 * partial32 * u1 + s31 * s32 * u2)
      eta <- beta_mu[[1L]] + beta_mu[[2L]] * data$x[rows] +
        beta_mu[[3L]] * data$z[rows] + b0 + b1 * data$x[rows] +
        b2 * data$z[rows]
      node_ll[[node]] <- node_log_weight[[node]] + sum(stats::dbinom(
        data$y[rows], size = 1L, prob = stats::plogis(eta), log = TRUE
      ))
    }
    peak <- max(node_ll)
    peak + log(sum(exp(node_ll - peak)))
  }, numeric(1L))
  sum(group_loglik)
}

test_that("binomial correlated q2 SD targets select both covariance axes", {
  dat <- binomial_correlated_sd_fixture()
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'
  spec <- drm_build_binomial_spec(bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  ), dat)

  sd_re <- spec$random_scale$mu
  expect_identical(sd_re$dpars, c(key_intercept, key_slope))
  expect_identical(sd_re$target_identity[[key_intercept]]$coef, "(Intercept)")
  expect_identical(sd_re$target_identity[[key_slope]]$coef, "x")
  expect_identical(sd_re$target_identity[[key_intercept]]$target_coef, 1L)
  expect_identical(sd_re$target_identity[[key_slope]]$target_coef, 2L)
  expect_identical(sd_re$re_sd_row0, seq_len(spec$random$mu$n_re) - 1L)
  expect_equal(nrow(sd_re$X_list[[key_intercept]]), nlevels(dat$id))
  expect_equal(nrow(sd_re$X_list[[key_slope]]), nlevels(dat$id))
  expect_error(drm_build_binomial_spec(bf(
    y ~ x + (1 + x | id), sd(id) ~ w
  ), dat), "Ambiguous.*id")
})

test_that("binomial correlated q3 SD targets resolve all three covariance axes", {
  dat <- binomial_correlated_sd_fixture()
  dat$z <- dat$x^2 - mean(dat$x^2)
  dat$h <- rep(seq(-1, 1, length.out = nlevels(dat$id)), each = 6L)
  dat$j <- rep(rep(c(-1, 1), length.out = nlevels(dat$id)), each = 6L)
  formula <- bf(
    y ~ x + z + (1 + x + z | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ h,
    sd(id, dpar = "mu", coef = "z") ~ j
  )

  spec <- drm_build_binomial_spec(formula, dat)
  sd_re <- spec$random_scale$mu
  keys <- c(
    'sd(id, dpar = "mu", coef = "(Intercept)")',
    'sd(id, dpar = "mu", coef = "x")',
    'sd(id, dpar = "mu", coef = "z")'
  )
  expect_identical(sd_re$dpars, keys)
  expect_identical(
    unname(vapply(sd_re$target_identity[keys], `[[`, integer(1L), "target_coef")),
    1:3
  )
  expect_identical(sd_re$re_sd_row0, seq_len(spec$random$mu$n_re) - 1L)

  beta_sd <- numeric(ncol(sd_re$X))
  alpha <- list(c(log(0.5), 0.2), c(log(0.3), -0.15), c(log(0.4), 0.1))
  predictors <- list(dat$w, dat$h, dat$j)
  for (i in seq_along(keys)) {
    beta_sd[sd_re$coef_index[[keys[[i]]]]] <- alpha[[i]]
  }
  eta_cor <- atanh(c(0.3, -0.2, 0.4))
  par <- list(
    log_sd_mu = rep(log(0.5), 3L),
    beta_sd_mu = beta_sd,
    eta_cor_mu = eta_cor
  )
  ids <- spec$random$mu$index0[1L, ] + 1L
  L <- do.call(cbind, lapply(seq_along(ids), function(position) {
    z <- numeric(spec$random$mu$n_re)
    z[ids[[position]]] <- 1
    transform_mu_random_effects(
      z, par, spec$random$mu, sd_re, tmb_data = spec$tmb_data,
      binomial_q2 = TRUE
    )[ids]
  }))
  group_predictors <- vapply(predictors, `[`, numeric(1L), 1L)
  tau <- vapply(seq_along(alpha), function(i) {
    exp(alpha[[i]][[1L]] + alpha[[i]][[2L]] * group_predictors[[i]])
  }, numeric(1L))
  partial <- tanh(eta_cor)
  R <- rbind(
    c(1, partial[[1L]], partial[[2L]]),
    c(partial[[1L]], 1,
      partial[[1L]] * partial[[2L]] +
        sqrt(1 - partial[[1L]]^2) * sqrt(1 - partial[[2L]]^2) *
        partial[[3L]]),
    c(partial[[2L]],
      partial[[1L]] * partial[[2L]] +
        sqrt(1 - partial[[1L]]^2) * sqrt(1 - partial[[2L]]^2) *
        partial[[3L]], 1)
  )
  expected <- diag(tau) %*% R %*% diag(tau)
  expect_equal(L %*% t(L), expected, tolerance = 1e-10)
})

test_that("Bernoulli correlated q3 SD regression fits and recovers all targets", {
  set.seed(2026102632L)
  groups <- 128L
  repeats <- 40L
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  z <- stats::rnorm(length(id))
  w_group <- as.numeric(scale(stats::rnorm(groups)))
  h_group <- as.numeric(scale(stats::rnorm(groups)))
  j_group <- as.numeric(scale(stats::rnorm(groups)))
  w <- rep(w_group, each = repeats)
  h <- rep(h_group, each = repeats)
  j <- rep(j_group, each = repeats)
  alpha <- list(c(log(0.65), 0.45), c(log(0.55), -0.45), c(log(0.5), 0.4))
  tau0 <- exp(alpha[[1L]][[1L]] + alpha[[1L]][[2L]] * w_group)
  tau1 <- exp(alpha[[2L]][[1L]] + alpha[[2L]][[2L]] * h_group)
  tau2 <- exp(alpha[[3L]][[1L]] + alpha[[3L]][[2L]] * j_group)
  partial <- c(0.2, -0.2, 0.25)
  s21 <- sqrt(1 - partial[[1L]]^2)
  s31 <- sqrt(1 - partial[[2L]]^2)
  s32 <- sqrt(1 - partial[[3L]]^2)
  u <- matrix(stats::rnorm(3L * groups), nrow = 3L)
  b0 <- tau0 * u[1L, ]
  b1 <- tau1 * (partial[[1L]] * u[1L, ] + s21 * u[2L, ])
  b2 <- tau2 * (partial[[2L]] * u[1L, ] +
                  s31 * partial[[3L]] * u[2L, ] + s31 * s32 * u[3L, ])
  y <- stats::rbinom(
    length(id), 1L,
    stats::plogis(-0.1 + 0.2 * x - 0.15 * z + b0[as.integer(id)] +
                    b1[as.integer(id)] * x + b2[as.integer(id)] * z)
  )
  dat <- data.frame(y, x, z, w, h, j, id)
  keys <- c(
    'sd(id, dpar = "mu", coef = "(Intercept)")',
    'sd(id, dpar = "mu", coef = "x")',
    'sd(id, dpar = "mu", coef = "z")'
  )
  formula <- bf(
    y ~ x + z + (1 + x + z | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ h,
    sd(id, dpar = "mu", coef = "z") ~ j
  )

  fit <- drmTMB(formula, family = binomial(), data = dat)

  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_length(fit$corpars$mu, 3L)
  expect_equal(names(fit$corpars$mu), c(
    "cor((Intercept),x | id)", "cor((Intercept),z | id)", "cor(x,z | id)"
  ))
  expect_true(all(vapply(keys, function(key) {
    all(is.finite(coef(fit, key))) && all(predict(fit, dpar = key) > 0)
  }, logical(1L))))
  expect_lt(abs(coef(fit, keys[[1L]])[["w"]] - alpha[[1L]][[2L]]), 0.25)
  expect_lt(abs(coef(fit, keys[[2L]])[["h"]] - alpha[[2L]][[2L]]), 0.25)
  expect_lt(abs(coef(fit, keys[[3L]])[["j"]] - alpha[[3L]][[2L]]), 0.25)
  expect_lt(abs(unname(fit$corpars$mu[[1L]]) - partial[[1L]]), 0.3)
  expect_lt(abs(unname(fit$corpars$mu[[2L]]) - partial[[2L]]), 0.3)
  expected_23 <- partial[[1L]] * partial[[2L]] + s21 * s31 * partial[[3L]]
  expect_lt(abs(unname(fit$corpars$mu[[3L]]) - expected_23), 0.3)

  fitted_sd <- lapply(keys, function(key) coef(fit, key))
  sd_group <- list(
    exp(fitted_sd[[1L]][[1L]] + fitted_sd[[1L]][[2L]] * w_group),
    exp(fitted_sd[[2L]][[1L]] + fitted_sd[[2L]][[2L]] * h_group),
    exp(fitted_sd[[3L]][[1L]] + fitted_sd[[3L]][[2L]] * j_group)
  )
  oracle <- binomial_correlated_q3_gh_loglik(
    dat, coef(fit, "mu"), sd_group, unname(fit$corpars$mu)
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 2)

  re <- fit$model$random$mu
  eta_cor <- as.numeric(fit$obj$env$parList(fit$opt$par)$eta_cor_mu)
  effect_sd <- drm_ordinary_sd_effect_override(fit, re)
  indices <- re$index0[1L, ] + 1L
  draws <- replicate(2000L, {
    drm_fresh_ordinary_random_effect_values(
      re, fit$sdpars$mu, fit$corpars$mu,
      eta_lookup = eta_cor,
      sd_by_effect_override = effect_sd
    )$values[indices]
  })
  covariance <- stats::cov(t(draws))
  expect_equal(
    unname(sqrt(diag(covariance))),
    unname(vapply(keys, function(key) predict(fit, dpar = key)[[1L]], numeric(1L))),
    tolerance = 0.08
  )
  expect_lt(max(abs(
    stats::cov2cor(covariance) - matrix(c(
      1, fit$corpars$mu[[1L]], fit$corpars$mu[[2L]],
      fit$corpars$mu[[1L]], 1, fit$corpars$mu[[3L]],
      fit$corpars$mu[[2L]], fit$corpars$mu[[3L]], 1
    ), nrow = 3L)
  )), 0.08)
})

test_that("correlated binomial SDs form the requested marginal covariance", {
  dat <- binomial_correlated_sd_fixture()
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'
  spec <- drm_build_binomial_spec(bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  ), dat)
  sd_re <- spec$random_scale$mu
  beta_sd <- numeric(ncol(sd_re$X))
  beta_sd[sd_re$coef_index[[key_intercept]]] <- c(log(0.5), 0.25)
  beta_sd[sd_re$coef_index[[key_slope]]] <- c(log(0.3), -0.2)
  par <- list(
    log_sd_mu = c(log(0.5), log(0.8)),
    beta_sd_mu = beta_sd,
    eta_cor_mu = atanh(0.6)
  )
  ids <- spec$random$mu$index0[1L, ] + 1L
  basis_effect <- function(position) {
    z <- numeric(spec$random$mu$n_re)
    z[ids[[position]]] <- 1
    transformed <- transform_mu_random_effects(
      z, par, spec$random$mu, sd_re, tmb_data = spec$tmb_data,
      binomial_q2 = TRUE
    )
    transformed[ids]
  }
  L <- cbind(basis_effect(1L), basis_effect(2L))
  tau0 <- exp(log(0.5) + 0.25 * dat$w[[1L]])
  tau1 <- exp(log(0.3) - 0.2 * dat$v[[1L]])
  rho <- 0.6
  expected <- matrix(
    c(tau0^2, rho * tau0 * tau1,
      rho * tau0 * tau1, tau1^2),
    nrow = 2L
  )
  expect_equal(L[1L, ], c(tau0, 0), tolerance = 1e-10)
  expect_equal(L[2L, ], c(rho * tau1, sqrt(1 - rho^2) * tau1),
               tolerance = 1e-10)
  expect_equal(L %*% t(L), expected, tolerance = 1e-10)

  wrong_static_innovation <- exp(log(0.8) + log(sqrt(1 - rho^2)))
  expect_gt(abs(L[2L, 2L] - wrong_static_innovation), 0.1)
  independent <- diag(c(tau0, tau1))
  expect_gt(abs((L %*% t(L))[1L, 2L] -
                  (independent %*% t(independent))[1L, 2L]), 0.05)
})

test_that("one correlated binomial coefficient can retain a constant SD", {
  dat <- binomial_correlated_sd_fixture()
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'
  cases <- list(
    list(
      formula = bf(
        y ~ x + (1 + x | id),
        sd(id, dpar = "mu", coef = "(Intercept)") ~ w
      ),
      selected = key_intercept,
      selected_coef = 1L,
      static_coef = 2L,
      selected_alpha = c(log(0.5), 0.25),
      selected_x = dat$w[seq_len(nlevels(dat$id))],
      static_log_sd = log(0.8)
    ),
    list(
      formula = bf(
        y ~ x + (1 + x | id),
        sd(id, dpar = "mu", coef = "x") ~ v
      ),
      selected = key_slope,
      selected_coef = 2L,
      static_coef = 1L,
      selected_alpha = c(log(0.3), -0.2),
      selected_x = dat$v[seq_len(nlevels(dat$id))],
      static_log_sd = log(0.5)
    )
  )

  for (case in cases) {
    spec <- drm_build_binomial_spec(case$formula, dat)
    sd_re <- spec$random_scale$mu
    expect_identical(sd_re$dpars, case$selected)
    group_rows <- seq_len(nlevels(dat$id)) - 1L
    expected_rows <- if (case$selected_coef == 1L) {
      c(group_rows, rep(-1L, nlevels(dat$id)))
    } else {
      c(rep(-1L, nlevels(dat$id)), group_rows)
    }
    expect_identical(sd_re$re_sd_row0, expected_rows)
    expect_identical(
      sd_re$target_identity[[case$selected]]$target_coef,
      case$selected_coef
    )

    beta_sd <- numeric(ncol(sd_re$X))
    beta_sd[sd_re$coef_index[[case$selected]]] <- case$selected_alpha
    par <- list(
      log_sd_mu = replace(c(log(0.5), log(0.8)), case$static_coef,
                          case$static_log_sd),
      beta_sd_mu = beta_sd,
      eta_cor_mu = atanh(0.4)
    )
    ids <- spec$random$mu$index0[1L, ] + 1L
    basis_effect <- function(position) {
      z <- numeric(spec$random$mu$n_re)
      z[ids[[position]]] <- 1
      transform_mu_random_effects(
        z, par, spec$random$mu, sd_re, tmb_data = spec$tmb_data,
        binomial_q2 = TRUE
      )[ids]
    }
    L <- cbind(basis_effect(1L), basis_effect(2L))
    selected_tau <- exp(case$selected_alpha[[1L]] +
                          case$selected_alpha[[2L]] * case$selected_x[[1L]])
    static_tau <- exp(case$static_log_sd)
    tau <- if (case$selected_coef == 1L) {
      c(selected_tau, static_tau)
    } else {
      c(static_tau, selected_tau)
    }
    rho <- 0.4
    expected <- matrix(
      c(tau[[1L]]^2, rho * tau[[1L]] * tau[[2L]],
        rho * tau[[1L]] * tau[[2L]], tau[[2L]]^2),
      nrow = 2L
    )
    expect_equal(L %*% t(L), expected, tolerance = 1e-10)
  }
})

test_that("TMB fits correlated binomial blocks with partial SD targets", {
  set.seed(2026101828L)
  groups <- 48L
  repeats <- 24L
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- rep(c(-1, 1), length.out = groups)
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  rho <- 0.35
  b0 <- exp(log(0.5) + 0.3 * w_group) * stats::rnorm(groups)
  b1 <- exp(log(0.3) - 0.4 * v_group) *
    (rho * stats::rnorm(groups) + sqrt(1 - rho^2) * stats::rnorm(groups))
  y <- stats::rbinom(
    length(id), 1L,
    stats::plogis(0.1 + 0.25 * x + b0[as.integer(id)] +
                    b1[as.integer(id)] * x)
  )
  dat <- data.frame(y, x, w, v, id)
  targets <- list(
    list(
      formula = bf(
        y ~ x + (1 + x | id),
        sd(id, dpar = "mu", coef = "(Intercept)") ~ w
      ),
      key = 'sd(id, dpar = "mu", coef = "(Intercept)")',
      coef = "(Intercept)",
      group_predictor = w_group
    ),
    list(
      formula = bf(
        y ~ x + (1 + x | id),
        sd(id, dpar = "mu", coef = "x") ~ v
      ),
      key = 'sd(id, dpar = "mu", coef = "x")',
      coef = "x",
      group_predictor = v_group
    )
  )

  for (target in targets) {
    fit <- drmTMB(target$formula, family = binomial(), data = dat)
    expect_equal(fit$opt$convergence, 0L)
    expect_true(isTRUE(fit$sdr$pdHess))
    expect_true(all(is.finite(coef(fit, target$key))))
    expect_true(all(is.finite(predict(fit, dpar = target$key))))

    # Check each mixed predictor-dependent/constant TMB branch against an
    # independent two-dimensional Gauss-Hermite marginal likelihood.
    sd_coef <- coef(fit, target$key)
    modelled_sd <- exp(sd_coef[[1L]] + sd_coef[[2L]] * target$group_predictor)
    constant_sd <- rep(unname(fit$sdpars$mu[[1L]]), groups)
    if (identical(target$coef, "(Intercept)")) {
      sd_intercept <- modelled_sd
      sd_slope <- constant_sd
    } else {
      sd_intercept <- constant_sd
      sd_slope <- modelled_sd
    }
    oracle <- binomial_correlated_sd_gh_loglik(
      dat,
      coef(fit, "mu"),
      sd_intercept,
      sd_slope,
      unname(fit$corpars$mu[[1L]])
    )
    expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 0.5)

    # Independently check the R-side covariance reconstruction at fitted
    # parameters. The fit above has already exercised the corresponding
    # mixed predictor-dependent/constant branches in the TMB likelihood.
    re <- fit$model$random$mu
    raw_par <- selected_tmb_par_list(fit)
    effect_sd <- drm_ordinary_sd_effect_override(fit, re)
    indices <- re$index0[1L, ] + 1L
    draws <- replicate(1200L, {
      drm_fresh_ordinary_random_effect_values(
        re, fit$sdpars$mu, fit$corpars$mu,
        eta_lookup = unname(raw_par$eta_cor_mu),
        sd_by_effect_override = effect_sd
      )$values[indices]
    })
    covariance <- stats::cov(t(draws))
    tau <- sqrt(diag(covariance))
    expect_true(all(is.finite(covariance)))
    expect_gt(tau[[1L]], 0)
    expect_gt(tau[[2L]], 0)
    expect_equal(
      stats::cov2cor(covariance)[1L, 2L],
      unname(fit$corpars$mu[[1L]]),
      tolerance = 0.12
    )
  }
})

test_that("Bernoulli q2 SD regression fits, predicts, simulates, and refits", {
  set.seed(2026101819L)
  groups <- 64L
  repeats <- 32L
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- rep(c(-1, 1), length.out = groups)
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  tau0 <- exp(log(0.55) + 0.4 * w_group)
  tau1 <- exp(log(0.32) - 0.6 * v_group)
  rho <- 0.4
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  b0 <- tau0 * z0
  b1 <- tau1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  y <- stats::rbinom(
    length(id), 1L,
    stats::plogis(-0.15 + 0.3 * x + b0[as.integer(id)] +
                    b1[as.integer(id)] * x)
  )
  dat <- data.frame(y, x, w, v, id)
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'
  formula <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  )
  fit <- drmTMB(formula, family = binomial(), data = dat)

  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_true(all(is.finite(c(coef(fit, key_intercept), coef(fit, key_slope),
                              fit$corpars$mu))))
  expect_lt(abs(coef(fit, key_intercept)[["w"]] - 0.4), 0.5)
  expect_lt(abs(coef(fit, key_slope)[["v"]] + 0.6), 0.5)
  expect_lt(abs(unname(fit$corpars$mu[[1L]]) - rho), 0.45)
  expect_true(all(predict(fit, dpar = key_intercept) > 0))
  expect_true(all(predict(fit, dpar = key_slope) > 0))
  grid <- data.frame(w = c(-0.5, 0, 0.5), v = c(0.5, 0, -0.5))
  expect_true(all(predict(fit, dpar = key_intercept, newdata = grid) > 0))
  expect_true(all(predict(fit, dpar = key_slope, newdata = grid) > 0))

  re <- fit$model$random$mu
  raw_par <- selected_tmb_par_list(fit)
  effect_sd <- drm_ordinary_sd_effect_override(fit, re)
  first_group_indices <- re$index0[1L, ] + 1L
  fresh_effects <- replicate(500L, {
    drm_fresh_ordinary_random_effect_values(
      re, fit$sdpars$mu, fit$corpars$mu,
      eta_lookup = unname(raw_par$eta_cor_mu),
      sd_by_effect_override = effect_sd
    )$values[first_group_indices]
  })
  fresh_covariance <- stats::cov(t(fresh_effects))
  fresh_correlation <- stats::cov2cor(fresh_covariance)[1L, 2L]
  expect_equal(
    fresh_correlation,
    unname(fit$corpars$mu[[1L]]),
    tolerance = 0.15
  )
  expect_equal(
    diag(fresh_covariance) / c(
      predict(fit, dpar = key_intercept)[[1L]]^2,
      predict(fit, dpar = key_slope)[[1L]]^2
    ),
    c(1, 1),
    tolerance = 0.2
  )

  simulated <- stats::simulate(fit, nsim = 1L, seed = 2026101820L)
  expect_equal(length(simulated[[1L]]), nrow(dat))
  expect_true(all(simulated[[1L]] %in% c(0, 1)))
  refit_data <- dat
  refit_data$y <- simulated[[1L]]
  refit <- drmTMB(formula, family = binomial(), data = refit_data)
  expect_equal(refit$opt$convergence, 0L)
  expect_true(isTRUE(refit$sdr$pdHess))

  save_path <- tempfile(fileext = ".rds")
  saveRDS(fit, save_path)
  restored <- readRDS(save_path)
  expect_equal(predict(restored, dpar = key_intercept),
               predict(fit, dpar = key_intercept))
  expect_equal(predict(restored, dpar = key_slope),
               predict(fit, dpar = key_slope))

  beta0 <- coef(fit, "mu")
  alpha0 <- coef(fit, key_intercept)
  alpha1 <- coef(fit, key_slope)
  rho_hat <- unname(fit$corpars$mu[[1L]])
  oracle <- binomial_correlated_sd_gh_loglik(
    dat,
    beta0,
    exp(alpha0[[1L]] + alpha0[[2L]] * w_group),
    exp(alpha1[[1L]] + alpha1[[2L]] * v_group),
    rho_hat
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 0.5)

  constant_formula <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ 1
  )
  constant <- drmTMB(constant_formula, family = binomial(), data = dat)
  ordinary <- drmTMB(bf(y ~ x + (1 + x | id)), family = binomial(), data = dat)
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)
})

test_that("correlated binomial SD regression respects probit and cloglog links", {
  set.seed(20261019L)
  groups <- 160L
  repeats <- 32L
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- rep(c(-1, 1), length.out = groups)
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  rho <- 0.5
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  b0 <- exp(log(0.5) + 0.65 * w_group) * z0
  b1 <- exp(log(0.3) - 0.5 * v_group) *
    (rho * z0 + sqrt(1 - rho^2) * z1)
  eta <- 0.1 + 0.25 * x + b0[as.integer(id)] + b1[as.integer(id)] * x
  grid <- data.frame(w = w_group, v = v_group)
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'
  formula <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  )

  for (link in c("probit", "cloglog")) {
    set.seed(20261020L + match(link, c("probit", "cloglog")))
    probability <- switch(
      link,
      probit = stats::pnorm(eta),
      cloglog = -expm1(-exp(eta))
    )
    dat <- data.frame(y = stats::rbinom(length(id), 1L, probability), x, w, v, id)
    fit <- drmTMB(formula, family = stats::binomial(link = link), data = dat)

    expect_equal(fit$opt$convergence, 0L, info = link)
    expect_true(isTRUE(fit$sdr$pdHess), info = link)
    expect_true(all(is.finite(c(
      coef(fit, key_intercept), coef(fit, key_slope), fit$corpars$mu
    ))), info = link)
    intercept_slope <- unname(coef(fit, key_intercept)[["w"]])
    random_slope_slope <- unname(coef(fit, key_slope)[["v"]])
    correlation <- unname(fit$corpars$mu[[1L]])
    expect_true(intercept_slope > 0,
                info = paste(link, "intercept SD direction"))
    expect_true(abs(intercept_slope - 0.65) < 0.15,
                info = paste(link, "intercept SD recovery"))
    expect_true(random_slope_slope < 0,
                info = paste(link, "random-slope SD direction"))
    expect_true(abs(random_slope_slope + 0.5) < 0.15,
                info = paste(link, "random-slope SD recovery"))
    expect_true(correlation > 0.25,
                info = paste(link, "nonzero correlation"))
    expect_true(abs(correlation - rho) < 0.2,
                info = paste(link, "correlation recovery"))
    expect_true(all(is.finite(predict(fit, dpar = key_intercept, newdata = grid))),
                info = link)
    expect_true(all(is.finite(predict(fit, dpar = key_slope, newdata = grid))),
                info = link)

    oracle <- binomial_correlated_sd_gh_loglik(
      dat,
      coef(fit, "mu"),
      predict(fit, dpar = key_intercept, newdata = grid),
      predict(fit, dpar = key_slope, newdata = grid),
      unname(fit$corpars$mu[[1L]]),
      link = link
    )
    expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 0.5,
                 info = paste(link, "independent Gauss-Hermite oracle"))
  }
})

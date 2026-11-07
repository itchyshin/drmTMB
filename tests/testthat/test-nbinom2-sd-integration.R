nbinom2_sd_recovery_fixture <- function(groups = 72L, repeats = 10L,
                                        seed = 2026101729L,
                                        alpha = c(`(Intercept)` = log(0.48),
                                                  w = 0.4),
                                        sigma = 0.28) {
  set.seed(seed)
  group_index <- rep(seq_len(groups), each = repeats)
  group_names <- paste0("g", seq_len(groups))
  w_group <- seq(-1, 1, length.out = groups)
  x <- stats::rnorm(length(group_index))
  tau_group <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  u <- stats::setNames(stats::rnorm(groups), group_names)
  eta <- 0.35 + 0.25 * x + tau_group[group_index] * u[group_index]
  y <- stats::rnbinom(
    length(eta),
    size = 1 / sigma^2,
    mu = exp(eta)
  )
  list(
    data = data.frame(
      y = y,
      x = x,
      w = w_group[group_index],
      id = factor(group_names[group_index], levels = group_names)
    ),
    alpha = alpha,
    sigma = sigma,
    tau_group = tau_group
  )
}

nbinom2_sd_scalar_laplace_log_marginal <- function(y, eta, sigma, tau) {
  size <- 1 / sigma^2
  nll <- function(b) {
    -sum(stats::dnbinom(
      y,
      size = size,
      mu = exp(eta + b),
      log = TRUE
    )) - stats::dnorm(b, mean = 0, sd = tau, log = TRUE)
  }
  mode <- stats::optimize(nll, interval = c(-10, 10), tol = 1e-11)$minimum
  mu <- exp(eta + mode)
  curvature <- 1 / tau^2 + sum((y + size) * size * mu / (size + mu)^2)
  -nll(mode) - 0.5 * log(curvature) + 0.5 * log(2 * pi)
}

nbinom2_sd_laplace_oracle <- function(data, beta_mu, alpha, log_sigma) {
  rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows, function(i) {
    w <- data$w[i[[1L]]]
    tau <- exp(alpha[[1L]] + alpha[[2L]] * w)
    eta <- beta_mu[[1L]] + beta_mu[["x"]] * data$x[i]
    nbinom2_sd_scalar_laplace_log_marginal(
      data$y[i], eta, exp(log_sigma[[1L]]), tau
    )
  }, numeric(1L)))
}

test_that("NB2 ordinary intercept SD fit matches a groupwise Laplace oracle", {
  sim <- nbinom2_sd_recovery_fixture()
  fit <- drmTMB::drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = nbinom2(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-3)
  alpha_hat <- stats::coef(fit, "sd(id)")
  expect_named(alpha_hat, c("(Intercept)", "w"))
  sd_labels <- paste0("sd(id):", names(alpha_hat))
  sd_vcov <- stats::vcov(fit)[sd_labels, sd_labels, drop = FALSE]
  expect_true(all(is.finite(diag(sd_vcov)) & diag(sd_vcov) > 0))
  sd_summary <- summary(fit)$coefficients[sd_labels, , drop = FALSE]
  expect_true(all(is.finite(sd_summary$std_error) &
                  sd_summary$std_error > 0))
  expect_lt(abs(alpha_hat[["(Intercept)"]] - sim$alpha[[1L]]), 0.3)
  expect_lt(abs(alpha_hat[["w"]] - sim$alpha[[2L]]), 0.5)

  sd_prediction <- stats::predict(fit, dpar = "sd(id)")
  expect_named(sd_prediction, levels(sim$data$id))
  expect_equal(
    unname(sd_prediction),
    unname(exp(alpha_hat[[1L]] + alpha_hat[[2L]] * seq(-1, 1,
                                                       length.out = nlevels(sim$data$id)))),
    tolerance = 1e-7
  )
  oracle <- nbinom2_sd_laplace_oracle(
    sim$data,
    stats::coef(fit, "mu"),
    alpha_hat,
    stats::coef(fit, "sigma")
  )
  expect_equal(as.numeric(stats::logLik(fit)), oracle, tolerance = 1e-5)
  expect_named(fit$sdpars, "sd(id)")
  expect_equal(unname(fit$sdpars[["sd(id)"]]),
               unname(sd_prediction), tolerance = 1e-7)
  prediction_table <- predict_parameters(
    fit,
    dpar = "sd(id)",
    include_newdata = FALSE
  )
  expect_identical(prediction_table$row_label, levels(sim$data$id))
  expect_equal(prediction_table$estimate, unname(sd_prediction))

  stored_path <- tempfile(fileext = ".rds")
  on.exit(unlink(stored_path), add = TRUE)
  saveRDS(fit, stored_path)
  restored <- readRDS(stored_path)
  expect_equal(stats::coef(restored, "sd(id)"), alpha_hat)
  expect_equal(stats::predict(restored, dpar = "sd(id)"), sd_prediction)

  simulated <- stats::simulate(fit, nsim = 2L, seed = 2026101731L)
  expect_equal(dim(simulated), c(nrow(sim$data), 2L))
  expect_true(all(is.finite(as.matrix(simulated)) &
                  as.matrix(simulated) >= 0))

  selected_groups <- levels(sim$data$id)[c(1L, nlevels(sim$data$id))]
  selected_rows <- match(selected_groups, as.character(sim$data$id))
  set.seed(2026101732L)
  fresh_mu_draws <- replicate(800L, {
    fresh <- drm_ordinary_random_effect_draws(fit)$mu
    fresh[selected_rows]
  })
  empirical_variance_ratio <- stats::var(fresh_mu_draws[2L, ]) /
    stats::var(fresh_mu_draws[1L, ])
  expected_variance_ratio <-
    (sd_prediction[[selected_groups[[2L]]]] /
       sd_prediction[[selected_groups[[1L]]]])^2
  expect_equal(empirical_variance_ratio, expected_variance_ratio,
               tolerance = 0.18)

  target <- "fixef:sd(id):w"
  profile_ci <- suppressMessages(stats::confint(
    fit, parm = target, method = "profile", level = 0.95
  ))
  expect_identical(profile_ci$parm, target)
  expect_true(all(is.finite(c(profile_ci$lower, profile_ci$upper))))

  boot_ci <- suppressMessages(stats::confint(
    fit, parm = target, method = "bootstrap", R = 2L,
    seed = 2026101733L
  ))
  expect_true(all(is.finite(as.matrix(boot_ci))))
  boot_diagnostics <- attr(boot_ci, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(boot_diagnostics), 2L)
  expect_true(any(boot_diagnostics$refit_status == "ok"))
})

test_that("NB2 independent-slope SD recovers and matches a groupwise Laplace oracle", {
  sim <- nbinom2_sd_slope_fixture()
  fit <- drmTMB::drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id) ~ w),
    family = nbinom2(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-3)
  alpha_hat <- stats::coef(fit, "sd(id)")
  expect_named(alpha_hat, c("(Intercept)", "w"))
  expect_identical(sign(alpha_hat[["w"]]), sign(sim$alpha[["w"]]))
  expect_lt(abs(alpha_hat[["(Intercept)"]] - sim$alpha[["(Intercept)"]]), 0.35)
  expect_lt(abs(alpha_hat[["w"]] - sim$alpha[["w"]]), 0.5)

  sd_prediction <- stats::predict(fit, dpar = "sd(id)")
  expect_named(sd_prediction, levels(sim$data$id))
  expect_equal(
    unname(sd_prediction),
    unname(exp(alpha_hat[["(Intercept)"]] + alpha_hat[["w"]] * sim$w_group)),
    tolerance = 1e-7
  )
  oracle <- nbinom2_sd_slope_laplace_oracle(
    sim$data,
    stats::coef(fit, "mu"),
    alpha_hat,
    stats::coef(fit, "sigma")
  )
  expect_equal(as.numeric(stats::logLik(fit)), oracle, tolerance = 1e-5)
  wrong_loading <- nbinom2_sd_slope_laplace_oracle(
    sim$data,
    stats::coef(fit, "mu"),
    alpha_hat,
    stats::coef(fit, "sigma"),
    wrong_loading = TRUE
  )
  expect_gt(abs(as.numeric(stats::logLik(fit)) - wrong_loading), 0.01)
  expect_equal(unname(fit$sdpars[["sd(id)"]]), unname(sd_prediction),
               tolerance = 1e-7)

  prediction_table <- predict_parameters(
    fit,
    dpar = "sd(id)",
    include_newdata = FALSE
  )
  expect_identical(prediction_table$row_label, levels(sim$data$id))
  expect_equal(prediction_table$estimate, unname(sd_prediction))

  stored_path <- tempfile(fileext = ".rds")
  on.exit(unlink(stored_path), add = TRUE)
  saveRDS(fit, stored_path)
  restored <- readRDS(stored_path)
  expect_equal(stats::coef(restored, "sd(id)"), alpha_hat)
  expect_equal(stats::predict(restored, dpar = "sd(id)"), sd_prediction)

  simulated <- stats::simulate(fit, nsim = 2L, seed = 2026101822L)
  expect_equal(dim(simulated), c(nrow(sim$data), 2L))
  expect_true(all(is.finite(as.matrix(simulated)) &
                  as.matrix(simulated) >= 0))

  target <- "fixef:sd(id):w"
  profile_ci <- suppressMessages(stats::confint(
    fit, parm = target, method = "profile", level = 0.95
  ))
  expect_identical(profile_ci$parm, target)
  expect_true(all(is.finite(c(profile_ci$lower, profile_ci$upper))))

  boot_ci <- suppressMessages(stats::confint(
    fit, parm = target, method = "bootstrap", R = 2L,
    seed = 2026101823L
  ))
  expect_true(all(is.finite(as.matrix(boot_ci))))
  boot_diagnostics <- attr(boot_ci, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(boot_diagnostics), 2L)
  expect_true(any(boot_diagnostics$refit_status == "ok"))
})

test_that("constant NB2 SD formula retains the ordinary random-intercept likelihood", {
  sim <- nbinom2_sd_recovery_fixture(
    groups = 32L,
    repeats = 8L,
    seed = 2026101730L,
    alpha = c(`(Intercept)` = log(0.5), w = 0)
  )
  ordinary <- drmTMB::drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = nbinom2(),
    data = sim$data
  )
  scaled <- drmTMB::drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ 1),
    family = nbinom2(),
    data = sim$data
  )

  expect_equal(ordinary$opt$convergence, 0L)
  expect_equal(scaled$opt$convergence, 0L)
  expect_true(isTRUE(ordinary$sdr$pdHess))
  expect_true(isTRUE(scaled$sdr$pdHess))
  expect_equal(as.numeric(stats::logLik(scaled)),
               as.numeric(stats::logLik(ordinary)), tolerance = 1e-5)
  expect_equal(
    unname(stats::predict(scaled, dpar = "sd(id)")),
    rep(unname(ordinary$sdpars$mu[["(1 | id)"]]), nlevels(sim$data$id)),
    tolerance = 1e-5
  )
})

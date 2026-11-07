gamma_sd_recovery_data <- function(groups = 48L, repeats = 9L,
                                   slope = 0.45, seed = 20261024L) {
  set.seed(seed)
  id_index <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- stats::rnorm(length(id_index))
  group_sd <- exp(-0.55 + slope * w_group)
  b <- stats::rnorm(groups, sd = group_sd)
  mu <- exp(0.2 + 0.3 * x + b[id_index])
  cv <- 0.4
  y <- stats::rgamma(length(mu), shape = 1 / cv^2, scale = mu * cv^2)
  list(
    data = data.frame(y, x, w, id = factor(id_index)),
    slope = slope,
    w_group = w_group,
    group_sd = group_sd
  )
}

gamma_sd_scalar_laplace_log_marginal <- function(y, eta, cv, tau) {
  shape <- 1 / cv^2
  nll <- function(b) {
    -sum(stats::dgamma(
      y,
      shape = shape,
      scale = exp(eta + b) * cv^2,
      log = TRUE
    )) - stats::dnorm(b, mean = 0, sd = tau, log = TRUE)
  }
  mode <- stats::optimize(nll, interval = c(-10, 10), tol = 1e-11)$minimum
  mu <- exp(eta + mode)
  curvature <- 1 / tau^2 + sum(y / (mu * cv^2))
  -nll(mode) - 0.5 * log(curvature) + 0.5 * log(2 * pi)
}

gamma_sd_laplace_oracle <- function(data, beta_mu, alpha, log_sigma) {
  rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows, function(i) {
    w <- data$w[i[[1L]]]
    tau <- exp(alpha[[1L]] + alpha[[2L]] * w)
    eta <- beta_mu[[1L]] + beta_mu[["x"]] * data$x[i]
    gamma_sd_scalar_laplace_log_marginal(
      data$y[i], eta, exp(log_sigma[[1L]]), tau
    )
  }, numeric(1L)))
}

test_that("Gamma SD regression recovers a synthetic group-scale trend", {
  sim <- gamma_sd_recovery_data()
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = Gamma(link = "log"),
    data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )

  estimate <- stats::coef(fit, dpar = "sd(id)")[["w"]]
  vc <- stats::vcov(fit)
  label <- grep("w$", colnames(vc), value = TRUE)
  expect_length(label, 1L)
  se <- sqrt(vc[label, label])
  expect_true(is_converged(fit))
  expect_true(is.finite(se) && se > 0)
  expect_lt(abs(estimate - sim$slope), 2.5 * se)
  oracle <- gamma_sd_laplace_oracle(
    sim$data,
    stats::coef(fit, dpar = "mu"),
    stats::coef(fit, dpar = "sd(id)"),
    stats::coef(fit, dpar = "sigma")
  )
  expect_equal(as.numeric(stats::logLik(fit)), oracle, tolerance = 1e-5)
  expect_identical(fit$model$random_scale$mu$target_identity[["sd(id)"]]$group,
                   "id")
  predicted <- predict(fit, dpar = "sd(id)")
  expect_equal(length(predicted), length(sim$w_group))
  expect_true(all(is.finite(predicted) & predicted > 0))
  expect_gt(predicted[[length(predicted)]], predicted[[1L]])
  expect_equal(nrow(simulate(fit, nsim = 1L, seed = 20261025L)),
               nrow(sim$data))
  restored_path <- tempfile(fileext = ".rds")
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_identical(
    restored$model$random_scale$mu$target_identity[["sd(id)"]]$group,
    "id"
  )
  expect_equal(predict(restored, dpar = "sd(id)"), predicted)
  unlink(restored_path)
})

test_that("constant Gamma SD formula matches the existing constant-SD model", {
  sim <- gamma_sd_recovery_data(groups = 36L, repeats = 8L,
                                slope = 0, seed = 20261026L)
  ordinary <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = Gamma(link = "log"), data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )
  scaled <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ 1),
    family = Gamma(link = "log"), data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )

  expect_equal(ordinary$opt$convergence, 0L)
  expect_true(is_converged(scaled))
  expect_equal(as.numeric(logLik(scaled)), as.numeric(logLik(ordinary)),
               tolerance = 1e-5)
  expect_equal(
    unname(predict(scaled, dpar = "sd(id)")),
    rep(unname(ordinary$sdpars$mu[["(1 | id)"]]), length(sim$w_group)),
    tolerance = 1e-5
  )
})

test_that("Gamma SD regression recovers an independent random-slope scale trend", {
  set.seed(20261027L)
  groups <- 100L
  repeats <- 16L
  id_index <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- stats::rnorm(length(id_index))
  slope_truth <- 0.35
  group_sd <- exp(-0.45 + slope_truth * w_group)
  b <- stats::rnorm(groups, sd = group_sd)
  mu <- exp(0.2 + b[id_index] * x)
  cv <- 0.35
  y <- stats::rgamma(length(mu), shape = 1 / cv^2, scale = mu * cv^2)
  dat <- data.frame(y, x, w, id = factor(id_index))

  fit <- drmTMB(
    bf(y ~ 1 + (0 + x | id), sigma ~ 1, sd(id) ~ w),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(optimizer_preset = "careful")
  )

  estimate <- stats::coef(fit, dpar = "sd(id)")[["w"]]
  vc <- stats::vcov(fit)
  label <- grep("w$", colnames(vc), value = TRUE)
  expect_length(label, 1L)
  se <- sqrt(vc[label, label])
  expect_true(is_converged(fit))
  expect_true(is.finite(se) && se > 0)
  expect_lt(abs(estimate - slope_truth), 2.5 * se)
  expect_identical(
    fit$model$random_scale$mu$target_identity[["sd(id)"]]$coef,
    "x"
  )
  predicted <- predict(fit, dpar = "sd(id)")
  expect_length(predicted, groups)
  expect_gt(predicted[[groups]], predicted[[1L]])
})

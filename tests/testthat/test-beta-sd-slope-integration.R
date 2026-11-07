beta_sd_slope_dgp <- function(groups = 160L, repeats = 60L, seed = 20261018L) {
  set.seed(seed)
  z_group <- seq(-1, 1, length.out = groups)
  slope_sd <- exp(log(0.3) + 0.28 * z_group)
  b_group <- stats::rnorm(groups, sd = slope_sd)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(c(-1, 0, 1), length.out = groups * repeats)
  z <- z_group[as.integer(id)]
  mu <- stats::plogis(-0.2 + 0.25 * x + b_group[as.integer(id)] * x)
  sigma <- 0.38
  precision <- 1 / sigma^2
  y <- stats::rbeta(length(mu), mu * precision, (1 - mu) * precision)
  list(
    data = data.frame(y, x, z, id),
    truth = c("(Intercept)" = log(0.3), z = 0.28),
    group_z = z_group
  )
}

beta_sd_slope_marginal_loglik <- function(fit, data, reverse_sd = FALSE) {
  beta_mu <- stats::coef(fit, "mu")
  beta_sigma <- stats::coef(fit, "sigma")
  beta_sd <- stats::coef(fit, 'sd(id, coef = "x")')
  fixed_design <- stats::model.matrix(~ x, data = data)
  eta_fixed <- as.vector(fixed_design[, names(beta_mu), drop = FALSE] %*% beta_mu)
  group_levels <- levels(data$id)
  group_rows <- split(seq_len(nrow(data)), data$id)[group_levels]
  sd_data <- unique(data[c("id", "z")])
  sd_design <- stats::model.matrix(~ z, data = sd_data)
  sd_design <- sd_design[match(group_levels, as.character(sd_data$id)), , drop = FALSE]
  group_sd <- exp(as.vector(sd_design %*% beta_sd))
  if (reverse_sd) group_sd <- rev(group_sd)
  precision <- exp(-2 * unname(beta_sigma[["(Intercept)"]]))

  sum(vapply(seq_along(group_levels), function(g) {
    rows <- group_rows[[g]]
    log_integrand <- function(u) {
      mu <- stats::plogis(eta_fixed[rows] + group_sd[[g]] * u * data$x[rows])
      sum(stats::dbeta(data$y[rows], mu * precision,
                       (1 - mu) * precision, log = TRUE)) +
        stats::dnorm(u, log = TRUE)
    }
    peak <- stats::optimize(log_integrand, interval = c(-8, 8),
                            maximum = TRUE)$objective
    integral <- stats::integrate(
      function(u) exp(vapply(u, log_integrand, numeric(1)) - peak),
      lower = -8, upper = 8, rel.tol = 1e-9, subdivisions = 300L
    )$value
    peak + log(integral)
  }, numeric(1)))
}

test_that("Beta slope SD likelihood matches independent quadrature", {
  sim <- beta_sd_slope_dgp(groups = 72L, repeats = 24L, seed = 202610201L)
  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id, coef = "x") ~ z),
    family = beta_family(), data = sim$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  oracle <- beta_sd_slope_marginal_loglik(fit, sim$data)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle) / nlevels(sim$data$id), 0.05)
  reversed <- beta_sd_slope_marginal_loglik(fit, sim$data, reverse_sd = TRUE)
  expect_gt(abs(oracle - reversed), 0.5)
})

test_that("Beta random-slope SD regression recovers and predicts the SD surface", {
  sim <- beta_sd_slope_dgp()
  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id, coef = "x") ~ z),
    family = beta_family(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  estimate <- coef(fit, dpar = 'sd(id, coef = "x")')
  expect_named(estimate, names(sim$truth))
  expect_equal(unname(estimate), unname(sim$truth), tolerance = 0.15)
  expect_true(all(is.finite(vcov(fit, dpar = 'sd(id, coef = "x")'))))
  expect_equal(
    unname(predict(fit, dpar = 'sd(id, coef = "x")')),
    unname(exp(sim$truth[[1L]] + sim$truth[[2L]] * sim$group_z)),
    tolerance = 0.08
  )

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  expect_equal(
    predict(readRDS(path), dpar = 'sd(id, coef = "x")'),
    predict(fit, dpar = 'sd(id, coef = "x")')
  )
})

test_that("constant Beta random-slope SD matches the legacy fit", {
  sim <- beta_sd_slope_dgp(groups = 28L, repeats = 12L, seed = 20261019L)
  legacy <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1),
    family = beta_family(), data = sim$data
  )
  constant <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1,
       sd(id, coef = "x") ~ 1),
    family = beta_family(), data = sim$data
  )

  expect_equal(legacy$opt$convergence, 0)
  expect_equal(constant$opt$convergence, 0)
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(legacy)),
               tolerance = 1e-5)
})

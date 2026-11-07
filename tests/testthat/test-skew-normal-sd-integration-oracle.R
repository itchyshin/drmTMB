skew_normal_sd_group_marginal_loglik <- function(fit, data,
                                                  reverse_sd = FALSE) {
  beta_mu <- stats::coef(fit, "mu")
  beta_sigma <- stats::coef(fit, "sigma")
  beta_nu <- stats::coef(fit, "nu")
  beta_sd <- stats::coef(fit, "sd(id)")
  fixed_design <- stats::model.matrix(~ x, data = data)
  eta_fixed <- as.vector(fixed_design[, names(beta_mu), drop = FALSE] %*% beta_mu)
  group_levels <- levels(data$id)
  group_rows <- split(seq_len(nrow(data)), data$id)[group_levels]
  sd_data <- unique(data[c("id", "w")])
  sd_design <- stats::model.matrix(~ w, data = sd_data)
  sd_design <- sd_design[match(group_levels, as.character(sd_data$id)), , drop = FALSE]
  group_sd <- exp(as.vector(sd_design %*% beta_sd))
  if (reverse_sd) group_sd <- rev(group_sd)
  sigma <- exp(unname(beta_sigma[["(Intercept)"]]))
  nu <- unname(beta_nu[["(Intercept)"]])

  sum(vapply(seq_along(group_levels), function(g) {
    rows <- group_rows[[g]]
    log_integrand <- function(u) {
      mu <- eta_fixed[rows] + group_sd[[g]] * u
      sum(skew_normal_log_density_reference(
        y = data$y[rows], mu = mu, sigma = sigma, nu = nu
      )) + stats::dnorm(u, log = TRUE)
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

test_that("skew-normal intercept SD likelihood matches independent quadrature", {
  set.seed(2026102011L)
  groups <- 48L
  repeats <- 9L
  id <- factor(rep(seq_len(groups), each = repeats))
  w_group <- seq(-1, 1, length.out = groups)
  w <- rep(w_group, each = repeats)
  x <- stats::rnorm(groups * repeats)
  group_sd <- exp(-0.55 + 0.45 * w_group)
  b <- stats::rnorm(groups, sd = group_sd)
  mu <- 0.25 + 0.3 * x + b[as.integer(id)]
  sigma <- rep(0.7, length(mu))
  nu <- rep(1.1, length(mu))
  native <- skew_normal_public_to_native(mu, sigma, nu)
  y <- native$xi + native$omega * (
    native$delta * abs(stats::rnorm(length(mu))) +
      sqrt(1 - native$delta^2) * stats::rnorm(length(mu))
  )
  dat <- data.frame(y, x, w, id)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w),
    family = skew_normal(), data = dat,
    control = drm_control(optimizer_preset = "careful", se = FALSE)
  )

  expect_true(is_converged(fit))
  oracle <- skew_normal_sd_group_marginal_loglik(fit, dat)
  expect_lt(abs(as.numeric(stats::logLik(fit)) - oracle) / groups, 0.05)
  reversed <- skew_normal_sd_group_marginal_loglik(fit, dat, reverse_sd = TRUE)
  expect_gt(abs(oracle - reversed), 0.5)
})

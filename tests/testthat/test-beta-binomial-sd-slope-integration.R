new_beta_binomial_sd_slope_integration_data <- function(
  groups = 72L,
  repeats = 18L,
  seed = 202610207L
) {
  set.seed(seed)
  group <- factor(rep(seq_len(groups), each = repeats))
  w_group <- seq(-1, 1, length.out = groups)
  w <- rep(w_group, each = repeats)
  x <- stats::rnorm(length(group))
  slope_sd <- exp(log(0.35) + 0.4 * w_group)
  slope <- stats::rnorm(groups, sd = slope_sd)
  mu <- stats::plogis(-0.1 + 0.55 * x + slope[as.integer(group)] * x)
  trials <- rep(12L, length(group))
  sigma <- 0.22
  precision <- 1 / sigma^2
  probability <- stats::rbeta(
    length(group),
    shape1 = mu * precision,
    shape2 = (1 - mu) * precision
  )
  success <- stats::rbinom(length(group), size = trials, prob = probability)
  data.frame(success, failure = trials - success, x, w, group)
}

beta_binomial_sd_slope_marginal_loglik <- function(
  fit,
  data,
  reverse_sd = FALSE
) {
  beta_mu <- stats::coef(fit, "mu")
  beta_sigma <- stats::coef(fit, "sigma")
  beta_sd <- stats::coef(fit, dpar = "sd(group, coef = \"x\")")
  fixed_design <- stats::model.matrix(~ x, data = data)
  fixed_design <- fixed_design[, names(beta_mu), drop = FALSE]
  eta_fixed <- as.vector(fixed_design %*% beta_mu)
  group_levels <- levels(data$group)
  group_rows <- split(seq_len(nrow(data)), data$group)
  group_rows <- group_rows[group_levels]
  sd_data <- unique(data[c("group", "w")])
  sd_design <- stats::model.matrix(~ w, data = sd_data)
  sd_design <- sd_design[match(group_levels, as.character(sd_data$group)), ,
                         drop = FALSE]
  group_sd <- exp(as.vector(sd_design %*% beta_sd))
  if (reverse_sd) group_sd <- rev(group_sd)
  precision <- exp(-2 * unname(beta_sigma[["(Intercept)"]]))

  sum(vapply(seq_along(group_levels), function(g) {
    rows <- group_rows[[g]]
    log_integrand <- function(u) {
      probability <- stats::plogis(
        eta_fixed[rows] + group_sd[[g]] * u * data$x[rows]
      )
      success <- data$success[rows]
      trials <- success + data$failure[rows]
      alpha <- probability * precision
      beta <- (1 - probability) * precision
      log_likelihood <- sum(
        lgamma(trials + 1) - lgamma(success + 1) -
          lgamma(trials - success + 1) +
          lbeta(success + alpha, trials - success + beta) -
          lbeta(alpha, beta)
      )
      log_likelihood + stats::dnorm(u, log = TRUE)
    }
    peak <- stats::optimize(
      log_integrand, interval = c(-8, 8), maximum = TRUE
    )$objective
    integrated <- stats::integrate(
      function(u) exp(vapply(u, log_integrand, numeric(1)) - peak),
      lower = -8,
      upper = 8,
      rel.tol = 1e-9,
      subdivisions = 300L
    )$value
    peak + log(integrated)
  }, numeric(1)))
}

test_that("beta-binomial slope SD likelihood matches independent quadrature", {
  dat <- new_beta_binomial_sd_slope_integration_data()
  fit <- drmTMB(
    bf(
      cbind(success, failure) ~ 1 + x + (0 + x | group),
      sigma ~ 1,
      sd(group, coef = "x") ~ w
    ),
    family = beta_binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_true(is_converged(fit))
  oracle_loglik <- beta_binomial_sd_slope_marginal_loglik(fit, dat)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle_loglik) / nlevels(dat$group), 0.05)
  reversed_loglik <- beta_binomial_sd_slope_marginal_loglik(
    fit, dat, reverse_sd = TRUE
  )
  expect_gt(abs(oracle_loglik - reversed_loglik), 0.5)
})

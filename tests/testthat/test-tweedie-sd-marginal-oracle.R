tweedie_sd_oracle_data <- function(groups = 36L, repeats = 12L,
                                  slope = 0.45, seed = 20261029L) {
  set.seed(seed)
  id_index <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- stats::rnorm(length(id_index))
  group_sd <- exp(-0.6 + slope * w_group)
  b <- stats::rnorm(groups, sd = group_sd)
  mu <- exp(0.25 + 0.25 * x + b[id_index])
  sigma <- 0.55
  power <- 1.5
  y <- drmTMB:::rtweedie_compound(
    length(mu), mu = mu, phi = sigma^2, power = power
  )
  data.frame(y, x, w, id = factor(id_index))
}

tweedie_sd_marginal_oracle_loglik <- function(fit, data,
                                              reverse_sd = FALSE,
                                              max_terms = 1200L) {
  beta_mu <- stats::coef(fit, dpar = "mu")
  beta_sd <- stats::coef(fit, dpar = "sd(id)")
  sigma <- as.numeric(stats::predict(fit, dpar = "sigma"))[[1L]]
  power <- as.numeric(stats::predict(fit, dpar = "nu"))[[1L]]
  phi <- sigma^2
  group_w <- vapply(levels(data$id), function(level) {
    unique(data$w[data$id == level])[[1L]]
  }, numeric(1L))
  tau <- exp(beta_sd[["(Intercept)"]] + beta_sd[["w"]] * group_w)
  if (reverse_sd) tau <- rev(tau)
  groups <- split(seq_len(nrow(data)), data$id, drop = TRUE)

  vapply(seq_along(groups), function(g) {
    index <- groups[[g]]
    eta_fixed <- beta_mu[["(Intercept)"]] + beta_mu[["x"]] * data$x[index]
    log_integrand <- function(u) {
      mu <- exp(eta_fixed + tau[[g]] * u)
      sum(tweedie_compound_log_density_reference(
        y = data$y[index],
        mu = mu,
        phi = phi,
        power = power,
        max_terms = max_terms
      )) + stats::dnorm(u, log = TRUE)
    }
    mode <- stats::optimize(
      function(u) -log_integrand(u),
      interval = c(-8, 8)
    )$minimum
    shift <- log_integrand(mode)
    area <- stats::integrate(
      function(u) exp(vapply(u, log_integrand, numeric(1L)) - shift),
      lower = -8,
      upper = 8,
      rel.tol = 1e-7,
      subdivisions = 300L
    )$value
    shift + log(area)
  }, numeric(1L))
}

test_that("Tweedie SD marginal likelihood matches independent quadrature", {
  dat <- tweedie_sd_oracle_data()
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w),
    family = tweedie(),
    data = dat,
    control = drm_control(optimizer_preset = "careful")
  )

  expect_true(is_converged(fit))
  quadrature <- tweedie_sd_marginal_oracle_loglik(fit, dat)
  expect_lt(abs(sum(quadrature) - as.numeric(stats::logLik(fit))), 2)
  wrong_group_map <- tweedie_sd_marginal_oracle_loglik(
    fit,
    dat,
    reverse_sd = TRUE
  )
  expect_gt(abs(sum(wrong_group_map) - sum(quadrature)), 1)
})

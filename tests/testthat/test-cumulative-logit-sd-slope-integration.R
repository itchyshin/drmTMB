cumulative_logit_sd_slope_oracle_data <- function(groups = 256L,
                                                  repeats = 30L,
                                                  seed = 202610205L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  group_w <- seq(-1, 1, length.out = groups)
  w <- group_w[as.integer(id)]
  x <- stats::rnorm(length(id))
  slope_sd <- exp(-1 + 0.5 * group_w)
  random_slope <- stats::rnorm(groups, sd = slope_sd)
  latent <- 0.45 * x + random_slope[as.integer(id)] * x +
    stats::rlogis(length(id))
  category <- cut(
    latent,
    breaks = c(-Inf, -0.75, 0.75, Inf),
    labels = c("low", "middle", "high"),
    ordered_result = TRUE
  )
  data.frame(
    score = ordered(category, levels = c("low", "middle", "high")),
    x = x,
    w = w,
    id = id
  )
}

cumulative_logit_sd_slope_quadrature_loglik <- function(fit, data,
                                                        reverse_sd = FALSE) {
  beta_mu <- stats::coef(fit, dpar = "mu")
  beta_sd <- stats::coef(fit, dpar = 'sd(id, coef = "x")')
  cutpoints <- unname(fit$ordinal$cutpoints)
  group_w <- vapply(levels(data$id), function(level) {
    unique(data$w[data$id == level])[[1L]]
  }, numeric(1L))
  tau <- exp(beta_sd[["(Intercept)"]] + beta_sd[["w"]] * group_w)
  if (reverse_sd) tau <- rev(tau)
  groups <- split(seq_len(nrow(data)), data$id, drop = TRUE)

  vapply(seq_along(groups), function(g) {
    index <- groups[[g]]
    y <- as.integer(data$score[index])
    eta_fixed <- beta_mu[["x"]] * data$x[index]
    log_integrand <- function(u) {
      eta <- eta_fixed + tau[[g]] * u * data$x[index]
      cdf_1 <- stats::plogis(cutpoints[[1L]] - eta)
      cdf_2 <- stats::plogis(cutpoints[[2L]] - eta)
      probability <- cbind(cdf_1, cdf_2 - cdf_1, 1 - cdf_2)
      selected <- probability[cbind(seq_along(y), y)]
      sum(log(pmax(selected, 1e-300))) + stats::dnorm(u, log = TRUE)
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
      rel.tol = 1e-8,
      subdivisions = 300L
    )$value
    shift + log(area)
  }, numeric(1L))
}

test_that("cumulative-logit slope-SD likelihood matches independent quadrature", {
  dat <- cumulative_logit_sd_slope_oracle_data()
  fit <- drmTMB(
    bf(score ~ x + (0 + x | id), sd(id, coef = "x") ~ w),
    family = cumulative_logit(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_true(is_converged(fit))
  quadrature <- cumulative_logit_sd_slope_quadrature_loglik(fit, dat)
  expect_lt(abs(sum(quadrature) - as.numeric(stats::logLik(fit))), 2)
  wrong_group_map <- cumulative_logit_sd_slope_quadrature_loglik(
    fit,
    dat,
    reverse_sd = TRUE
  )
  expect_gt(abs(sum(wrong_group_map) - sum(quadrature)), 1)
})

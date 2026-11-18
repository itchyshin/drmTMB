zero_one_beta_sd_data <- function(
  groups = 80L,
  repeats = 16L,
  beta_sd = c("(Intercept)" = log(0.28), w = 0.48),
  seed = 20261020L
) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  tau <- exp(beta_sd[["(Intercept)"]] + beta_sd[["w"]] * w_group)
  b <- stats::rnorm(groups, sd = tau)
  mu <- stats::plogis(-0.35 + b[group])
  sigma <- 0.45
  phi <- 1 / sigma^2
  prop <- stats::rbeta(length(group), mu * phi, (1 - mu) * phi)
  boundary <- stats::rbinom(length(group), size = 1L, prob = 0.18) == 1L
  prop[boundary] <- stats::rbinom(sum(boundary), size = 1L, prob = 0.58)
  data.frame(prop = prop, w = w, id = factor(group))
}

zero_one_beta_sd_log_observation <- function(
  y,
  eta_mu,
  beta_sigma,
  beta_zoi,
  beta_coi
) {
  mu <- stats::plogis(eta_mu)
  sigma <- exp(beta_sigma)
  phi <- 1 / sigma^2
  zoi <- stats::plogis(beta_zoi)
  coi <- stats::plogis(beta_coi)
  out <- numeric(length(y))
  at_zero <- y == 0
  at_one <- y == 1
  interior <- !at_zero & !at_one
  out[at_zero] <- log(zoi) + log1p(-coi)
  out[at_one] <- log(zoi) + log(coi)
  if (any(interior)) {
    alpha <- pmax(mu[interior] * phi, 1e-8)
    beta_shape <- pmax((1 - mu[interior]) * phi, 1e-8)
    out[interior] <- log1p(-zoi) +
      lgamma(alpha + beta_shape) - lgamma(alpha) - lgamma(beta_shape) +
      (alpha - 1) * log(y[interior]) +
      (beta_shape - 1) * log1p(-y[interior])
  }
  out
}

zero_one_beta_sd_quadrature_loglik <- function(fit, data, reverse_sd = FALSE) {
  beta_mu <- stats::coef(fit, dpar = "mu")
  beta_sigma <- stats::coef(fit, dpar = "sigma")
  beta_zoi <- stats::coef(fit, dpar = "zoi")
  beta_coi <- stats::coef(fit, dpar = "coi")
  beta_sd <- stats::coef(fit, dpar = "sd(id)")
  w_group <- vapply(
    levels(data$id),
    function(level) unique(data$w[data$id == level])[[1L]],
    numeric(1L)
  )
  tau <- exp(beta_sd[["(Intercept)"]] + beta_sd[["w"]] * w_group)
  if (reverse_sd) tau <- rev(tau)
  groups <- split(seq_len(nrow(data)), data$id, drop = TRUE)
  group_loglik <- vapply(seq_along(groups), function(g) {
    index <- groups[[g]]
    y <- data$prop[index]
    log_integrand <- function(u) {
      value <- sum(zero_one_beta_sd_log_observation(
        y,
        rep(beta_mu[["(Intercept)"]] + tau[[g]] * u, length(y)),
        beta_sigma[["(Intercept)"]],
        beta_zoi[["(Intercept)"]],
        beta_coi[["(Intercept)"]]
      )) + stats::dnorm(u, log = TRUE)
      if (is.finite(value)) value else -1e100
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
      subdivisions = 500L
    )$value
    shift + log(area)
  }, numeric(1L))
  group_loglik
}

test_that("zero-one beta SD regression recovers the predictor and likelihood", {
  dat <- zero_one_beta_sd_data()
  control <- drm_control(se = FALSE)
  fit <- drmTMB(
    bf(prop ~ 1 + (1 | id), sd(id) ~ w),
    family = zero_one_beta(),
    data = dat,
    control = control
  )

  expect_true(is_converged(fit))
  expect_identical(fit$model$random_scale$mu$target_identity[["sd(id)"]]$group,
                   "id")
  estimate <- stats::coef(fit, dpar = "sd(id)")
  expect_lt(abs(estimate[["w"]] - 0.48), 0.25)
  predicted_sd <- stats::predict(
    fit,
    newdata = data.frame(w = c(-1, 0, 1), id = factor(levels(dat$id)[1L],
                                                        levels = levels(dat$id))),
    dpar = "sd(id)"
  )
  expect_true(all(diff(as.numeric(predicted_sd)) > 0))

  quadrature <- zero_one_beta_sd_quadrature_loglik(fit, dat)
  expect_equal(sum(quadrature), as.numeric(stats::logLik(fit)), tolerance = 0.10)
  wrong_index <- zero_one_beta_sd_quadrature_loglik(fit, dat, reverse_sd = TRUE)
  expect_gt(abs(sum(wrong_index) - sum(quadrature)), 1)

  constant <- drmTMB(
    bf(prop ~ 1 + (1 | id), sd(id) ~ 1),
    family = zero_one_beta(),
    data = dat,
    control = control
  )
  baseline <- drmTMB(
    bf(prop ~ 1 + (1 | id)),
    family = zero_one_beta(),
    data = dat,
    control = control
  )
  expect_equal(
    as.numeric(stats::logLik(constant)),
    as.numeric(stats::logLik(baseline)),
    tolerance = 1e-6
  )

  simulated <- stats::simulate(fit, nsim = 1L, seed = 20261021L)
  expect_length(simulated[[1L]], nrow(dat))
  restored_path <- tempfile(fileext = ".rds")
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_identical(
    restored$model$random_scale$mu$target_identity,
    fit$model$random_scale$mu$target_identity
  )

  target <- "fixef:sd(id):w"
  profile_ci <- suppressMessages(confint(
    fit,
    parm = target,
    method = "profile",
    level = 0.80
  ))
  expect_identical(profile_ci$parm, target)
  expect_true(all(is.finite(c(profile_ci$lower, profile_ci$upper))))
  bootstrap_ci <- suppressMessages(confint(
    fit,
    parm = target,
    method = "bootstrap",
    R = 2L,
    seed = 20261022L
  ))
  expect_true(all(is.finite(as.matrix(bootstrap_ci))))
  expect_equal(
    nrow(attr(bootstrap_ci, "bootstrap.diagnostics", exact = TRUE)),
    2L
  )
})

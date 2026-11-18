cumulative_logit_sd_data <- function(
  groups = 240L,
  repeats = 18L,
  sd_coef = c("(Intercept)" = -0.7, w = 0.45),
  seed = 20261023L
) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  x <- stats::rnorm(length(group))
  tau <- exp(sd_coef[["(Intercept)"]] + sd_coef[["w"]] * w_group)
  b <- stats::rnorm(groups, sd = tau)
  eta <- 0.45 * x + b[group]
  cumulative_1 <- stats::plogis(-0.75 - eta)
  cumulative_2 <- stats::plogis(0.85 - eta)
  probability <- cbind(
    cumulative_1,
    cumulative_2 - cumulative_1,
    1 - cumulative_2
  )
  score <- vapply(seq_along(group), function(i) {
    sample.int(3L, size = 1L, prob = probability[i, ])
  }, integer(1L))
  data.frame(
    score = ordered(score, levels = seq_len(3L)),
    x = x,
    w = w,
    id = factor(group)
  )
}

cumulative_logit_sd_quadrature_loglik <- function(fit, data, reverse_sd = FALSE) {
  beta_mu <- stats::coef(fit, dpar = "mu")
  beta_sd <- stats::coef(fit, dpar = "sd(id)")
  cutpoints <- unname(fit$ordinal$cutpoints)
  w_group <- vapply(levels(data$id), function(level) {
    unique(data$w[data$id == level])[[1L]]
  }, numeric(1L))
  tau <- exp(beta_sd[["(Intercept)"]] + beta_sd[["w"]] * w_group)
  if (reverse_sd) tau <- rev(tau)
  groups <- split(seq_len(nrow(data)), data$id, drop = TRUE)
  vapply(seq_along(groups), function(g) {
    index <- groups[[g]]
    y <- as.integer(data$score[index])
    eta_fixed <- if ("(Intercept)" %in% names(beta_mu)) {
      beta_mu[["(Intercept)"]] + beta_mu[["x"]] * data$x[index]
    } else {
      beta_mu[["x"]] * data$x[index]
    }
    log_integrand <- function(u) {
      eta <- eta_fixed + tau[[g]] * u
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

test_that("cumulative-logit SD regression recovers and preserves target outputs", {
  dat <- cumulative_logit_sd_data()
  control <- drm_control(se = FALSE)
  fit <- drmTMB(
    bf(score ~ 1 + x + (1 | id), sd(id) ~ w),
    family = cumulative_logit(),
    data = dat,
    control = control
  )

  expect_true(is_converged(fit))
  expect_identical(fit$model$random_scale$mu$target_identity[["sd(id)"]]$group,
                   "id")
  estimate <- stats::coef(fit, dpar = "sd(id)")
  expect_lt(abs(estimate[["w"]] - 0.45), 0.25)
  predicted_sd <- stats::predict(
    fit,
    newdata = data.frame(
      w = c(-1, 0, 1),
      id = factor(levels(dat$id)[1L], levels = levels(dat$id))
    ),
    dpar = "sd(id)"
  )
  expect_true(all(diff(as.numeric(predicted_sd)) > 0))

  quadrature <- cumulative_logit_sd_quadrature_loglik(fit, dat)
  expect_lt(abs(sum(quadrature) - as.numeric(stats::logLik(fit))), 2)
  wrong_index <- cumulative_logit_sd_quadrature_loglik(
    fit,
    dat,
    reverse_sd = TRUE
  )
  expect_gt(abs(sum(wrong_index) - sum(quadrature)), 1)

  constant <- drmTMB(
    bf(score ~ 1 + x + (1 | id), sd(id) ~ 1),
    family = cumulative_logit(),
    data = dat,
    control = control
  )
  baseline <- drmTMB(
    bf(score ~ 1 + x + (1 | id)),
    family = cumulative_logit(),
    data = dat,
    control = control
  )
  expect_equal(
    as.numeric(stats::logLik(constant)),
    as.numeric(stats::logLik(baseline)),
    tolerance = 1e-6
  )

  simulated <- stats::simulate(fit, nsim = 1L, seed = 20261024L)
  expect_true(is.ordered(simulated[[1L]]))
  restored_path <- tempfile(fileext = ".rds")
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_identical(
    restored$model$random_scale$mu$target_identity,
    fit$model$random_scale$mu$target_identity
  )
  expect_equal(
    stats::predict(restored, dpar = "sd(id)"),
    stats::predict(fit, dpar = "sd(id)")
  )
})

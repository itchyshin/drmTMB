zi_poisson_sd_integration_data <- function(groups = 72L, repeats = 18L,
                                          seed = 20261018L) {
  set.seed(seed)
  group_index <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  group_sd <- exp(-0.55 + 0.35 * w_group)
  group_effect <- stats::rnorm(groups, sd = group_sd)
  mu <- exp(0.25 + group_effect[group_index])
  zi <- 0.25
  y <- ifelse(stats::rbinom(length(group_index), 1L, zi) == 1L,
              0L, stats::rpois(length(group_index), mu))
  data.frame(
    y = y,
    w = w_group[group_index],
    id = factor(group_index, levels = seq_len(groups))
  )
}

zi_poisson_sd_marginal_loglik <- function(fit, data, reverse_sd = FALSE) {
  beta_mu <- coef(fit, "mu")
  beta_zi <- coef(fit, "zi")
  beta_sd <- coef(fit, "sd(id)")
  group_levels <- levels(data$id)
  group_data <- unique(data[c("id", "w")])
  group_data <- group_data[match(group_levels, as.character(group_data$id)), ]
  X_sd <- stats::model.matrix(~ w, group_data)
  group_sd <- exp(as.vector(X_sd %*% beta_sd))
  if (reverse_sd) group_sd <- rev(group_sd)
  group_rows <- split(seq_len(nrow(data)), data$id)
  group_rows <- group_rows[group_levels]
  eta_zi <- unname(beta_zi[["(Intercept)"]])
  log_zi <- stats::plogis(eta_zi, log.p = TRUE)
  log_one_minus_zi <- stats::plogis(eta_zi, lower.tail = FALSE, log.p = TRUE)
  logspace_add_two <- function(a, b) {
    pmax(a, b) + log1p(exp(-abs(a - b)))
  }
  sum(vapply(seq_along(group_levels), function(g) {
    rows <- group_rows[[g]]
    log_integrand <- function(z) {
      mu <- exp(unname(beta_mu[["(Intercept)"]]) + group_sd[[g]] * z)
      y <- data$y[rows]
      row_loglik <- ifelse(
        y == 0L,
        vapply(mu, function(m) {
          logspace_add_two(log_zi, log_one_minus_zi - m)
        }, numeric(1)),
        log_one_minus_zi + stats::dpois(y, lambda = mu, log = TRUE)
      )
      sum(row_loglik) + stats::dnorm(z, log = TRUE)
    }
    peak <- stats::optimize(log_integrand, c(-8, 8), maximum = TRUE)$objective
    integrated <- stats::integrate(
      function(z) exp(vapply(z, log_integrand, numeric(1)) - peak),
      lower = -8, upper = 8, rel.tol = 1e-8, subdivisions = 200L
    )$value
    peak + log(integrated)
  }, numeric(1)))
}

zi_poisson_slope_sd_data <- function(groups = 64L, repeats = 12L,
                                    seed = 20261021L) {
  set.seed(seed)
  group_index <- rep(seq_len(groups), each = repeats)
  x_within <- rep(seq(-1.5, 1.5, length.out = repeats), groups)
  w_group <- seq(-1, 1, length.out = groups)
  group_sd <- exp(-0.55 + 0.35 * w_group)
  group_slope <- stats::rnorm(groups, sd = group_sd)
  mu <- exp(0.15 + group_slope[group_index] * x_within)
  zi <- 0.2
  y <- ifelse(stats::rbinom(length(group_index), 1L, zi) == 1L,
              0L, stats::rpois(length(group_index), mu))
  data.frame(
    y = y,
    x = x_within,
    w = w_group[group_index],
    id = factor(group_index, levels = seq_len(groups))
  )
}

zi_poisson_slope_sd_marginal_loglik <- function(fit, data,
                                               reverse_sd = FALSE) {
  beta_mu <- coef(fit, "mu")
  beta_zi <- coef(fit, "zi")
  sd_target <- names(fit$model$random_scale$mu$target_identity)[[1L]]
  beta_sd <- coef(fit, sd_target)
  fixed_slope <- if ("x" %in% names(beta_mu)) {
    unname(beta_mu[["x"]])
  } else {
    0
  }
  group_levels <- levels(data$id)
  group_data <- unique(data[c("id", "w")])
  group_data <- group_data[match(group_levels, as.character(group_data$id)), ]
  X_sd <- stats::model.matrix(~ w, group_data)
  group_sd <- exp(as.vector(X_sd %*% beta_sd))
  if (reverse_sd) group_sd <- rev(group_sd)
  group_rows <- split(seq_len(nrow(data)), data$id)
  group_rows <- group_rows[group_levels]
  eta_zi <- unname(beta_zi[["(Intercept)"]])
  log_zi <- stats::plogis(eta_zi, log.p = TRUE)
  log_one_minus_zi <- stats::plogis(eta_zi, lower.tail = FALSE, log.p = TRUE)
  logspace_add_two <- function(a, b) {
    pmax(a, b) + log1p(exp(-abs(a - b)))
  }
  sum(vapply(seq_along(group_levels), function(g) {
    rows <- group_rows[[g]]
    log_integrand <- function(z) {
      mu <- exp(unname(beta_mu[["(Intercept)"]]) +
                  fixed_slope * data$x[rows] +
                  group_sd[[g]] * z * data$x[rows])
      y <- data$y[rows]
      row_loglik <- ifelse(
        y == 0L,
        vapply(mu, function(m) {
          logspace_add_two(log_zi, log_one_minus_zi - m)
        }, numeric(1)),
        log_one_minus_zi + stats::dpois(y, lambda = mu, log = TRUE)
      )
      sum(row_loglik) + stats::dnorm(z, log = TRUE)
    }
    peak <- stats::optimize(log_integrand, c(-8, 8), maximum = TRUE)$objective
    integrated <- stats::integrate(
      function(z) exp(vapply(z, log_integrand, numeric(1)) - peak),
      lower = -8, upper = 8, rel.tol = 1e-8, subdivisions = 200L
    )$value
    peak + log(integrated)
  }, numeric(1)))
}

test_that("zero-inflated Poisson direct SD matches an independent cluster integral", {
  dat <- zi_poisson_sd_integration_data()
  fit <- drmTMB(
    bf(y ~ 1 + (1 | id), zi ~ 1, sd(id) ~ w),
    family = stats::poisson(link = "log"), data = dat
  )

  expect_true(is_converged(fit))
  expect_true(isTRUE(fit$sdr$pdHess))
  sd_coef <- coef(fit, "sd(id)")
  sd_se <- sqrt(vcov(fit)["sd(id):w", "sd(id):w"])
  expect_lt(abs(unname(sd_coef[["w"]]) - 0.35), 2.5 * sd_se)
  expect_identical(fit$model$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  sd_prediction <- predict(fit, dpar = "sd(id)")
  expect_equal(length(sd_prediction), nlevels(dat$id))
  expect_true(all(diff(unname(sd_prediction)) > 0))

  oracle <- zi_poisson_sd_marginal_loglik(fit, dat)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle) / nlevels(dat$id), 0.1)
  wrong_group_oracle <- zi_poisson_sd_marginal_loglik(
    fit, dat, reverse_sd = TRUE
  )
  expect_gt(abs(oracle - wrong_group_oracle), 1)

  simulated <- simulate(fit, nsim = 1L, seed = 20261019L)
  expect_equal(nrow(simulated), nrow(dat))
  save_path <- tempfile(fileext = ".rds")
  on.exit(unlink(save_path), add = TRUE)
  saveRDS(fit, save_path)
  restored <- readRDS(save_path)
  expect_equal(predict(restored, dpar = "sd(id)"), sd_prediction)

  target <- "fixef:sd(id):w"
  profile_ci <- suppressMessages(confint(
    fit, parm = target, method = "profile", level = 0.95
  ))
  expect_identical(profile_ci$parm, target)
  expect_true(all(is.finite(c(profile_ci$lower, profile_ci$upper))))
  bootstrap_ci <- suppressMessages(confint(
    fit, parm = target, method = "bootstrap", R = 2L, seed = 20261020L
  ))
  expect_true(all(is.finite(as.matrix(bootstrap_ci))))
  expect_equal(nrow(attr(bootstrap_ci, "bootstrap.diagnostics", exact = TRUE)),
               2L)

  constant <- drmTMB(
    bf(y ~ 1 + (1 | id), zi ~ 1, sd(id) ~ 1),
    family = stats::poisson(link = "log"), data = dat
  )
  baseline <- drmTMB(
    bf(y ~ 1 + (1 | id), zi ~ 1),
    family = stats::poisson(link = "log"), data = dat
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(baseline)),
               tolerance = 1e-5)
})

test_that("zero-inflated Poisson selected slope SD recovers and integrates", {
  dat <- zi_poisson_slope_sd_data()
  slope_formula <- bf(
    y ~ 1 + (0 + x | id), zi ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ w
  )

  # This is a short targeted synthetic fit, not an interval-coverage campaign.
  fit <- drmTMB(
    slope_formula,
    family = stats::poisson(link = "log"), data = dat
  )

  expect_true(is_converged(fit))
  expect_true(isTRUE(fit$sdr$pdHess))
  sd_target <- names(fit$model$random_scale$mu$target_identity)[[1L]]
  sd_coef <- coef(fit, sd_target)
  sd_se <- sqrt(vcov(fit)[paste0(sd_target, ":w"), paste0(sd_target, ":w")])
  expect_lt(abs(unname(sd_coef[["w"]]) - 0.35), 2.5 * sd_se)
  expect_identical(fit$model$random_scale$mu$target_identity[[sd_target]]$coef,
                   "x")
  sd_prediction <- predict(fit, dpar = sd_target)
  expect_equal(length(sd_prediction), nlevels(dat$id))
  expect_true(all(diff(unname(sd_prediction)) > 0))

  oracle <- zi_poisson_slope_sd_marginal_loglik(fit, dat)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle) / nlevels(dat$id), 0.1)
  wrong_group_oracle <- zi_poisson_slope_sd_marginal_loglik(
    fit, dat, reverse_sd = TRUE
  )
  expect_gt(abs(oracle - wrong_group_oracle), 1)

  constant <- drmTMB(
    bf(y ~ 1 + (0 + x | id), zi ~ 1,
       sd(id, dpar = "mu", coef = "x") ~ 1),
    family = stats::poisson(link = "log"), data = dat
  )
  expect_true(is_converged(constant))
  expect_length(coef(constant, sd_target), 1L)
})

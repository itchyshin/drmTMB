new_beta_binomial_sd_data <- function(groups = 72L, repeats = 18L, seed = 20261018) {
  set.seed(seed)
  w_group <- seq(-1, 1, length.out = groups)
  group <- factor(rep(seq_len(groups), each = repeats))
  w <- rep(w_group, each = repeats)
  group_sd <- exp(log(0.35) + 0.4 * w_group)
  b <- stats::rnorm(groups, sd = group_sd)
  mu <- stats::plogis(-0.2 + b[as.integer(group)])
  trials <- rep(12L, length(group))
  sigma <- 0.22
  phi <- 1 / sigma^2
  probability <- stats::rbeta(
    length(group), shape1 = mu * phi, shape2 = (1 - mu) * phi
  )
  success <- stats::rbinom(length(group), size = trials, prob = probability)
  data.frame(success, failure = trials - success, group, w)
}

beta_binomial_sd_marginal_loglik <- function(fit, data, reverse_sd = FALSE) {
  beta_mu <- coef(fit, "mu")
  beta_sigma <- coef(fit, "sigma")
  beta_sd <- coef(fit, "sd(group)")
  mu <- stats::plogis(unname(beta_mu[["(Intercept)"]]))
  sigma <- exp(unname(beta_sigma[["(Intercept)"]]))
  group_levels <- levels(data$group)
  sd_design <- stats::model.matrix(~ w, data = unique(data[c("group", "w")]))
  sd_design <- sd_design[match(group_levels, as.character(unique(data$group))), ,
                         drop = FALSE]
  group_sd <- exp(as.vector(sd_design %*% beta_sd))
  if (reverse_sd) group_sd <- rev(group_sd)
  group_rows <- split(seq_len(nrow(data)), data$group)
  group_rows <- group_rows[group_levels]
  sum(vapply(seq_along(group_levels), function(g) {
    rows <- group_rows[[g]]
    log_integrand <- function(u) {
      eta <- stats::qlogis(mu) + group_sd[[g]] * u
      success <- data$success[rows]
      trials <- success + data$failure[rows]
      probability <- stats::plogis(eta)
      precision <- 1 / sigma^2
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
    peak <- optimize(log_integrand, interval = c(-8, 8), maximum = TRUE)$objective
    integrated <- stats::integrate(
      function(u) exp(vapply(u, log_integrand, numeric(1)) - peak),
      lower = -8, upper = 8, rel.tol = 1e-9, subdivisions = 300L
    )$value
    peak + log(integrated)
  }, numeric(1)))
}

test_that("Beta-binomial ordinary-intercept SD regression recovers group variation", {
  dat <- new_beta_binomial_sd_data()
  fit <- drmTMB(
    bf(cbind(success, failure) ~ 1 + (1 | group), sigma ~ 1,
       sd(group) ~ w),
    family = beta_binomial(), data = dat
  )

  expect_true(is_converged(fit))
  expect_true(isTRUE(fit$sdr$pdHess))
  sd_coef <- coef(fit)[["sd(group)"]]
  sd_se <- sqrt(vcov(fit)["sd(group):w", "sd(group):w"])
  expect_lt(abs(unname(sd_coef[["w"]]) - 0.4), 2.5 * sd_se)
  predicted_sd <- predict(fit, dpar = "sd(group)")
  expect_true(all(is.finite(predicted_sd)))
  expect_true(all(diff(unname(predicted_sd)) > 0))
  expect_true(all(is.finite(fit$sdpars[["sd(group)"]])))

  quadrature_loglik <- beta_binomial_sd_marginal_loglik(fit, dat)
  expect_lt(abs(as.numeric(logLik(fit)) - quadrature_loglik) / 72, 0.05)
  wrong_group_loglik <- beta_binomial_sd_marginal_loglik(
    fit, dat, reverse_sd = TRUE
  )
  expect_gt(abs(quadrature_loglik - wrong_group_loglik), 1)

  simulated <- simulate(fit, nsim = 1L, seed = 20261019)
  expect_equal(nrow(simulated), nrow(dat))
  save_path <- tempfile(fileext = ".rds")
  saveRDS(fit, save_path)
  restored <- readRDS(save_path)
  expect_equal(predict(restored, dpar = "sd(group)"), predicted_sd)
  unlink(save_path)

  target <- "fixef:sd(group):w"
  profile_ci <- suppressMessages(confint(
    fit, parm = target, method = "profile", level = 0.95
  ))
  expect_identical(profile_ci$parm, target)
  expect_true(all(is.finite(c(profile_ci$lower, profile_ci$upper))))
  bootstrap_ci <- suppressMessages(confint(
    fit, parm = target, method = "bootstrap", R = 2L, seed = 20261020
  ))
  expect_true(all(is.finite(as.matrix(bootstrap_ci))))
  bootstrap_diagnostics <- attr(
    bootstrap_ci, "bootstrap.diagnostics", exact = TRUE
  )
  expect_equal(nrow(bootstrap_diagnostics), 2L)

  constant <- drmTMB(
    bf(cbind(success, failure) ~ 1 + (1 | group), sigma ~ 1,
       sd(group) ~ 1),
    family = beta_binomial(), data = dat
  )
  baseline <- drmTMB(
    bf(cbind(success, failure) ~ 1 + (1 | group), sigma ~ 1),
    family = beta_binomial(), data = dat
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(baseline)),
               tolerance = 1e-5)
})


# Inf in a mu predictor must abort in drmTMB and name the column for the
# families that did not yet call drm_abort_if_nonfinite_fit_design() (#1730).
# NA in a predictor stays on the complete-case path.

nonfinite_mu_case <- function(family, formula, data, label) {
  data$x[1] <- Inf
  list(family = family, formula = formula, data = data, label = label)
}

expect_nonfinite_mu_abort <- function(case) {
  err <- expect_error(
    drmTMB(
      case$formula,
      family = case$family,
      data = case$data,
      control = drm_control(se = FALSE)
    ),
    class = "rlang_error"
  )
  msg <- conditionMessage(err)
  expect_match(
    msg,
    sprintf("%s models require finite fixed-effect design values", case$label),
    fixed = TRUE
  )
  expect_match(msg, "\\bx\\b")
  expect_match(msg, "dpar = \"mu\"", fixed = TRUE)
}

test_that("#1730: Inf in a mu predictor aborts and names the column", {
  set.seed(1730)
  n <- 24
  x <- stats::rnorm(n)
  y_count <- stats::rpois(n, 2)
  y_pos <- y_count + 1L
  successes <- stats::rbinom(n, 8, 0.4)
  cases <- list(
    nonfinite_mu_case(
      Gamma(link = "log"),
      bf(y ~ x, sigma ~ 1),
      data.frame(y = exp(stats::rnorm(n)), x = x),
      "Gamma"
    ),
    nonfinite_mu_case(
      tweedie(),
      bf(y ~ x, sigma ~ 1, nu ~ 1),
      data.frame(y = y_count, x = x),
      "Tweedie"
    ),
    nonfinite_mu_case(
      beta_family(),
      bf(y ~ x, sigma ~ 1),
      data.frame(y = stats::plogis(stats::rnorm(n)), x = x),
      "Beta"
    ),
    nonfinite_mu_case(
      poisson(),
      bf(y ~ x),
      data.frame(y = y_count, x = x),
      "Poisson"
    ),
    nonfinite_mu_case(
      nbinom2(),
      bf(y ~ x, sigma ~ 1),
      data.frame(y = y_count, x = x),
      "nbinom2"
    ),
    nonfinite_mu_case(
      binomial(),
      bf(y ~ x),
      data.frame(y = stats::rbinom(n, 1, 0.4), x = x),
      "binomial"
    ),
    nonfinite_mu_case(
      zero_one_beta(),
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      data.frame(y = c(0, 1, stats::plogis(stats::rnorm(n - 2))), x = x),
      "Zero-one beta"
    ),
    nonfinite_mu_case(
      beta_binomial(),
      bf(cbind(successes, failures) ~ x, sigma ~ 1),
      data.frame(successes = successes, failures = 8 - successes, x = x),
      "beta-binomial"
    ),
    nonfinite_mu_case(
      cumulative_logit(),
      bf(score ~ x),
      data.frame(score = ordered(sample(c("low", "mid", "high"), n, TRUE)), x = x),
      "cumulative-logit"
    ),
    nonfinite_mu_case(
      truncated_nbinom2(),
      bf(y ~ x, sigma ~ 1),
      data.frame(y = y_pos, x = x),
      "truncated_nbinom2"
    )
  )
  for (case in cases) {
    expect_nonfinite_mu_abort(case)
  }
})

test_that("#1730: Inf in a Gamma sigma predictor aborts and names the column", {
  set.seed(1730)
  d <- data.frame(y = exp(stats::rnorm(24)), z = stats::rnorm(24))
  d$z[1] <- Inf
  err <- expect_error(
    drmTMB(
      bf(y ~ 1, sigma ~ z),
      family = Gamma(link = "log"),
      data = d,
      control = drm_control(se = FALSE)
    ),
    class = "rlang_error"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "Gamma models require finite fixed-effect design values", fixed = TRUE)
  expect_match(msg, "\\bz\\b")
  expect_match(msg, "dpar = \"sigma\"", fixed = TRUE)
})

test_that("#1730: NA in a Gamma predictor stays dropped", {
  set.seed(1730)
  d <- data.frame(y = exp(stats::rnorm(24)), x = stats::rnorm(24))
  d$x[1] <- NA_real_
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = Gamma(link = "log"),
    data = d,
    control = drm_control(se = FALSE)
  )
  expect_equal(nobs(fit), 23L)
})

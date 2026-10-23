# Issue #1188: the parametric bootstrap drew every replicate over the FULL
# design and refitted on all rows, regardless of how many rows the seed fit
# actually observed. Under `missing = miss_control(response = "include")` the
# fitted data keeps the masked rows (with NA responses), so overwriting the
# response column wholesale handed each replicate MORE data than the seed fit
# had. A bootstrap whose replicates are richer than the original understates
# uncertainty, and the narrowing deepens with the missing fraction.
#
# Measured on this fixture family before the fix (S = 200 datasets, R = 99
# replicates each, nominal 95% percentile interval on `fixef:mu:x`, truth
# 0.5): coverage 0.895 / 0.820 / 0.720 at 10% / 30% / 50% of responses masked.
# After the fix, on the same datasets and bootstrap seeds: 0.910 / 0.895 /
# 0.910, against a Wald reference of 0.920 / 0.925 / 0.915.
#
# The default `response = "drop"` policy is untouched: it complete-cases the
# stored data, so a drop fit's `object$data` carries no NA and the mask
# restoration is a no-op there.

new_masked_locscale_data <- function(n = 60L, masked = 30L, seed = 1L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  y <- 0.3 + 0.5 * x + stats::rnorm(n) * exp(0.1 * x)
  out <- data.frame(y = y, x = x)
  if (masked > 0L) {
    out$y[seq_len(masked)] <- NA_real_
  }
  out
}

new_masked_locscale_fit <- function(masked = 30L, ...) {
  drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = new_masked_locscale_data(masked = masked, ...),
    missing = miss_control(response = "include")
  )
}

test_that("bootstrap replicates keep the seed fit's response mask", {
  fit <- new_masked_locscale_fit(masked = 30L)
  expect_identical(nobs(fit), 30L)
  expect_identical(nrow(fit$data), 60L)

  simulations <- stats::simulate(fit, nsim = 3L, seed = 20260905)

  for (index in seq_len(3L)) {
    replicate <- drmTMB:::bootstrap_response_data(fit, simulations, index)
    expect_identical(nrow(replicate), nrow(fit$data))
    expect_identical(which(is.na(replicate$y)), which(is.na(fit$data$y)))
    # Observed rows carry the simulated draw, unchanged.
    observed <- !is.na(fit$data$y)
    expect_equal(
      replicate$y[observed],
      simulations[[paste0("sim_", index)]][observed]
    )
  }
})

test_that("a bootstrap replicate refits on the seed fit's observed row count", {
  fit <- new_masked_locscale_fit(masked = 30L)
  simulations <- stats::simulate(fit, nsim = 1L, seed = 20260905)
  replicate <- drmTMB:::bootstrap_response_data(fit, simulations, 1L)

  refit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = replicate,
    control = drmTMB:::bootstrap_refit_control(NULL),
    missing = drmTMB:::bootstrap_refit_missing_control(fit)
  )
  expect_identical(nobs(refit), nobs(fit))
})

test_that("mask restoration is a no-op when the fitted data has no missing response", {
  dat <- new_masked_locscale_data(masked = 0L)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
  simulations <- stats::simulate(fit, nsim = 2L, seed = 20260905)

  for (index in seq_len(2L)) {
    replicate <- drmTMB:::bootstrap_response_data(fit, simulations, index)
    expect_equal(replicate$y, simulations[[paste0("sim_", index)]])
    expect_false(anyNA(replicate$y))
  }
})

test_that("bootstrap_refit_missing_control carries only an include policy", {
  include_fit <- new_masked_locscale_fit(masked = 30L)
  carried <- drmTMB:::bootstrap_refit_missing_control(include_fit)
  expect_s3_class(carried, "drm_missing_control")
  expect_identical(carried$response, "include")

  drop_fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = new_masked_locscale_data(masked = 12L)
  )
  # A drop fit stores complete-cased data, so there is no mask to restore and
  # no policy to carry.
  expect_identical(nrow(drop_fit$data), nobs(drop_fit))
  expect_null(drmTMB:::bootstrap_refit_missing_control(drop_fit))
})

test_that("a cbind(successes, failures) replicate keeps the mask and the trial sizes", {
  set.seed(20260903)
  n <- 60L
  dat <- data.frame(x = stats::rnorm(n), trials = sample(5:20, n, replace = TRUE))
  dat$s <- stats::rbinom(n, size = dat$trials, prob = stats::plogis(-0.2 + 0.6 * dat$x))
  dat$f <- dat$trials - dat$s
  dat$s[seq_len(12L)] <- NA_integer_
  dat$f[seq_len(12L)] <- NA_integer_

  fit <- drmTMB(
    bf(cbind(s, f) ~ x),
    family = binomial(),
    data = dat,
    missing = miss_control(response = "include")
  )
  expect_identical(nobs(fit), 48L)

  simulations <- stats::simulate(fit, nsim = 2L, seed = 20260905)
  observed <- !is.na(fit$data$s)

  for (index in seq_len(2L)) {
    replicate <- drmTMB:::bootstrap_response_data(fit, simulations, index)
    expect_identical(which(is.na(replicate$s)), which(is.na(fit$data$s)))
    expect_identical(which(is.na(replicate$f)), which(is.na(fit$data$f)))
    expect_equal(
      (replicate$s + replicate$f)[observed],
      fit$data$trials[observed]
    )
  }
})

test_that("a masked fit's bootstrap spread tracks its own Wald standard error", {
  # The defect's signature is a bootstrap spread that ignores the missing
  # fraction: pre-fix, the bootstrap sd stayed near 0.13 while the seed fit's
  # Wald SE grew from 0.175 (10% masked) to 0.208 (50% masked), giving
  # sd / SE = 0.63 at 50% masking. Post-fix the same call reads ~1.0. This
  # band is wide enough for the Monte Carlo noise of R = 99 (the relative
  # standard error of a bootstrap sd is about 1 / sqrt(2 (R - 1)), ~7%) and
  # still excludes the pre-fix value by a wide margin.
  fit <- new_masked_locscale_fit(masked = 30L)
  wald <- stats::confint(fit, parm = "fixef:mu:x", method = "wald")
  wald_se <- (wald$upper - wald$lower) / (2 * stats::qnorm(0.975))

  boot <- stats::confint(
    fit,
    parm = "fixef:mu:x",
    method = "bootstrap",
    R = 99L,
    seed = 20260905
  )
  diagnostics <- attr(boot, "bootstrap.diagnostics")
  draws <- diagnostics$draw_value[
    diagnostics$parm == "fixef:mu:x" & diagnostics$draw_used
  ]
  expect_gte(length(draws), 90L)

  ratio <- stats::sd(draws) / wald_se
  expect_gt(ratio, 0.75)
  expect_lt(ratio, 1.35)
})

# Arc 2c DG2 sentinels: one independent `sigma` random intercept `(1 | id)` for
# lognormal and Gamma, the two positive-continuous families that gained a `mu`
# random intercept in Arc 2a. The bar mirrors Arc 2b (Fisher's review): a
# magnitude check on the RE-SD (not just a positivity floor), a BLUP-vs-truth
# correlation on the LOG-SIGMA scale (the scale the residual-scale RE lives on
# for both families), and the two rejection gates -- a `sigma` random effect may
# not be combined with a `mu` random effect, and only intercepts (not slopes) are
# admitted. The systematic small-cluster ML-Laplace bias is characterised
# separately by the >=50-seed sweep in
# docs/dev-log/simulation-artifacts/2026-07-12-arc2c-sigma-recovery/.

expect_sigma_random_intercept_recovered <- function(fit, data, model_type, u_true,
                                                    sd_true = 0.4,
                                                    sd_rel_tol = 0.35,
                                                    cor_min = 0.70) {
  label <- "(1 | id)"
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, model_type)
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$sigma$n_terms, 1L)
  expect_equal(fit$model$random$sigma$labels, label)
  # intercept design column is an all-ones column, not an observed covariate
  expect_true(all(fit$model$random$sigma$value[, 1] == 1))
  expect_named(fit$sdpars$sigma, label)
  sd_hat <- unname(fit$sdpars$sigma[[label]])
  expect_gt(sd_hat, 0.05)
  # magnitude recovery, not just positivity (a 90%-biased SD must fail)
  expect_lt(abs(sd_hat - sd_true) / sd_true, sd_rel_tol)

  sigma_effects <- fit$random_effects$sigma$terms[[label]]
  expect_equal(length(sigma_effects), length(u_true))
  # BLUP vs truth on the log-sigma scale (both are on that scale here)
  expect_gt(stats::cor(sigma_effects, u_true), cor_min)

  fixed_sigma <- drmTMB:::drm_fixed_effect_basis(fit, dpar = "sigma")$eta
  sigma_contribution <- drmTMB:::sigma_random_effect_contribution(
    fit,
    dpar = "sigma"
  )
  expected_sigma_link <- fixed_sigma + sigma_contribution
  expect_equal(
    predict(fit, dpar = "sigma", type = "link"),
    expected_sigma_link,
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, dpar = "sigma", type = "response"),
    exp(expected_sigma_link),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, newdata = data, dpar = "sigma", type = "link"),
    fixed_sigma,
    tolerance = 1e-10
  )
  expect_equal(stats::sigma(fit), exp(expected_sigma_link), tolerance = 1e-10)
  expect_contains(
    drmTMB:::drm_emmeans_blocked_features(fit),
    "sigma random effects"
  )
  printed <- capture.output(print(fit), type = "message")
  expect_match(paste(printed, collapse = "\n"), "sigma random-effect terms: 1")

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == paste0("sd:sigma:", label), , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_true(sd_target$profile_ready)

  chk <- check_drm(fit)
  replication <- chk[chk$check == "sigma_random_effect_replication", ]
  expect_equal(replication$status, "ok")
  expect_false(any(chk$status == "error"))
}

base_sigma <- function(seed, n_id = 40L, n_each = 15L, sd_sigma = 0.4) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  u <- stats::rnorm(n_id, sd = sd_sigma)
  u <- u - mean(u)
  list(id = id, n = n, x = x, u = u, sd_sigma = sd_sigma)
}

test_that("lognormal sigma supports an independent random intercept", {
  b <- base_sigma(20260733)
  sdlog <- exp(-0.5 + b$u[b$id])
  y <- stats::rlnorm(b$n, meanlog = 0.2 + 0.5 * b$x, sdlog = sdlog)
  d <- data.frame(y = y, x = b$x, z = stats::rnorm(b$n), id = b$id)
  fit <- drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = lognormal(), data = d)
  expect_sigma_random_intercept_recovered(
    fit,
    d,
    "lognormal",
    b$u,
    b$sd_sigma
  )

  # a fixed-effect covariate + RE on sigma fits (previously a rejected boundary case)
  combo <- drmTMB(bf(y ~ x, sigma ~ z + (1 | id)), family = lognormal(), data = d)
  expect_equal(combo$opt$convergence, 0)
  expect_true(isTRUE(combo$sdr$pdHess))

  # a sigma random effect may not be combined with a mu random effect
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ (1 | id)), family = lognormal(), data = d),
    "combined"
  )
  # only intercepts are admitted -- a sigma random slope must still error
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z + (0 + z | id)), family = lognormal(), data = d),
    "random intercept"
  )
})

test_that("Gamma sigma supports an independent random intercept", {
  b <- base_sigma(20260744)
  mu_i <- exp(0.2 + 0.5 * b$x)
  sigma_i <- exp(-0.6 + b$u[b$id])
  y <- stats::rgamma(b$n, shape = 1 / sigma_i^2, scale = mu_i * sigma_i^2)
  d <- data.frame(y = y, x = b$x, z = stats::rnorm(b$n), id = b$id)
  fit <- drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = Gamma(link = "log"), data = d)
  expect_sigma_random_intercept_recovered(fit, d, "gamma", b$u, b$sd_sigma)

  # a fixed-effect covariate + RE on sigma fits (previously a rejected boundary case)
  combo <- drmTMB(bf(y ~ x, sigma ~ z + (1 | id)), family = Gamma(link = "log"), data = d)
  expect_equal(combo$opt$convergence, 0)
  expect_true(isTRUE(combo$sdr$pdHess))

  # a sigma random effect may not be combined with a mu random effect
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ (1 | id)),
      family = Gamma(link = "log"), data = d
    ),
    "combined"
  )
  # only intercepts are admitted -- a sigma random slope must still error
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z + (0 + z | id)),
      family = Gamma(link = "log"), data = d
    ),
    "random intercept"
  )
})

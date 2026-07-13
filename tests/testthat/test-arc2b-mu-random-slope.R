# Arc 2b DG2 sentinels: one independent `mu` random slope `(0 + x | id)` for the
# five families that gained a random intercept in Arc 2a. The bar is stronger than
# a smoke test (Fisher's review): a magnitude check on the RE-SD (not just a
# positivity floor), a BLUP-vs-truth correlation on the LINEAR-PREDICTOR scale
# (the scale the slope RE lives on for every one of these families), and the
# `(0 + x | p | id)` correlated block must still error. The systematic small-cluster
# ML-Laplace bias is characterised separately by the >=50-seed sweep in
# docs/dev-log/simulation-artifacts/2026-07-12-arc2b-slope-recovery/.

expect_mu_random_slope_recovered <- function(fit, model_type, slope, slope_sd,
                                             sd_rel_tol = 0.45, cor_min = 0.40) {
  label <- "(0 + x | id)"
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, model_type)
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, label)
  # slope design column is the observed x, not an all-ones intercept column
  expect_equal(fit$model$random$mu$value[, 1], fit$model$data$x)
  expect_named(fit$sdpars$mu, label)
  sd_hat <- unname(fit$sdpars$mu[[label]])
  expect_gt(sd_hat, 0.05)
  # magnitude recovery, not just positivity (a 90%-biased SD must fail)
  expect_lt(abs(sd_hat - slope_sd) / slope_sd, sd_rel_tol)

  slope_effects <- fit$random_effects$mu$terms[[label]]
  expect_equal(length(slope_effects), length(slope))
  # BLUP vs truth on the linear-predictor scale (both are on that scale here)
  expect_gt(stats::cor(slope_effects, slope), cor_min)

  expect_true(drmTMB:::has_ordinary_mu_random_effects(fit))
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 1L)
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    as.vector(fit$model$X$mu %*% coef(fit, "mu")) +
      drmTMB:::mu_random_effect_contribution(fit),
    tolerance = 1e-8
  )

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == paste0("sd:mu:", label), , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_true(sd_target$profile_ready)

  chk <- check_drm(fit)
  replication <- chk[chk$check == "mu_random_effect_replication", ]
  expect_equal(replication$status, "ok")
  design <- chk[chk$check == "mu_random_effect_design", ]
  expect_equal(design$status, "ok")
}

base_slope <- function(seed, n_id = 40L, n_each = 15L, slope_sd = 0.5) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  slope <- stats::rnorm(n_id, sd = slope_sd)
  slope <- slope - mean(slope)
  list(id = id, n = n, x = x, slope = slope, eta_slope = slope[id] * x,
       slope_sd = slope_sd)
}

test_that("skew_normal mu supports an independent random slope", {
  b <- base_slope(20260720)
  z <- stats::rnorm(b$n)
  mu <- 0.2 + 0.6 * b$x + b$eta_slope
  sigma <- exp(-0.3 + 0.15 * z); nu <- 1.6
  delta <- nu / sqrt(1 + nu^2); ms <- sqrt(2 / pi) * delta
  omega <- sigma / sqrt(1 - ms^2); xi <- mu - omega * ms
  y <- xi + omega * (delta * abs(stats::rnorm(b$n)) + sqrt(1 - delta^2) * stats::rnorm(b$n))
  d <- data.frame(y = y, x = b$x, z = z, id = b$id)
  fit <- drmTMB(bf(y ~ x + (0 + x | id), sigma ~ z, nu ~ 1), family = skew_normal(), data = d)
  expect_mu_random_slope_recovered(fit, "skew_normal", b$slope, b$slope_sd, cor_min = 0.65)
  expect_error(
    drmTMB(bf(y ~ x + (0 + x | p | id), sigma ~ z, nu ~ 1), family = skew_normal(), data = d),
    "random intercept"
  )
})

test_that("tweedie mu supports an independent random slope", {
  b <- base_slope(20260721)
  mu <- exp(0.2 + 0.5 * b$x + b$eta_slope)
  y <- drmTMB:::rtweedie_compound(b$n, mu = mu, phi = 1.4, power = 1.5)
  d <- data.frame(y = y, x = b$x, id = b$id)
  fit <- drmTMB(bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1), family = tweedie(), data = d)
  expect_mu_random_slope_recovered(fit, "tweedie", b$slope, b$slope_sd, cor_min = 0.55)
  expect_error(
    drmTMB(bf(y ~ x + (0 + x | p | id), sigma ~ 1, nu ~ 1), family = tweedie(), data = d),
    "random intercept"
  )
})

test_that("zero_one_beta mu supports an independent random slope", {
  b <- base_slope(20260722)
  mu <- stats::plogis(0.3 + 0.7 * b$x + b$eta_slope); phi <- 1 / 0.4^2
  y <- stats::rbeta(b$n, mu * phi, (1 - mu) * phi)
  bound <- stats::runif(b$n) < 0.15
  y[bound] <- ifelse(stats::runif(sum(bound)) < 0.5, 1, 0)
  d <- data.frame(y = y, x = b$x, id = b$id)
  fit <- drmTMB(bf(y ~ x + (0 + x | id)), family = zero_one_beta(), data = d)
  expect_mu_random_slope_recovered(fit, "zero_one_beta", b$slope, b$slope_sd, cor_min = 0.40)
  expect_error(
    drmTMB(bf(y ~ x + (0 + x | p | id)), family = zero_one_beta(), data = d),
    "random intercept"
  )
})

test_that("binomial mu supports an independent random slope (trials > 1)", {
  b <- base_slope(20260723)
  p <- stats::plogis(-0.2 + 0.7 * b$x + b$eta_slope); trials <- stats::rpois(b$n, 10) + 4
  succ <- stats::rbinom(b$n, trials, p)
  d <- data.frame(succ = succ, fail = trials - succ, x = b$x, id = b$id)
  fit <- drmTMB(bf(cbind(succ, fail) ~ x + (0 + x | id)), family = binomial(), data = d)
  expect_mu_random_slope_recovered(fit, "binomial", b$slope, b$slope_sd, cor_min = 0.40)
  expect_error(
    drmTMB(bf(cbind(succ, fail) ~ x + (0 + x | p | id)), family = binomial(), data = d),
    "random intercept"
  )
})

test_that("cumulative_logit mu supports an independent random slope", {
  b <- base_slope(20260724)
  cut <- c(-1, 0, 1)
  lat <- 0.8 * b$x + b$eta_slope + stats::rlogis(b$n)
  y <- ordered(findInterval(lat, cut) + 1L, levels = 1:4)
  d <- data.frame(y = y, x = b$x, id = b$id)
  fit <- drmTMB(bf(y ~ x + (0 + x | id)), family = cumulative_logit(), data = d)
  expect_mu_random_slope_recovered(fit, "cumulative_logit", b$slope, b$slope_sd, cor_min = 0.35)
  expect_error(
    drmTMB(bf(y ~ x + (0 + x | p | id)), family = cumulative_logit(), data = d),
    "random intercept"
  )
})

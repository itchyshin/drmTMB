# M1 (Dinnage audit, issue #1307): the mi_family == 1 (Bernoulli) two-point
# mixture site was repaired in test-dinnage-audit-wave1.R to move weights(i)
# outside the mixture (w * log(sum) instead of log(sum of w-th powers)). The
# same defect is still present at the eleven other mi_family sites (2..12):
# weights(i) multiplies each quadrature leaf BEFORE logspace_add() combines
# them, and the combined log_denom is subtracted with no outer weight at all,
# so `weights = c` does not equal literal row duplication for any
# non-Bernoulli impute_model() family. One block per mi_family, mirroring the
# fixture shape of the matching tests/testthat/test-missing-predictor-*.R file
# but with ~25% of the imputed covariate missing (vs. the ~8-10% used by
# those fixtures, which target manual-loglik parity rather than a weight
# sweep).
#
# Fisher's caveat (docs/dev-log/audits/2026-09-13-dinnage-wave1-review.md,
# S3): invariance must be asserted at a converged optimum, so every fit's
# opt$convergence is checked before coefficients are compared.

run_mi_weight_invariance <- function(fit_fn, dat, dup_tolerance = 1e-5) {
  fit_w1 <- fit_fn(dat, weights = rep(1, nrow(dat)))
  testthat::expect_equal(fit_w1$opt$convergence, 0L)

  fit_w2 <- fit_fn(dat, weights = rep(2, nrow(dat)))
  testthat::expect_equal(fit_w2$opt$convergence, 0L)

  fit_dup <- fit_fn(rbind(dat, dat))
  testthat::expect_equal(fit_dup$opt$convergence, 0L)

  coef_w1 <- unlist(coef(fit_w1))
  coef_w2 <- unlist(coef(fit_w2))
  coef_dup <- unlist(coef(fit_dup))

  # The exact statement of the M1 contract: the weighted objective IS the
  # weight times the unweighted objective, at any parameter value. Evaluated
  # at the weights = 2 optimum (and at the weights = 1 optimum) through the
  # fitted TMB objective, so a weight that multiplies only part of a row's
  # contribution (a leaf inside a mixture, or an unweighted imputation prior)
  # fails here by a parameter-dependent margin, not by optimizer noise.
  for (p in list(fit_w2$opt$par, fit_w1$opt$par)) {
    testthat::expect_equal(
      fit_w2$obj$fn(p),
      2 * fit_w1$obj$fn(p),
      tolerance = 1e-10
    )
  }

  testthat::expect_equal(coef_w1, coef_w2, tolerance = 1e-6)
  testthat::expect_equal(coef_dup, coef_w2, tolerance = dup_tolerance)
}

test_that("M1 ordinal: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  # A deterministic cut() of a smooth function of z (the missing-predictor
  # ordered fixture's shape) makes score's posterior given z nearly a point
  # mass, which hides this defect (the weighted and unweighted mixture forms
  # coincide when one state dominates). Draw the latent score with real noise
  # around a moderate z-signal instead, so the imputation posterior actually
  # spreads mass over more than one state.
  set.seed(2)
  n <- 60
  z <- stats::rnorm(n)
  latent <- 0.5 * z + stats::rnorm(n, 0, 1)
  score_full <- cut(
    latent,
    breaks = stats::quantile(latent, c(0, 1 / 3, 2 / 3, 1)),
    labels = c("low", "medium", "high"),
    include.lowest = TRUE,
    ordered_result = TRUE
  )
  score_effect <- c(low = -0.45, medium = 0.15, high = 0.65)
  y <- 1 +
    0.35 * z +
    unname(score_effect[as.character(score_full)]) +
    stats::rnorm(n, 0, 0.4)
  dat <- data.frame(y = y, z = z, score = score_full)
  miss_idx <- seq(3, n, by = 4)
  dat$score[miss_idx] <- NA

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(score), sigma ~ 1),
      data = data,
      impute = list(score = impute_model(score ~ z, family = cumulative_logit())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 categorical: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  # As with ordinal above: the missing-predictor categorical fixture's
  # deterministic threshold on a smooth score hides this defect behind a
  # near-point-mass posterior. Draw habitat with sample() against z-dependent
  # probabilities so the imputation posterior genuinely spreads mass.
  set.seed(3)
  n <- 66
  z <- stats::rnorm(n)
  p_forest <- stats::plogis(-0.3 * z)
  p_grass <- stats::plogis(0.2 * z) * 0.5
  p_wetland <- pmax(0.05, 1 - p_forest - p_grass)
  probs <- cbind(p_forest, p_grass, p_wetland)
  probs <- probs / rowSums(probs)
  habitat_full <- factor(
    vapply(seq_len(n), function(i) {
      sample(c("forest", "grass", "wetland"), 1, prob = probs[i, ])
    }, character(1)),
    levels = c("forest", "grass", "wetland")
  )
  habitat_effect <- c(forest = -0.35, grass = 0.2, wetland = 0.75)
  y <- 1 +
    0.35 * z +
    unname(habitat_effect[as.character(habitat_full)]) +
    stats::rnorm(n, 0, 0.4)
  dat <- data.frame(y = y, z = z, habitat = habitat_full)
  miss_idx <- seq(3, n, by = 4)
  dat$habitat[miss_idx] <- NA

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(habitat), sigma ~ 1),
      data = data,
      impute = list(habitat = impute_model(habitat ~ z, family = categorical())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 beta: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  set.seed(4)
  n <- 72
  z <- seq(-1.8, 1.8, length.out = n)
  cover_full <- stats::plogis(
    -0.25 + 0.9 * z + 0.18 * sin(seq_len(n) / 5)
  )
  y <- 0.35 + 1.25 * cover_full - 0.30 * z + 0.04 * cos(seq_len(n) / 4)
  dat <- data.frame(y = y, z = z, cover = cover_full)
  miss_idx <- seq(3, n, by = 4)
  dat$cover[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = data,
      impute = list(cover = impute_model(cover ~ z, family = beta())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 poisson: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  # The missing-predictor poisson fixture rounds a deterministic mean-plus-
  # wobble, which is nearly recoverable from z alone and hides this defect
  # behind a near-point-mass posterior. Draw actual rpois() counts so the
  # imputation posterior has genuine spread.
  set.seed(5)
  n <- 76
  z <- stats::rnorm(n)
  lambda <- exp(0.5 + 0.35 * z)
  abundance_full <- stats::rpois(n, lambda)
  y <- 1 + 0.30 * abundance_full - 0.2 * z + stats::rnorm(n, 0, 0.5)
  dat <- data.frame(y = y, z = z, abundance = abundance_full)
  miss_idx <- seq(3, n, by = 4)
  dat$abundance[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(abundance), sigma ~ 1),
      data = data,
      impute = list(abundance = impute_model(abundance ~ z, family = poisson())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 lognormal: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  set.seed(6)
  n <- 76
  z <- seq(-1.6, 1.6, length.out = n)
  biomass_full <- exp(0.15 + 0.55 * z + 0.10 * sin(seq_len(n) / 4))
  y <- 0.40 + 0.85 * biomass_full - 0.25 * z + 0.05 * cos(seq_len(n) / 5)
  dat <- data.frame(y = y, z = z, biomass = biomass_full)
  miss_idx <- seq(3, n, by = 4)
  dat$biomass[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = data,
      impute = list(biomass = impute_model(biomass ~ z, family = lognormal())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 gamma: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  set.seed(7)
  n <- 78
  z <- seq(-1.7, 1.7, length.out = n)
  mean_full <- exp(0.20 + 0.45 * z)
  biomass_full <- mean_full * (1 + 0.18 * sin(seq_len(n) / 4))
  y <- 0.35 + 0.75 * biomass_full - 0.20 * z + 0.04 * cos(seq_len(n) / 5)
  dat <- data.frame(y = y, z = z, biomass = biomass_full)
  miss_idx <- seq(3, n, by = 4)
  dat$biomass[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = data,
      impute = list(biomass = impute_model(biomass ~ z, family = Gamma(link = "log"))),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 nbinom2: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  # The missing-predictor nbinom2 fixture assigns qnbinom() quantiles by a
  # deterministic rank permutation of z, which is nearly recoverable from z
  # alone and hides this defect. Draw actual rnbinom() counts so the
  # imputation posterior has genuine spread.
  set.seed(8)
  n <- 84
  z <- stats::rnorm(n)
  mu <- exp(0.6 + 0.35 * z)
  size <- 1 / 0.65^2
  abundance_full <- stats::rnbinom(n, size = size, mu = mu)
  y <- 1 + 0.25 * abundance_full - 0.2 * z + stats::rnorm(n, 0, 0.5)
  dat <- data.frame(y = y, z = z, abundance = abundance_full)
  miss_idx <- seq(3, n, by = 4)
  dat$abundance[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(abundance), sigma ~ 1),
      data = data,
      impute = list(abundance = impute_model(abundance ~ z, family = nbinom2())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 tweedie: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  set.seed(9)
  n <- 82
  z <- seq(-1.7, 1.8, length.out = n)
  mean_full <- exp(0.10 + 0.45 * z)
  zero <- seq_len(n) %% 6 %in% c(0, 1)
  biomass_full <- ifelse(
    zero,
    0,
    mean_full * (1 + 0.16 * sin(seq_len(n) / 4))
  )
  y <- 0.25 + 0.62 * biomass_full - 0.18 * z + 0.04 * cos(seq_len(n) / 6)
  dat <- data.frame(y = y, z = z, biomass = biomass_full)
  miss_idx <- seq(3, n, by = 4)
  dat$biomass[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = data,
      impute = list(biomass = impute_model(biomass ~ z, family = tweedie())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  # The duplication arm is loosened for tweedie ONLY, and for a reason that is
  # not M1: drm_build_tweedie_missing_predictor_model() sizes its fixed
  # 35-node Legendre quadrature support from a start-value dispersion
  # phi = var(x_observed) / mean(mu^power), and stats::var() divides by n - 1,
  # so rbind(dat, dat) changes phi, the support, and hence the numerical value
  # of the same integral (measured: 1.3 nats over 20 missing rows at
  # identical parameters, ~1e-2 on the sigma intercept). The weights = 2 fit
  # uses the n-row support, so the two objective-identity checks above are
  # the exact M1 assertion here; the duplication arm only guards the gross
  # pre-fix bias. Tracked as a separate finding (quadrature support should
  # not depend on a moment estimate), not fixed in the M1 change.
  run_mi_weight_invariance(fit_fn, dat, dup_tolerance = 1e-2)
})

test_that("M1 zero_one_beta: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  set.seed(10)
  n <- 96
  z <- seq(-2, 2, length.out = n)
  cover_full <- stats::plogis(-0.20 + 0.85 * z + 0.12 * sin(seq_len(n) / 4))
  zero_rows <- seq(6, n, by = 18)
  one_rows <- seq(13, n, by = 19)
  cover_full[zero_rows] <- 0
  cover_full[one_rows] <- 1
  y <- 0.25 + 1.15 * cover_full - 0.28 * z + 0.05 * cos(seq_len(n) / 5)
  dat <- data.frame(y = y, z = z, cover = cover_full)
  miss_idx <- seq(3, n, by = 4)
  dat$cover[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = data,
      impute = list(cover = impute_model(cover ~ z, family = zero_one_beta())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 truncated_nbinom2: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  # The missing-predictor truncated_nbinom2 fixture assigns qnbinom() quantiles
  # by a deterministic rank permutation of z, which hides this defect behind a
  # near-point-mass posterior. Draw zero-truncated NB counts by inverse-CDF
  # sampling on a uniform above the zero mass, so the imputation posterior has
  # genuine spread.
  set.seed(11)
  n <- 84
  z <- stats::rnorm(n)
  mu <- exp(0.8 + 0.35 * z)
  sigma <- 0.55
  size <- 1 / sigma^2
  p0 <- stats::dnbinom(0, size = size, mu = mu)
  u <- stats::runif(n, p0, 1)
  abundance_full <- stats::qnbinom(u, size = size, mu = mu)
  y <- 1 + 0.20 * abundance_full - 0.15 * z + stats::rnorm(n, 0, 0.5)
  dat <- data.frame(y = y, z = z, abundance = abundance_full)
  miss_idx <- seq(3, n, by = 4)
  dat$abundance[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(abundance), sigma ~ 1),
      data = data,
      impute = list(abundance = impute_model(abundance ~ z, family = truncated_nbinom2())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

test_that("M1 beta_binomial: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  set.seed(12)
  n <- 86
  z <- seq(-1.8, 1.8, length.out = n)
  trials <- rep(8:16, length.out = n)
  sigma_mi_true <- 0.35
  phi <- 1 / sigma_mi_true^2
  mu_mi <- stats::plogis(-0.25 + 0.85 * z)
  latent_level <- ppoints(n)[order(order(cos(2 * seq_len(n))))]
  count_level <- ppoints(n)[order(order(sin(seq_len(n))))]
  p <- stats::qbeta(latent_level, mu_mi * phi, (1 - mu_mi) * phi)
  success_full <- stats::qbinom(count_level, size = trials, prob = p)
  cover_full <- success_full / trials
  y <- 0.30 + 1.15 * cover_full - 0.24 * z + 0.05 * cos(seq_len(n) / 6)
  dat <- data.frame(
    y = y,
    z = z,
    cover = cover_full,
    success = success_full,
    trials = trials
  )
  miss_idx <- seq(3, n, by = 4)
  dat$cover[miss_idx] <- NA_real_
  dat$success[miss_idx] <- NA_real_

  fit_fn <- function(data, weights = NULL) {
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = data,
      impute = list(
        cover = impute_model(
          success ~ z,
          family = beta_binomial(),
          trials = trials
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    )
  }

  run_mi_weight_invariance(fit_fn, dat)
})

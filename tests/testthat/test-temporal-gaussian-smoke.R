temporal_smoke_data <- function(with_intercept = FALSE) {
  set.seed(20260908)
  dat <- expand.grid(
    id = sprintf("site_%02d", seq_len(8L)),
    occasion = c(0L, 1L, 3L, 4L),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  dat$treatment <- rep(rep(c(0, 1), each = 4L), length.out = nrow(dat))
  dat$y <- 0.4 + 0.6 * dat$treatment + stats::rnorm(nrow(dat), sd = 0.5)
  dat
}

test_that("ordinary Gaussian fixed-effect fits retain their established estimates", {
  dat <- temporal_smoke_data()
  fit <- drmTMB(
    bf(y ~ treatment, sigma ~ 1),
    data = dat,
    family = gaussian(),
    REML = FALSE
  )
  reference <- stats::lm(y ~ treatment, data = dat)
  expect_equal(unname(fit$coefficients$mu), unname(stats::coef(reference)), tolerance = 1e-7)
  expect_equal(
    unname(exp(fit$coefficients$sigma)),
    unname(stats::sigma(reference) * sqrt(stats::df.residual(reference) / nrow(dat))),
    tolerance = 1e-7
  )
})

test_that("Gaussian AR1 temporal random effects fit with and without a stable intercept", {
  dat <- temporal_smoke_data()
  ar1_only <- drmTMB(
    bf(y ~ treatment + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat,
    family = gaussian(),
    REML = FALSE
  )
  expect_s3_class(ar1_only, "drmTMB")
  expect_true(is.finite(stats::logLik(ar1_only)))
  expect_equal(sort(ar1_only$temporal_start_attempts$persistence_start), c(-0.3, 0.3))
  expect_equal(sum(ar1_only$temporal_start_attempts$selected), 1L)

  combined <- drmTMB(
    bf(y ~ treatment + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat,
    family = gaussian(),
    REML = FALSE
  )
  expect_s3_class(combined, "drmTMB")
  expect_true(is.finite(stats::logLik(combined)))
  temporal_label <- temporal_mu_sd_label(combined$model$structured$temporal_mu)
  expect_setequal(names(combined$sdpars$mu), c("(1 | id)", temporal_label))
  expect_named(
    combined$corpars$temporal,
    combined$model$structured$temporal_mu$label
  )
  expect_true(is.finite(exp(unname(combined$coefficients$sigma))))
})

test_that("temporal AR1 data checks preserve the intended admission boundary", {
  dat <- temporal_smoke_data()
  duplicated <- rbind(dat, dat[1L, ])
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = duplicated, family = gaussian(), REML = FALSE
    ),
    "keys must be unique"
  )
  dat$occasion <- as.numeric(dat$occasion) + 0.5
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "finite integers"
  )
  dat <- temporal_smoke_data()
  dat$occasion <- 2L * (match(dat$occasion, c(0L, 1L, 3L, 4L)) - 1L)
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "lag variation"
  )
  dat <- temporal_smoke_data()
  dat$y[1L] <- NA_real_
  dat$occasion[2L] <- NA_integer_
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "before response omission"
  )
})

test_that("combined temporal AR1 enforces its same-ID and multiple-series contract", {
  dat <- temporal_smoke_data()
  dat$other <- rep(c("a", "b"), length.out = nrow(dat))
  expect_error(
    drmTMB(
      bf(y ~ (1 | other) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "same ID"
  )
  one_series <- dat[dat$id == dat$id[[1L]], , drop = FALSE]
  expect_error(
    drmTMB(
      bf(y ~ (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = one_series, family = gaussian(), REML = FALSE
    ),
    "multiple series"
  )
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ treatment),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "sigma ~ 1"
  )
})

test_that("temporal AR1 rejects deferred family, estimator, and scale combinations explicitly", {
  dat <- temporal_smoke_data()
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = poisson()
    ),
    "only for univariate Gaussian"
  )
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = TRUE
    ),
    "maximum likelihood"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ temporal(1 | id, time = occasion, structure = "ar1"),
        sigma ~ 1,
        sd(id) ~ 1
      ),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "additional modelling feature"
  )
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE, weights = rep(2, nrow(dat))
    ),
    "unit likelihood weights"
  )
})

test_that("temporal AR1 exposes labelled components and mean-only Wald inference", {
  dat <- temporal_smoke_data()
  dat <- dat[rep(seq_len(nrow(dat)), 3L), , drop = FALSE]
  dat$id <- paste(dat$id, rep(seq_len(3L), each = 32L), sep = "_")
  fit <- suppressWarnings(drmTMB(
    bf(y ~ treatment + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  ))
  expect_named(fit$sdpars$mu, temporal_mu_sd_label(fit$model$structured$temporal_mu))
  expect_named(fit$corpars$temporal, fit$model$structured$temporal_mu$label)
  expect_named(fit$random_effects$temporal, c("values", "latent", "terms"))
  expect_identical(
    rownames(stats::vcov(fit)),
    c("mu:(Intercept)", "mu:treatment")
  )
  expect_identical(
    colnames(stats::vcov(fit)),
    c("mu:(Intercept)", "mu:treatment")
  )
  temporal_check <- check_drm(fit)
  temporal_wald <- temporal_check[temporal_check$check == "temporal_mean_wald", , drop = FALSE]
  expect_identical(temporal_wald$status, "note")
  expect_match(temporal_wald$value, "available_for_this_fit")
  expect_match(temporal_wald$message, "coverage calibration remains unresolved")
  non_pd <- fit
  non_pd$sdr$pdHess <- FALSE
  non_pd_check <- check_drm(non_pd)
  non_pd_wald <- non_pd_check[non_pd_check$check == "temporal_mean_wald", , drop = FALSE]
  expect_identical(non_pd_wald$status, "warning")
  expect_match(non_pd_wald$value, "reason=full_hessian")
  intervals <- stats::confint(fit, method = "wald")
  expect_setequal(intervals$parm, c("fixef:mu:(Intercept)", "fixef:mu:treatment"))
  summary_wald <- summary(fit, conf.int = TRUE, method = "wald")
  expect_setequal(summary_wald$confint$parm, intervals$parm)
  expect_error(
    summary(fit, conf.int = TRUE, method = "profile"),
    "Wald intervals only"
  )
  expect_error(
    stats::confint(fit, parm = "sigma", method = "wald"),
    "mean regression coefficients"
  )
  expect_error(stats::confint(fit, method = "profile"), "Wald intervals only")
  expect_error(stats::confint(fit, method = "bootstrap"), "Wald intervals only")
  expect_length(stats::fitted(fit), nrow(dat))
  expect_error(
    stats::predict(fit, newdata = dat[1L, , drop = FALSE]),
    "fitted observations"
  )
  expect_identical(dim(stats::simulate(fit, nsim = 2L, seed = 1L)), c(nrow(dat), 2L))
  expect_identical(
    dim(stats::simulate(fit, nsim = 2L, seed = 1L, re.form = NA)),
    c(nrow(dat), 2L)
  )
})

test_that("temporal fitted values, residuals, and simulation modes use the intended latent effects", {
  dat <- temporal_smoke_data()
  fit <- suppressWarnings(drmTMB(
    bf(y ~ treatment + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  ))
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  conditional_mu <- fixed_mu +
    mu_random_effect_contribution(fit, dpar = "mu") +
    temporal_mu_contribution(fit)
  expect_equal(stats::fitted(fit), conditional_mu)
  expect_equal(stats::residuals(fit), fit$model$y - conditional_mu)

  set.seed(918)
  expected_conditional <- conditional_mu + stats::rnorm(
    nrow(dat), sd = observation_sigma(fit)
  )
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 918, re.form = NA)[[1L]]),
    expected_conditional
  )

  set.seed(919)
  fresh_draws <- drm_ordinary_random_effect_draws(fit)
  fresh_mu <- drm_marginal_predict(fit, "mu", fresh_draws)
  expected_fresh <- stats::rnorm(nrow(dat), mean = fresh_mu, sd = observation_sigma(fit))
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 919)[[1L]]),
    expected_fresh
  )
})

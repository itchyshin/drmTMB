test_that("fixed priors admit one Gaussian mean random intercept", {
  d <- data.frame(y = 1:6, x = 1:6, g = rep(letters[1:3], each = 2))
  p <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
  expect_no_error(drmTMB:::drm_validate_fixed_prior_request(
    p, bf(y ~ x + (1 | g), sigma ~ 1), gaussian(), d
  ))
})

test_that("fixed priors refuse other random-effect shapes", {
  d <- data.frame(y = 1:6, x = 1:6, g = rep(letters[1:3], each = 2), h = rep(1:2, 3))
  p <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
  check <- function(f, family = gaussian()) {
    expect_error(drmTMB:::drm_validate_fixed_prior_request(p, f, family, d),
                 "fixed-effect-only")
  }
  check(bf(y ~ x + (1 + x | g)))
  check(bf(y ~ x + (1 | g) + (1 | h)))
  check(bf(y ~ x, sigma ~ 1 + (1 | g)))
  check(bf(y ~ x + (1 | block | g)))
  check(bf(y ~ x + (1 || g)))
  check(bf(y ~ x + (1 | g)), binomial())
})

test_that("random intercept leaves fixed-effect prior selection intact", {
  d <- data.frame(y = 1:8, x = rep(1:4, 2), f = factor(rep(c("a", "b"), 4)),
                  g = rep(letters[1:4], each = 2))
  p <- drm_priors(drm_prior_normal("mu", "fb", mean = 0.3, sd = 2),
                  drm_prior_ridge("sigma", "(Intercept)", lambda = 0.4))
  r <- drm_resolve_priors(bf(y ~ x + f + (1 | g), sigma ~ 1), gaussian(), d, p)
  expect_identical(r$coefficient, c("fb", "(Intercept)"))
  expect_identical(r$dpar, c("mu", "sigma"))
  expect_equal(r$matrix_column, c(3, 1))
  d$g[1] <- NA
  expect_error(drm_resolve_priors(bf(y ~ x + f + (1 | g)), gaussian(), d, p),
               "complete")
})

test_that("random-intercept prior admission retains the existing data and control fences", {
  d <- data.frame(y = 1:6, x = 1:6, g = rep(letters[1:3], each = 2))
  f <- bf(y ~ x + (1 | g), sigma ~ 1)
  p <- drm_priors(drm_prior_ridge("mu", "x", lambda = 1))
  validate <- drmTMB:::drm_validate_fixed_prior_request
  expect_error(validate(p, f, gaussian(), d, REML = TRUE), "REML")
  expect_error(validate(p, f, gaussian(), d, weights = c(1, 1, 2, 1, 1, 1)), "unit weights")
  expect_error(validate(p, f, gaussian(), d, control = list(sparse_fixed = TRUE)), "dense")
  expect_error(validate(p, f, gaussian(), d, control = list(aggregate_gaussian = TRUE)), "unaggregated")
  expect_error(validate(p, f, gaussian(), d, control = list(logsigma_clamp = c(-2, 2))), "clamp")
})

test_that("random-intercept prior fits preserve update and inference contracts", {
  d <- data.frame(x = rep(c(-1, 0, 1), 6), g = factor(rep(1:6, each = 3)))
  d$y <- 0.5 + 0.6 * d$x + rep(c(-0.5, 0.2, 0.7, -0.3, 0.4, -0.4), each = 3) +
    rep(c(0.1, -0.2, 0.1), 6)
  fm <- bf(y ~ x + (1 | g), sigma ~ 1)
  p <- drm_priors(drm_prior_normal("mu", "x", mean = 0.2, sd = 0.8))
  z <- drm_priors(drm_prior_ridge("mu", "x", lambda = 0))
  fit <- drmTMB(fm, data = d, priors = p, control = drm_control(se = FALSE, logsigma_clamp = NULL))
  expect_equal(fit$penalized_objective, -fit$logLik + fit$fixed_prior_penalty, tolerance = 1e-9)
  expect_identical(fit$estimator, "MAP")
  expect_error(confint(fit), "fixed-effect")
  expect_error(confint(fit, method = "bootstrap"), "fixed-effect")
  expect_error(summary(fit, conf.int = TRUE), "fixed-effect")
  expect_error(predict_parameters(fit, conf.int = TRUE), "fixed-effect")
  expect_error(predict(fit, se.fit = TRUE), "reserved")
  expect_error(AIC(fit), "fixed-effect")
  retained <- update(fit)
  expect_equal(retained$resolved_priors, fit$resolved_priors)
  removed <- update(fit, priors = NULL)
  expect_null(removed$priors)
  expect_identical(removed$estimator, "ML")
  added <- update(removed, priors = p)
  expect_equal(added$resolved_priors, fit$resolved_priors)
  zero <- update(fit, priors = z)
  expect_identical(zero$estimator, "ML")
  expect_equal(zero$fixed_prior_penalty, 0)
  expect_equal(zero$opt$objective, removed$opt$objective, tolerance = 1e-7)
})

test_that("zero ridge preserves random-intercept default ML controls", {
  d <- data.frame(x = rep(c(-1, 0, 1), 6), g = factor(rep(1:6, each = 3)))
  d$y <- 0.5 + 0.6*d$x + rep(c(-0.5, 0.2, 0.7, -0.3, 0.4, -0.4), each = 3) +
    rep(c(0.1, -0.2, 0.1), 6)
  fm <- bf(y ~ x + (1 | g), sigma ~ 1)
  plain <- drmTMB(fm, data = d)
  zero <- drmTMB(fm, data = d, priors = drm_priors(drm_prior_ridge("mu", "x", lambda = 0)))
  expect_identical(zero$estimator, "ML")
  expect_identical(zero$model$tmb_data$use_logsigma_clamp, plain$model$tmb_data$use_logsigma_clamp)
  expect_equal(zero$opt$objective, plain$opt$objective, tolerance = 1e-8)
  expect_equal(unlist(zero$coefficients), unlist(plain$coefficients), tolerance = 1e-8)
})

test_that("profile readiness reflects active priors for fixed and mixed models", {
  d <- data.frame(x = rep(c(-1, 0, 1), 6), g = factor(rep(1:6, each = 3)))
  d$y <- 0.5 + 0.6*d$x + rep(c(-0.5, 0.2, 0.7, -0.3, 0.4, -0.4), each = 3) +
    rep(c(0.1, -0.2, 0.1), 6)
  p <- drm_priors(drm_prior_normal("mu", "x", sd = 0.8))
  z <- drm_priors(drm_prior_ridge("mu", "x", lambda = 0))
  for (fm in list(bf(y ~ x), bf(y ~ x + (1 | g)))) {
    fit <- drmTMB(fm, data = d, priors = p)
    targets <- profile_targets(fit)
    expect_gt(nrow(targets), 0)
    expect_false(any(targets$profile_ready))
    expect_true(all(targets$profile_note == "fixed_prior_inference_unavailable"))
    expect_equal(nrow(profile_targets(fit, ready_only = TRUE)), 0)
    expect_false(any(summary(fit)$parameters$profile_ready))
    expect_error(profile(fit), "fixed-effect")
    zero <- drmTMB(fm, data = d, priors = z)
    plain <- drmTMB(fm, data = d)
    expect_identical(profile_targets(zero)$profile_ready, profile_targets(plain)$profile_ready)
  }
})

test_that("live Julia random-intercept bridge validates prior coordinates", {
  drm_skip_live_julia()
  d <- data.frame(x = rep(c(-1, 0, 1), 6), g = factor(rep(1:6, each = 3)))
  d$y <- 0.5 + 0.6*d$x + rep(c(-0.5, 0.2, 0.7, -0.3, 0.4, -0.4), each = 3) +
    rep(c(0.1, -0.2, 0.1), 6)
  p <- drm_priors(drm_prior_normal("mu", "x", mean = 0.2, sd = 0.8))
  fit <- drmTMB(bf(y ~ x + (1 | g)), data = d, priors = p, engine = "julia")
  expect_identical(fit$resolved_priors$coefficient, "x")
  expect_equal(names(coef(fit, dpar = "mu")), colnames(model.matrix(~x, d)))
  expect_error(confint(fit, method = "profile"), "fixed-effect")
  payload <- fit$bridge_payload
  payload$options$prior_expected[[1L]]$coef <- "__wrong_coordinate__"
  expect_error(drmTMB:::drm_julia_call_conditional_gaussian_components(
    payload$formula, "gaussian", payload$data, payload$tree, payload$options),
    "resolved prior coordinates differ")
  names_bad <- as.character(fit$bridge$coef_names)
  mu <- grep("^mu_", names_bad)
  expect_gte(length(mu), 2L)
  names_bad[mu[[1L]]] <- paste0(names_bad[mu[[1L]]], "__wrong")
  expect_error(drmTMB:::drm_julia_bridge_check_coef_labels(names_bad, fit$bridge_payload),
               "do not match")
  fm <- bf(y ~ x + (1 | g))
  plain <- drmTMB(fm, data = d, engine = "julia")
  zero <- drmTMB(fm, data = d, engine = "julia",
                 priors = drm_priors(drm_prior_ridge("mu", "x", lambda = 0)))
  expect_true(isTRUE(plain$bridge$converged))
  expect_true(isTRUE(zero$bridge$converged))
  expect_identical(plain$estimator, "ML")
  expect_identical(zero$estimator, "ML")
  expect_equal(zero$fixed_prior_penalty, 0, tolerance = 0)
  expect_equal(zero$logLik, plain$logLik, tolerance = 1e-7)
  expect_equal(zero$penalized_objective, -plain$logLik, tolerance = 1e-7)
  expect_equal(unlist(zero$coefficients), unlist(plain$coefficients), tolerance = 1e-5)
})

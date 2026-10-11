# #1459 — open design question. The continuous mi() prior is NOT multiplied
# by case weights. These tests pin that current behaviour and the R gates
# around it. They do not change the prior. Pending Shinichi's decision:
# should the prior be weighted so weight 2 matches a duplicated row?

test_that("unit weights are detected as unit, non-unit weights are not", {
  expect_true(drmTMB:::drm_weights_are_unit(NULL))
  expect_true(drmTMB:::drm_weights_are_unit(rep(1, 5)))
  expect_false(drmTMB:::drm_weights_are_unit(rep(2, 5)))
  expect_false(drmTMB:::drm_weights_are_unit(c(1, 1, 2)))
  expect_false(drmTMB:::drm_weights_are_unit(c(1, NA, 1)))
})

test_that("mi() plus non-unit weights emits the classed #1459 warning helper", {
  expect_false(drmTMB:::drm_warn_mi_prior_ignores_weights(NULL, TRUE))
  expect_false(drmTMB:::drm_warn_mi_prior_ignores_weights(rep(1, 4), TRUE))
  expect_false(drmTMB:::drm_warn_mi_prior_ignores_weights(rep(2, 4), FALSE))
  expect_warning(
    drmTMB:::drm_warn_mi_prior_ignores_weights(rep(2, 4), TRUE),
    class = "drmTMB_mi_weights_prior_unweighted"
  )
})

test_that("weight 0 or NA on a missing mi() covariate is a named error", {
  observed <- c(TRUE, FALSE, TRUE, FALSE)
  expect_false(drmTMB:::drm_abort_mi_zero_weight_missing(NULL, observed, "x"))
  expect_false(drmTMB:::drm_abort_mi_zero_weight_missing(rep(1, 4), observed, "x"))
  expect_false(drmTMB:::drm_abort_mi_zero_weight_missing(c(2, 1, 1, 1), observed, "x"))
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing(c(1, 0, 1, 1), observed, "x"),
    class = "drmTMB_mi_zero_weight_missing"
  )
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing(c(1, NA, 1, 1), observed, "x"),
    class = "drmTMB_mi_zero_weight_missing"
  )
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing(c(1, 1, 1, 0), observed, "x"),
    class = "drmTMB_mi_zero_weight_missing"
  )
  dat <- data.frame(x = c(0.1, NA_real_, 0.3), y = 1:3)
  impute <- list(x = x ~ 1)
  expect_false(drmTMB:::drm_abort_mi_zero_weight_missing_in_data(dat, NULL, impute))
  expect_false(drmTMB:::drm_abort_mi_zero_weight_missing_in_data(dat, rep(1, 3), impute))
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing_in_data(dat, c(1, 0, 1), impute),
    class = "drmTMB_mi_zero_weight_missing"
  )
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing_in_data(dat, c(1, NA, 1), impute),
    class = "drmTMB_mi_zero_weight_missing"
  )
}))

test_that("predict/simulate refuse an explicit weights argument on an mi() fit", {
  object <- list(missing_data = list(predictors = list(x = list(variable = "x"))))
  expect_false(drmTMB:::drm_abort_mi_weights_predict(object, list()))
  expect_false(drmTMB:::drm_abort_mi_weights_predict(
    list(missing_data = list(predictors = list())),
    list(weights = 1)
  ))
  expect_error(
    drmTMB:::drm_abort_mi_weights_predict(object, list(weights = rep(2, 3))),
    class = "drmTMB_mi_weights_predict_unsupported"
  )
})

mi_weights_1459_data <- function() {
  n <- 40
  z <- seq(-1.2, 1.2, length.out = n)
  x <- 0.2 + 0.6 * z + 0.08 * sin(seq_len(n) / 3)
  y <- 0.4 + 0.7 * x - 0.15 * z
  dat <- data.frame(y = y, z = z, x = x)
  dat$x[c(6, 18, 30)] <- NA_real_
  dat
}

fit_mi_weights_1459 <- function(dat, weights = NULL) {
  drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE),
    weights = weights
  )
}

gaussian_mi_prior_term <- function(fit, rows = NULL) {
  rp <- fit$obj$report(fit$obj$env$last.par.best)
  x <- as.numeric(rp$mi_x_full)
  eta <- as.vector(fit$model$missing_predictor$X %*% coef(fit, "mi_x"))
  sigma <- as.numeric(rp$sigma_mi)
  if (is.null(rows)) {
    rows <- seq_along(x)
  }
  stats::dnorm(x[rows], eta[rows], sigma, log = TRUE)
}

test_that("weights = 1 with mi() matches the unweighted fit exactly (#1459)", {
  dat <- mi_weights_1459_data()
  fit0 <- fit_mi_weights_1459(dat)
  expect_no_warning(
    fit1 <- fit_mi_weights_1459(dat, weights = rep(1, nrow(dat)))
  )
  expect_equal(unname(unlist(coef(fit0))), unname(unlist(coef(fit1))), tolerance = 1e-10)
  expect_equal(as.numeric(logLik(fit0)), as.numeric(logLik(fit1)), tolerance = 1e-10)
  expect_equal(
    fit0$obj$fn(fit0$opt$par),
    fit1$obj$fn(fit1$opt$par),
    tolerance = 1e-10
  )
})

test_that("weight-2 matches a duplicated row in the response only (#1459 pending)", {
  dat <- mi_weights_1459_data()
  w <- rep(1, nrow(dat))
  w[[2L]] <- 2
  expect_warning(
    fit_w2 <- fit_mi_weights_1459(dat, weights = w),
    class = "drmTMB_mi_weights_prior_unweighted"
  )
  dat_dup <- rbind(dat, dat[2, , drop = FALSE])
  fit_dup <- fit_mi_weights_1459(dat_dup)
  expect_equal(fit_w2$opt$convergence, 0L)
  expect_equal(fit_dup$opt$convergence, 0L)
  p <- fit_w2$opt$par
  nll_w2 <- fit_w2$obj$fn(p)
  prior_row2 <- gaussian_mi_prior_term(fit_w2, 2L)
  # Row 2 is observed x. Weight 2 multiplies the response only, so the
  # duplicated-row objective at the same parameter includes one extra
  # unweighted prior copy. nll = -logLik, so the gap is -prior_row2.
  expect_equal(
    fit_dup$obj$fn(p) - nll_w2,
    -prior_row2,
    tolerance = 1e-6
  )
  expect_false(isTRUE(all.equal(
    unname(unlist(coef(fit_w2))),
    unname(unlist(coef(fit_dup))),
    tolerance = 1e-5
  )))
})

test_that("weight 0 or NA on a missing mi() covariate is a named error at fit time", {
  dat <- mi_weights_1459_data()
  w0 <- rep(1, nrow(dat))
  w0[6] <- 0
  expect_error(
    fit_mi_weights_1459(dat, weights = w0),
    class = "drmTMB_mi_zero_weight_missing"
  )
  w_na <- rep(1, nrow(dat))
  w_na[6] <- NA_real_
  expect_error(
    fit_mi_weights_1459(dat, weights = w_na),
    class = "drmTMB_mi_zero_weight_missing"
  )
})

test_that("weight 0 multiplies the response once and never yields 0 * Inf", {
  dat <- mi_weights_1459_data()
  w <- rep(1, nrow(dat))
  w[[4L]] <- 0
  expect_warning(
    fit0 <- fit_mi_weights_1459(dat, weights = w),
    class = "drmTMB_mi_weights_prior_unweighted"
  )
  expect_true(is.finite(fit0$obj$fn(fit0$opt$par)))
  dat_y <- dat
  dat_y$y[[4L]] <- dat_y$y[[4L]] + 50
  expect_warning(
    fit_y <- fit_mi_weights_1459(dat_y, weights = w),
    class = "drmTMB_mi_weights_prior_unweighted"
  )
  # Row 4 is observed x; changing y with weight 0 must not move the nll
  # at a shared parameter (response ignored). The prior is still present.
  p <- fit0$opt$par
  expect_equal(fit0$obj$fn(p), fit_y$obj$fn(p), tolerance = 1e-8)
})

test_that("predict and simulate honour a weighted mi() fit via fitted coefficients", {
  dat <- mi_weights_1459_data()
  w <- rep(1, nrow(dat))
  w[[2L]] <- 2
  expect_warning(
    fit <- fit_mi_weights_1459(dat, weights = w),
    class = "drmTMB_mi_weights_prior_unweighted"
  )
  pred <- predict(fit, dpar = "mu")
  expect_true(all(is.finite(pred)))
  expect_equal(length(pred), nrow(dat))
  sims <- simulate(fit, nsim = 1, seed = 1, re.form = NA)
  expect_true(all(is.finite(as.matrix(sims))))
  expect_error(
    predict(fit, dpar = "mu", weights = w),
    class = "drmTMB_mi_weights_predict_unsupported"
  )
  expect_error(
    simulate(fit, nsim = 1, weights = w),
    class = "drmTMB_mi_weights_predict_unsupported"
  )
})

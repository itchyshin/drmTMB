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
  expect_true(drmTMB:::drm_mi_prior_path_unweighted(list(enabled = TRUE, family = "gaussian")))
  expect_true(drmTMB:::drm_mi_prior_path_unweighted(
    list(enabled = TRUE, family = "beta"),
    list(enabled = TRUE)
  ))
  expect_false(drmTMB:::drm_mi_prior_path_unweighted(list(enabled = TRUE, family = "beta")))
  expect_false(drmTMB:::drm_mi_prior_path_unweighted(list(enabled = TRUE, family = "gamma")))
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
})

test_that("predict/simulate refuse an explicit weights argument on an mi() fit", {
  object <- list(missing_data = list(predictors = list(x = list(variable = "x"))))
  expect_false(drmTMB:::drm_abort_mi_weights_predict(object, list()))
  expect_false(drmTMB:::drm_abort_mi_weights_predict(
    list(missing_data = list(predictors = list())),
    list(weights = 1)
  ))
  expect_false(drmTMB:::drm_abort_mi_weights_predict(object, list(weights = 1)))
  expect_false(drmTMB:::drm_abort_mi_weights_predict(object, list(weights = rep(1, 3))))
  expect_error(
    drmTMB:::drm_abort_mi_weights_predict(object, list(weights = rep(2, 3))),
    class = "drmTMB_mi_weights_predict_unsupported"
  )
})

mi_weights_1459_data <- function() {
  n <- 48
  z <- seq(-1.5, 1.5, length.out = n)
  x <- 0.25 + 0.8 * z + 0.08 * sin(seq_len(n))
  y <- 0.7 + 1.4 * x - 0.35 * z + 0.12 * cos(seq_len(n) / 3)
  dat <- data.frame(y = y, z = z, x = x)
  dat$x[c(6, 18, 30)] <- NA_real_
  dat
}

mi_weight_warnings <- function(expr) {
  warns <- list()
  value <- withCallingHandlers(
    eval.parent(substitute(expr)),
    warning = function(w) {
      warns <<- c(warns, list(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = warns)
}

has_warning_class <- function(warns, class) {
  any(vapply(warns, inherits, logical(1), class))
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
  cap0 <- mi_weight_warnings(fit_mi_weights_1459(dat))
  cap1 <- mi_weight_warnings(
    fit_mi_weights_1459(dat, weights = rep(1, nrow(dat)))
  )
  fit0 <- cap0$value
  fit1 <- cap1$value
  expect_false(has_warning_class(cap0$warnings, "drmTMB_mi_weights_prior_unweighted"))
  expect_false(has_warning_class(cap1$warnings, "drmTMB_mi_weights_prior_unweighted"))
  expect_equal(unname(unlist(coef(fit0))), unname(unlist(coef(fit1))), tolerance = 1e-10)
  expect_equal(as.numeric(logLik(fit0)), as.numeric(logLik(fit1)), tolerance = 1e-10)
  expect_equal(
    as.numeric(fit0$obj$fn(fit0$opt$par)),
    as.numeric(fit1$obj$fn(fit1$opt$par)),
    tolerance = 1e-10
  )
})

test_that("Gaussian weight-2 matches a duplicated row in the response only (#1459 pending)", {
  dat <- mi_weights_1459_data()
  w <- rep(1, nrow(dat))
  w[[2L]] <- 2
  cap_w2 <- mi_weight_warnings(fit_mi_weights_1459(dat, weights = w))
  expect_true(has_warning_class(cap_w2$warnings, "drmTMB_mi_weights_prior_unweighted"))
  fit_w2 <- cap_w2$value
  dat_dup <- rbind(dat, dat[2, , drop = FALSE])
  fit_dup <- mi_weight_warnings(fit_mi_weights_1459(dat_dup))$value
  expect_equal(fit_w2$opt$convergence, 0L)
  expect_equal(fit_dup$opt$convergence, 0L)
  p <- fit_w2$opt$par
  nll_w2 <- as.numeric(fit_w2$obj$fn(p))
  prior_row2 <- as.numeric(gaussian_mi_prior_term(fit_w2, 2L))
  # Row 2 is observed x. Weight 2 multiplies the response only, so the
  # duplicated-row objective at the same parameter includes one extra
  # unweighted prior copy. nll = -logLik, so the gap is -prior_row2.
  expect_equal(
    as.numeric(fit_dup$obj$fn(p)) - nll_w2,
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

test_that("weight 0 keeps a -Inf Gaussian density off the tape (#1459)", {
  dat <- mi_weights_1459_data()
  w <- rep(1, nrow(dat))
  w[[4L]] <- 0
  cap0 <- mi_weight_warnings(fit_mi_weights_1459(dat, weights = w))
  expect_true(has_warning_class(cap0$warnings, "drmTMB_mi_weights_prior_unweighted"))
  fit0 <- cap0$value
  # y = 1e200 on a weight-0 row poisons starting values if we refit from
  # scratch. Rebuild the TMB object at the sane MLE so the pin matches
  # the Code Reviewer check (main: fn = NaN, gr = -Inf).
  data_big <- fit0$obj$env$data
  data_big$y[[4L]] <- 1e200
  obj_big <- TMB::MakeADFun(
    data = data_big,
    parameters = fit0$obj$env$parList(),
    map = fit0$obj$env$map,
    random = fit0$obj$env$random,
    DLL = "drmTMB",
    silent = TRUE
  )
  p <- fit0$opt$par
  fn <- as.numeric(obj_big$fn(p))
  gr <- as.numeric(obj_big$gr(p))
  expect_true(is.finite(fn))
  expect_true(length(gr) > 0L)
  expect_true(all(is.finite(gr)))
})

test_that("Gamma mi() plus non-unit weights does not emit the Gaussian-prior warning", {
  skip_on_cran()
  n <- 48
  z <- seq(-1.5, 1.5, length.out = n)
  x <- exp(0.4 + 0.25 * z)
  y <- 0.35 + 0.4 * x - 0.15 * z
  dat <- data.frame(y = y, z = z, x = x)
  dat$x[c(8, 20, 32)] <- NA_real_
  w <- rep(2, n)
  cap <- mi_weight_warnings(drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE),
    weights = w
  ))
  expect_false(has_warning_class(cap$warnings, "drmTMB_mi_weights_prior_unweighted"))
  expect_true(is.finite(as.numeric(cap$value$obj$fn(cap$value$opt$par))))
})

test_that("Beta mi() plus non-unit weights does not emit the Gaussian-prior warning", {
  n <- 48
  z <- seq(-1.5, 1.5, length.out = n)
  cover <- stats::plogis(-0.25 + 0.9 * z + 0.08 * sin(seq_len(n)))
  y <- 0.35 + 1.2 * cover - 0.25 * z + 0.04 * cos(seq_len(n) / 4)
  dat <- data.frame(y = y, z = z, cover = cover)
  dat$cover[c(8, 20, 32)] <- NA_real_
  w <- rep(2, n)
  cap <- mi_weight_warnings(drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(cover = impute_model(cover ~ z, family = beta_family())),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE),
    weights = w
  ))
  expect_false(has_warning_class(cap$warnings, "drmTMB_mi_weights_prior_unweighted"))
  expect_true(is.finite(as.numeric(cap$value$obj$fn(cap$value$opt$par))))
})

test_that("predict and simulate honour a weighted mi() fit via fitted coefficients", {
  dat <- mi_weights_1459_data()
  w <- rep(1, nrow(dat))
  w[[2L]] <- 2
  cap <- mi_weight_warnings(fit_mi_weights_1459(dat, weights = w))
  expect_true(has_warning_class(cap$warnings, "drmTMB_mi_weights_prior_unweighted"))
  fit <- cap$value
  pred <- predict(fit, dpar = "mu")
  expect_true(all(is.finite(pred)))
  expect_equal(length(pred), nrow(dat))
  sims <- simulate(fit, nsim = 1, seed = 1, re.form = NA)
  expect_true(all(is.finite(as.matrix(sims))))
  pred1 <- predict(fit, dpar = "mu", weights = 1)
  expect_equal(as.numeric(pred1), as.numeric(pred), tolerance = 1e-12)
  expect_error(
    predict(fit, dpar = "mu", weights = w),
    class = "drmTMB_mi_weights_predict_unsupported"
  )
  expect_error(
    simulate(fit, nsim = 1, weights = w),
    class = "drmTMB_mi_weights_predict_unsupported"
  )
})

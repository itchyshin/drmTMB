missing_predictor_gaussian_data <- function() {
  z <- seq(-1.5, 1.5, length.out = 48)
  w <- cos(seq_along(z) / 5)
  x_full <- 0.25 + 0.8 * z - 0.15 * w + 0.08 * sin(seq_along(z))
  y <- 0.7 + 1.4 * x_full - 0.35 * z + 0.12 * cos(seq_along(z) / 3)
  dat <- data.frame(y = y, x = x_full, z = z, w = w)
  dat$x[c(6, 17, 31, 42)] <- NA_real_
  dat
}

fit_missing_predictor_gaussian <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + w),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

missing_predictor_joint_gaussian_data <- function() {
  n <- 48L
  z <- seq(-1.3, 1.3, length.out = n)
  e1 <- sin(seq_len(n) * 0.73)
  e2 <- cos(seq_len(n) * 0.41)
  x1 <- 0.35 + 0.70 * z + e1
  x2 <- -0.20 - 0.45 * z + 0.50 * e1 + e2
  y <- 0.80 + 0.45 * z + 0.90 * x1 - 0.65 * x2 +
    0.20 * sin(seq_len(n) / 3)
  dat <- data.frame(y = y, z = z, x1 = x1, x2 = x2)
  dat$x1[c(4, 11, 23, 37)] <- NA_real_
  dat$x2[c(7, 11, 29, 42)] <- NA_real_
  dat
}

fit_missing_predictor_joint_gaussian <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(x1) + mi(x2), sigma ~ 1),
    data = dat,
    impute = impute_joint(cbind(x1, x2) ~ z),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

joint_gaussian_observed_nll <- function(fit, dat) {
  par <- fit$obj$env$parList(fit$opt$par)
  p <- length(par$beta_mi) / 2L
  beta_x <- matrix(par$beta_mi, nrow = p)
  sigma_x <- exp(par$log_sigma_mi)
  rho_x <- 0.999999 * tanh(par$eta_cor_mi[[1L]])
  Sigma_x <- diag(sigma_x) %*%
    matrix(c(1, rho_x, rho_x, 1), nrow = 2L) %*%
    diag(sigma_x)
  beta_y <- par$beta_mu
  sigma_y <- exp(par$beta_sigma[[1L]])
  nll <- 0
  for (i in seq_len(nrow(dat))) {
    mean_x <- as.vector(c(1, dat$z[[i]]) %*% beta_x)
    mean_y <- beta_y[[1L]] + beta_y[[2L]] * dat$z[[i]] +
      sum(beta_y[3:4] * mean_x)
    cov_yx <- as.vector(t(beta_y[3:4]) %*% Sigma_x)
    Sigma <- rbind(
      c(sigma_y^2 + sum(beta_y[3:4] * (Sigma_x %*% beta_y[3:4])), cov_yx),
      cbind(cov_yx, Sigma_x)
    )
    value <- c(dat$y[[i]], dat$x1[[i]], dat$x2[[i]])
    keep <- !is.na(value)
    delta <- value[keep] - c(mean_y, mean_x)[keep]
    Sigma_keep <- Sigma[keep, keep, drop = FALSE]
    nll <- nll + 0.5 * (
      length(delta) * log(2 * pi) +
        log(det(Sigma_keep)) +
        drop(crossprod(delta, solve(Sigma_keep, delta)))
    )
  }
  nll
}

test_that("joint Gaussian mi() matches an independent observed-data likelihood", {
  dat <- missing_predictor_joint_gaussian_data()
  fit <- fit_missing_predictor_joint_gaussian(dat)

  expect_equal(nobs(fit), nrow(dat))
  expect_named(fit$missing_data$predictors, c("x1", "x2"))
  expect_equal(fit$missing_data$predictors$x1$model_row, which(is.na(dat$x1)))
  expect_equal(fit$missing_data$predictors$x2$model_row, which(is.na(dat$x2)))
  expect_true(all(is.finite(fitted(fit))))
  expect_true(all(is.finite(coef(fit, "mi_x1"))))
  expect_true(all(is.finite(coef(fit, "mi_x2"))))
  expect_true(is.finite(coef(fit)$rho_mi_x1_x2[[1L]]))
  expect_equal(
    joint_gaussian_observed_nll(fit, dat),
    fit$opt$objective,
    tolerance = 1e-7
  )
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-3)

  x1 <- imputed(fit, "x1", se = FALSE)
  x2 <- imputed(fit, "x2", se = FALSE)
  expect_equal(x1$model_row, which(is.na(dat$x1)))
  expect_equal(x2$model_row, which(is.na(dat$x2)))
  expect_true(all(is.finite(x1$estimate)))
  expect_true(all(is.finite(x2$estimate)))
})

test_that("joint Gaussian mi() ignores missing-value storage sentinels", {
  dat <- missing_predictor_joint_gaussian_data()
  fit <- fit_missing_predictor_joint_gaussian(dat)
  data_sentinel <- fit$model$tmb_data
  missing <- data_sentinel$mi_observed_joint == 0L
  data_sentinel$mi_x_joint[missing] <- c(-999, 999)[(seq_len(sum(missing)) - 1L) %% 2L + 1L]
  obj_sentinel <- TMB::MakeADFun(
    data = data_sentinel,
    parameters = fit$model$start,
    map = fit$model$map,
    random = fit$model$tmb_random_names,
    DLL = "drmTMB",
    silent = TRUE
  )
  expect_equal(
    obj_sentinel$fn(fit$opt$par),
    fit$obj$fn(fit$opt$par),
    tolerance = 1e-10
  )
  expect_equal(
    obj_sentinel$gr(fit$opt$par),
    fit$obj$gr(fit$opt$par),
    tolerance = 1e-8
  )
})

test_that("joint Gaussian mi() keeps its narrow grammar boundary", {
  dat <- missing_predictor_joint_gaussian_data()
  expect_error(
    impute_joint(cbind(x1, x2) ~ z + (1 | group)),
    "fixed-effect"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x1) + mi(x2) + mi(x3), sigma ~ 1),
      data = transform(dat, x3 = z),
      impute = impute_joint(cbind(x1, x2) ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "exactly two"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x1):mi(x2), sigma ~ 1),
      data = dat,
      impute = impute_joint(cbind(x1, x2) ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "simple additive"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x1) + mi(x2), sigma ~ z),
      data = dat,
      impute = impute_joint(cbind(x1, x2) ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "sigma ~ 1"
  )
  dat_response_missing <- dat
  dat_response_missing$y[[2L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x1) + mi(x2), sigma ~ 1),
      data = dat_response_missing,
      impute = impute_joint(cbind(x1, x2) ~ z),
      missing = miss_control(response = "include", predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "does not combine"
  )
})

test_that("joint Gaussian mi() has a fixed-seed parameter-recovery smoke", {
  set.seed(20260813)
  n <- 600L
  z <- rnorm(n)
  Sigma_x <- matrix(c(1, 0.5, 0.5, 1.44), nrow = 2L)
  error_x <- matrix(rnorm(2L * n), nrow = n) %*% chol(Sigma_x)
  x1 <- 0.3 + 0.7 * z + error_x[, 1L]
  x2 <- -0.2 - 0.4 * z + error_x[, 2L]
  y <- 1 + 0.5 * z + 0.8 * x1 - 0.6 * x2 + rnorm(n, sd = 0.7)
  dat <- data.frame(y = y, z = z, x1 = x1, x2 = x2)
  dat$x1[sample.int(n, 120L)] <- NA_real_
  dat$x2[sample.int(n, 120L)] <- NA_real_

  fit <- fit_missing_predictor_joint_gaussian(dat)
  estimate <- coef(fit)
  expect_lt(abs(estimate$mu[["mi(x1)"]] - 0.8), 0.2)
  expect_lt(abs(estimate$mu[["mi(x2)"]] + 0.6), 0.2)
  expect_lt(abs(estimate$mi_x1[["mi_x1_z"]] - 0.7), 0.2)
  expect_lt(abs(estimate$mi_x2[["mi_x2_z"]] + 0.4), 0.2)
  expect_lt(abs(estimate$rho_mi_x1_x2[[1L]] - 0.5), 0.2)
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
})

missing_predictor_grouped_gaussian_data <- function() {
  group <- factor(rep(letters[1:8], each = 7))
  z <- seq(-1.4, 1.4, length.out = length(group))
  group_shift <- rep(seq(-0.45, 0.45, length.out = 8), each = 7)
  x_full <- 0.15 + 0.65 * z + group_shift + 0.05 * sin(seq_along(z))
  y <- 0.6 + 1.35 * x_full - 0.25 * z + 0.08 * cos(seq_along(z) / 4)
  dat <- data.frame(y = y, x = x_full, z = z, group = group)
  dat$x[c(4, 15, 26, 41, 52)] <- NA_real_
  dat
}

fit_missing_predictor_grouped_gaussian <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + (1 | group)),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

missing_predictor_structured_gaussian_data <- function() {
  line <- factor(rep(letters[1:6], each = 6))
  z <- seq(-1.2, 1.2, length.out = length(line))
  line_shift <- rep(c(-0.40, -0.15, 0.05, 0.18, 0.32, 0.48), each = 6)
  x_full <- 0.20 + 0.55 * z + line_shift + 0.03 * sin(seq_along(z))
  y <- 0.70 + 1.25 * x_full - 0.20 * z + 0.05 * cos(seq_along(z) / 3)
  dat <- data.frame(y = y, x = x_full, z = z, line = line)
  dat$x[c(3, 10, 17, 25, 32)] <- NA_real_
  Q <- diag(nlevels(line))
  dimnames(Q) <- list(levels(line), levels(line))
  list(data = dat, Q = Q)
}

fit_missing_predictor_structured_gaussian <- function(dat, Q) {
  drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + relmat(1 | line, Q = Q)),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

test_that("Gaussian mi() predictor model retains missing-predictor rows", {
  dat <- missing_predictor_gaussian_data()
  missing_x <- is.na(dat$x)

  fit <- fit_missing_predictor_gaussian(dat)

  expect_equal(nobs(fit), nrow(dat))
  expect_equal(fit$missing_data$version, "MD3a")
  expect_equal(fit$missing_data$predictor_policy, "model")
  expect_equal(fit$missing_data$original_row, seq_len(nrow(dat)))
  expect_equal(fit$missing_data$observed_y, rep(TRUE, nrow(dat)))
  expect_named(fit$missing_data$predictors, "x")
  expect_equal(fit$missing_data$predictors$x$model_row, which(missing_x))
  expect_equal(fit$missing_data$predictors$x$original_row, which(missing_x))
  expect_equal(fit$missing_data$predictors$x$counts$observed, sum(!missing_x))
  expect_equal(fit$missing_data$predictors$x$counts$missing, sum(missing_x))
  expect_true(all(is.finite(fitted(fit))))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_x"))))
  expect_true(all(is.finite(coef(fit, "sigma_mi_x"))))
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
})

test_that("Gaussian mi() predictor models can combine with response masks", {
  dat <- missing_predictor_gaussian_data()
  dat$y[c(3, 18)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + w),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_equal(fit$missing_data$predictors$x$model_row, which(is.na(dat$x)))
  expect_length(fitted(fit), nrow(dat))
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_true(all(is.finite(fitted(fit)[observed_y])))
})

test_that("Gaussian mi() predictor model supports one grouped covariate intercept", {
  dat <- missing_predictor_grouped_gaussian_data()
  missing_x <- is.na(dat$x)

  fit <- fit_missing_predictor_grouped_gaussian(dat)

  expect_equal(fit$missing_data$version, "MD3b")
  expect_equal(nobs(fit), nrow(dat))
  expect_equal(fit$missing_data$predictors$x$model_row, which(missing_x))
  expect_true(fit$missing_data$predictors$x$random$enabled)
  expect_equal(fit$missing_data$predictors$x$random$group, "group")
  expect_equal(
    fit$missing_data$predictors$x$random$n_group,
    nlevels(dat$group)
  )
  expect_true(all(is.finite(coef(fit, "mi_x"))))
  expect_true(all(is.finite(coef(fit, "sd_mi_group_x"))))
  expect_true(all(is.finite(fitted(fit))))
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
})

test_that("Gaussian grouped mi() predictor model can combine with response masks", {
  dat <- missing_predictor_grouped_gaussian_data()
  dat$y[c(5, 33)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + (1 | group)),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD3b")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_equal(fit$missing_data$predictors$x$model_row, which(is.na(dat$x)))
  expect_true(fit$missing_data$predictors$x$random$enabled)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_true(all(is.finite(fitted(fit)[observed_y])))
})

test_that("Gaussian mi() predictor model supports one structured covariate intercept", {
  fixture <- missing_predictor_structured_gaussian_data()
  dat <- fixture$data
  Q <- fixture$Q
  missing_x <- is.na(dat$x)

  fit <- fit_missing_predictor_structured_gaussian(dat, Q)

  expect_equal(fit$missing_data$version, "MD4")
  expect_equal(nobs(fit), nrow(dat))
  expect_equal(fit$missing_data$predictors$x$model_row, which(missing_x))
  expect_false(fit$missing_data$predictors$x$random$enabled)
  expect_true(fit$missing_data$predictors$x$structured$enabled)
  expect_equal(fit$missing_data$predictors$x$structured$type, "relmat")
  expect_equal(fit$missing_data$predictors$x$structured$group, "line")
  expect_equal(fit$missing_data$predictors$x$structured$n_re, nrow(Q))
  expect_equal(
    fit$missing_data$predictors$x$structured$levels,
    rownames(Q)
  )
  expect_true(all(is.finite(coef(fit, "mi_x"))))
  expect_true(all(is.finite(coef(fit, "sd_mi_relmat_x"))))
  expect_true(all(is.finite(fitted(fit))))
  expect_true(all(is.finite(imputed(fit)$estimate)))
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
})

test_that("Gaussian structured mi() predictor model can combine with response masks", {
  fixture <- missing_predictor_structured_gaussian_data()
  dat <- fixture$data
  Q <- fixture$Q
  dat$y[c(5, 21)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + relmat(1 | line, Q = Q)),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD4")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(fit$missing_data$predictors$x$structured$enabled)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_true(all(is.finite(fitted(fit)[observed_y])))
})

test_that("Gaussian structured mi() predictor model validates the MD4 boundary", {
  fixture <- missing_predictor_structured_gaussian_data()
  dat <- fixture$data
  Q <- fixture$Q

  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = x ~ z + relmat(1 + z | line, Q = Q)),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "intercept-only"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = transform(dat, group = line),
      impute = list(x = x ~ z + relmat(1 | line, Q = Q) + (1 | group)),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "cannot combine"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = transform(dat, partner = line),
      impute = list(
        x = x ~ z +
          phylo_interaction(
            1 | line:partner,
            tree1 = tree1,
            tree2 = tree2
          )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "does not support"
  )

  dat_missing_line <- dat
  dat_missing_line$line[2] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat_missing_line,
      impute = list(x = x ~ z + relmat(1 | line, Q = Q)),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "outside explicit"
  )
})

test_that("imputed() reports MD3a missing-predictor conditional modes", {
  dat <- missing_predictor_gaussian_data()
  missing_x <- is.na(dat$x)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + w),
    missing = miss_control(predictor = "model")
  )

  out <- imputed(fit)
  modes <- fit$obj$env$parList(fit$opt$par)$x_miss

  expect_s3_class(out, "data.frame")
  expect_named(
    out,
    c(
      "variable",
      "original_row",
      "model_row",
      "observed",
      "estimate",
      "std_error",
      "source",
      "uncertainty_status"
    )
  )
  expect_equal(out$variable, rep("x", sum(missing_x)))
  expect_equal(out$original_row, which(missing_x))
  expect_equal(out$model_row, which(missing_x))
  expect_false(any(out$observed))
  expect_equal(out$estimate, as.numeric(modes), tolerance = 1e-8)
  expect_true(all(is.finite(out$std_error)))
  expect_true(all(out$std_error > 0))
  expect_equal(out$source, rep("conditional_mode", sum(missing_x)))
  expect_equal(out$uncertainty_status, rep("ok", sum(missing_x)))
  expect_equal(
    fit$missing_data$predictors$x$conditional_mode,
    as.numeric(modes),
    tolerance = 1e-8
  )
})

test_that("imputed() can return all retained MD3a predictor rows", {
  dat <- missing_predictor_gaussian_data()
  missing_x <- is.na(dat$x)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + w),
    missing = miss_control(predictor = "model")
  )

  out <- imputed(fit, rows = "all")

  expect_equal(nrow(out), nrow(dat))
  expect_equal(out$original_row, seq_len(nrow(dat)))
  expect_equal(out$observed, !missing_x)
  expect_equal(out$estimate[!missing_x], dat$x[!missing_x], tolerance = 1e-12)
  expect_true(all(is.na(out$std_error[!missing_x])))
  expect_equal(out$source[!missing_x], rep("observed", sum(!missing_x)))
  expect_equal(
    out$estimate[missing_x],
    fit$missing_data$predictors$x$conditional_mode,
    tolerance = 1e-8
  )
})

test_that("imputed() works without retained TMB object but marks unavailable SEs", {
  dat <- missing_predictor_gaussian_data()

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + w),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE, keep_tmb_object = FALSE)
  )

  out <- imputed(fit)

  expect_null(fit$obj)
  expect_equal(
    out$estimate,
    fit$missing_data$predictors$x$conditional_mode,
    tolerance = 1e-8
  )
  expect_true(all(is.na(out$std_error)))
  expect_equal(out$uncertainty_status, rep("sdreport_skipped", nrow(out)))
})

test_that("imputed() supports grouped MD3b missing-predictor fits", {
  dat <- missing_predictor_grouped_gaussian_data()
  missing_x <- is.na(dat$x)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = x ~ z + (1 | group)),
    missing = miss_control(predictor = "model")
  )

  out <- imputed(fit, variable = "x")

  expect_equal(fit$missing_data$version, "MD3b")
  expect_equal(out$original_row, which(missing_x))
  expect_equal(out$source, rep("conditional_mode", sum(missing_x)))
  expect_true(all(is.finite(out$estimate)))
  expect_true(all(is.finite(out$std_error)))
})

test_that("imputed() errors outside fitted missing-predictor summaries", {
  dat <- missing_predictor_gaussian_data()

  fit_response <- drmTMB(
    bf(y ~ z, sigma ~ 1),
    data = transform(dat, y = replace(y, 3, NA_real_)),
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  expect_error(imputed(fit_response), "no modelled missing predictors")

  fit_mi <- fit_missing_predictor_gaussian(dat)
  expect_error(imputed(fit_mi, variable = "w"), "Unknown")
})

test_that("Gaussian mi() predictor model validates the first MD3a boundary", {
  dat <- missing_predictor_gaussian_data()

  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "impute"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + x, sigma ~ 1),
      data = dat,
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "exactly one"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x) + mi(w), sigma ~ 1),
      data = dat,
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "exactly one"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(log(x)), sigma ~ 1),
      data = dat,
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "bare predictor"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x):z, sigma ~ 1),
      data = dat,
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "simple additive"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(w = x ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "must match"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = x ~ .),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "explicit predictor names"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = x ~ y + z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "response variables"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = transform(
        dat,
        group = factor(rep(letters[1:6], length.out = nrow(dat)))
      ),
      impute = list(x = x ~ z + (0 + z | group)),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "random intercepts"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = transform(
        dat,
        group = factor(rep(letters[1:6], length.out = nrow(dat)))
      ),
      impute = list(x = x ~ z + (1 | group) + (1 | w)),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "only one random-intercept"
  )

  dat_missing_z <- dat
  dat_missing_z$z[4] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat_missing_z,
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "outside explicit"
  )

  dat_missing_group <- transform(
    dat,
    group = factor(rep(letters[1:6], length.out = nrow(dat)))
  )
  dat_missing_group$group[2] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat_missing_group,
      impute = list(x = x ~ z + (1 | group)),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "outside explicit"
  )
})

test_that("ordinary missing predictors still use complete-case behaviour", {
  dat <- missing_predictor_gaussian_data()
  keep <- stats::complete.cases(dat[, c("y", "x", "z")])

  fit_default <- drmTMB(
    bf(y ~ z + x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_cc <- drmTMB(
    bf(y ~ z + x, sigma ~ 1),
    data = dat[keep, , drop = FALSE],
    control = drm_control(se = FALSE)
  )

  expect_equal(fit_default$missing_data$response_policy, "drop")
  expect_equal(fit_default$missing_data$predictor_policy, "fail")
  expect_equal(fit_default$missing_data$original_row, which(keep))
  expect_equal(coef(fit_default, "mu"), coef(fit_cc, "mu"), tolerance = 1e-8)
  expect_equal(as.numeric(logLik(fit_default)), as.numeric(logLik(fit_cc)))
})

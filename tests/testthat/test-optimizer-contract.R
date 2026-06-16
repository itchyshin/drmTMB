test_that("optimizer presets expand to explicit nlminb controls", {
  default <- drm_control()
  expect_equal(default$optimizer_preset, "default")
  expect_equal(default$optimizer, list())

  careful <- drm_control(optimizer_preset = "careful")
  expect_equal(careful$optimizer, list(iter.max = 1000L, eval.max = 1000L))

  robust <- drm_control(
    optimizer_preset = "robust",
    optimizer = list(eval.max = 8000L, trace = 1L)
  )
  expect_equal(
    robust$optimizer,
    list(iter.max = 5000L, eval.max = 8000L, trace = 1L)
  )

  expect_error(drm_control(optimizer_preset = "wide"), "should be one of")
})

test_that("optimizer presets are recorded on fitted objects", {
  dat <- data.frame(y = c(-0.2, 0.0, 0.3, 0.6), x = c(-1, 0, 1, 2))

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(optimizer_preset = "careful", se = FALSE)
  )

  expect_equal(fit$control$optimizer_preset, "careful")
  expect_equal(fit$control$optimizer$iter.max, 1000L)
  expect_equal(fit$control$optimizer$eval.max, 1000L)
  expect_equal(fit$optimizer_used$optimizer, "nlminb")
  expect_equal(fit$optimizer_used$optimizer_preset, "careful")
  expect_false(fit$optimizer_used$retried)
  expect_equal(fit$optimizer_attempts$optimizer_preset, "careful")
  expect_equal(fit$optimizer_attempts$status, "ok")
  expect_equal(fit$uncertainty$status, "skipped")
})

test_that("default optimizer errors retry larger nlminb presets", {
  obj <- list(
    par = c(beta = 1),
    fn = function(par) sum(par^2),
    gr = function(par) 2 * par
  )
  calls <- list()
  optimizer <- function(start, objective, gradient, control) {
    calls[[length(calls) + 1L]] <<- control
    if (length(calls) == 1L) {
      stop("NA/NaN gradient evaluation")
    }
    list(
      par = start,
      objective = objective(start),
      convergence = 0L,
      message = "relative convergence (4)",
      iterations = 1L,
      evaluations = c("function" = 1L, "gradient" = 1L)
    )
  }

  expect_snapshot(
    result <- drmTMB:::drm_optimize_with_preset_retry(
      obj,
      drm_control(),
      optimizer = optimizer
    )
  )

  expect_equal(length(calls), 2L)
  expect_equal(calls[[1L]], list())
  expect_equal(calls[[2L]], list(iter.max = 1000L, eval.max = 1000L))
  expect_equal(result$selected$optimizer, "nlminb")
  expect_equal(result$selected$optimizer_preset, "careful")
  expect_true(result$selected$retried)
  expect_equal(result$attempts$optimizer_preset, c("default", "careful"))
  expect_equal(result$attempts$status, c("error", "ok"))
  expect_false(result$attempts$selected[[1L]])
  expect_true(result$attempts$selected[[2L]])
})

test_that("custom optimizer controls do not enter the preset retry ladder", {
  obj <- list(
    par = c(beta = 1),
    fn = function(par) sum(par^2),
    gr = function(par) 2 * par
  )
  calls <- list()
  optimizer <- function(start, objective, gradient, control) {
    calls[[length(calls) + 1L]] <<- control
    stop("NA/NaN gradient evaluation")
  }

  expect_snapshot(
    drmTMB:::drm_optimize_with_preset_retry(
      obj,
      drm_control(optimizer = list(eval.max = 10L)),
      optimizer = optimizer
    ),
    error = TRUE
  )

  expect_equal(length(calls), 1L)
  expect_equal(calls[[1L]], list(eval.max = 10L))
})

test_that("preset retry reports failure after all larger presets fail", {
  obj <- list(
    par = c(beta = 1),
    fn = function(par) sum(par^2),
    gr = function(par) 2 * par
  )
  calls <- list()
  optimizer <- function(start, objective, gradient, control) {
    calls[[length(calls) + 1L]] <<- control
    stop("NA/NaN gradient evaluation")
  }

  expect_snapshot(
    drmTMB:::drm_optimize_with_preset_retry(
      obj,
      drm_control(),
      optimizer = optimizer
    ),
    error = TRUE
  )

  expect_equal(length(calls), 3L)
  expect_equal(calls[[1L]], list())
  expect_equal(calls[[2L]], list(iter.max = 1000L, eval.max = 1000L))
  expect_equal(calls[[3L]], list(iter.max = 5000L, eval.max = 5000L))
})

test_that("future optimizer contract names are reserved in plain control lists", {
  dat <- data.frame(y = c(-0.2, 0.0, 0.3, 0.6), x = c(-1, 0, 1, 2))
  reserved <- c(
    "optimizer_preset",
    "start",
    "starts",
    "start_from",
    "warm_start",
    "warm_starts",
    "warm_start_from",
    "map",
    "fixed",
    "fallback_optimizer",
    "fallback_optimizers",
    "optimizer_fallback",
    "optimizer_fallbacks",
    "multi_start",
    "multistart"
  )

  for (name in reserved) {
    control <- stats::setNames(list(TRUE), name)
    expect_error(
      drmTMB(
        bf(y ~ x, sigma ~ 1),
        data = dat,
        control = control
      ),
      "reserved"
    )
    expect_error(
      drm_control(optimizer = control),
      "reserved"
    )
  }

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = list(start = TRUE, map = TRUE)
    ),
    "start"
  )
})

test_that("Gaussian fixed-effect starts use OLS mean and residual scale", {
  dat <- data.frame(
    x = seq(-1.5, 1.5, length.out = 10),
    z = rep(c(-0.5, 0.25), length.out = 10)
  )
  dat$y <- 0.6 +
    0.8 * dat$x +
    c(-0.15, 0.12, -0.05, 0.22, -0.18, 0.08, 0.16, -0.12, 0.04, -0.02)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    data = dat,
    control = drm_control(se = FALSE)
  )

  X_mu <- stats::model.matrix(~x, dat)
  X_sigma <- stats::model.matrix(~z, dat)
  expected_mu <- stats::lm.fit(x = X_mu, y = dat$y)$coefficients
  expected_mu[is.na(expected_mu)] <- 0
  resid <- dat$y - as.vector(X_mu %*% expected_mu)
  y_scale <- stats::sd(dat$y)
  sigma_floor <- max(1e-4, 0.05 * y_scale)
  expected_sigma0 <- sqrt(max(stats::var(resid), sigma_floor^2))
  expected_sigma <- drmTMB:::gaussian_sigma_fixed_start(
    resid = resid,
    X_sigma = X_sigma,
    sigma0 = expected_sigma0,
    sigma_floor = sigma_floor,
    observed_y = rep(TRUE, nrow(dat))
  )

  expect_equal(unname(fit$model$start$beta_mu), unname(expected_mu))
  expect_equal(unname(fit$model$start$beta_sigma), unname(expected_sigma))
  expect_equal(fit$uncertainty$status, "skipped")
})

test_that("Gaussian fixed-effect sigma starts use residual scale slopes", {
  dat <- data.frame(
    x = seq(-1, 1, length.out = 80),
    z = rep(seq(-1, 1, length.out = 8), length.out = 80)
  )
  mu <- 0.2 + 0.5 * dat$x
  sigma <- exp(-0.7 + 0.6 * dat$z)
  eps <- rep(c(-1.4, -0.6, 0.2, 1.1, -0.9, 0.7, 1.5, -0.3), 10)
  dat$y <- mu + sigma * eps

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$uncertainty$status, "skipped")
  expect_gt(abs(unname(fit$model$start$beta_sigma[["z"]])), 0.05)
})

test_that("bivariate Gaussian starts use response-specific OLS and Fisher-z rho12", {
  dat <- data.frame(x = seq(-1.5, 1.5, length.out = 12))
  e1 <- c(
    -0.25,
    -0.05,
    0.16,
    0.22,
    -0.14,
    0.08,
    0.18,
    -0.16,
    0.06,
    -0.03,
    0.12,
    -0.19
  )
  e2 <- 0.35 *
    e1 +
    c(
      0.08,
      -0.14,
      0.04,
      -0.07,
      0.13,
      -0.03,
      0.10,
      -0.11,
      0.05,
      -0.06,
      0.02,
      -0.01
    )
  dat$y1 <- 0.4 + 0.7 * dat$x + e1
  dat$y2 <- -0.2 + 0.45 * dat$x + e2

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  X <- stats::model.matrix(~x, dat)
  expected_mu1 <- stats::lm.fit(x = X, y = dat$y1)$coefficients
  expected_mu2 <- stats::lm.fit(x = X, y = dat$y2)$coefficients
  expected_mu1[is.na(expected_mu1)] <- 0
  expected_mu2[is.na(expected_mu2)] <- 0
  resid1 <- dat$y1 - as.vector(X %*% expected_mu1)
  resid2 <- dat$y2 - as.vector(X %*% expected_mu2)
  expected_sigma1 <- sqrt(max(stats::var(resid1), 1e-4^2))
  expected_sigma2 <- sqrt(max(stats::var(resid2), 1e-4^2))
  expected_rho <- max(min(stats::cor(resid1, resid2), 0.8), -0.8)

  expect_equal(unname(fit$model$start$beta_mu1), unname(expected_mu1))
  expect_equal(unname(fit$model$start$beta_mu2), unname(expected_mu2))
  expect_equal(unname(fit$model$start$beta_sigma1), log(expected_sigma1))
  expect_equal(unname(fit$model$start$beta_sigma2), log(expected_sigma2))
  expect_equal(unname(fit$model$start$beta_rho12), atanh(expected_rho))
  expect_equal(fit$uncertainty$status, "skipped")
})

test_that("bivariate Gaussian sigma starts use residual scale slopes", {
  dat <- data.frame(
    x = seq(-1, 1, length.out = 80),
    z1 = rep(seq(-1, 1, length.out = 8), length.out = 80),
    z2 = rep(seq(1, -1, length.out = 8), length.out = 80)
  )
  mu1 <- 0.2 + 0.4 * dat$x
  mu2 <- -0.1 + 0.3 * dat$x
  sigma1 <- exp(-0.8 + 0.55 * dat$z1)
  sigma2 <- exp(-0.6 - 0.45 * dat$z2)
  eps1 <- rep(c(-1.4, -0.6, 0.2, 1.1, -0.9, 0.7, 1.5, -0.3), 10)
  eps2 <- rep(c(0.4, -1.2, 0.8, -0.5, 1.3, -0.1, -0.7, 1.0), 10)
  dat$y1 <- mu1 + sigma1 * eps1
  dat$y2 <- mu2 + sigma2 * eps2

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$uncertainty$status, "skipped")
  expect_gt(abs(unname(fit$model$start$beta_sigma1[["z1"]])), 0.05)
  expect_gt(abs(unname(fit$model$start$beta_sigma2[["z2"]])), 0.05)
})

test_that("Gaussian constant sigma remains an optimized parameter", {
  dat <- data.frame(
    y = c(-0.22, -0.04, 0.19, 0.43, 0.73, 0.96, 1.20),
    x = seq(-1.5, 1.5, length.out = 7)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_null(fit$model$map$beta_sigma)
  expect_equal(sum(names(fit$opt$par) == "beta_sigma"), 1L)
  expect_equal(
    length(fit$opt$par),
    ncol(fit$model$X$mu) + ncol(fit$model$X$sigma)
  )
  expect_equal(fit$df, length(fit$opt$par))
})

test_that("bivariate Gaussian constant sigmas remain optimized parameters", {
  dat <- data.frame(x = seq(-1, 1, length.out = 10))
  e1 <- c(-0.12, 0.03, 0.09, -0.06, 0.15, -0.08, 0.04, 0.11, -0.05, 0.02)
  e2 <- c(0.05, -0.10, 0.07, 0.02, -0.04, 0.09, -0.03, 0.06, -0.08, 0.01)
  dat$y1 <- 0.15 + 0.55 * dat$x + e1
  dat$y2 <- -0.20 + 0.35 * dat$x + e2

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_null(fit$model$map$beta_sigma1)
  expect_null(fit$model$map$beta_sigma2)
  expect_equal(sum(names(fit$opt$par) == "beta_sigma1"), 1L)
  expect_equal(sum(names(fit$opt$par) == "beta_sigma2"), 1L)
  expect_equal(
    length(fit$opt$par),
    ncol(fit$model$X$mu1) +
      ncol(fit$model$X$mu2) +
      ncol(fit$model$X$sigma1) +
      ncol(fit$model$X$sigma2) +
      ncol(fit$model$X$rho12)
  )
  expect_equal(fit$df, length(fit$opt$par))
})

test_that("reported parameters are split from the selected optimum", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )

  par_list <- fit$obj$env$parList(fit$opt$par)
  expect_equal(
    fit$coefficients,
    drmTMB:::split_tmb_parameters(
      par_list,
      fit$model
    )
  )
  expect_equal(fit$sdpars, drmTMB:::split_tmb_sdpars(par_list, fit$model))
  expect_equal(fit$corpars, drmTMB:::split_tmb_corpars(par_list, fit$model))
  expect_equal(fit$uncertainty$status, "ok")
})

test_that("profile intervals re-pin the TMB object to the selected optimum", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  bad_par <- fit$opt$par + seq_along(fit$opt$par)
  fit$obj$env$last.par <- bad_par
  fit$obj$env$last.par.best <- bad_par

  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  expect_equal(unname(fit$obj$env$last.par), unname(fit$opt$par))
  expect_equal(unname(fit$obj$env$last.par.best), unname(fit$opt$par))

  fit$obj$env$last.par <- bad_par
  fit$obj$env$last.par.best <- bad_par
  ci <- stats::confint(
    fit,
    parm = "fixef:mu:(Intercept)",
    method = "profile",
    trace = FALSE
  )
  expect_equal(ci$conf.status, "profile")
  expect_lt(ci$lower, unname(fit$coefficients$mu[["(Intercept)"]]))
  expect_gt(ci$upper, unname(fit$coefficients$mu[["(Intercept)"]]))
})

test_that("pinning preserves random-effect slots in the TMB object", {
  set.seed(20260515)
  id <- factor(rep(seq_len(8), each = 5))
  x <- rep(seq(-1, 1, length.out = 5), times = 8)
  u <- stats::rnorm(8, sd = 0.4)
  dat <- data.frame(
    y = 0.2 + 0.5 * x + u[id] + stats::rnorm(length(id), sd = 0.35),
    x = x,
    id = id
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  original_last <- fit$obj$env$last.par
  fit$obj$env$last.par <- original_last + seq_along(original_last)
  fit$obj$env$last.par.best <- fit$obj$env$last.par.best +
    seq_along(fit$obj$env$last.par.best)

  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  fixed <- fit$obj$env$lfixed()
  expect_equal(length(fit$obj$env$last.par), length(fit$tmb_state$last.par))
  expect_equal(unname(fit$obj$env$last.par[fixed]), unname(fit$opt$par))
  expect_equal(
    unname(fit$obj$env$last.par[!fixed]),
    unname(fit$tmb_state$last.par[!fixed])
  )
  expect_equal(
    unname(fit$obj$env$last.par.best),
    unname(fit$tmb_state$last.par.best)
  )
  expect_true(all(is.finite(ranef(fit)$mu$values)))
})

# --- #570 start-candidate rescue ladder -------------------------------------

test_that("start ladder records every candidate and selects the lowest converged objective", {
  obj <- list(
    par = c(theta = 0),
    fn = function(par) (par[["theta"]] - 3)^2,
    gr = function(par) 2 * (par[["theta"]] - 3)
  )
  optimizer <- function(start, objective, gradient, control) {
    list(
      par = start,
      objective = objective(start),
      convergence = 0L,
      message = "relative convergence (4)",
      iterations = 1L,
      evaluations = c("function" = 1L, "gradient" = 1L)
    )
  }
  candidates <- list(
    list(label = "cold", par = c(theta = 0)),
    list(label = "warm", par = c(theta = 3))
  )

  result <- drmTMB:::drm_run_start_ladder(
    obj,
    drm_control(se = FALSE),
    candidates,
    optimizer = optimizer
  )

  expect_equal(result$attempts$start_label, c("cold", "warm"))
  expect_equal(result$attempts$status, c("ok", "ok"))
  expect_equal(result$attempts$objective, c(9, 0))
  expect_equal(result$attempts$eligible, c(TRUE, TRUE))
  expect_equal(result$attempts$selected, c(FALSE, TRUE))
  expect_true(result$selected_converged)
  expect_equal(result$selected$start_label, "warm")
  expect_equal(unname(result$opt$par[["theta"]]), 3)
  expect_equal(result$opt$objective, 0)
  expect_true(all(is.finite(result$attempts$max_gradient)))
})

test_that("start ladder prefers a converged attempt over a lower non-converged objective", {
  obj <- list(
    par = c(theta = 0),
    fn = function(par) par[["theta"]],
    gr = function(par) 1
  )
  optimizer <- function(start, objective, gradient, control) {
    conv <- if (start[["theta"]] < 0) 1L else 0L
    list(
      par = start,
      objective = objective(start),
      convergence = conv,
      message = "m",
      iterations = 1L,
      evaluations = c("function" = 1L, "gradient" = 1L)
    )
  }
  candidates <- list(
    list(label = "converged_high", par = c(theta = 5)),
    list(label = "unconverged_low", par = c(theta = -2))
  )

  result <- drmTMB:::drm_run_start_ladder(
    obj,
    drm_control(se = FALSE),
    candidates,
    optimizer = optimizer
  )

  expect_equal(result$attempts$convergence, c(0L, 1L))
  expect_equal(result$attempts$eligible, c(TRUE, FALSE))
  expect_equal(result$selected$start_label, "converged_high")
  expect_true(result$selected_converged)
})

test_that("start ladder returns the best attempt and flags failure when none converge", {
  obj <- list(
    par = c(theta = 0),
    fn = function(par) par[["theta"]]^2,
    gr = function(par) 2 * par[["theta"]]
  )
  optimizer <- function(start, objective, gradient, control) {
    list(
      par = start,
      objective = objective(start),
      convergence = 1L,
      message = "false convergence (8)",
      iterations = 1L,
      evaluations = c("function" = 1L, "gradient" = 1L)
    )
  }
  candidates <- list(
    list(label = "cold", par = c(theta = 4)),
    list(label = "warm", par = c(theta = 1))
  )

  expect_warning(
    result <- drmTMB:::drm_run_start_ladder(
      obj,
      drm_control(se = FALSE),
      candidates,
      optimizer = optimizer
    ),
    "did not reach a converged optimum"
  )

  expect_false(result$selected_converged)
  expect_equal(result$selected$start_label, "warm")
  expect_equal(result$opt$objective, 1)
  expect_true(all(result$attempts$convergence == 1L))
  expect_false(any(result$attempts$eligible))
})

test_that("start ladder records an errored candidate without selecting it", {
  obj <- list(
    par = c(theta = 0),
    fn = function(par) par[["theta"]]^2,
    gr = function(par) 2 * par[["theta"]]
  )
  optimizer <- function(start, objective, gradient, control) {
    if (start[["theta"]] == 99) {
      stop("NA/NaN function evaluation")
    }
    list(
      par = start,
      objective = objective(start),
      convergence = 0L,
      message = "ok",
      iterations = 1L,
      evaluations = c("function" = 1L, "gradient" = 1L)
    )
  }
  candidates <- list(
    list(label = "cold", par = c(theta = 2)),
    list(label = "broken", par = c(theta = 99))
  )

  result <- drmTMB:::drm_run_start_ladder(
    obj,
    drm_control(se = FALSE),
    candidates,
    optimizer = optimizer
  )

  expect_equal(result$attempts$status, c("ok", "error"))
  expect_equal(result$attempts$start_label, c("cold", "broken"))
  expect_true(is.na(result$attempts$objective[[2L]]))
  expect_true(is.na(result$attempts$max_gradient[[2L]]))
  expect_false(result$attempts$selected[[2L]])
  expect_equal(result$selected$start_label, "cold")
})

test_that("log-SD start candidates scale targeted entries and keep the cold start first", {
  par <- c(
    beta_mu = 0.5,
    log_sd_phylo = log(0.2),
    log_sd_phylo = log(0.25),
    beta_sigma = -0.7
  )

  candidates <- drmTMB:::drm_log_sd_start_candidates(
    par,
    which = "log_sd_phylo",
    factors = c(0.5, 2)
  )

  expect_equal(
    vapply(candidates, `[[`, character(1), "label"),
    c("cold", "log_sd x0.5", "log_sd x2")
  )
  expect_equal(candidates[[1L]]$par, par)
  expect_equal(
    unname(candidates[[3L]]$par[names(par) == "log_sd_phylo"]),
    unname(par[names(par) == "log_sd_phylo"] + log(2))
  )
  expect_equal(
    unname(candidates[[3L]]$par[names(par) == "beta_mu"]),
    unname(par[["beta_mu"]])
  )
  expect_equal(
    unname(candidates[[3L]]$par[names(par) == "beta_sigma"]),
    unname(par[["beta_sigma"]])
  )
})

test_that("log-SD start candidates return only the cold start when no targets are present", {
  par <- c(beta_mu = 0.5, beta_sigma = -0.7)

  candidates <- drmTMB:::drm_log_sd_start_candidates(
    par,
    which = "log_sd_phylo",
    factors = c(0.5, 2)
  )

  expect_length(candidates, 1L)
  expect_equal(candidates[[1L]]$label, "cold")
  expect_equal(candidates[[1L]]$par, par)
})

test_that("start ladder on a real fit never selects a worse objective than the cold start", {
  set.seed(20260616)
  id <- factor(rep(seq_len(8), each = 6))
  x <- rep(seq(-1, 1, length.out = 6), times = 8)
  u <- stats::rnorm(8, sd = 0.5)
  dat <- data.frame(
    y = 0.3 + 0.6 * x + u[id] + stats::rnorm(length(id), sd = 0.4),
    x = x,
    id = id
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
  obj <- fit$obj
  candidates <- drmTMB:::drm_log_sd_start_candidates(
    obj$par,
    which = c("log_sd_mu", "log_sd_phylo", "log_sd_sigma")
  )

  expect_gt(length(candidates), 1L)

  result <- drmTMB:::drm_run_start_ladder(
    obj,
    drm_control(se = FALSE),
    candidates
  )

  cold_objective <- result$attempts$objective[
    result$attempts$start_label == "cold"
  ]
  expect_lte(result$opt$objective, cold_objective + 1e-6)
  expect_true(result$selected_converged)
  expect_true(all(is.finite(
    result$attempts$max_gradient[result$attempts$status == "ok"]
  )))
})

# Arc D Design 1: regression-predicted random-effect scales must never let an
# exp() overflow masquerade as a finite profile endpoint.

arc_d_overflow_fixture <- function() {
  set.seed(20260726)
  id <- factor(rep(seq_len(8L), each = 3L))
  w <- rep(seq(-0.8, 0.8, length.out = 8L), each = 3L)
  u <- stats::rnorm(nlevels(id), sd = 0.3)
  data.frame(
    id = id,
    w = w,
    y = 0.4 + 0.2 * w + u[id] + stats::rnorm(length(id), sd = 0.25)
  )
}

test_that("sd() overflow guard is identity below the double-overflow boundary", {
  eta <- c(-20, -1, 0, 1, 20, 700)
  expect_equal(
    drmTMB:::drm_exp_sd_logscale_guarded(eta),
    exp(eta),
    tolerance = 1e-12
  )
})

test_that("ordinary direct-SD values agree between C++ and R", {
  fit <- drmTMB(
    bf(y ~ w + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = gaussian(),
    data = arc_d_overflow_fixture(),
    control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  par <- fit$opt$par
  full_par <- fit$tmb_state$last.par.best
  full_par[fit$obj$env$lfixed()] <- par
  report <- fit$obj$report(full_par)
  eta <- as.vector(
    fit$model$tmb_data$X_sd_mu %*%
      unname(par[names(par) == "beta_sd_mu"])
  )
  expect_equal(report$sd_logscale_overflow_guard_hit, 0)
  expect_equal(
    report$sd_mu_group,
    drmTMB:::drm_exp_sd_logscale_guarded(
      drmTMB:::drm_softclamp_log_sd(eta, fit$model$tmb_data)
    )
  )
})

test_that("direct-SD clamp preserves raw log scale and aligns C++ with R", {
  fit <- drmTMB(
    bf(y ~ w + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = gaussian(),
    data = arc_d_overflow_fixture(),
    control = drm_control(se = FALSE, keep_tmb_object = TRUE)
  )
  par <- fit$opt$par
  position <- which(names(par) == "beta_sd_mu")
  clamped_par <- par
  clamped_par[position] <- c(0, 20)
  full_par <- fit$tmb_state$last.par.best
  full_par[fit$obj$env$lfixed()] <- clamped_par
  par_list <- fit$obj$env$parList(clamped_par)
  raw <- drmTMB:::drm_direct_sd_logscale_values(par_list, fit$model)$mu
  report <- fit$obj$report(full_par)

  expect_gt(max(raw), fit$model$tmb_data$logsigma_clamp[[2L]])
  expect_equal(report$log_sd_mu_group, unname(raw))
  expect_equal(
    report$sd_mu_group,
    drmTMB:::drm_exp_sd_logscale_guarded(
      drmTMB:::drm_softclamp_log_sd(raw, fit$model$tmb_data)
    )
  )
})

test_that("a direct-SD overflow guard hit is non-finite and cannot profile", {
  fit <- drmTMB(
    bf(y ~ w + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = gaussian(),
    data = arc_d_overflow_fixture(),
    control = drm_control(
      se = FALSE,
      keep_tmb_object = TRUE,
      logsigma_clamp = NULL
    )
  )
  par <- fit$opt$par
  position <- which(names(par) == "beta_sd_mu")
  expect_length(position, 2L)
  overflow_par <- par
  overflow_par[position] <- c(0, 1000)
  expect_false(is.finite(fit$obj$fn(overflow_par)))
  full_overflow_par <- fit$tmb_state$last.par.best
  full_overflow_par[fit$obj$env$lfixed()] <- overflow_par
  report <- fit$obj$report(full_overflow_par)
  expect_gt(report$sd_logscale_overflow_guard_hit, 0)
  expect_true(all(is.finite(report$sd_mu_group)))

  target <- drmTMB:::drm_profile_targets(fit)
  target <- target[which(
    target$tmb_parameter == "beta_sd_mu" & target$index == 2L
  ), , drop = FALSE]
  expect_equal(nrow(target), 1L)
  # sd() regression coefficients use the tmbprofile route (their target
  # transformation is linear_predictor). A guard hit therefore presents the
  # existing non-finite objective that the profile machinery already maps to a
  # failed row; it never supplies a finite root at the guard boundary.
  diagnostics <- drmTMB:::profile_interval_diagnostics(
    c(NA_real_, NA_real_),
    transformation = target$transformation
  )
  expect_equal(drmTMB:::profile_conf_status_from_diagnostics(diagnostics), "profile_failed")
})

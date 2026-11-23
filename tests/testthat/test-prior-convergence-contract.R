test_that("prior convergence requires optimizer, relative score, interior, and PD Hessian", {
  classify <- drmTMB:::drm_convergence_status_from_parts

  expect_identical(classify(
    optimizer_ok = FALSE, relative_gradient = 0, at_boundary = FALSE,
    pd_hessian = TRUE
  ), "not_converged")
  expect_identical(classify(
    optimizer_ok = TRUE, relative_gradient = 2e-3, at_boundary = FALSE,
    pd_hessian = TRUE
  ), "not_converged")
  expect_identical(classify(
    optimizer_ok = TRUE, relative_gradient = 1e-8, at_boundary = TRUE,
    pd_hessian = TRUE
  ), "boundary")
  expect_identical(classify(
    optimizer_ok = TRUE, relative_gradient = 1e-8, at_boundary = TRUE,
    pd_hessian = FALSE
  ), "boundary")
  expect_identical(classify(
    optimizer_ok = TRUE, relative_gradient = 1e-8, at_boundary = FALSE,
    pd_hessian = FALSE
  ), "degenerate")
  expect_identical(classify(
    optimizer_ok = TRUE, relative_gradient = 1e-8, at_boundary = FALSE,
    pd_hessian = TRUE
  ), "converged")
})

test_that("an active log-sigma clamp counts as a fitted boundary", {
  testthat::local_mocked_bindings(
    check_logsigma_clamp_active = function(object) data.frame(
      check = "logsigma_clamp_active", status = "note", value = "-690",
      message = "The fitted log(sigma) reached the lower clamp."
    ),
    check_rho12_boundary = function(...) NULL,
    check_random_effect_sd_boundary = function(...) NULL,
    check_tweedie_eta_nu_cap = function(...) NULL,
    check_temporal_boundary = function(...) NULL,
    .package = "drmTMB"
  )
  expect_true(drmTMB:::drm_convergence_at_boundary(list()))
})

test_that("prior-held parameters come from unsupported unpenalized curvature", {
  held <- drmTMB:::drm_prior_held_parameters(
    penalized_hessian = diag(c(2, 1)),
    unpenalized_hessian = diag(c(2, 0)),
    parameter_names = c("beta_mu", "log_sd_mu")
  )
  expect_equal(held, data.frame(name = "log_sd_mu[1]", kind = "random_effect_sd"))

  none <- drmTMB:::drm_prior_held_parameters(
    penalized_hessian = diag(c(2, 1)),
    unpenalized_hessian = diag(c(2, 1)),
    parameter_names = c("beta_mu", "log_sd_mu")
  )
  expect_equal(none, data.frame(name = character(), kind = character()))

  indefinite <- drmTMB:::drm_prior_held_parameters(
    penalized_hessian = diag(c(2, 1)),
    unpenalized_hessian = diag(c(2, -1e-4)),
    parameter_names = c("beta_mu", "log_sd_mu")
  )
  expect_equal(indefinite, data.frame(name = character(), kind = character()))
})

test_that("convergence status uses four numerical checks, not extra geometry gates", {
  fit <- structure(list(
    penalised = TRUE,
    estimator = "ML",
    opt = list(convergence = 0L, objective = 1, par = 0),
    logLik = 0,
    relative_gradient = 0,
    pd_hessian = TRUE,
    pd_hessian_penalised = TRUE,
    sdpars = list(),
    corpars = list()
  ), class = "drmTMB")
  testthat::local_mocked_bindings(
    drm_is_mspl = function(object) FALSE,
    drm_convergence_at_boundary = function(object) FALSE,
    drm_fixed_effect_rank_deficient = function(object) TRUE,
    drm_standard_errors_pathological = function(object) TRUE,
    drm_mle_nonexistent_is_true = function(object) TRUE,
    .package = "drmTMB"
  )

  expect_identical(drmTMB::convergence_status(fit), "converged")
  fit$penalised <- FALSE
  expect_identical(drmTMB::convergence_status(fit), "converged")
})

test_that("no-prior fit output keeps the pre-prior contract", {
  set.seed(20261121)
  dat <- data.frame(y = rnorm(40), x = rnorm(40))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)

  expect_false("penalized" %in% names(fit))
  expect_false("penalised" %in% names(fit))
  expect_false("objective" %in% names(fit))
  expect_false("pd_hessian_unpenalised" %in% names(fit))
  expect_false("prior_held_params" %in% names(fit))
  expect_false("se_type" %in% names(fit))
  expect_true(is.finite(fit$relative_gradient))
  expect_true(is.logical(fit$pd_hessian))
  expect_identical(drmTMB::convergence_status(fit), "converged")
  fit_no_se <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ 1), data = dat,
    control = drmTMB::drm_control(se = FALSE)
  )
  expect_null(fit_no_se$sdr)
  expect_true(fit_no_se$pd_hessian)
  expect_identical(drmTMB::convergence_status(fit_no_se), "converged")

  failed <- fit
  failed$opt$convergence <- 1L
  expect_identical(drmTMB::convergence_status(failed), "not_converged")

  non_pd <- fit
  non_pd$pd_hessian <- FALSE
  expect_identical(drmTMB::convergence_status(non_pd), "degenerate")

  set.seed(20261122)
  group <- factor(rep(seq_len(8), each = 20))
  re_data <- data.frame(
    y = rnorm(160) + rnorm(8, sd = 0.7)[group],
    group = group
  )
  re_fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ 1 + (1 | group), sigma ~ 1), data = re_data
  )
  boundary <- re_fit
  boundary$sdpars$mu[[1L]] <- 1e-8
  expect_identical(drmTMB::convergence_status(boundary), "boundary")
})

test_that("prior fits retain both objectives and curvature diagnostics", {
  set.seed(20261122)
  dat <- data.frame(y = 0.4 + 0.7 * rnorm(60) + rnorm(60, sd = 0.6),
    x = rnorm(60))
  priors <- data.frame(
    prior = "normal(0,2)", class = "fixef", dpar = "mu",
    coef = "x", scale = "link"
  )
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ 1), data = dat, priors = priors
  )

  expect_true(fit$penalized)
  expect_true(fit$penalised)
  expect_equal(fit$objective, as.numeric(stats::logLik(fit)) + fit$log_prior,
    tolerance = 1e-7)
  expect_true(is.finite(fit$relative_gradient))
  expect_true(is.logical(fit$pd_hessian_penalised))
  expect_true(is.logical(fit$pd_hessian_unpenalised))
  expect_named(fit$prior_held_params, c("name", "kind"))
  expect_identical(fit$se_type, "penalised")
  hessian_penalised <- solve(fit$sdr$cov.fixed)
  hessian_unpenalised <- hessian_penalised
  slope_position <- which(names(fit$opt$par) == "beta_mu")[[2L]]
  hessian_unpenalised[slope_position, slope_position] <-
    hessian_unpenalised[slope_position, slope_position] - 1 / 2^2
  unpenalised_eigenvalues <- eigen(
    (hessian_unpenalised + t(hessian_unpenalised)) / 2,
    symmetric = TRUE,
    only.values = TRUE
  )$values
  expect_identical(
    fit$pd_hessian_unpenalised,
    min(unpenalised_eigenvalues) >
      1e-8 * max(1, max(abs(unpenalised_eigenvalues)))
  )
  expect_identical(drmTMB::convergence_status(fit), "converged")
  fit_checks <- drmTMB::check_drm(fit)
  expect_identical(
    fit_checks$value[fit_checks$check == "prior_held_params"],
    "none"
  )

  prior_held <- fit
  prior_held$pd_hessian_unpenalised <- FALSE
  prior_held$prior_held_params <- data.frame(
    name = "beta_mu[2]", kind = "fixed_effect"
  )
  expect_identical(drmTMB::convergence_status(prior_held), "converged")
  held_check <- drmTMB::check_drm(prior_held)
  expect_identical(
    held_check$status[held_check$check == "prior_held_params"],
    "note"
  )

  score_failed <- fit
  score_failed$relative_gradient <- 1
  expect_identical(drmTMB::convergence_status(score_failed), "not_converged")
  hessian_failed <- fit
  hessian_failed$pd_hessian_penalised <- FALSE
  expect_identical(drmTMB::convergence_status(hessian_failed), "degenerate")

  fit_no_se <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ 1), data = dat, priors = priors,
    control = drmTMB::drm_control(se = FALSE, logsigma_clamp = NULL)
  )
  expect_null(fit_no_se$sdr)
  expect_true(fit_no_se$pd_hessian_penalised)
  expect_true(is.logical(fit_no_se$pd_hessian_unpenalised))
})

test_that("prior curvature can hold a weak direction without changing status", {
  set.seed(20261123)
  dat <- data.frame(
    y = rnorm(80),
    x = seq(-1, 1, length.out = 80) * 1e-5
  )
  priors <- data.frame(
    prior = "normal(0,0.1)", class = "fixef", dpar = "mu",
    coef = "x", scale = "link"
  )
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ 1), data = dat, priors = priors,
    control = drmTMB::drm_control(logsigma_clamp = NULL)
  )

  expect_true(fit$pd_hessian_penalised)
  expect_false(fit$pd_hessian_unpenalised)
  expect_true(length(fit$prior_held_params) > 0L)
  expect_identical(drmTMB::convergence_status(fit), "converged")
  held_check <- drmTMB::check_drm(fit)
  expect_identical(
    held_check$status[held_check$check == "prior_held_params"],
    "note"
  )
})

test_that("v2 response validation rejects a changed objective", {
  validate <- get0("drm_julia_validate_prior_v2_result", mode = "function")
  expect_true(is.function(validate), info = "v2 response validator must exist")
  if (is.function(validate)) {
    expected <- list(list(spec_index = 1L, kind = "ranef_sd_gamma", class = "ranef_sd",
      dpar = "mu", group = "site", coef = "(Intercept)", block_kind = "iid_random_intercept",
      shape = 2, rate = 3, measure = "natural_sd"))
    response <- list(prior_contract = "parameter_priors_v2", resolved_priors_v2 = expected,
      working_coordinates = c("mu_(Intercept)", "sigma_(Intercept)", "eta_sd[mu|site|(Intercept)]"),
      working_values = c(0, 0, log(0.8)), coefficients = c(0, 0, log(0.8)), data_nll = 4, data_logLik = -4, loglik = -4,
      fixed_prior_penalty = 0, sd_prior_penalty = -dgamma(.8, shape=2, rate=3, log=TRUE),
      penalized_objective = 4 - dgamma(.8, shape=2, rate=3, log=TRUE), data_gradient = c(0, 0, 1),
      fixed_prior_gradient = c(0, 0, 0), sd_prior_gradient = c(0, 0, 1.4),
      penalized_gradient = c(0, 0, 2.4), estim_method = "MAP", infocrit_basis = "unavailable")
    expect_silent(validate(response, expected))
    response$penalized_objective <- response$penalized_objective + 1
    expect_error(validate(response, expected), "objective")
  }
})

test_that("v2 response rejects altered records, coordinates and diagnostics", {
  expected <- list(list(spec_index = 1L, kind = "ranef_sd_gamma", class = "ranef_sd",
    dpar = "mu", group = "site", coef = "(Intercept)", block_kind = "iid_random_intercept",
    shape = 2, rate = 3, measure = "natural_sd"))
  coords <- c("mu_(Intercept)", "sigma_(Intercept)", "eta_sd[mu|site|(Intercept)]")
  good <- list(prior_contract = "parameter_priors_v2", resolved_priors_v2 = expected,
    working_coordinates = coords, working_values = c(0, 0, log(.8)), coefficients = c(0, 0, log(.8)), data_nll = 4,
    data_logLik = -4, loglik = -4, fixed_prior_penalty = 0, sd_prior_penalty = -dgamma(.8, shape=2, rate=3, log=TRUE),
    penalized_objective = 4 - dgamma(.8, shape=2, rate=3, log=TRUE), data_gradient = c(0, 0, 1),
    fixed_prior_gradient = c(0, 0, 0), sd_prior_gradient = c(0, 0, 1.4),
    penalized_gradient = c(0, 0, 2.4), estim_method = "MAP", infocrit_basis = "unavailable")
  bad <- good; bad$resolved_priors_v2[[1]]$rate <- 4
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "prior records")
  bad <- good; bad$working_coordinates <- rev(coords)
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "coordinate identities")
  bad <- good; bad$data_logLik <- -3
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "likelihood")
  bad <- good; bad$loglik <- -3
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "likelihood")
  bad <- good; bad$penalized_gradient[[3]] <- 0
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "gradient")
  bad <- good; bad$working_values[[1]] <- Inf
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "working values")
  bad <- good; bad$working_values[[1]] <- 10
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "working values")
  bad <- good; bad$estim_method <- "ML"
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "estimator")
  bad <- good; bad$infocrit_basis <- "ml"
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "estimator")
  bad <- good; bad$sd_prior_gradient <- NULL
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "missing")
  # Compensating changes preserve the decomposition but falsify the SD prior.
  bad <- good; bad$sd_prior_penalty <- bad$sd_prior_penalty + 1
  bad$data_nll <- bad$data_nll - 1; bad$data_logLik <- -bad$data_nll; bad$loglik <- bad$data_logLik
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "SD prior penalty")
  bad <- good; bad$sd_prior_gradient[[3]] <- bad$sd_prior_gradient[[3]] + 1
  bad$data_gradient[[3]] <- bad$data_gradient[[3]] - 1
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "SD prior gradient")
  bad <- good; bad$sd_prior_gradient[[1]] <- 1; bad$data_gradient[[1]] <- -1
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "SD prior gradient")
  bad <- good; bad$working_coordinates[[3]] <- "eta_sd[mu|other|(Intercept)]"
  expect_error(drm_julia_validate_prior_v2_result(bad, expected), "SD prior coordinate")
  bad <- good; bad$working_values[[3]] <- -1000; bad$coefficients[[3]] <- -1000
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "SD prior coordinate")
  bad <- good; bad$working_values[[3]] <- -400; bad$coefficients[[3]] <- -400
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "SD prior coordinate")
  bad <- good; bad$working_values[[3]] <- 400; bad$coefficients[[3]] <- 400
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "SD prior coordinate")
})

test_that("v2 response independently checks mixed fixed-prior contributions", {
  expected <- list(
    list(spec_index=1L, kind="fixed_normal", class="fixed", dpar="mu", coef="(Intercept)", mean=0, sd=1),
    list(spec_index=2L, kind="fixed_ridge", class="fixed", dpar="sigma", coef="(Intercept)", lambda=2),
    list(spec_index=3L, kind="ranef_sd_gamma", class="ranef_sd", dpar="mu", group="site", coef="(Intercept)",
      block_kind="iid_random_intercept", shape=2, rate=3, measure="natural_sd"))
  coords <- c("mu_(Intercept)", "sigma_(Intercept)", "eta_sd[mu|site|(Intercept)]")
  fixed <- -dnorm(.7, mean=0, sd=1, log=TRUE) + .5 * 2 * (-.2)^2
  sd <- -dgamma(.8, shape=2, rate=3, log=TRUE)
  good <- list(prior_contract="parameter_priors_v2", resolved_priors_v2=expected,
    working_coordinates=coords, working_values=c(.7,-.2,log(.8)), coefficients=c(.7,-.2,log(.8)),
    data_nll=4, data_logLik=-4, loglik=-4, fixed_prior_penalty=fixed, sd_prior_penalty=sd,
    penalized_objective=4+fixed+sd, data_gradient=c(0,0,1), fixed_prior_gradient=c(.7,-.4,0),
    sd_prior_gradient=c(0,0,1.4), penalized_gradient=c(.7,-.4,2.4),
    estim_method="MAP", infocrit_basis="unavailable")
  expect_silent(drm_julia_validate_prior_v2_result(good, expected, coords))
  bad <- good; bad$fixed_prior_penalty <- bad$fixed_prior_penalty + 1
  bad$data_nll <- bad$data_nll - 1; bad$data_logLik <- -bad$data_nll; bad$loglik <- bad$data_logLik
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "fixed prior penalty")
  bad <- good; bad$fixed_prior_gradient[[1]] <- bad$fixed_prior_gradient[[1]] + 1
  bad$data_gradient[[1]] <- bad$data_gradient[[1]] - 1
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "fixed prior gradient")
  bad <- good; bad$fixed_prior_gradient[[3]] <- 1; bad$data_gradient[[3]] <- 0
  expect_error(drm_julia_validate_prior_v2_result(bad, expected, coords), "fixed prior gradient")
  bad <- good; bad$working_coordinates[[1]] <- "mu_wrong"
  expect_error(drm_julia_validate_prior_v2_result(bad, expected), "fixed prior coordinate")
  duplicate <- c(expected, list(expected[[1L]])); duplicate[[4L]]$spec_index <- 4L
  bad <- good; bad$resolved_priors_v2 <- duplicate
  expect_error(drm_julia_validate_prior_v2_result(bad, duplicate, coords), "fixed prior target")
  zero <- good; zero_records <- expected; zero_records[[2L]]$lambda <- 0
  zero$resolved_priors_v2 <- zero_records
  zero$fixed_prior_penalty <- -dnorm(.7, mean=0, sd=1, log=TRUE)
  zero$fixed_prior_gradient <- c(.7,0,0)
  zero$penalized_objective <- 4 + zero$fixed_prior_penalty + sd
  zero$penalized_gradient <- c(.7,0,2.4)
  expect_silent(drm_julia_validate_prior_v2_result(zero, zero_records, coords))
})

test_that("conditional bridge invokes the shared v2 validator", {
  src <- drm_julia_conditional_gaussian_components_source()
  expect_match(src, "_bridge_prior_contract\\(opts\\)")
  expect_match(src, "_bridge_enable_priors_v2!")
  expect_match(src, "_bridge_attach_priors_v2!")
})

test_that("v2 request preserves mixed specification order and expansion", {
  build <- get0("drm_julia_prior_v2_options", mode = "function")
  expect_true(is.function(build))
  if (is.function(build)) {
    sd <- structure(list(dpar="mu", group="site", coef="(Intercept)", shape=2, rate=3), class="drm_sd_prior")
    ridge <- structure(list(kind="ridge", dpar="mu", coef="all", intercept="include", precision=.5), class="drm_fixed_prior")
    resolved <- data.frame(class=c("fixed", "fixed", "sd_gamma"), dpar=c("mu", "mu", "mu"),
      coefficient=c("(Intercept)", "x", "(Intercept)"), reason=c("all; intercept include", "all; intercept include", NA),
      kind=c("ridge", "ridge", NA), group=c(NA, NA, "site"), stringsAsFactors=FALSE)
    opts <- build(list(sd, ridge), resolved)
    expect_identical(opts$prior_contract, "parameter_priors_v2")
    expect_identical(vapply(opts$prior_expected_v2, `[[`, integer(1), "spec_index"), c(1L,2L,2L))
    expect_identical(vapply(opts$prior_expected_v2, `[[`, character(1), "coef"), c("(Intercept)", "(Intercept)", "x"))
  }
})

test_that("live conditional bridge preserves an SD prior", {
  skip_if_not(identical(Sys.getenv("DRM_PRIOR_V2_LIVE"), "1"))
  if (exists("drm_julia_bridge_summary_record_live", mode="function")) drm_julia_bridge_summary_record_live()
  d <- data.frame(x=rep(c(-1, 0, 1), 3), site=rep(c("a", "b", "c"), each=3))
  d$y <- c(1,1.4,2.3,2.8,2.1,2.6,3.2,3.4,4.3)
  f <- bf(y ~ x + (1 | site), sigma ~ 1)
  p <- drm_priors(drm_prior_sd_gamma(dpar="mu", group="site", coef="(Intercept)", shape=2, rate=3))
  fit <- drmTMB_julia_bridge(formula=f, family=gaussian(), data=d, env=environment(),
    weights_missing=TRUE, control=NULL, impute=NULL, missing=miss_control(), REML=FALSE,
    call=quote(drmTMB(f, data=d, priors=p, engine="julia")), priors=p)
  expect_identical(fit$estimator, "MAP")
  expect_equal(fit$penalized_objective, -fit$logLik + fit$fixed_prior_penalty + fit$sd_prior_penalty, tolerance=1e-10)
  expect_equal(nrow(fit$resolved_sd_prior), 1L)
  expect_error(AIC(fit), "prior")
})

test_that("public Julia bridge replays mixed SD and fixed priors", {
  skip_if_not(identical(Sys.getenv("DRM_PRIOR_V2_LIVE"), "1"))
  if (exists("drm_julia_bridge_summary_record_live", mode="function")) drm_julia_bridge_summary_record_live()
  d <- data.frame(x=rep(c(-1, 0, 1), 3), site=rep(c("a", "b", "c"), each=3))
  d$y <- c(1,1.4,2.3,2.8,2.1,2.6,3.2,3.4,4.3)
  f <- bf(y ~ x + (1 | site), sigma ~ 1)
  p <- drm_priors(drm_prior_sd_gamma(dpar="mu", group="site", coef="(Intercept)", shape=2, rate=3),
    drm_prior_ridge("mu", "all", intercept="include", lambda=.5))
  fit <- drmTMB(f, data=d, priors=p, engine="julia")
  expect_identical(fit$estimator, "MAP")
  expect_equal(fit$penalized_objective, -fit$logLik + fit$fixed_prior_penalty + fit$sd_prior_penalty, tolerance=1e-10)
  expect_equal(nrow(fit$resolved_sd_prior), 1L)
  expect_equal(nrow(fit$resolved_priors), 2L)
  expect_error(confint(fit), "prior")
  expect_error(AIC(fit), "prior")
  replay <- update(fit)
  expect_equal(replay$resolved_priors, fit$resolved_priors)
  expect_equal(replay$resolved_sd_prior, fit$resolved_sd_prior)
  expect_equal(replay$penalized_objective, fit$penalized_objective, tolerance=1e-7)
})

test_that("live fixed-only call retains v1 handshake", {
  skip_if_not(identical(Sys.getenv("DRM_PRIOR_V2_LIVE"), "1"))
  if (exists("drm_julia_bridge_summary_record_live", mode="function")) drm_julia_bridge_summary_record_live()
  d <- data.frame(x=rep(c(-1,0,1),3), site=rep(c("a","b","c"),each=3), y=c(1,1.4,2.3,2.8,2.1,2.6,3.2,3.4,4.3))
  p <- drm_priors(drm_prior_normal("mu", "x", sd=2))
  fit <- drmTMB(bf(y ~ x + (1 | site), sigma ~ 1), data=d, priors=p, engine="julia")
  expect_identical(fit$bridge$fixed_prior_contract, "fixed_effect_priors_v1")
  # Exact v1 field set from the current paired Julia main and conditional wrapper.
  # fit_failed fields were already present on Julia main before this prior change.
  expect_setequal(names(fit$bridge), c("family", "coef_names", "coefficients", "coef", "vcov", "vcov_names", "loglik", "aic", "bic", "df", "nobs", "converged", "convergence_status", "estim_method", "ml_loglik", "infocrit_basis", "iterations", "marginal", "fitted", "residuals", "sigma", "corpairs", "dpars", "fixed_prior_contract", "resolved_priors", "fixed_prior_penalty", "likelihood_gradient", "prior_gradient", "penalized_gradient", "penalized_objective", "gradient", "gradient_names", "grad_source", "diagnostics", "coef_label_contract", "raw_coef_names", "coef_name_map", "conditional_re", "fit_failed", "fit_failed_message"))
  expect_null(fit$bridge$prior_contract)
  expect_identical(fit$estimator, "MAP")
})

test_that("v1 prior wire payload stays unchanged", {
  p <- structure(list(kind="normal", dpar="mu", coef="x", mean=.25, sd=2), class="drm_fixed_prior")
  r <- data.frame(dpar="mu", coefficient="x")
  expect_identical(drm_fixed_prior_bridge_options(list(p), r),
    list(priors=list(list(kind="normal", dpar="mu", coef="x", mean=.25, sd=2)),
      prior_expected=list(list(dpar="mu", coef="x"))))
})

test_that("factor mean predictors retain the pre-fit Gaussian RE refusal", {
  d <- data.frame(y=1:6, x=factor(rep(c("a","b"),3)), site=rep(c("s1","s2","s3"),each=2))
  expect_error(drm_julia_refuse_gaussian_ordinary_re_factor_fe(bf(y ~ x + (1 | site)), "gaussian", d),
    "does not yet match factor coefficient names")
})

test_that("stale v1 conditional backend fails before fit", {
  skip_if_not(identical(Sys.getenv("DRM_PRIOR_V2_LIVE"), "1"))
  if (exists("drm_julia_bridge_summary_record_live", mode="function")) drm_julia_bridge_summary_record_live()
  JuliaCall::julia_command('module BridgeV1Counter; const fits = Ref(0); _bridge_data(x) = x; _bridge_options(x) = x; _bridge_fit(args...; kwargs...) = (fits[] += 1); end')
  src <- drm_julia_conditional_gaussian_components_source()
  src <- gsub("drmTMB_backend", "BridgeV1Counter", src, fixed=TRUE)
  src <- gsub("drmTMB_drm_bridge_conditional_gaussian_components", "test_v1_counter_components", src, fixed=TRUE)
  src <- gsub("drmTMB_drm_bridge_conditional_gaussian_ri", "test_v1_counter_ri", src, fixed=TRUE)
  JuliaCall::julia_command(src)
  msg <- JuliaCall::julia_eval('try test_v1_counter_components(nothing, "gaussian", nothing, nothing, Dict{Symbol,Any}(:prior_contract=>"parameter_priors_v2", :priors_v2=>[1], :prior_expected_v2=>[1])); "accepted" catch e; sprint(showerror,e) end')
  expect_match(msg, "backend lacks parameter_priors_v2")
  expect_equal(JuliaCall::julia_eval("BridgeV1Counter.fits[]"), 0)
})

test_that("v2 accepts only explicitly supplied finite unit weights", {
  validate <- get0("drm_julia_validate_sd_unit_weights", mode="function")
  expect_true(is.function(validate))
  if (is.function(validate)) {
    expect_silent(validate(rep(1, 3), 3L))
    expect_error(validate(c(1,2,1), 3L), "unit weights")
    expect_error(validate(c(1,NA,1), 3L), "unit weights")
    expect_error(validate(c(1,1), 3L), "unit weights")
    expect_error(validate(NULL, 3L), "unit weights")
  }
})

test_that("public Julia SD fit matches the eligible frozen dense oracle", {
  skip_if_not(identical(Sys.getenv("DRM_PRIOR_V2_LIVE"), "1"))
  root <- Sys.getenv("DRM_PRIOR_V2_ORACLE_PATH", "")
  skip_if_not(nzchar(root) && requireNamespace("jsonlite", quietly=TRUE))
  if (exists("drm_julia_bridge_summary_record_live", mode="function")) drm_julia_bridge_summary_record_live()
  fixture <- jsonlite::fromJSON(file.path(root, "fixture.json"), simplifyVector=FALSE)$cases[[1L]]
  fits <- jsonlite::fromJSON(file.path(root, "fitted_optima.json"), simplifyVector=FALSE)$fits
  ref <- Filter(function(z) identical(z$case, 0L) && z$shape == 2 && z$rate == 3, fits)[[1L]]
  expect_true(ref$refinement$success)
  expect_true(ref$parameter_comparison_eligible)
  d <- data.frame(y=unlist(fixture$y), x=unlist(fixture$x), site=paste0("g", unlist(fixture$group)))
  p <- drm_priors(drm_prior_sd_gamma(dpar="mu", group="site", coef="(Intercept)", shape=2, rate=3))
  fit <- drmTMB(bf(y ~ x + (1 | site), sigma ~ x), data=d, priors=p, engine="julia", weights=rep(1, nrow(d)))
  expect_equal(fit$penalized_objective, ref$objective, tolerance=1e-7)
  expect_lt(max(abs(fit$penalized_gradient)), 1e-6)
  expect_equal(as.numeric(fit$bridge$working_values), unlist(ref$coordinates), tolerance=1e-5)
  expect_error(drmTMB(bf(y ~ x + (1 | site), sigma ~ x), data=d, priors=p, engine="julia", weights=c(2, rep(1, nrow(d)-1))), "unit weights")
  expect_error(BIC(fit), "prior")
  expect_error(confint(fit, method="profile"), "prior")
  expect_error(confint(fit, method="bootstrap"), "prior")
  expect_error(summary(fit, conf.int=TRUE), "prior")
})

test_that("mixed Julia fit agrees with the source-bound native fit on frozen data", {
  skip_if_not(identical(Sys.getenv("DRM_PRIOR_V2_LIVE"), "1"))
  root <- Sys.getenv("DRM_PRIOR_V2_ORACLE_PATH", "")
  skip_if_not(nzchar(root) && requireNamespace("jsonlite", quietly=TRUE))
  if (exists("drm_julia_bridge_summary_record_live", mode="function")) drm_julia_bridge_summary_record_live()
  fixture <- jsonlite::fromJSON(file.path(root, "fixture.json"), simplifyVector=FALSE)$cases[[1L]]
  d <- data.frame(y=unlist(fixture$y), x=unlist(fixture$x), site=paste0("g", unlist(fixture$group)))
  f <- bf(y ~ x + (1 | site), sigma ~ x)
  p <- drm_priors(drm_prior_sd_gamma(dpar="mu", group="site", coef="(Intercept)", shape=2, rate=3),
    drm_prior_normal("mu", "x", mean=.2, sd=.8))
  native <- drmTMB(f, data=d, priors=p, engine="tmb", control=drm_control(se=FALSE, logsigma_clamp=NULL))
  julia <- drmTMB(f, data=d, priors=p, engine="julia")
  expect_equal(julia$penalized_objective, native$penalized_objective, tolerance=1e-7)
  expect_lt(max(abs(julia$penalized_gradient)), 1e-6)
  expect_lt(max(abs(native$gradient)), 1e-6)
})

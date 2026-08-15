# External oracle tests: drmTMB vs lme4 and glmmTMB
#
# These tests validate drmTMB against independent implementations (lme4 strong,
# glmmTMB weak per docs/design/242-external-comparator-evidence-class.md).
#
# EVIDENCE CLASS: external_comparator, ML-only (point-estimate + logLik) and
# profile-interval endpoints at a 5e-4 ABSOLUTE bound, single dataset/seed per
# test. No capability-ledger row is added: docs/design/242 requires every
# external_comparator claim_boundary to state it does not cover intervals, so
# this evidence is deliberately a test-only regression guard.
#
# fm1P/fm1B PROVENANCE IS UNRESOLVED and this suite does not depend on resolving
# it. An earlier revision claimed "REML = FALSE confirmed empirically"; that was
# withdrawn after a converged REML/bobyqa refit was shown to reproduce fm1P to
# 5.63e-5 -- better than two of three ML reconstructions. Within-REML optimizer
# spread (5.63e-4) matches the ML-vs-REML separation (6.08e-4), so reconstruction
# cannot identify the estimator. See docs/dev-log/external-oracle/rose-audit.md.
#
# NOTE: Do NOT assert REML interval parity here. Fisher's review measured a
# real ~5% profile-CI gap on 3 of 4 targets (sd(Intercept), sd(Days), cor)
# in a single REML-vs-REML spot check. REML point-estimate and logLik agreement
# are licensed and separate. Any future REML profile-CI claim needs its own
# dedicated investigation.

# ============================================================================
# BLOCK 1: Point agreement vs matched lmerMod twins
# ============================================================================

test_that("Gaussian correlated random slope (fm_us1) agrees with lme4 lmerMod twin", {
  testthat::skip_if_not_installed("lme4")
  testthat::skip_if_not_installed("glmmTMB")

  # Load the external oracle models from glmmTMB test suite
  glmmtmb_path <- find.package("glmmTMB")
  models_rda <- file.path(glmmtmb_path, "test_data", "models.rda")
  # Guard the FIXTURE, not just the package: if glmmTMB stops shipping test_data/
  # an unguarded load() is an R CMD check ERROR, where we want a stated SKIP.
  testthat::skip_if_not(file.exists(models_rda),
                        "glmmTMB no longer ships test_data/models.rda")
  load(models_rda,
    envir = (e <- new.env())
  )

  # Extract the glmmTMB fit and its lmerMod twin
  fm_us1_glmmtmb <- get("fm_us1", envir = e)
  fm_us1_lmer <- get("fm_us1_lmer", envir = e)

  # Extract data and refit with drmTMB in ML mode
  dat <- fm_us1_glmmtmb$frame
  fit_drm <- drmTMB(
    bf(Reaction ~ Days + (Days | Subject)),
    family = gaussian(),
    data = dat,
    REML = FALSE
  )

  # Check convergence and then fixed effects
  expect_equal(fit_drm$opt$convergence, 0)
  expect_equal(
    unname(coef(fit_drm, "mu")),
    unname(lme4::fixef(fm_us1_lmer)),
    tolerance = 1e-4,
    info = "drmTMB vs lme4 fixed effects on fm_us1 data (strong independence)"
  )

  # Random effect standard deviations (intercept and slope)
  # drmTMB names them as "(1 + Days | Subject):(Intercept)" and "(1 + Days | Subject):Days"
  vc_lmer <- lme4::VarCorr(fm_us1_lmer)$Subject
  lmer_int_sd <- unname(attr(vc_lmer, "stddev")[1L])
  lmer_slope_sd <- unname(attr(vc_lmer, "stddev")[2L])

  expect_equal(
    unname(fit_drm$sdpars$mu[1L]),
    lmer_int_sd,
    tolerance = 1e-4,
    info = "drmTMB vs lme4 random-intercept SD on fm_us1 data"
  )
  expect_equal(
    unname(fit_drm$sdpars$mu[2L]),
    lmer_slope_sd,
    tolerance = 1e-4,
    info = "drmTMB vs lme4 random-slope SD on fm_us1 data"
  )

  # Random effect correlation (between intercept and slope)
  cor_lmer <- attr(vc_lmer, "correlation")[1L, 2L]
  expect_equal(
    unname(fit_drm$corpars$mu[1L]),
    cor_lmer,
    tolerance = 1e-4,
    info = "drmTMB vs lme4 random-effect correlation on fm_us1 data"
  )

  # Residual standard deviation (sigma)
  expect_equal(
    stats::sigma(fit_drm)[[1L]],
    stats::sigma(fm_us1_lmer),
    tolerance = 1e-4,
    info = "drmTMB vs lme4 sigma on fm_us1 data"
  )

  # Log-likelihood
  expect_equal(
    as.numeric(stats::logLik(fit_drm)),
    as.numeric(stats::logLik(fm_us1_lmer)),
    tolerance = 1e-4,
    info = "drmTMB vs lme4 logLik on fm_us1 data"
  )
})

test_that("Gaussian independent random effects (fm_diag2) agrees with lme4", {
  testthat::skip_if_not_installed("lme4")
  testthat::skip_if_not_installed("glmmTMB")

  glmmtmb_path <- find.package("glmmTMB")
  models_rda <- file.path(glmmtmb_path, "test_data", "models.rda")
  # Guard the FIXTURE, not just the package: if glmmTMB stops shipping test_data/
  # an unguarded load() is an R CMD check ERROR, where we want a stated SKIP.
  testthat::skip_if_not(file.exists(models_rda),
                        "glmmTMB no longer ships test_data/models.rda")
  load(models_rda,
    envir = (e <- new.env())
  )

  fm_diag2_glmmtmb <- get("fm_diag2", envir = e)
  fm_diag2_lmer <- get("fm_diag2_lmer", envir = e)

  dat <- fm_diag2_glmmtmb$frame
  fit_drm <- drmTMB(
    bf(Reaction ~ Days + (1 | Subject) + (0 + Days | Subject)),
    family = gaussian(),
    data = dat,
    REML = FALSE
  )

  expect_equal(fit_drm$opt$convergence, 0)

  # fm_diag2 has two independent random terms, not a correlated block
  expect_equal(
    unname(coef(fit_drm, "mu")),
    unname(lme4::fixef(fm_diag2_lmer)),
    tolerance = 1e-4,
    info = "drmTMB vs lme4 fixed effects on fm_diag2 data"
  )

  # For independent terms, lme4 creates separate VarCorr entries
  vc_lmer_list <- lme4::VarCorr(fm_diag2_lmer)
  lmer_int_sd <- unname(attr(vc_lmer_list$Subject, "stddev"))
  lmer_slope_sd <- unname(attr(vc_lmer_list$"Subject.1", "stddev"))

  expect_equal(
    unname(fit_drm$sdpars$mu[1L]),
    lmer_int_sd,
    tolerance = 1e-4,
    info = "drmTMB vs lme4 intercept SD on fm_diag2 data"
  )
  expect_equal(
    unname(fit_drm$sdpars$mu[2L]),
    lmer_slope_sd,
    tolerance = 1e-4,
    info = "drmTMB vs lme4 slope SD on fm_diag2 data"
  )

  expect_equal(
    stats::sigma(fit_drm)[[1L]],
    stats::sigma(fm_diag2_lmer),
    tolerance = 1e-4,
    info = "drmTMB vs lme4 sigma on fm_diag2 data"
  )

  expect_equal(
    as.numeric(stats::logLik(fit_drm)),
    as.numeric(stats::logLik(fm_diag2_lmer)),
    tolerance = 1e-4,
    info = "drmTMB vs lme4 logLik on fm_diag2 data"
  )
})

# ============================================================================
# BLOCK 2: Interval agreement vs lme4 reference matrices (fm1P profile, fm1B bootstrap)
# ============================================================================

test_that("Profile confidence intervals agree with lme4 fm1P reference on lme4::sleepstudy", {
  testthat::skip_if_not_installed("lme4")


  confint_ex <- file.path(find.package("lme4"), "testdata", "confint_ex.rda")
  testthat::skip_if_not(file.exists(confint_ex),
                        "lme4 no longer ships testdata/confint_ex.rda")
  load(confint_ex)

  # fm1P holds profile CI endpoints for
  #   Reaction ~ Days + (Days | Subject) on sleepstudy.
  # Its estimator is NOT determinable (see the header note): fm1P is a bare matrix
  # with no estimator metadata and lme4 ships no generating script. We fit drmTMB
  # in its ML default below and compare endpoints; the agreement is asserted at a
  # level comparable to lme4's own optimizer-to-optimizer reproducibility, not as
  # proof of a matched estimator.

  # Fit drmTMB with identical formula and data, in its ML default (REML = FALSE).
  # This states OUR estimator choice; it does not assert the reference's.
  fit <- drmTMB(
    bf(Reaction ~ Days + (Days | Subject)),
    family = gaussian(),
    data = lme4::sleepstudy,
    REML = FALSE
  )

  # Compute profile confidence intervals for the four random/scale targets
  # These are the same targets present in fm1P
  ci_drm <- confint(
    fit,
    method = "profile",
    parm = c(
      "sd:mu:(1 + Days | Subject):(Intercept)",
      "sd:mu:(1 + Days | Subject):Days",
      "cor:mu:cor((Intercept),Days | Subject)",
      "sigma"
    )
  )

  # Bound = 5e-4 ABSOLUTE, applied as max(abs(drmTMB - fm1P)) over both endpoints.
  #
  # It is asserted with expect_lt() rather than expect_equal(tolerance = ), because
  # under testthat edition 3 the `tolerance` argument routes to waldo and is
  # RELATIVE. On these targets a relative 5e-4 permits absolute slack of 2.6e-2 to
  # 5.4e-4 -- 40x looser than intended on sd(Intercept). An earlier revision of this
  # file used the relative form while its comments claimed an absolute bound.
  #
  # What this bound does and does not adjudicate:
  #   * Worst observed target is sigma at 3.114e-4 (62% of budget, ~1.61x margin);
  #     sd(Intercept) is 2.627e-4, sd(Days) 1.389e-5, cor 3.268e-5. Informative,
  #     not a rubber stamp: injecting a 5.643e-4 discrepancy fails all 4 targets,
  #     and a REML = TRUE refit fails 3 of 4 by 1.800 / 0.3985 / 1.928e-2.
  #   * It does NOT establish which estimator produced fm1P. That is not recoverable:
  #     fm1P is a bare matrix with no estimator metadata, no generating script ships
  #     in lme4, and a converged REML/bobyqa refit reproduces it to 5.63e-5 -- better
  #     than two of three ML reconstructions. Within-REML optimizer spread (5.63e-4)
  #     is the same size as the ML-vs-REML separation (6.08e-4), so reconstruction
  #     cannot separate the two.
  #   * The honest claim is therefore: drmTMB's profile endpoints agree with lme4's
  #     shipped reference to within lme4's own optimizer-to-optimizer reproducibility
  #     for this model. That is a meaningful regression guard, not an estimator proof.
  tolerance_profile <- 5e-4

  # `label` is passed through so a failure names the target it belongs to; without
  # it expect_lt() reports only an anonymous number and the diagnostic is lost.
  expect_abs_close <- function(actual, expected, info) {
    delta <- max(abs(as.numeric(actual) - as.numeric(expected)))
    testthat::expect_lt(delta, tolerance_profile,
                        label = paste0("max abs diff [", info, "]"))
  }

  # Map drmTMB targets to lme4 fm1P row names
  # fm1P rownames: sd_(Intercept)|Subject, cor_Days.(Intercept)|Subject, sd_Days|Subject, sigma, (Intercept), Days
  # We extract the four scale/RE targets (skipping the two fixed effects)

  # sd (Intercept) | Subject
  expect_abs_close(
    as.numeric(ci_drm[ci_drm$parm == "sd:mu:(1 + Days | Subject):(Intercept)", c("lower", "upper")]),
    as.numeric(fm1P["sd_(Intercept)|Subject", ]),
    info = "sd(Intercept|Subject) profile CI: drmTMB vs lme4 fm1P"
  )

  # sd Days | Subject
  expect_abs_close(
    as.numeric(ci_drm[ci_drm$parm == "sd:mu:(1 + Days | Subject):Days", c("lower", "upper")]),
    as.numeric(fm1P["sd_Days|Subject", ]),
    info = "sd(Days|Subject) profile CI: drmTMB vs lme4 fm1P"
  )

  # cor Days, (Intercept) | Subject
  expect_abs_close(
    as.numeric(ci_drm[ci_drm$parm == "cor:mu:cor((Intercept),Days | Subject)", c("lower", "upper")]),
    as.numeric(fm1P["cor_Days.(Intercept)|Subject", ]),
    info = "cor(Days, Intercept | Subject) profile CI: drmTMB vs lme4 fm1P"
  )

  # sigma (residual scale)
  expect_abs_close(
    as.numeric(ci_drm[ci_drm$parm == "sigma", c("lower", "upper")]),
    as.numeric(fm1P["sigma", ]),
    info = "sigma profile CI: drmTMB vs lme4 fm1P"
  )
})

test_that("confint() defaults to Wald and method argument is honored", {
  testthat::skip_if_not_installed("lme4")


  fit <- drmTMB(
    bf(Reaction ~ Days + (Days | Subject)),
    family = gaussian(),
    data = lme4::sleepstudy,
    REML = FALSE
  )

  # confint() with no method argument should default to Wald
  ci_default <- confint(fit)
  expect_true(
    all(ci_default$method == "wald"),
    info = "confint() default method should be 'wald'"
  )

  # confint() with method = "profile" should use profile
  ci_profile <- confint(
    fit,
    method = "profile",
    parm = c(
      "sd:mu:(1 + Days | Subject):(Intercept)",
      "sd:mu:(1 + Days | Subject):Days",
      "cor:mu:cor((Intercept),Days | Subject)",
      "sigma"
    )
  )
  expect_true(
    all(ci_profile$method == "profile"),
    info = "confint(method='profile') should return profile method"
  )

  # The two methods should differ (profile is typically tighter than Wald)
  # Check at least one target differs by more than numeric epsilon
  sd_int_wald_range <-
    ci_default[ci_default$parm == "sd:mu:(1 + Days | Subject):(Intercept)", ]$upper -
      ci_default[ci_default$parm == "sd:mu:(1 + Days | Subject):(Intercept)", ]$lower

  sd_int_prof_range <-
    ci_profile[ci_profile$parm == "sd:mu:(1 + Days | Subject):(Intercept)", ]$upper -
      ci_profile[ci_profile$parm == "sd:mu:(1 + Days | Subject):(Intercept)", ]$lower

  expect_true(
    abs(sd_int_wald_range - sd_int_prof_range) > 0.1,
    info = "Wald and profile CIs should differ substantively on lme4::sleepstudy"
  )
})

# ============================================================================
# BLOCK 3: Transformation contract assertions
# ============================================================================

test_that("Transformation column specifies exp for scale targets and tanh for correlation", {
  testthat::skip_if_not_installed("lme4")


  fit <- drmTMB(
    bf(Reaction ~ Days + (Days | Subject)),
    family = gaussian(),
    data = lme4::sleepstudy,
    REML = FALSE
  )

  pt <- profile_targets(fit)

  # Check scale targets (random-effect SDs and sigma) have "exp" transformation
  scale_targets <- c(
    "sd:mu:(1 + Days | Subject):(Intercept)",
    "sd:mu:(1 + Days | Subject):Days",
    "sigma"
  )
  for (target in scale_targets) {
    row <- pt[pt$parm == target, ]
    expect_equal(
      row$transformation,
      "exp",
      info = paste("Scale target", target, "must use exp transformation")
    )
  }

  # Check correlation target has "tanh" transformation
  cor_target <- "cor:mu:cor((Intercept),Days | Subject)"
  cor_row <- pt[pt$parm == cor_target, ]
  expect_equal(
    cor_row$transformation,
    "tanh",
    info = paste("Correlation target", cor_target, "must use tanh transformation")
  )

  # Verify confint() reflects these transformations
  ci <- confint(fit)

  for (target in scale_targets) {
    row <- ci[ci$parm == target, ]
    expect_equal(
      row$transformation,
      "exp",
      info = paste("confint() scale target", target, "must report exp transformation")
    )
  }

  cor_row <- ci[ci$parm == cor_target, ]
  expect_equal(
    cor_row$transformation,
    "tanh",
    info = paste("confint() correlation target", cor_target, "must report tanh transformation")
  )
})

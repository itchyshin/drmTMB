# Phase 19 reader-facing comparator article: regression guards for the eight
# comparator cells verified VIABLE in
# docs/dev-log/external-oracle/phase19/PR2-build-plan.md Sec 3 (Comparisons
# 1-8, article order c08, c04, c05, c06, c07, c01, c09, c03). Each test_that()
# below mirrors one article Comparison: same drmTMB call, same comparator
# call, same matched-scale conversion, cited to the plan section and the
# feasibility-batch line range that first measured it.
#
# EVIDENCE CLASS: external_comparator, point-estimate + logLik only (no
# interval/coverage claim), single dataset per cell, following
# docs/design/242-external-comparator-evidence-class.md. No capability-ledger
# row is added (PR2-build-plan.md Sec 0, "New capability-ledger rows: None").
#
# Package-attachment rule: every comparator call below uses pkg::fun() /
# pkg::dataset explicitly. NEVER library()/require() a comparator package --
# doing so once leaked lme4 onto the search path and broke landed reader
# tests. This matters doubly here because both drmTMB and glmmTMB export a
# `nbinom2()` family constructor (Comparison 8); an unqualified `nbinom2`
# symbol picks up whichever package is later on the search path, silently
# handing one package's family object to the other's fitting function
# (PR2-build-plan.md Sec 3, Comparison 8, "The `drmTMB::` prefix is
# mandatory, not stylistic").
#
# metadat is declared in DESCRIPTION Suggests (added alongside this file, per
# PR2-build-plan.md Sec 9.3, Sec 11 "DESCRIPTION Suggests must gain metadat").
# Comparisons 2 and 3 need metadat::dat.bcg, and the article's chunks call it
# too, so R CMD check's unstated-dependency scan over tests and tangled
# vignette sources reaches it; declaring it is what keeps that scan quiet.
# The declaration records a dependency the package already had transitively
# rather than adding a new one: metafor 5.0.1 lists metadat in its Depends
# field (R (>= 4.0.0), methods, Matrix, metadat, numDeriv), so metadat is
# already installed wherever metafor is. Note that DESCRIPTION declares a bare
# metafor with no version floor, so that transitive guarantee is a property of
# the metafor versions in use, not something this package pins -- which is the
# second reason to declare metadat directly. Both tests still call
# skip_if_not_installed("metadat"), because Suggests packages are not
# guaranteed present at test time.

# ============================================================================
# Block 2a -- checked against a separate estimation engine (STRONG:
# lme4, metafor per docs/design/242-external-comparator-evidence-class.md:108-109)
# ============================================================================

test_that("Comparison 1 (c08): binomial herd random intercept agrees with lme4::glmer on cbpp", {
  testthat::skip_if_not_installed("lme4")

  fit <- drmTMB(
    bf(mu = cbind(incidence, size - incidence) ~ period + (1 | herd)),
    data = lme4::cbpp,
    family = binomial()
  )
  fit_glmer <- lme4::glmer(
    cbind(incidence, size - incidence) ~ period + (1 | herd),
    family = binomial,
    data = lme4::cbpp
  )

  expect_equal(fit$opt$convergence, 0)

  # Logit coefficients directly -- no conversion. Tolerance stated honestly
  # at 1e-3, not 1e-4 (PR2-build-plan.md:381-389): both sides are nAGQ = 1
  # Laplace, and the gap is a stable package-level difference between TMB's
  # AD inner Laplace solve and lme4's PIRLS Laplace solve, not
  # under-convergence -- refitting glmer with tight optCtrl tolerances
  # reproduces the same loose fit to six decimals. Measured max abs diff on
  # the fixed effects: 5.8e-04 (well inside budget).
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_glmer)),
    tolerance = 1e-3,
    info = "binomial mu coefficients: drmTMB vs lme4::glmer on cbpp"
  )

  # Herd random-intercept SD, no conversion. Measured max abs diff: 1.9e-04.
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(lme4::VarCorr(fit_glmer)$herd, "stddev")),
    tolerance = 1e-3,
    info = "herd random-intercept SD: drmTMB vs lme4::glmer on cbpp"
  )

  # Measured max abs diff: 2.8e-04.
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_glmer)),
    tolerance = 1e-3,
    info = "logLik: drmTMB vs lme4::glmer on cbpp"
  )
})

test_that("Comparison 2 (c04): meta_V() pooled effect agrees with metafor::rma.uni ML", {
  testthat::skip_if_not_installed("metafor")
  testthat::skip_if_not_installed("metadat")

  dat <- metafor::escalc(
    measure = "RR",
    ai = tpos, bi = tneg, ci = cpos, di = cneg,
    data = metadat::dat.bcg
  )

  fit <- drmTMB(
    bf(mu = yi ~ 1 + meta_V(V = vi), sigma = ~1),
    data = dat,
    family = gaussian()
  )
  # method = "ML" is mandatory: rma.uni() defaults to REML, which silently
  # mismatches the estimator (PR2-build-plan.md:412-416; confirmed
  # feasibility-batch-2.md:34-38).
  fit_metafor <- metafor::rma.uni(yi, vi, data = dat, method = "ML")

  expect_equal(fit$opt$convergence, 0)

  # Measured max abs diff: 1.8e-07.
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_metafor)),
    tolerance = 1e-4,
    info = "mu coefficients: drmTMB vs metafor::rma.uni(method='ML') on dat.bcg"
  )

  # V is known input data on both sides. drmTMB reports log(tau) as the
  # sigma intercept; metafor reports tau^2 directly. Convert with
  # tau^2 = exp(2 * coef(fit, "sigma")) (PR2-build-plan.md:417-423,
  # R/methods.R drm_total_obs_sd(v_known, sigma) = sqrt(v_known + sigma^2)).
  # Do NOT compare coef(fit, "sigma") to tau2 directly -- that mixes a
  # log-scale intercept with a response-scale variance and is the shape of
  # error this file exists to catch. Measured max abs diff: 1.0e-07.
  tau2_drm <- exp(2 * coef(fit, "sigma"))
  expect_equal(
    unname(tau2_drm),
    unname(fit_metafor$tau2),
    tolerance = 1e-4,
    info = "tau^2 = exp(2*sigma): drmTMB vs metafor::rma.uni(method='ML') on dat.bcg"
  )

  # Both packages maximise the same function -- the conversion is forced,
  # not merely consistent (PR2-build-plan.md:419-423,
  # adversarial-scales.md:145-162). Measured max abs diff: 5.8e-13.
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_metafor)),
    tolerance = 1e-6,
    info = "logLik: drmTMB vs metafor::rma.uni(method='ML') on dat.bcg"
  )
})

test_that("Comparison 3 (c05): meta_V() with sigma ~ alloc agrees with metafor::rma.mv DIAG", {
  testthat::skip_if_not_installed("metafor")
  testthat::skip_if_not_installed("metadat")

  dat <- metafor::escalc(
    measure = "RR",
    ai = tpos, bi = tneg, ci = cpos, di = cneg,
    data = metadat::dat.bcg
  )
  dat$id <- seq_len(nrow(dat))

  fit <- drmTMB(
    bf(mu = yi ~ 1 + meta_V(V = vi), sigma = ~alloc),
    data = dat,
    family = gaussian()
  )
  fit_metafor <- metafor::rma.mv(
    yi, vi,
    random = ~ alloc | id,
    struct = "DIAG",
    data = dat,
    method = "ML"
  )

  expect_equal(fit$opt$convergence, 0)

  # Measured max abs diff: 5.3e-08.
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_metafor)),
    tolerance = 1e-4,
    info = "mu coefficients: drmTMB vs metafor::rma.mv(struct='DIAG') on dat.bcg"
  )

  # Two conversion steps stack (PR2-build-plan.md:448-455). Step 1: contrast
  # each allocation level's log(tau) to the reference cell mean (reference
  # level "alternate" on both sides, matching R's default factor coding).
  # Step 2: exp() to reach tau, square to reach rma.mv's tau^2 -- rma.mv
  # prints tau/tau^2 on the response scale, drmTMB's sigma linear predictor
  # is on the log scale, so both the contrast AND the exp() are required.
  # $tau2 is ordered (alternate, random, systematic), matching the DIAG
  # random-effect factor level order.
  b <- coef(fit, "sigma")
  tau2_drm <- c(
    alternate = exp(2 * b[["(Intercept)"]]),
    random = exp(2 * (b[["(Intercept)"]] + b[["allocrandom"]])),
    systematic = exp(2 * (b[["(Intercept)"]] + b[["allocsystematic"]]))
  )
  # Measured max abs diff: 3.4e-07 (allocrandom cell; the other two are
  # 3.4e-08 and 1.6e-08 -- see PR2-build-plan.md:456-463).
  expect_equal(
    unname(tau2_drm),
    unname(fit_metafor$tau2),
    tolerance = 1e-4,
    info = "per-level tau^2: drmTMB vs metafor::rma.mv(struct='DIAG') on dat.bcg"
  )

  # The two log-likelihoods are identical to 1.05e-12: this is a structural
  # identity, not two close models (PR2-build-plan.md:459-463,
  # adversarial-scales.md:186-214). Do not read the three tau values as a
  # substantive comparative-heterogeneity finding -- mc-0260m's recorded
  # boundary says heterogeneity intervals are not usable at this K
  # (PR2-build-plan.md:465-477) -- this test asserts point/logLik agreement
  # only, no interval claim.
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_metafor)),
    tolerance = 1e-6,
    info = "logLik: drmTMB vs metafor::rma.mv(struct='DIAG') on dat.bcg"
  )
})

# ============================================================================
# Block 2b -- checked against ordinal (independence not yet classified in
# docs/design/242-external-comparator-evidence-class.md; PR2-build-plan.md
# Sec 10.3)
# ============================================================================

test_that("Comparison 4 (c06): cumulative_logit() fixed effects agrees with ordinal::clm on wine", {
  testthat::skip_if_not_installed("ordinal")

  fit <- drmTMB(
    bf(mu = rating ~ temp + contact),
    data = ordinal::wine,
    family = cumulative_logit()
  )
  fit_clm <- ordinal::clm(rating ~ temp + contact, data = ordinal::wine)

  expect_equal(fit$opt$convergence, 0)

  # Same logit link, same cumulative direction, same sign convention on both
  # sides -- no transform (PR2-build-plan.md:496-502). Measured max abs
  # diff on the two slopes: ~1.5e-06.
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_clm)[c("tempwarm", "contactyes")]),
    tolerance = 1e-4,
    info = "slope coefficients: drmTMB vs ordinal::clm on wine"
  )

  # Cutpoints, no transform. Measured max abs diff: ~2.0e-06.
  expect_equal(
    unname(fit$ordinal$cutpoints),
    unname(stats::coef(fit_clm)[c("1|2", "2|3", "3|4", "4|5")]),
    tolerance = 1e-4,
    info = "ordinal cutpoints: drmTMB vs ordinal::clm on wine"
  )

  # Measured max abs diff: 3.9e-11.
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_clm)),
    tolerance = 1e-4,
    info = "logLik: drmTMB vs ordinal::clm on wine"
  )

  # The boundary that makes this comparison valuable (PR2-build-plan.md:505-521):
  # cumulative_logit() rejects a scale submodel outright (dpars = c("mu")
  # only), while ordinal::clm(scale = ~temp) fits one. Assert both halves so
  # the asymmetry stays a checked fact, not an unverified claim.
  expect_error(
    drmTMB(
      bf(mu = rating ~ temp + contact, sigma = ~temp),
      data = ordinal::wine,
      family = cumulative_logit()
    ),
    "Unsupported parameter"
  )
  fit_clm_scale <- ordinal::clm(
    rating ~ temp + contact,
    scale = ~temp,
    data = ordinal::wine
  )
  expect_true(is.finite(as.numeric(stats::logLik(fit_clm_scale))))
})

test_that("Comparison 5 (c07): cumulative_logit() judge random intercept agrees with ordinal::clmm on wine", {
  testthat::skip_if_not_installed("ordinal")

  fit <- drmTMB(
    bf(mu = rating ~ temp + contact + (1 | judge)),
    data = ordinal::wine,
    family = cumulative_logit()
  )
  fit_clmm <- ordinal::clmm(
    rating ~ temp + contact + (1 | judge),
    data = ordinal::wine
  )

  expect_equal(fit$opt$convergence, 0)

  # No transform on slopes or cutpoints (as Comparison 4). Measured max abs
  # diff on the two slopes: ~1.5e-05.
  expect_equal(
    unname(coef(fit, "mu")),
    unname(fit_clmm$beta[c("tempwarm", "contactyes")]),
    tolerance = 1e-4,
    info = "slope coefficients: drmTMB vs ordinal::clmm on wine"
  )
  expect_equal(
    unname(fit$ordinal$cutpoints),
    unname(fit_clmm$alpha[c("1|2", "2|3", "3|4", "4|5")]),
    tolerance = 1e-4,
    info = "ordinal cutpoints: drmTMB vs ordinal::clmm on wine"
  )

  # Compare SD to SD -- NOT to clmm's printed variance
  # (PR2-build-plan.md:533-536). Measured max abs diff: ~6e-06.
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(ordinal::VarCorr(fit_clmm)$judge, "stddev")),
    tolerance = 1e-4,
    info = "judge random-intercept SD: drmTMB vs ordinal::clmm on wine"
  )

  # Measured max abs diff: ~3.5e-06.
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_clmm)),
    tolerance = 1e-4,
    info = "logLik: drmTMB vs ordinal::clmm on wine"
  )

  # Point-fit parity only -- no REML or interval claim licensed for this
  # family (PR2-build-plan.md:541-546).
})

# ============================================================================
# Block 2c -- checked against glmmTMB, built on the same TMB/AD stack (WEAK
# per docs/design/242-external-comparator-evidence-class.md:110-111): a
# consistency check between related implementations, not a
# cross-implementation check.
# ============================================================================

test_that("Comparison 6 (c01): gaussian sigma ~ Days agrees with glmmTMB dispformula on sleepstudy", {
  suppressWarnings(testthat::skip_if_not_installed("glmmTMB"))
  # lme4 supplies the sleepstudy dataset used on both sides and in the
  # fixed-effect density sub-check. Both packages are Suggests, so a machine
  # with glmmTMB and without lme4 is a legitimate check environment; without
  # this guard the test errors there instead of skipping.
  testthat::skip_if_not_installed("lme4")

  fit <- drmTMB(
    bf(mu = Reaction ~ Days + (1 + Days | Subject), sigma = ~Days),
    data = lme4::sleepstudy,
    family = gaussian()
  )
  fit_glmm <- suppressWarnings(glmmTMB::glmmTMB(
    Reaction ~ Days + (Days | Subject),
    dispformula = ~Days,
    data = lme4::sleepstudy
  ))

  expect_equal(fit$opt$convergence, 0)

  expect_equal(
    unname(coef(fit, "mu")),
    unname(glmmTMB::fixef(fit_glmm)$cond),
    tolerance = 1e-4,
    info = "mu coefficients: drmTMB vs glmmTMB dispformula on sleepstudy"
  )

  # Both sides put the dispersion linear predictor on log(SD) -- no
  # transform, no squaring (PR2-build-plan.md:574-576). Measured max abs
  # diff: sigma:(Intercept) 1.57e-07, sigma:Days 3.77e-08 -- re-measured
  # values, NOT the round-2 1e-6/1.1e-7 figures (PR2-build-plan.md:616-625).
  expect_equal(
    unname(coef(fit, "sigma")),
    unname(glmmTMB::fixef(fit_glmm)$disp),
    tolerance = 1e-4,
    info = "sigma coefficients (log-SD, no transform): drmTMB vs glmmTMB dispformula on sleepstudy"
  )

  # Two DIFFERENT models, do not merge (Noether R1 repair,
  # PR2-build-plan.md:578-608). (1) The conversion itself, verified from the
  # density on a FIXED-EFFECT variant with no random effect and hence no
  # Laplace step on either side: hand dnorm(sd = exp(eta)) must reproduce
  # logLik(); sd = sqrt(exp(eta)) must miss by ~3700 units.
  fit_fe <- drmTMB(
    bf(mu = Reaction ~ Days, sigma = ~Days),
    data = lme4::sleepstudy,
    family = gaussian()
  )
  b_mu <- coef(fit_fe, "mu")
  b_sigma <- coef(fit_fe, "sigma")
  eta_mu <- b_mu[["(Intercept)"]] + b_mu[["Days"]] * lme4::sleepstudy$Days
  eta_sigma <- b_sigma[["(Intercept)"]] + b_sigma[["Days"]] * lme4::sleepstudy$Days
  ll_sd_exp <- sum(stats::dnorm(
    lme4::sleepstudy$Reaction,
    mean = eta_mu, sd = exp(eta_sigma), log = TRUE
  ))
  ll_sd_sqrtexp <- sum(stats::dnorm(
    lme4::sleepstudy$Reaction,
    mean = eta_mu, sd = sqrt(exp(eta_sigma)), log = TRUE
  ))
  expect_equal(
    ll_sd_exp,
    as.numeric(stats::logLik(fit_fe)),
    tolerance = 1e-8,
    info = "fixed-effect density check: sd = exp(eta) reproduces logLik() exactly"
  )
  expect_gt(
    abs(ll_sd_sqrtexp - as.numeric(stats::logLik(fit_fe))),
    100,
    label = "sd = sqrt(exp(eta)) misses logLik() by ~3700 units (wrong transform)"
  )

  # (2) On the displayed random-effect model, logLik() is a Laplace
  # marginal on both sides, so no row-by-row density identity holds -- what
  # the two packages share is the marginal log-likelihood itself. Measured
  # max abs diff: 1.63e-11.
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_glmm)),
    tolerance = 1e-6,
    info = "marginal logLik (random-effect model): drmTMB vs glmmTMB dispformula on sleepstudy"
  )
})

test_that("Comparison 7 (c09): lognormal() mu ~ species, sigma ~ sex agrees with glmmTMB gaussian on log(y)", {
  suppressWarnings(testthat::skip_if_not_installed("glmmTMB"))
  testthat::skip_if_not_installed("palmerpenguins")

  pen <- palmerpenguins::penguins[stats::complete.cases(
    palmerpenguins::penguins[, c("species", "sex", "body_mass_g")]
  ), ]

  fit <- drmTMB(
    bf(mu = body_mass_g ~ species, sigma = ~sex),
    data = pen,
    family = lognormal()
  )
  fit_glmm <- suppressWarnings(glmmTMB::glmmTMB(
    log(body_mass_g) ~ species,
    dispformula = ~sex,
    data = pen,
    family = stats::gaussian()
  ))

  expect_equal(fit$opt$convergence, 0)

  # Compare on the log scale, coefficient-for-coefficient, sigma unsquared.
  # Measured max abs diff: mu ~4e-8, sigma ~1.5e-7 -- essentially exact,
  # since neither side involves a Laplace approximation here.
  expect_equal(
    unname(coef(fit, "mu")),
    unname(glmmTMB::fixef(fit_glmm)$cond),
    tolerance = 1e-4,
    info = "mu coefficients (log scale): drmTMB vs glmmTMB gaussian on log(body_mass_g)"
  )
  expect_equal(
    unname(coef(fit, "sigma")),
    unname(glmmTMB::fixef(fit_glmm)$disp),
    tolerance = 1e-4,
    info = "sigma coefficients (log scale, no transform): drmTMB vs glmmTMB gaussian on log(body_mass_g)"
  )

  # Trap 1: mu is E[log y], NOT log E[y] (PR2-build-plan.md:653-660,
  # R/family-dpq.R stats::dlnorm(y, meanlog = params$mu, sdlog =
  # params$sigma)). Verify from the density: meanlog = mu reproduces
  # logLik(); meanlog = mu - sigma^2/2 misses by ~6 units, small enough to
  # look plausible on eyeball but wrong.
  X_mu <- stats::model.matrix(~species, pen)
  X_sigma <- stats::model.matrix(~sex, pen)
  eta_mu <- as.vector(X_mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(X_sigma %*% coef(fit, "sigma"))
  ll_meanlog_mu <- sum(stats::dlnorm(
    pen$body_mass_g, meanlog = eta_mu, sdlog = exp(eta_sigma), log = TRUE
  ))
  ll_meanlog_offset <- sum(stats::dlnorm(
    pen$body_mass_g,
    meanlog = eta_mu - exp(eta_sigma)^2 / 2, sdlog = exp(eta_sigma), log = TRUE
  ))
  expect_equal(
    ll_meanlog_mu,
    as.numeric(stats::logLik(fit)),
    tolerance = 1e-6,
    info = "density check: meanlog = mu reproduces logLik() exactly"
  )
  expect_gt(
    abs(ll_meanlog_offset - as.numeric(stats::logLik(fit))),
    1,
    label = "meanlog = mu - sigma^2/2 misses logLik() (wrong lognormal parameterization)"
  )

  # Trap 2: do not compare raw logLik across packages -- drmTMB reports the
  # likelihood on the original body_mass_g scale (including the
  # log-Jacobian); glmmTMB reports it for log(body_mass_g). The gap is
  # exactly sum(-log(y)) (PR2-build-plan.md:661-665,
  # adversarial-scales.md:129-135). Measured max abs diff on the identity:
  # <1e-6.
  expect_equal(
    as.numeric(stats::logLik(fit)) - as.numeric(stats::logLik(fit_glmm)),
    sum(-log(pen$body_mass_g)),
    tolerance = 1e-4,
    info = "logLik gap equals the log-Jacobian sum(-log(y)): drmTMB vs glmmTMB on log(body_mass_g)"
  )
})

test_that("Comparison 8 (c03): nbinom2 sigma ~ FoodTreatment agrees with glmmTMB dispformula on Owls", {
  suppressWarnings(testthat::skip_if_not_installed("glmmTMB"))

  # drmTMB:: prefix is mandatory here, not stylistic: glmmTMB also exports
  # nbinom2(), and without library(glmmTMB) attached (never done in this
  # file) an unqualified nbinom2 symbol would still resolve ambiguously
  # depending on search-path order (PR2-build-plan.md:692-697).
  fit <- drmTMB(
    bf(
      mu = SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest),
      sigma = ~FoodTreatment
    ),
    data = glmmTMB::Owls,
    family = drmTMB::nbinom2()
  )
  fit_glmm <- suppressWarnings(glmmTMB::glmmTMB(
    SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest),
    dispformula = ~FoodTreatment,
    family = glmmTMB::nbinom2,
    data = glmmTMB::Owls
  ))

  expect_equal(fit$opt$convergence, 0)

  # Measured max abs diff on the four mu coefficients: ~3.1e-06.
  expect_equal(
    unname(coef(fit, "mu")),
    unname(glmmTMB::fixef(fit_glmm)$cond),
    tolerance = 1e-4,
    info = "mu coefficients: drmTMB vs glmmTMB dispformula (nbinom2) on Owls"
  )

  # drmTMB's sigma maps to size = 1/sigma^2 (R/family-dpq.R
  # drm_nbinom2_size <- function(sigma) 1/sigma^2); glmmTMB's dispformula
  # predictor is log(size) directly. So log(theta) = -2*log(sigma) --
  # compare -2*coef(fit,"sigma") to fixef(g)$disp
  # (PR2-build-plan.md:703-708). Measured max abs diff: 1.15e-06, 1.32e-06.
  sigma_conv <- -2 * coef(fit, "sigma")
  expect_equal(
    unname(sigma_conv),
    unname(glmmTMB::fixef(fit_glmm)$disp),
    tolerance = 1e-4,
    info = "sigma conversion log(theta) = -2*log(sigma): drmTMB vs glmmTMB dispformula on Owls"
  )

  # Two DIFFERENT models, do not merge (same Noether R1 pattern as
  # Comparison 6). (1) The conversion itself, from the density on a
  # FIXED-EFFECT variant with no random effect and hence no Laplace step on
  # either side.
  fit_fe <- drmTMB(
    bf(mu = SiblingNegotiation ~ FoodTreatment, sigma = ~FoodTreatment),
    data = glmmTMB::Owls,
    family = drmTMB::nbinom2()
  )
  X_mu <- stats::model.matrix(~FoodTreatment, glmmTMB::Owls)
  X_sigma <- stats::model.matrix(~FoodTreatment, glmmTMB::Owls)
  eta_mu <- as.vector(X_mu %*% coef(fit_fe, "mu"))
  eta_sigma <- as.vector(X_sigma %*% coef(fit_fe, "sigma"))
  mu_hat <- exp(eta_mu)
  sigma_hat <- exp(eta_sigma)
  ll_size_invsigma2 <- sum(stats::dnbinom(
    glmmTMB::Owls$SiblingNegotiation, size = 1 / sigma_hat^2, mu = mu_hat, log = TRUE
  ))
  expect_equal(
    ll_size_invsigma2,
    as.numeric(stats::logLik(fit_fe)),
    tolerance = 1e-6,
    info = "density check: size = 1/sigma^2 reproduces logLik() exactly"
  )

  # The trap this comparison is last for: Comparison 6's no-transform
  # gaussian rule does NOT transfer. Applied naively (no -2* conversion) it
  # misses by ~0.57 and ~1.81 in absolute terms
  # (PR2-build-plan.md:730-736), and the factor is signed by family (-2*
  # for nbinom2, +2* for tweedie) -- the hardest kind of error to notice
  # because it lands in the right order of magnitude.
  naive_diff <- unname(coef(fit, "sigma")) - unname(glmmTMB::fixef(fit_glmm)$disp)
  expect_true(
    all(abs(naive_diff) > 0.5),
    info = "naive (unconverted) sigma comparison must NOT agree -- demonstrates the -2* trap"
  )

  # (2) On the displayed random-effect model, the two packages share the
  # marginal log-likelihood. Measured max abs diff: 4.20e-10.
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_glmm)),
    tolerance = 1e-6,
    info = "marginal logLik (random-effect model): drmTMB vs glmmTMB dispformula on Owls"
  )
})

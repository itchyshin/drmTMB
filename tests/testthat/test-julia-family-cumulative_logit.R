# A4 (2026-09-05): `cumulative_logit()` admitted through engine = "julia" on
# the fixed-effect (Workflow G) route -- ONE registry row in
# R/julia-family-registry.R plus the three guarded one-line hooks in
# R/julia-bridge.R that call R/julia-family-cumulative_logit.R (design 258
# section 8.9). This file is the family's focused-test limb (docs/design/168)
# and pins the things the admission rests on:
#
#   1. the registry row itself (fe + dispersionless; no phylo, RE, or
#      structured route);
#   2. the payload (no Julia): the ordered response crosses as integer codes
#      1..K, `mu` is labelled WITHOUT "(Intercept)", the `cutpoints` block is
#      labelled with drmTMB's own "<level_k>|<level_k+1>" spelling, and no
#      `sigma` block is invented (design 258 S7.1 / S8.9);
#   3. the same refusals as the native engine for a `sigma ~` formula and an
#      unordered factor, BEFORE Julia starts;
#   4. RED CONTROL: with the registry row absent, the family tag REFUSES;
#   5. the live round trip on the committed fixture: same target as
#      engine = "tmb" (coef by NAME <= 1e-4, logLik <= 1e-4, Wald SE rtol
#      <= 1e-3), the cutpoints landing in `fit$ordinal` (NOT in coef()/vcov())
#      and equal to the native slot, the coef_labels echo validated, and the
#      estimator label equal to what DRM.jl's `estim_method` reports.
#
# Parameterisation is the same on both engines (R/family.R `cumulative_logit()`;
# DRM.jl src/cumulative.jl at pin 430ef64cc): Pr(y <= k) = plogis(theta_k - eta),
# eta = X beta with the intercept dropped, theta_1 = delta_1,
# theta_k = theta_{k-1} + exp(delta_k). Measured at the pin, 2026-09-05:
# coef 2.198e-14, logLik 1.125e-11, SE 5.758e-09 rel, cutpoints 8.982e-13.

# Fixture: the call shape of tests/testthat/test-cumulative-logit.R
# (new_ordinal_data() defaults), reproduced here so this file stands alone.
drm_cumulative_logit_julia_fixture <- function(n = 900L, seed = 20260509) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  cutpoints <- c(-0.90, 0.75)
  eta <- 0.85 * dat$x
  p_low <- stats::plogis(cutpoints[[1L]] - eta)
  p_medium <- stats::plogis(cutpoints[[2L]] - eta) - p_low
  prob <- cbind(p_low, p_medium, 1 - stats::plogis(cutpoints[[2L]] - eta))
  draw <- vapply(
    seq_len(n),
    function(i) sample.int(3L, size = 1L, prob = prob[i, ]),
    integer(1)
  )
  dat$score <- ordered(
    c("low", "medium", "high")[draw],
    levels = c("low", "medium", "high")
  )
  dat
}

drm_cumulative_logit_julia_formula <- function() {
  drmTMB::bf(score ~ x)
}

# cli WRAPS an abort message at the console width, so a phrase that is one
# line here can arrive split across two with an indent. Measured 2026-09-05:
# "internal ordinal diagnostics on either engine" came back as
# "...diagnostics\n  on either engine", so a fixed = TRUE match on the raw
# message is width-dependent and would go flaky on a narrower CI console.
# Collapse every run of whitespace to one space before matching.
drm_flat_msg <- function(x) gsub("[[:space:]]+", " ", x)

test_that("cumulative_logit has exactly one registry row: fixed-effect, dispersionless", {
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")
  expect_identical(sum(fam == "cumulative_logit"), 1L)
  row <- reg[[which(fam == "cumulative_logit")]]
  expect_true(isTRUE(row$fe))
  # The only dpar is `mu` (R/family.R): no sigma block for the label defaulter
  # to invent, and a user-written `sigma ~` formula is refused (see below).
  expect_true(isTRUE(row$dispersionless))
  expect_identical(row$drmjl_tag, "cumulative_logit")
  # NOT widened: every other route column stays FALSE (a later row's job)
  for (col in c("phylo_only", "locscale_phylo", "slope_phylo", "structured")) {
    expect_false(isTRUE(row[[col]]), info = col)
  }
  expect_true("cumulative_logit" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_true("cumulative_logit" %in% drmTMB:::drm_julia_dispersionless_families())
  expect_false("cumulative_logit" %in% drmTMB:::drm_julia_phylo_only_families())
  expect_false("cumulative_logit" %in% drmTMB:::drm_julia_structured_families())
  expect_false("cumulative_logit" %in% drmTMB:::drm_julia_locscale_phylo_families())
  expect_false("cumulative_logit" %in% drmTMB:::drm_julia_slope_phylo_families())
})

test_that("drm_julia_family_tag() admits cumulative_logit on the fixed-effect route", {
  expect_identical(drmTMB:::drm_julia_family_tag("cumulative_logit"), "cumulative_logit")
  expect_identical(
    drmTMB:::drm_julia_bridge_family_type(drmTMB::cumulative_logit()),
    "cumulative_logit"
  )
})

test_that("RED CONTROL: with the registry row absent the family tag refuses again", {
  original <- drmTMB:::drm_julia_family_registry
  testthat::local_mocked_bindings(
    drm_julia_family_registry = function() {
      Filter(function(s) !identical(s$family, "cumulative_logit"), original())
    },
    .package = "drmTMB"
  )
  expect_false("cumulative_logit" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_error(
    drmTMB:::drm_julia_family_tag("cumulative_logit"),
    "currently supports Workflow G"
  )
})

test_that("cumulative_logit payload: integer-coded response, no mu intercept, labelled cutpoints", {
  dat <- drm_cumulative_logit_julia_fixture()
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = drm_cumulative_logit_julia_formula(),
    family_type = "cumulative_logit",
    data = dat,
    env = environment()
  )
  expect_identical(payload$formula$mu, "score ~ x")
  expect_named(payload$formula, "mu")
  # (1) DATA: the ordered factor crosses as integer codes 1..K, in the SAME
  # coding the native engine's prepare_ordinal_response() builds.
  expect_type(payload$data$score, "integer")
  expect_identical(payload$data$score, as.integer(dat$score))
  expect_identical(sort(unique(payload$data$score)), 1:3)
  # (2) LABELS: mu without "(Intercept)"; cutpoints in drmTMB's own spelling;
  # NO sigma block (dispersionless).
  expect_identical(
    payload$coef_labels,
    list(mu = "x", cutpoints = c("low|medium", "medium|high"))
  )
  wire <- lapply(payload$options$coef_labels, function(x) unlist(x, use.names = FALSE))
  expect_identical(wire, list(mu = "x", cutpoints = c("low|medium", "medium|high")))
  # An intercept-only location formula sends an EMPTY mu label set (DRM.jl's
  # mu block has zero columns after the intercept is dropped) and still
  # labels the cutpoints. Measured live at the pin: fits at the native logLik.
  payload1 <- drmTMB:::drm_julia_bridge_payload(
    formula = drmTMB::bf(score ~ 1),
    family_type = "cumulative_logit",
    data = dat,
    env = environment()
  )
  expect_identical(payload1$coef_labels$mu, character(0))
  expect_identical(payload1$coef_labels$cutpoints, c("low|medium", "medium|high"))
  # A 4-level ordered response labels three cutpoints, in level order.
  dat4 <- dat
  dat4$score <- ordered(
    c("a", "b", "c", "d")[pmin(as.integer(dat$score) + (seq_len(nrow(dat)) %% 2L), 4L)],
    levels = c("a", "b", "c", "d")
  )
  payload4 <- drmTMB:::drm_julia_bridge_payload(
    formula = drm_cumulative_logit_julia_formula(),
    family_type = "cumulative_logit",
    data = dat4,
    env = environment()
  )
  expect_identical(payload4$coef_labels$cutpoints, c("a|b", "b|c", "c|d"))
  expect_identical(sort(unique(payload4$data$score)), 1:4)
})

test_that("cumulative_logit refuses a sigma formula and an unordered factor before Julia starts", {
  dat <- drm_cumulative_logit_julia_fixture()
  # The native engine refuses the same formula ("support only a `mu` location
  # formula"); the bridge refuses it on the R side via the dispersionless rule.
  expect_error(
    drmTMB:::drm_julia_bridge_payload(
      formula = drmTMB::bf(score ~ x, sigma ~ 1),
      family_type = "cumulative_logit",
      data = dat,
      env = environment()
    ),
    "does not support a `sigma` formula"
  )
  dat_unordered <- dat
  dat_unordered$score <- factor(as.character(dat$score))
  expect_error(
    drmTMB:::drm_julia_bridge_payload(
      formula = drm_cumulative_logit_julia_formula(),
      family_type = "cumulative_logit",
      data = dat_unordered,
      env = environment()
    ),
    "Ordinal models require an ordered response"
  )
})

test_that("the ordinal-slot helper fails closed on a cutpoint label echo out of step", {
  dat <- drm_cumulative_logit_julia_fixture()
  out <- list(
    formula = drm_cumulative_logit_julia_formula(),
    data = dat,
    coefficients = list(mu = c(x = 0.8), cutpoints = c(theta1 = -1, theta2 = 0.5)),
    coef_vector = c(mu_x = 0.8, cutpoints_theta1 = -1, cutpoints_theta2 = 0.5),
    vcov = diag(3),
    model = list(dpars = c("mu", "cutpoints")),
    uncertainty = list(finite_dpars = c("mu", "cutpoints"))
  )
  expect_error(
    drmTMB:::drm_julia_cumulative_logit_ordinal_slot(out),
    "cutpoint labels that do not match"
  )
  # With drmTMB's own labels echoed, the cutpoints leave the fixed-effect
  # surface and land in `ordinal` on the natural scale.
  good <- out
  good$coefficients$cutpoints <- c(`low|medium` = -1, `medium|high` = 0.5)
  good$coef_vector <- c(mu_x = 0.8, `cutpoints_low|medium` = -1, `cutpoints_medium|high` = 0.5)
  dimnames(good$vcov) <- list(names(good$coef_vector), names(good$coef_vector))
  res <- drmTMB:::drm_julia_cumulative_logit_ordinal_slot(good)
  expect_named(res$coefficients, "mu")
  expect_identical(res$model$dpars, "mu")
  expect_identical(names(res$coef_vector), "mu_x")
  expect_identical(rownames(res$vcov), "mu_x")
  expect_identical(res$uncertainty$finite_dpars, "mu")
  expect_identical(res$ordinal$levels, c("low", "medium", "high"))
  expect_identical(res$ordinal$response, "score")
  expect_identical(res$ordinal$n_categories, 3L)
  expect_equal(
    res$ordinal$cutpoints,
    c(`low|medium` = -1, `medium|high` = -1 + exp(0.5))
  )
  expect_equal(res$ordinal$theta_raw, c(`low|medium` = -1, `medium|high` = 0.5))
})

# ---- live round trip (opt-in; skips only when the engine is absent) --------

drm_cumulative_logit_julia_roundtrip <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path, build, formula_fn) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      dat <- build()
      form <- formula_fn()
      ft <- drmTMB::drmTMB(form, family = drmTMB::cumulative_logit(), data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(form, family = drmTMB::cumulative_logit(), data = dat, engine = "julia")
      flat <- function(f) {
        cf <- stats::coef(f)
        out <- numeric()
        for (nm in names(cf)) {
          out <- c(out, stats::setNames(as.numeric(cf[[nm]]), paste0(nm, ":", names(cf[[nm]]))))
        }
        out
      }
      se_of <- function(f) {
        V <- as.matrix(stats::vcov(f))
        stats::setNames(sqrt(diag(V)), sub("_", ":", rownames(V), fixed = TRUE))
      }
      list(
        class_julia = class(fj),
        model_type = fj$model$model_type,
        dpars = fj$model$dpars,
        engine = fj$engine,
        estimator = fj$estimator,
        estim_method = as.character(fj$bridge$estim_method),
        label_contract = fj$bridge_public_coef_labels$contract,
        public_labels = fj$bridge_public_coef_labels$public,
        coef_tmb = flat(ft),
        coef_julia = flat(fj),
        coef_vector_names = names(fj$coef_vector),
        vcov_names = rownames(as.matrix(stats::vcov(fj))),
        loglik_tmb = as.numeric(stats::logLik(ft)),
        loglik_julia = as.numeric(stats::logLik(fj)),
        se_tmb = se_of(ft),
        se_julia = se_of(fj),
        ordinal_tmb = ft$ordinal,
        ordinal_julia = fj$ordinal,
        fitted_tmb = as.numeric(stats::fitted(ft)),
        fitted_julia = as.numeric(stats::fitted(fj)),
        converged = drmTMB::is_converged(fj),
        nobs = stats::nobs(fj),
        # #1144 parity evidence, captured in the SAME Julia session as the
        # numbers above rather than in a second boot.
        targets_tmb = drmTMB::profile_targets(ft)$parm,
        targets_julia = drmTMB::profile_targets(fj)$parm,
        ready_julia = drmTMB::profile_targets(fj)$profile_ready,
        note_julia = drmTMB::profile_targets(fj)$profile_note,
        cutpoint_parm = {
          tg <- drmTMB::profile_targets(ft)
          tg$parm[tg$target_class == "ordinal-cutpoint"]
        },
        # Native: the constrained cutpoint profile #1144 polished.
        ci_cutpoint_tmb = {
          tg <- drmTMB::profile_targets(ft)
          cp <- tg$parm[tg$target_class == "ordinal-cutpoint"]
          stats::confint(ft, parm = cp, level = 0.95, method = "profile", trace = FALSE)
        },
        # Native Wald refusal, for the engine-to-engine refusal comparison.
        wald_refusal_tmb = tryCatch({
          tg <- drmTMB::profile_targets(ft)
          cp <- tg$parm[tg$target_class == "ordinal-cutpoint"]
          stats::confint(ft, parm = cp[[1L]], method = "wald")
          NA_character_
        }, error = function(e) conditionMessage(e)),
        # Julia: the same three requests, refused.
        refusals_julia = vapply(
          c("wald", "profile", "bootstrap"),
          function(m) {
            tryCatch({
              stats::confint(fj, parm = "ordinal:cutpoint:low|medium", method = m)
              NA_character_
            }, error = function(e) conditionMessage(e))
          },
          character(1L)
        )
      )
    },
    args = list(
      pkg = pkg, jl_path = jl_path,
      build = drm_cumulative_logit_julia_fixture,
      formula_fn = drm_cumulative_logit_julia_formula
    ),
    error = "stack"
  )
}

test_that("cumulative_logit fits through engine = 'julia' on the same target as engine = 'tmb'", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  # A subprocess error is a FAILURE here, never a skip: the environment gates
  # above already cover the absent-engine case, so a refusal ("currently
  # supports Workflow G ...") or a DRM.jl-side abort ("unknown dpar",
  # "coef_labels is missing an entry ...", "no method matching Float64(::
  # CategoricalValue ...)") must surface as red.
  out <- drm_cumulative_logit_julia_roundtrip()

  expect_true("drmTMB_julia" %in% out$class_julia)
  expect_identical(out$model_type, "cumulative_logit")
  expect_identical(out$engine, "julia")
  expect_true(isTRUE(out$converged))
  expect_identical(out$nobs, 900L)

  # design 258 S7.2/S7.3/S8.9: the echo validated; mu carries no intercept;
  # the cutpoints block is echoed in drmTMB's own spelling.
  expect_identical(out$label_contract, "bridge_formula_labels_v1")
  expect_identical(
    out$public_labels,
    c("mu_x", "cutpoints_low|medium", "cutpoints_medium|high")
  )

  # Cutpoints are NOT a dpar on the R side: they leave coef()/vcov() and land
  # in `fit$ordinal`, shaped like the native engine's slot.
  expect_identical(out$dpars, "mu")
  expect_identical(names(out$coef_julia), "mu:x")
  expect_identical(out$coef_vector_names, "mu_x")
  expect_identical(out$vcov_names, "mu_x")
  expect_identical(names(out$ordinal_julia), names(out$ordinal_tmb))
  expect_identical(out$ordinal_julia$levels, c("low", "medium", "high"))
  expect_identical(out$ordinal_julia$response, "score")
  expect_identical(out$ordinal_julia$n_categories, 3L)
  expect_identical(names(out$ordinal_julia$cutpoints), c("low|medium", "medium|high"))
  expect_lt(max(abs(out$ordinal_julia$cutpoints - out$ordinal_tmb$cutpoints)), 1e-4)
  expect_lt(max(abs(out$ordinal_julia$theta_raw - out$ordinal_tmb$theta_raw)), 1e-4)
  expect_true(all(diff(out$ordinal_julia$cutpoints) > 0))

  # Same target: coefficients matched BY NAME; logLik; expected-score fitted().
  expect_setequal(names(out$coef_julia), names(out$coef_tmb))
  cj <- out$coef_julia[names(out$coef_tmb)]
  expect_lt(max(abs(cj - out$coef_tmb)), 1e-4)
  expect_lt(abs(out$loglik_julia - out$loglik_tmb), 1e-4)
  expect_lt(max(abs(out$fitted_julia - out$fitted_tmb)), 1e-4)

  # SE axis: per-coefficient Wald SE, relative tolerance 1e-3 (tools/parity_se.R)
  expect_setequal(names(out$se_julia), names(out$se_tmb))
  sj <- out$se_julia[names(out$se_tmb)]
  expect_true(all(is.finite(sj)) && all(sj > 1e-6))
  expect_lt(max(abs(sj - out$se_tmb) / pmax(abs(sj), abs(out$se_tmb))), 1e-3)

  # Estimator honesty (#1152): the label equals what the engine reports.
  expect_identical(out$estimator, "ML")
  expect_identical(toupper(out$estim_method), "ML")

  # ---- #1144, live: the ordinal cutpoint accessor and interval boundary ----
  # Discovery parity: the Julia fit lists the SAME target names as the native
  # fit, in the same order. Before this fix it listed only `fixef:mu:x`.
  expect_identical(out$targets_julia, out$targets_tmb)
  expect_true(all(startsWith(out$cutpoint_parm, "ordinal:cutpoint:")))
  is_cutpoint <- out$targets_julia %in% out$cutpoint_parm
  expect_true(any(is_cutpoint))
  # ... but they are never ready, and they say why.
  expect_false(any(out$ready_julia[is_cutpoint]))
  expect_true(all(out$note_julia[is_cutpoint] == "julia_ordinal_cutpoint_native_only"))
  expect_true(out$ready_julia[out$targets_julia == "fixef:mu:x"])

  # The native engine still solves the constrained cutpoint profile #1144
  # polished: finite bounds, conf.status "profile".
  expect_identical(
    out$ci_cutpoint_tmb$conf.status,
    rep("profile", length(out$cutpoint_parm))
  )
  expect_true(all(is.finite(out$ci_cutpoint_tmb$lower)))
  expect_true(all(is.finite(out$ci_cutpoint_tmb$upper)))

  # Refusal parity on the Wald axis: BOTH engines refuse a Wald cutpoint
  # interval. The native message names the profile route; the Julia one names
  # the engine.
  expect_match(
    drm_flat_msg(out$wald_refusal_tmb),
    "not available for ordered cutpoints",
    fixed = TRUE
  )
  expect_identical(names(out$refusals_julia), c("wald", "profile", "bootstrap"))
  expect_true(all(!is.na(out$refusals_julia)))
  for (method in names(out$refusals_julia)) {
    msg <- drm_flat_msg(out$refusals_julia[[method]])
    expect_match(
      msg, "Ordered-cutpoint confidence intervals are not available", fixed = TRUE
    )
    expect_match(msg, "engine = \"tmb\"", fixed = TRUE)
    # The measured pre-fix defect must be gone on the live route too.
    expect_false(grepl("Unknown confidence-interval target", msg, fixed = TRUE))
  }
})

# ---- #1144: ordinal cutpoint accessor / interval boundary ------------------
#
# #1144 polished the constrained cutpoint solve so the NATIVE engine reports
# honest `"ordinal:cutpoint:<label>"` profile intervals. `cumulative_logit` is
# an admitted bridge family, so the same question must have an answer through
# `engine = "julia"`. Measured on this fixture at DRM.jl pin 430ef64cc
# (2026-09-05) BEFORE the fix: `fj$ordinal` carried the right cutpoints, but
# `profile_targets(fj)` listed only `fixef:mu:x`, and `confint(fj, parm =
# "ordinal:cutpoint:low|medium")` answered `Unknown confidence-interval
# target` for method = "wald", "profile" AND "bootstrap" -- a typo diagnosis
# for a target that is plainly on the fit.
#
# The interval cannot be routed (DRM.jl's `_bridge_parse_inference_parm`
# accepts only `fixef:` and `sd:` targets at the pin), so the contract this
# file pins is: DISCOVERABLE, and REFUSED BY NAME. Note that the native engine
# ALSO refuses Wald for cutpoints (R/profile.R, "Wald confidence intervals are
# not available for ordered cutpoints") -- so on the Wald axis the two engines
# now refuse alike, and only the profile route stays native-only.

# A `drmTMB_julia`-shaped fit carrying the ordinal slot the bridge builds, with
# the numbers measured live on the committed fixture. Offline: these blocks
# exercise R code only and must never need Julia.
drm_cumulative_logit_julia_stub <- function() {
  structure(
    list(
      model = list(model_type = "cumulative_logit", dpars = "mu"),
      coefficients = list(mu = c(x = 0.8318360)),
      coef_vector = c(mu_x = 0.8318360),
      vcov = matrix(0.0048, 1L, 1L, dimnames = list("mu_x", "mu_x")),
      bridge_payload = list(formula = list(mu = "score ~ x")),
      ordinal = list(
        response = "score",
        levels = c("low", "medium", "high"),
        n_categories = 3L,
        cutpoints = c(`low|medium` = -0.9909812, `medium|high` = 0.6237335),
        theta_raw = c(`low|medium` = -0.9909812, `medium|high` = 0.4791583)
      ),
      uncertainty = list(finite_dpars = "mu"),
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )
}

test_that("the Julia ordinal inventory has the native row shape", {
  rows <- drmTMB:::drm_julia_cumulative_logit_targets(drm_cumulative_logit_julia_stub())
  expect_identical(
    rows$parm,
    c(
      "ordinal:theta_ord:low|medium", "ordinal:theta_ord:medium|high",
      "ordinal:cutpoint:low|medium", "ordinal:cutpoint:medium|high"
    )
  )
  expect_identical(
    rows$target_class,
    c(rep("ordinal-cutpoint-internal", 2L), rep("ordinal-cutpoint", 2L))
  )
  # Same column vocabulary the native rows use (R/profile.R): the public
  # cutpoint is a `constrained` target on the `cutpoint` scale whose
  # link_estimate is the raw increment coordinate.
  expect_identical(rows$scale, c("internal", "internal", "cutpoint", "cutpoint"))
  expect_identical(rows$transformation, rep("ordered_cutpoint", 4L))
  expect_identical(rows$target_type, c("direct", "direct", "constrained", "constrained"))
  expect_identical(rows$tmb_parameter, rep("theta_ord", 4L))
  expect_identical(rows$index, c(1L, 2L, 1L, 2L))
  expect_equal(rows$estimate, c(-0.9909812, 0.4791583, -0.9909812, 0.6237335))
  expect_equal(rows$link_estimate, c(-0.9909812, 0.4791583, -0.9909812, 0.4791583))
  # NEVER ready: there is no cutpoint target in DRM.jl's bridge inference.
  expect_false(any(rows$profile_ready))
  expect_identical(
    rows$profile_note,
    c(rep("internal_ordinal_parameter", 2L), rep("julia_ordinal_cutpoint_native_only", 2L))
  )
  # A fit without an ordinal slot contributes nothing, so the union call site
  # needs no family guard.
  expect_identical(nrow(drmTMB:::drm_julia_cumulative_logit_targets(list())), 0L)
})

test_that("profile_targets() on a Julia cumulative_logit fit lists the ordinal rows", {
  targets <- drmTMB::profile_targets(drm_cumulative_logit_julia_stub())
  # The SAME public rows, in the SAME order, as the native fit reports on this
  # fixture (measured 2026-09-05: fixef:mu:x, two theta_ord, two cutpoint).
  expect_identical(
    targets$parm,
    c(
      "fixef:mu:x",
      "ordinal:theta_ord:low|medium", "ordinal:theta_ord:medium|high",
      "ordinal:cutpoint:low|medium", "ordinal:cutpoint:medium|high"
    )
  )
  expect_identical(targets$profile_ready, c(TRUE, rep(FALSE, 4L)))
  # `ready_only = TRUE` still hands back only what the engine can actually do.
  ready <- drmTMB::profile_targets(drm_cumulative_logit_julia_stub(), ready_only = TRUE)
  expect_identical(ready$parm, "fixef:mu:x")
})

test_that("confint() refuses a Julia cutpoint target by name, for every method", {
  fit <- drm_cumulative_logit_julia_stub()
  for (method in c("wald", "profile", "bootstrap")) {
    err <- expect_error(
      stats::confint(fit, parm = "ordinal:cutpoint:low|medium", method = method),
      "Ordered-cutpoint confidence intervals are not available"
    )
    msg <- drm_flat_msg(conditionMessage(err))
    # The refusal must name the method it refused, the engine that has the
    # capability, and where the fitted cutpoints already are.
    expect_match(msg, paste0("method = \"", method, "\""), fixed = TRUE)
    expect_match(msg, "engine = \"tmb\"", fixed = TRUE)
    expect_match(msg, "fit$ordinal$cutpoints", fixed = TRUE)
    # And it must NOT be the old typo diagnosis (#1144's measured defect).
    expect_false(grepl("Unknown confidence-interval target", msg, fixed = TRUE))
  }
})

test_that("the internal theta_ord coordinate is refused as internal on either engine", {
  err <- expect_error(
    stats::confint(
      drm_cumulative_logit_julia_stub(),
      parm = "ordinal:theta_ord:low|medium", method = "profile"
    ),
    "Ordered-cutpoint confidence intervals are not available"
  )
  # Distinct wording from the cutpoint case: this coordinate is refused
  # natively too, so the message must not blame the bridge.
  expect_match(
    drm_flat_msg(conditionMessage(err)),
    "internal ordinal diagnostics on either engine",
    fixed = TRUE
  )
})

test_that("a brace in a cutpoint label survives into the refusal verbatim", {
  # cli glue-expands its format string, so pasting the collapsed label text
  # INTO that string mangles any label containing a brace. Measured
  # 2026-09-05 before the fix: an "a{1}|b" cutpoint came back as
  # `Requested: "ordinal:cutpoint:a1|b"` -- the refusal quoted, and told the
  # user to use, a target name that does not exist on the fit. Ordered factor
  # levels may legally contain braces, so this is reachable.
  fit <- drm_cumulative_logit_julia_stub()
  fit$ordinal$levels <- c("a{1}", "b", "c")
  names(fit$ordinal$cutpoints) <- c("a{1}|b", "b|c")
  names(fit$ordinal$theta_raw) <- c("a{1}|b", "b|c")
  err <- expect_error(
    stats::confint(fit, parm = "ordinal:cutpoint:a{1}|b", method = "profile"),
    "Ordered-cutpoint confidence intervals are not available"
  )
  msg <- drm_flat_msg(conditionMessage(err))
  # Both the echoed request and the native-route hint keep the real label.
  expect_match(msg, 'Requested: "ordinal:cutpoint:a{1}|b"', fixed = TRUE)
  expect_match(msg, '("ordinal:cutpoint:a{1}|b", "ordinal:cutpoint:b|c")', fixed = TRUE)
  expect_false(grepl("ordinal:cutpoint:a1|b", msg, fixed = TRUE))
  # The label is discoverable under the same spelling.
  expect_true("ordinal:cutpoint:a{1}|b" %in% drmTMB::profile_targets(fit)$parm)
})

test_that("the cutpoint refusal is narrow: only real ordinal targets of this fit", {
  fit <- drm_cumulative_logit_julia_stub()
  # A mistyped label is NOT an ordinal target of this fit, so it keeps the
  # ordinary unknown-target message rather than being mis-diagnosed as an
  # engine-capability refusal.
  expect_error(
    stats::confint(fit, parm = "ordinal:cutpoint:nope", method = "profile"),
    "Unknown confidence-interval target"
  )
  # A fit with no ordinal slot is untouched on every path.
  plain <- fit
  plain$ordinal <- NULL
  plain$model$model_type <- "gaussian"
  expect_identical(drmTMB::profile_targets(plain)$parm, "fixef:mu:x")
  expect_error(
    stats::confint(plain, parm = "ordinal:cutpoint:low|medium", method = "profile"),
    "Unknown confidence-interval target"
  )
  # The fixed-effect Wald path this family already had is unchanged.
  ci <- stats::confint(fit, parm = "fixef:mu:x", method = "wald")
  expect_identical(ci$parm, "fixef:mu:x")
  expect_identical(ci$conf.status, "wald")
  expect_true(is.finite(ci$lower) && is.finite(ci$upper))
  # ... including the no-parm default table, which must not gain a cutpoint row
  # (a Wald cutpoint interval is refused on the native engine too).
  expect_identical(stats::confint(fit)$parm, "fixef:mu:x")
})

test_that("RED CONTROL: without the ordinal predicate the typo diagnosis returns", {
  # Neutralise the one guard `confint.drmTMB_julia()` calls. The cutpoint parm
  # then falls through to the generic matcher and reproduces the EXACT defect
  # measured before this fix.
  testthat::local_mocked_bindings(
    drm_julia_is_ordinal_parm = function(object, parm) FALSE,
    .package = "drmTMB"
  )
  err <- expect_error(
    stats::confint(
      drm_cumulative_logit_julia_stub(),
      parm = "ordinal:cutpoint:low|medium", method = "profile"
    )
  )
  # The generic matcher's wording was IMPROVED by #1156/#1218 -- it went from a bare
  # "Unknown confidence-interval target" to naming the target, the inventory note, the
  # method to use instead, and the valid targets. The control's INTENT is unchanged and
  # still discriminating: with the predicate mocked off you get the GENERIC path, and with
  # it active you get the ordinal-specific diagnosis. Both were measured side by side
  # before this assertion was rewritten -- the active path returns "Ordered-cutpoint
  # confidence intervals are not available for `engine = \"julia\"` fits.", which is why
  # the expect_false() below is the half that carries the control.
  expect_match(
    conditionMessage(err),
    "is listed by `profile_targets()` but is not a profile or bootstrap target",
    fixed = TRUE
  )
  expect_false(
    grepl("Ordered-cutpoint confidence intervals", conditionMessage(err), fixed = TRUE)
  )
})

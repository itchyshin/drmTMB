# fam-biv-student leaf (2026-09-05): `biv_student()` admitted through
# engine = "julia" on the fixed-effect (Workflow G) route. This is the family's
# focused-test limb (docs/design/168) and pins the six things the admission
# rests on:
#
#   1. the registry row itself (fe only: no phylo, no RE, no structured route,
#      and NOT dispersionless -- this family has sigma1, sigma2 and nu);
#   2. the retirement of the family-specific `engine = "julia"` abort that used
#      to fire inside drmTMB() before the registry was ever consulted;
#   3. the payload: all six dpars reach `options$coef_labels` in base-R
#      model.matrix() spelling (docs/design/258 S7.1), and the SHORT form
#      bf(mu1 = ..., mu2 = ...) is defaulted to the same four constant blocks
#      -- no Julia needed for any of this;
#   4. the SCOPE FENCE: every shape native `engine = "tmb"` refuses is refused
#      on the Julia route too, before Julia is started, with the native wording;
#   5. the live round trip: same target as engine = "tmb" (coef by NAME
#      <= 1e-4, |dlogLik| <= 1e-4, per-coefficient Wald SE rtol <= 1e-3), the
#      coef_labels echo validated, the estimator label equal to DRM.jl's
#      `estim_method`;
#   6. RED CONTROL: with the registry row absent the same call REFUSES.
#
# DRM.jl needed NO change. At pin 430ef64cc `_bridge_family("biv_student")`
# already returns `Student()` (src/bridge.jl) and the keyed mu1/mu2 parts select
# the bivariate formula, so `src/bivariate_student.jl` is what actually fits --
# probed directly before any R change and confirmed to route.
#
# Parameterisation is the same on both engines (R/family.R `biv_student()`;
# DRM.jl src/bivariate_student.jl at the pin): identity mu1/mu2; log sigma1 and
# sigma2, which are SCALES, not marginal SDs (SD = sigma * sqrt(nu / (nu - 2)));
# ONE shared nu on the "logm2" link nu = 2 + exp(eta); and a guarded-atanh
# rho12, the SCATTER correlation. Zero rho12 is not independence at finite nu.
# Measured at the pin, 2026-09-05: coef 3.771e-07, logLik diff 2.569e-11, SE
# 9.013e-07 relative.

# Fixture: the call shape and simulator of tests/testthat/test-biv-student.R,
# reproduced here so this file stands alone.
drm_biv_student_julia_fixture <- function() {
  n <- 400L
  set.seed(6401)
  nu <- 7
  rho12 <- 0.35
  x <- seq(-1, 1, length.out = n)
  z1 <- stats::rnorm(n)
  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  shared_scale <- sqrt(nu / stats::rchisq(n, df = nu))
  data.frame(
    x = x,
    y1 = 0.2 + 0.45 * x + 0.55 * z1 * shared_scale,
    y2 = -0.3 - 0.25 * x + 0.85 * z2 * shared_scale
  )
}

drm_biv_student_julia_formula <- function() {
  drmTMB::bf(
    mu1 = y1 ~ x, mu2 = y2 ~ x,
    sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1
  )
}

test_that("biv_student has exactly one registry row, fixed-effect only", {
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")
  expect_identical(sum(fam == "biv_student"), 1L)
  row <- reg[[which(fam == "biv_student")]]
  expect_true(isTRUE(row$fe))
  expect_identical(row$drmjl_tag, "biv_student")
  # NOT widened: every non-FE column stays FALSE (a later row's job). In
  # particular `dispersionless` must stay FALSE -- this family has sigma1,
  # sigma2 and nu, so the label defaulter has real blocks to fill.
  for (col in c("phylo_only", "locscale_phylo", "slope_phylo",
                "dispersionless", "structured")) {
    expect_false(isTRUE(row[[col]]), info = col)
  }
  expect_true("biv_student" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_false("biv_student" %in% drmTMB:::drm_julia_phylo_only_families())
  expect_false("biv_student" %in% drmTMB:::drm_julia_structured_families())
  expect_false("biv_student" %in% drmTMB:::drm_julia_dispersionless_families())
  expect_false("biv_student" %in% drmTMB:::drm_julia_locscale_phylo_families())
  expect_false("biv_student" %in% drmTMB:::drm_julia_slope_phylo_families())
})

test_that("drm_julia_family_tag() admits biv_student on the fixed-effect route", {
  expect_identical(drmTMB:::drm_julia_family_tag("biv_student"), "biv_student")
  # The family type drmTMB derives from the constructor is the registry key.
  expect_identical(
    drmTMB:::drm_julia_bridge_family_type(drmTMB::biv_student()),
    "biv_student"
  )
})

test_that("the family-specific engine = 'julia' abort in drmTMB() is gone", {
  # It used to read: "`biv_student()` is implemented only for
  # `engine = \"tmb\"`; the Julia route is deferred." -- a hard gate that fired
  # BEFORE the registry was consulted, so the registry row alone could never
  # have admitted this family. The registry is now the single authority.
  src <- paste(
    readLines(testthat::test_path("..", "..", "R", "drmTMB.R"), warn = FALSE),
    collapse = "\n"
  )
  expect_false(grepl("the Julia route is deferred", src, fixed = TRUE))
})

test_that("biv_student payload labels all six dpars in base-R spelling (design 258 S7.1)", {
  dat <- drm_biv_student_julia_fixture()
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = drm_biv_student_julia_formula(),
    family_type = "biv_student",
    data = dat,
    env = environment()
  )
  expect_identical(payload$formula$mu1, "y1 ~ x")
  expect_identical(payload$formula$mu2, "y2 ~ x")
  expect_identical(payload$formula$sigma1, "sigma1 ~ 1")
  expect_identical(payload$formula$sigma2, "sigma2 ~ 1")
  expect_identical(payload$formula$nu, "nu ~ 1")
  expect_identical(payload$formula$rho12, "rho12 ~ 1")
  labels <- lapply(payload$options$coef_labels, function(x) unlist(x, use.names = FALSE))
  expect_identical(
    labels,
    list(
      mu1 = c("(Intercept)", "x"), mu2 = c("(Intercept)", "x"),
      sigma1 = "(Intercept)", sigma2 = "(Intercept)",
      nu = "(Intercept)", rho12 = "(Intercept)"
    )
  )
})

test_that("the SHORT bf(mu1, mu2) form defaults all four constant blocks, nu included", {
  # `drm_julia_bridge_default_dpar_labels()` gains a biv_student branch because
  # DRM.jl's bivariate Student route always fits a `nu` block, exactly as
  # `drm_build_biv_student_spec()` inserts a default `nu ~ 1` when the formula
  # omits it. biv_gaussian's three-block branch would leave `nu` unlabelled and
  # DRM.jl's coef_labels echo would abort on the missing entry.
  dat <- drm_biv_student_julia_fixture()
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family_type = "biv_student",
    data = dat,
    env = environment()
  )
  labels <- lapply(payload$options$coef_labels, function(x) unlist(x, use.names = FALSE))
  expect_identical(
    labels,
    list(
      mu1 = c("(Intercept)", "x"), mu2 = c("(Intercept)", "x"),
      sigma1 = "(Intercept)", sigma2 = "(Intercept)",
      nu = "(Intercept)", rho12 = "(Intercept)"
    )
  )
})

test_that("the Julia route refuses every biv_student shape native engine = 'tmb' refuses", {
  # Fixed-effect admission does NOT widen the family: the A4.G17 fe-only fence
  # exempts every `biv_*` tag by prefix, so without
  # drm_julia_refuse_biv_student_beyond_native() these shapes reached DRM.jl.
  # Measured on this branch before the fence: `sigma1 = ~ z`, `rho12 = ~ z`,
  # `nu = ~ z` and `sigma1 = ~ 0 + z` all FIT through engine = "julia" while
  # engine = "tmb" refused them, and an ordinary bar came back as a raw Julia
  # stack trace naming the q=4 structured route. These refusals fire before
  # Julia is started, so this test needs no engine.
  dat <- drm_biv_student_julia_fixture()
  dat$g <- factor(rep(seq_len(20), length.out = nrow(dat)))
  dat$z <- stats::rnorm(nrow(dat))
  jfit <- function(f) {
    drmTMB::drmTMB(f, family = drmTMB::biv_student(), data = dat, engine = "julia")
  }
  expect_error(
    jfit(drmTMB::bf(mu1 = y1 ~ x + (1 | g), mu2 = y2 ~ x,
                    sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)),
    "currently allows fixed-effect formulas only"
  )
  for (part in c("sigma1", "sigma2", "nu", "rho12")) {
    args <- list(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1,
                 nu = ~ 1, rho12 = ~ 1)
    args[[part]] <- ~ z
    expect_error(
      jfit(do.call(drmTMB::bf, args)),
      "with intercept-only",
      info = part
    )
  }
  # `~ 0 + z` has no intercept and is still not intercept-only.
  expect_error(
    jfit(drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 0 + z,
                    sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)),
    "with intercept-only"
  )
  # ... but a redundantly parenthesised intercept IS intercept-only and must
  # NOT be caught: both engines fit `~ (1)` to the same logLik.
  expect_silent(
    drmTMB:::drm_julia_refuse_biv_student_beyond_native(
      drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ (1), sigma2 = ~ 1,
                 nu = ~ 1, rho12 = ~ 1),
      "biv_student"
    )
  )
  # The fence is family-scoped: it must not fire for any other family.
  expect_silent(
    drmTMB:::drm_julia_refuse_biv_student_beyond_native(
      drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z, sigma2 = ~ 1,
                 rho12 = ~ 1),
      "biv_gaussian"
    )
  )
})

test_that("RED CONTROL: without the registry row the same call is refused", {
  # The row IS the admission. Remove it and drm_julia_family_tag() must fall
  # back to the pre-change refusal, so nothing else in the bridge is quietly
  # letting this family through.
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")
  without <- reg[fam != "biv_student"]
  testthat::local_mocked_bindings(
    drm_julia_family_registry = function() without,
    .package = "drmTMB"
  )
  expect_false("biv_student" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_error(
    drmTMB:::drm_julia_family_tag("biv_student"),
    "currently supports Workflow G"
  )
})

# ---- live round trip (opt-in; skips only when the engine is absent) --------

drm_biv_student_julia_roundtrip <- function() {
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
      ft <- drmTMB::drmTMB(form, family = drmTMB::biv_student(), data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(form, family = drmTMB::biv_student(), data = dat, engine = "julia")
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
        engine = fj$engine,
        estimator = fj$estimator,
        estim_method = as.character(fj$bridge$estim_method),
        label_contract = fj$bridge_public_coef_labels$contract,
        public_labels = fj$bridge_public_coef_labels$public,
        coef_tmb = flat(ft), coef_julia = flat(fj),
        loglik_tmb = as.numeric(stats::logLik(ft)),
        loglik_julia = as.numeric(stats::logLik(fj)),
        se_tmb = se_of(ft), se_julia = se_of(fj),
        rho12_tmb = as.numeric(drmTMB::rho12(ft))[1],
        rho12_julia = as.numeric(drmTMB::rho12(fj))[1],
        nu_tmb = as.numeric(stats::predict(ft, dpar = "nu"))[1],
        nu_julia = as.numeric(stats::predict(fj, dpar = "nu"))[1],
        confint_julia = tryCatch({
          stats::confint(fj)
          "RETURNED"
        }, error = function(e) conditionMessage(e)),
        loglik_short = as.numeric(stats::logLik(drmTMB::drmTMB(
          drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
          family = drmTMB::biv_student(), data = dat, engine = "julia"
        ))),
        converged = drmTMB::is_converged(fj),
        nobs = stats::nobs(fj)
      )
    },
    args = list(
      pkg = pkg, jl_path = jl_path,
      build = drm_biv_student_julia_fixture,
      formula_fn = drm_biv_student_julia_formula
    ),
    error = "stack"
  )
}

test_that("biv_student fits through engine = 'julia' on the same target as engine = 'tmb'", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  # A subprocess error is a FAILURE here, never a skip: the environment gates
  # above already cover the absent-engine case, so a refusal ("currently
  # supports Workflow G ...", "the Julia route is deferred") or a DRM.jl-side
  # abort ("coef_labels is missing an entry ...") must surface as red.
  out <- drm_biv_student_julia_roundtrip()

  expect_true("drmTMB_julia" %in% out$class_julia)
  expect_identical(out$model_type, "biv_student")
  expect_identical(out$engine, "julia")
  expect_true(isTRUE(out$converged))
  expect_identical(out$nobs, 400L)

  # design 258 S7.2/S7.3: the echo validated and base-R spelling survived
  expect_identical(out$label_contract, "bridge_formula_labels_v1")
  expect_identical(
    out$public_labels,
    c("mu1_(Intercept)", "mu1_x", "mu2_(Intercept)", "mu2_x",
      "sigma1_(Intercept)", "sigma2_(Intercept)", "nu_(Intercept)",
      "rho12_(Intercept)")
  )

  # Same target: coefficients matched BY NAME (the Julia object orders its dpar
  # blocks mu1, mu2, nu, rho12, sigma1, sigma2; the native object mu1, mu2,
  # sigma1, sigma2, nu, rho12 -- a positional comparison would be wrong on both
  # sides of a real disagreement).
  expect_setequal(names(out$coef_julia), names(out$coef_tmb))
  cj <- out$coef_julia[names(out$coef_tmb)]
  expect_lt(max(abs(cj - out$coef_tmb)), 1e-4)
  expect_lt(abs(out$loglik_julia - out$loglik_tmb), 1e-4)

  # SE axis: per-coefficient Wald SE, relative tolerance 1e-3 (tools/parity_se.R)
  expect_setequal(names(out$se_julia), names(out$se_tmb))
  sj <- out$se_julia[names(out$se_tmb)]
  expect_true(all(is.finite(sj)) && all(sj > 1e-6))
  expect_lt(max(abs(sj - out$se_tmb) / pmax(abs(sj), abs(out$se_tmb))), 1e-3)

  # Response-scale agreement on the two parameters whose LINK differs from the
  # rest: the guarded-atanh scatter correlation and the logm2 shared nu. These
  # are where a scale-convention mismatch between the two implementations would
  # show up while the link-scale coefficients still looked fine.
  expect_lt(abs(out$rho12_julia - out$rho12_tmb), 1e-4)
  expect_lt(abs(out$nu_julia - out$nu_tmb), 1e-4)

  # The SHORT form reaches the same optimum as the fully written formula.
  expect_lt(abs(out$loglik_short - out$loglik_tmb), 1e-4)

  # Intervals stay deferred on BOTH engines for this family.
  # cli wraps the message, so normalise whitespace before matching.
  expect_match(
    gsub("[[:space:]]+", " ", out$confint_julia),
    "interval and profile claims are deferred"
  )

  # Estimator honesty (#1152): the label equals what the engine reports.
  expect_identical(out$estimator, "ML")
  expect_identical(toupper(out$estim_method), "ML")
})

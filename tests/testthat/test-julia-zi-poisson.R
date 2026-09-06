# Zero-inflated Poisson through engine = "julia" -- the focused-test limb
# (docs/design/168) for the `zi_poisson` capability row.
#
# WHY THIS FILE DID NOT EXIST, AND WHY IT SHOULD. The capability row
# `zi_poisson` in drm_julia_capability_comparison() has carried a same-target
# parity receipt since A3 (2026-09-05), but NO drmTMB test drove a `zi ~`
# formula through engine = "julia": measured 2026-09-05, of the files matching
# `engine = "julia"` in tests/testthat/, none also matched `zi ~`. The route
# was load-bearing with no test of its own.
#
# THE ADMISSION MECHANISM, which this file pins because it is easy to get
# wrong. Zero-inflation is NOT a family on either side. drmTMB spells a ZIP as
# `family = poisson()` plus a `zi ~` formula part; `drm_family_type()` returns
# "poisson", and "zi_poisson" is only the POST-FIT `model_type`. The bridge
# therefore admits this route through the `poisson` REGISTRY ROW plus the `zi`
# entry in julia_bridge_supported_dpars() -- not through a `zi_poisson` row.
# DRM.jl spells it the same way (`family = "poisson"` + a keyed `zi` formula
# entry, src/bridge.jl at pin 430ef64cc). There is deliberately no
# `spec("zi_poisson", ...)` row and no `_bridge_family("zi_poisson")` case; the
# tests below assert BOTH absences, so a future "fix" that adds either has to
# argue with a red test rather than land quietly.
#
# Measured at the pin (430ef64cc) on the fixture below, 2026-09-05:
# coef 5.776934e-12 (4/4 by name), logLik -786.1016601045 on both engines
# (diff 1.136868e-12), Wald SE 1.317571e-08 abs / 2.373401e-07 rel over 4 SEs,
# estimator ML on both.

# Fixture: the ZIP shape of tests/testthat/test-zi-poisson.R (a `zi` sub-model
# on its own covariate), reproduced here so this file stands alone. Smaller n
# than that file's 1800 -- this is a parity fixture, not a recovery test.
drm_zi_poisson_julia_fixture <- function() {
  set.seed(20260905)
  n <- 600L
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  mu <- exp(0.30 - 0.35 * x)
  zi <- stats::plogis(-0.90 + 0.55 * z)
  data.frame(
    count = ifelse(stats::runif(n) < zi, 0L, stats::rpois(n, mu)),
    x = x,
    z = z
  )
}

drm_zi_poisson_julia_formula <- function() {
  drmTMB::bf(count ~ x, zi ~ z)
}

# ---- the admission mechanism (offline: no Julia) ---------------------------

test_that("a zero-inflated Poisson is admitted by the poisson row, not a zi row", {
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")

  # There is NO zi_poisson registry row, and none is needed.
  expect_false("zi_poisson" %in% fam)
  expect_false("zi_poisson" %in% drmTMB:::drm_julia_registry_families("fe"))

  # The family type drmTMB derives from the ZIP constructor is "poisson" --
  # `zi_poisson` is a post-fit model_type, never a family tag.
  expect_identical(drm_family_type(stats::poisson(link = "log")), "poisson")
  expect_identical(
    drmTMB:::drm_julia_bridge_family_type(stats::poisson(link = "log")),
    "poisson"
  )
  expect_identical(drmTMB:::drm_julia_family_tag("poisson"), "poisson")

  # The poisson row is what carries it, and it is dispersionless (no sigma).
  row <- reg[[which(fam == "poisson")]]
  expect_true(isTRUE(row$fe))
  expect_true(isTRUE(row$dispersionless))
  expect_identical(row$drmjl_tag, "poisson")
})

test_that("RED CONTROL: the tag `zi_poisson` is REFUSED, not silently routed", {
  # If a future change ever made drm_family_type() emit "zi_poisson", this is
  # the fence that must catch it. A silent pass-through would send DRM.jl a tag
  # its _bridge_family() also refuses (measured at pin 430ef64cc, 2026-09-05:
  # "ArgumentError: drm_bridge: unsupported family `zi_poisson`"), so the
  # failure would surface as a raw Julia error rather than a drmTMB refusal.
  expect_error(
    drmTMB:::drm_julia_family_tag("zi_poisson"),
    "currently supports Workflow G fixed-effect families"
  )
  expect_error(
    drmTMB:::drm_julia_family_tag("zi_poisson", has_phylo = TRUE),
    "currently supports Workflow G fixed-effect families"
  )
})

test_that("`zi` is in the bridge dpar vocabulary and an unknown dpar still refuses", {
  expect_true("zi" %in% drmTMB:::julia_bridge_supported_dpars())

  # The vocabulary is a real gate, not a formality: a dpar outside it aborts on
  # the R side. Without this, "zi is in the list" would be uninformative.
  # `phylocov` is the case R/julia-bridge.R names as deliberately absent, so it
  # is the honest probe; the mutation is white-box because bf() normalises an
  # unrecognised LHS into a `mu` entry rather than carrying it through.
  expect_false("phylocov" %in% drmTMB:::julia_bridge_supported_dpars())
  ok <- drmTMB::bf(count ~ x, zi ~ z)
  expect_silent(drmTMB:::drm_julia_formula_spec(ok))
  bad <- ok
  bad$entries[[2L]]$dpar <- "phylocov"
  expect_error(
    drmTMB:::drm_julia_formula_spec(bad),
    "cannot marshal formula parameter"
  )
})

test_that("the ZIP payload carries both dpars and labels both blocks", {
  dat <- drm_zi_poisson_julia_fixture()
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = drm_zi_poisson_julia_formula(),
    family_type = "poisson",
    data = dat,
    env = environment()
  )
  expect_identical(payload$formula$mu, "count ~ x")
  expect_identical(payload$formula$zi, "zi ~ z")

  # design 258 S7.1: base-R model.matrix() spelling for every dpar sent.
  labels <- lapply(payload$options$coef_labels, function(x) unlist(x, use.names = FALSE))
  expect_identical(
    labels,
    list(mu = c("(Intercept)", "x"), zi = c("(Intercept)", "z"))
  )
  # poisson is dispersionless: NO `sigma` block is invented for it.
  expect_false("sigma" %in% names(payload$options$coef_labels))
})

# ---- live round trip (opt-in; skips only when the engine is absent) --------

drm_zi_poisson_julia_roundtrip <- function() {
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
      fam <- stats::poisson(link = "log")
      ft <- drmTMB::drmTMB(form, family = fam, data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(form, family = fam, data = dat, engine = "julia")
      # A plain Poisson on the SAME data: the contrast that proves the `zi`
      # part reached the engine rather than being dropped in marshalling.
      fp <- drmTMB::drmTMB(drmTMB::bf(count ~ x), family = fam, data = dat,
                           engine = "julia")
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
        model_type_tmb = ft$model$model_type,
        engine = fj$engine,
        estimator = fj$estimator,
        estim_method = as.character(fj$bridge$estim_method),
        label_contract = fj$bridge_public_coef_labels$contract,
        public_labels = fj$bridge_public_coef_labels$public,
        coef_tmb = flat(ft),
        coef_julia = flat(fj),
        loglik_tmb = as.numeric(stats::logLik(ft)),
        loglik_julia = as.numeric(stats::logLik(fj)),
        loglik_plain = as.numeric(stats::logLik(fp)),
        n_coef_plain = length(flat(fp)),
        se_tmb = se_of(ft),
        se_julia = se_of(fj),
        zi_response = as.numeric(stats::plogis(
          stats::coef(fj)$zi[["(Intercept)"]]
        )),
        converged = drmTMB::is_converged(fj),
        nobs = stats::nobs(fj)
      )
    },
    args = list(
      pkg = pkg, jl_path = jl_path,
      build = drm_zi_poisson_julia_fixture,
      formula_fn = drm_zi_poisson_julia_formula
    ),
    error = "stack"
  )
}

test_that("ZIP fits through engine = 'julia' on the same target as engine = 'tmb'", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  # A subprocess error is a FAILURE here, never a skip: the environment gates
  # above already cover the absent-engine case, so a refusal or a DRM.jl-side
  # abort must surface as red.
  out <- drm_zi_poisson_julia_roundtrip()

  expect_true("drmTMB_julia" %in% out$class_julia)
  expect_identical(out$engine, "julia")
  expect_true(isTRUE(out$converged))
  expect_identical(out$nobs, 600L)
  # The NATIVE fit is the one that carries the zi_poisson model_type.
  expect_identical(out$model_type_tmb, "zi_poisson")

  # design 258 S7.2/S7.3: the echo validated, base-R spelling survived, and
  # BOTH dpar blocks are present under their own prefix.
  expect_identical(out$label_contract, "bridge_formula_labels_v1")
  expect_identical(
    out$public_labels,
    c("mu_(Intercept)", "mu_x", "zi_(Intercept)", "zi_z")
  )

  # Same target: coefficients matched BY NAME across all four, both blocks.
  expect_setequal(names(out$coef_julia), names(out$coef_tmb))
  expect_length(out$coef_tmb, 4L)
  cj <- out$coef_julia[names(out$coef_tmb)]
  expect_lt(max(abs(cj - out$coef_tmb)), 1e-4)
  expect_lt(abs(out$loglik_julia - out$loglik_tmb), 1e-4)

  # The `zi` part genuinely reached the engine: a plain Poisson on the same
  # data has two coefficients, not four, and a materially worse likelihood.
  expect_identical(out$n_coef_plain, 2L)
  expect_gt(out$loglik_julia - out$loglik_plain, 1)

  # ... and the zero-inflation probability is on the response scale, in (0, 1),
  # near the simulated plogis(-0.90) at the mean of z.
  expect_gt(out$zi_response, 0)
  expect_lt(out$zi_response, 1)
  expect_lt(abs(out$zi_response - stats::plogis(-0.90)), 0.15)

  # SE axis: per-coefficient Wald SE, relative tolerance 1e-3 (tools/parity_se.R).
  expect_setequal(names(out$se_julia), names(out$se_tmb))
  sj <- out$se_julia[names(out$se_tmb)]
  expect_true(all(is.finite(sj)) && all(sj > 1e-6))
  expect_lt(max(abs(sj - out$se_tmb) / pmax(abs(sj), abs(out$se_tmb))), 1e-3)

  # Estimator honesty (#1152): the label equals what the engine reports.
  expect_identical(out$estimator, "ML")
  expect_identical(toupper(out$estim_method), "ML")
})

# A4 (2026-09-05): `zero_one_beta()` admitted through engine = "julia" on the
# fixed-effect route -- ONE registry row (R/julia-family-registry.R). The call
# shape below is copied from tests/testthat/test-zero-one-beta.R ("drmTMB fits
# fixed-effect zero-one beta models"): the same data generator, the same
# bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v), so a refusal here is a bridge
# refusal and never a malformed call.
#
# Measured 2026-09-05 at DRM.jl pin 430ef64cc (same target, n = 1600, seed
# 20260620), comparator code of the pin's tools/parity_fixture.R and
# tools/parity_se.R:
#   coef  max|d| 3.97868404888868e-11   logLik |d| 1.93267624126747e-12 (tol 1e-4)
#   SE    9.75879113856101e-07 rel / 1.76288246708789e-08 abs  (rtol 1e-3, 8 SEs)
#   estimator "ML" == DRM.jl estim_method "ML"
# No phylo, no random effects, no structured terms are admitted for this family
# through the bridge -- DRM.jl's ZeroOneBeta() itself refuses them.
#
# Live fits run in a callr subprocess (the repo convention: one Julia session,
# pkgload::load_all of THIS source tree, and an engine error is a test ERROR,
# never a swallowed skip -- #1127). One subprocess serves all three live tests.

zoib_bridge_data <- function(n = 1600, seed = 20260620) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n), z = stats::rnorm(n), w = stats::rnorm(n), v = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = -0.20, x = 0.65)
  beta_sigma <- c(`(Intercept)` = -0.85, z = 0.22)
  beta_zoi <- c(`(Intercept)` = -1.00, w = 0.45)
  beta_coi <- c(`(Intercept)` = 0.15, v = -0.55)
  mu <- stats::plogis(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  zoi <- stats::plogis(beta_zoi[[1L]] + beta_zoi[[2L]] * dat$w)
  coi <- stats::plogis(beta_coi[[1L]] + beta_coi[[2L]] * dat$v)
  y <- stats::rbeta(n, shape1 = mu / sigma^2, shape2 = (1 - mu) / sigma^2)
  boundary <- stats::runif(n) < zoi
  y[boundary] <- as.numeric(stats::runif(sum(boundary)) < coi[boundary])
  dat$prop <- y
  dat
}

zoib_bridge_formula <- function() bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v)

# ---- offline: the registry row and what derives from it ---------------------

test_that("zero_one_beta is ONE fixed-effect registry row and nothing wider", {
  reg <- drmTMB:::drm_julia_family_registry()
  row <- Filter(function(s) identical(s$family, "zero_one_beta"), reg)
  expect_length(row, 1L)
  row <- row[[1L]]
  expect_true(row$fe)
  expect_identical(row$drmjl_tag, "zero_one_beta")
  for (flag in c("phylo_only", "locscale_phylo", "slope_phylo", "dispersionless", "structured")) {
    expect_false(isTRUE(row[[flag]]), info = flag)
  }
  expect_true("zero_one_beta" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_false("zero_one_beta" %in% drmTMB:::drm_julia_phylo_only_families())
  expect_false("zero_one_beta" %in% drmTMB:::drm_julia_structured_families())
  expect_false("zero_one_beta" %in% drmTMB:::drm_julia_dispersionless_families())
})

test_that("drm_julia_family_tag() admits zero_one_beta with the tag DRM.jl accepts", {
  expect_identical(drmTMB:::drm_julia_family_tag("zero_one_beta"), "zero_one_beta")
  # the tag is the string DRM.jl's _bridge_family() has a case for (src/bridge.jl)
  expect_identical(drmTMB:::drm_julia_family_tag("zero_one_beta"),
                   drmTMB:::drm_family_type(zero_one_beta()))
})

test_that("all four zero_one_beta dpars reach the payload and the coef_labels (design 258)", {
  dat <- zoib_bridge_data(n = 40)
  fml <- zoib_bridge_formula()
  spec <- drmTMB:::drm_julia_formula_spec(fml)
  expect_identical(names(spec), c("mu", "sigma", "zoi", "coi"))
  expect_identical(unname(unlist(spec)),
                   c("prop ~ x", "sigma ~ z", "zoi ~ w", "coi ~ v"))
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    fml, dat, environment(), family_type = "zero_one_beta"
  )
  expect_identical(labels$mu, c("(Intercept)", "x"))
  expect_identical(labels$sigma, c("(Intercept)", "z"))
  expect_identical(labels$zoi, c("(Intercept)", "w"))
  expect_identical(labels$coi, c("(Intercept)", "v"))
  # zoi/coi are bridge-known block prefixes, so "zoi_(Intercept)" splits at the
  # dpar boundary and not at the first underscore (R/julia-bridge.R S1)
  split <- drmTMB:::drm_julia_split_coef_name(c("zoi_(Intercept)", "coi_v", "sigma_z"))
  expect_identical(split$dpar, c("zoi", "coi", "sigma"))
  expect_identical(split$term, c("(Intercept)", "v", "z"))
})

# ---- live: same-target parity against the native TMB engine ----------------

.zoib_live_cache <- new.env(parent = emptyenv())

zoib_live <- function() {
  if (!is.null(.zoib_live_cache$res)) return(.zoib_live_cache$res)
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  res <- callr::r(
    function(pkg, jl_path, gen, fml_fun) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      dat <- gen()
      fml <- fml_fun()
      ft <- drmTMB::drmTMB(fml, family = drmTMB::zero_one_beta(), data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(fml, family = drmTMB::zero_one_beta(), data = dat, engine = "julia")
      # parity_se.R contract: per-coefficient Wald SE, names normalised to the
      # flat "<dpar>_<term>" convention the fixtures use
      se_of <- function(f) {
        V <- as.matrix(stats::vcov(f))
        se <- sqrt(diag(V))
        names(se) <- sub(":", "_", rownames(V), fixed = TRUE)
        se
      }
      err_of <- function(expr) tryCatch({ expr; "" }, error = function(e) conditionMessage(e))
      dat2 <- gen(n = 400)
      dat2$g <- factor(rep(seq_len(20L), length.out = nrow(dat2)))
      # A4-INTEGRATION (2026-09-05): the default-label fix (G1-G3,
      # drm_julia_bridge_default_dpar_labels() in R/julia-bridge.R) now
      # defaults zoi/coi the same way it always defaulted sigma, so this
      # short formula (zoi/coi omitted) FITS through engine = "julia" today
      # -- it used to abort at DRM.jl's label echo (the file's former
      # "KNOWN HOLE" test, replaced below).
      fj_omit <- drmTMB::drmTMB(
        drmTMB::bf(prop ~ x, sigma ~ z),
        family = drmTMB::zero_one_beta(), data = dat2, engine = "julia")
      list(
        class = class(fj),
        engine = fj$engine,
        model_type = fj$model$model_type,
        dpars = fj$model$dpars,
        estimator = fj$estimator,
        engine_estim_method = as.character(fj$bridge$estim_method),
        reml = fj$REML,
        converged = drmTMB::is_converged(fj),
        coef_labels = fj$bridge_payload$coef_labels,
        public_labels = fj$bridge_public_coef_labels,
        raw_names = as.character(fj$bridge$coef_names),
        ct = unlist(drmTMB::fixef(ft)), cj = unlist(drmTMB::fixef(fj)),
        ll_t = as.numeric(stats::logLik(ft)), ll_j = as.numeric(stats::logLik(fj)),
        df_t = ft$df, df_j = fj$df,
        fitted_diff = max(abs(stats::fitted(ft) - stats::fitted(fj))),
        se_t = se_of(ft), se_j = se_of(fj),
        # neighbours, in DRM.jl's own words (forwarded through JuliaCall)
        err_ranef = err_of(drmTMB::drmTMB(
          drmTMB::bf(prop ~ x + (1 | g), sigma ~ z, zoi ~ w, coi ~ v),
          family = drmTMB::zero_one_beta(), data = dat2, engine = "julia")),
        omit_loglik = as.numeric(stats::logLik(fj_omit)),
        omit_estimator = fj_omit$estimator,
        omit_fixef_names = names(unlist(drmTMB::fixef(fj_omit)))
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, gen = zoib_bridge_data, fml_fun = zoib_bridge_formula),
    error = "error"
  )
  .zoib_live_cache$res <- res
  res
}

test_that("zero_one_beta fixed effects: engine = 'julia' matches engine = 'tmb' (coef, logLik, SE, estimator)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  res <- zoib_live()

  expect_true("drmTMB_julia" %in% res$class)
  expect_identical(res$engine, "julia")
  expect_identical(res$model_type, "zero_one_beta")
  expect_setequal(res$dpars, c("mu", "sigma", "zoi", "coi"))
  expect_true(isTRUE(res$converged))

  # G2 / design 258: all four dpars reached the payload and the echo validated
  # (the fit completed with the names the R side sent, in DRM.jl's block order)
  expect_identical(res$coef_labels$mu, c("(Intercept)", "x"))
  expect_identical(res$coef_labels$sigma, c("(Intercept)", "z"))
  expect_identical(res$coef_labels$zoi, c("(Intercept)", "w"))
  expect_identical(res$coef_labels$coi, c("(Intercept)", "v"))
  expect_identical(res$raw_names,
                   c("mu_(Intercept)", "mu_x", "sigma_(Intercept)", "sigma_z",
                     "zoi_(Intercept)", "zoi_w", "coi_(Intercept)", "coi_v"))
  expect_identical(res$public_labels$contract, "bridge_formula_labels_v1")

  # G3: coefficients matched BY NAME (fixef(fj) lists blocks alphabetically --
  # coi, mu, sigma, zoi -- a pre-existing split() order in R/julia-bridge.R,
  # not a naming difference; parity_numeric() in DRM.jl matches by name too)
  expect_setequal(names(res$cj), names(res$ct))
  expect_lt(max(abs(res$ct - res$cj[names(res$ct)])), 1e-4)
  expect_lt(abs(res$ll_t - res$ll_j), 1e-4)
  expect_identical(res$df_j, res$df_t)
  expect_lt(res$fitted_diff, 1e-6)

  # G4: SE axis (parity_se.R contract, rtol 1e-3)
  expect_setequal(names(res$se_j), names(res$se_t))
  st <- res$se_t; sj <- res$se_j[names(st)]
  expect_true(all(is.finite(st)) && all(is.finite(sj)))
  expect_lt(max(abs(st - sj) / pmax(abs(st), abs(sj))), 1e-3)

  # G5: the ENGINE is the authority on the estimator (#1152/#1155) -- compare,
  # do not merely observe that the mislabel guard did not fire
  expect_identical(res$engine_estim_method, "ML")
  expect_identical(res$estimator, res$engine_estim_method)
  expect_false(isTRUE(res$reml))
})

test_that("zero_one_beta through engine = 'julia' stays fixed-effect only (DRM.jl refuses random effects)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  res <- zoib_live()
  expect_match(res$err_ranef, "ZeroOneBeta\\(\\) currently supports fixed effects only")
})

test_that("A4-INTEGRATION: the default-label fix closes zero_one_beta's known hole -- a formula omitting zoi/coi now fits", {
  # Formerly a KNOWN HOLE (A4, #1171): DRM.jl defaults an absent sigma/zoi/coi
  # part to `~ 1` and fits the block, and its coef_labels echo demands a
  # label for EVERY block it fits, but the R producer only defaulted a
  # `sigma` label (drm_julia_bridge_default_dpar_labels(), R/julia-bridge.R).
  # This leaf widens that defaulter to read every dpar a family declares
  # beyond mu/sigma (G1-G3), so bf(prop ~ x, sigma ~ z) (zoi/coi omitted) now
  # fits through engine = "julia" too, matching engine = "tmb" (measured
  # logLik -425.0937691 on this fixture; A4-INTEGRATION after-task 3.1).
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  res <- zoib_live()
  expect_true(is.finite(res$omit_loglik))
  expect_identical(res$omit_estimator, "ML")
  expect_true(all(c("zoi.(Intercept)", "coi.(Intercept)") %in% res$omit_fixef_names))
})

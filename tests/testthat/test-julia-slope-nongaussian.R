# Non-Gaussian phylogenetic random-SLOPE route via engine = "julia" (cluster 3).
#
# HEADER CORRECTED 2026-09-05 (leaf jl-620-two-sd, verifying DRM.jl#620's closure).
# The previous header claimed "drmTMB's native TMB path rejects structured slopes.
# So the Julia bridge is the only route, and we assert a finite-and-sane floor."
# Both halves are false at this main, and the first half was the stated REASON this
# file settles for a floor instead of a cross-engine same-target receipt -- which is
# exactly how a parity cell stays unmeasured. Measured on this worktree,
# engine = "tmb", 40-tip `ape::rcoal` tree, seed 7, using the call shapes the
# package's own passing native tests build:
#
#   gaussian  bf(y ~ x + phylo(1 + x | species, tree), sigma ~ 1)  FITS, logLik -21.148924
#   poisson   bf(y ~ x + phylo(1 + x | species, tree))             FITS, logLik -68.436705
#   nbinom2   bf(y ~ x + phylo(1 + x | species, tree), sigma ~ 1)  FITS, logLik -73.445994
#   Gamma     bf(y ~ x + phylo(1 + x | species, tree), sigma ~ 1)  REFUSES:
#             "Gamma `phylo()` `mu` effects are intercept-only in this q=1 route."
#
# All three fitting families report TWO SD terms, `phylo(1 | species)` and
# `phylo(0 + x | species)`. The native shapes live at
# tests/testthat/test-count-structured-mu.R:781 (poisson) and :807 (nbinom2), and
# tests/testthat/test-julia-marker-slope-guard.R:137 (gaussian).
#
# The second half is stale rather than wrong-from-birth: since drmTMB#1146 this file
# asserts a REFUSAL, not a finite-and-sane floor (see the block comment below).
#
# WHAT IS ACTUALLY TRUE of the one cell this file exercises. Gamma
# `phylo(1 + x | species)` is refused by BOTH engines -- natively by drmTMB's q=1
# structured route (message above), and by `engine = "julia"` at the R bridge before
# Julia boots. There is therefore no Gamma same-target receipt available here and none
# is claimed. NOT COVERED, and worth a follow-up now that the header no longer hides
# it: the gaussian / poisson / nbinom2 cells above DO have a native twin, so a real
# cross-engine comparison is possible for them the moment the pinned DRM.jl engine
# admits the construct (DRM.jl#620's Gaussian route landed on DRM.jl main at 1a041d089,
# AFTER the pin 430ef64cc this suite runs against).

drm_slope_ng_path <- function() {
  drm_test_drmjl_path()
}

drm_phylo_slope_gamma_fit <- function(n_tip = 40L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_slope_ng_path()
  callr::r(
    function(pkg, jl_path, n_tip) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      set.seed(7)
      tree <- ape::rcoal(n_tip)
      sp <- tree$tip.label
      x <- stats::rnorm(n_tip)
      bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.6)
      eta <- 0.4 + 0.3 * x + bm[sp]
      mu <- exp(eta)
      y <- stats::rgamma(n_tip, shape = 5, rate = 5 / mu)
      dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)

      form <- drmTMB::bf(y ~ phylo(1 + x | species, tree = tree), sigma ~ 1)
      fj <- drmTMB::drmTMB(
        form,
        family = stats::Gamma(link = "log"),
        data = dat,
        engine = "julia"
      )
      list(
        engine = fj$engine,
        nobs = stats::nobs(fj),
        loglik_julia = as.numeric(stats::logLik(fj)),
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "stack"
  )
}

test_that("Gamma phylo random-slope (1 + x | species) is REFUSED before engine = \"julia\" boots", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("ape")
  # CHANGED BY drmTMB#1146 (DRM.jl#620/#621), 2026-09-05. Until this PR, this
  # cell reached DRM.jl and DRM.jl's own `_check_phylo_re_lhs`
  # (src/gaussian_ranef.jl, added by DRM.jl#621 at the 2026-09-03 re-pin)
  # refused it -- verified live at the pin (430ef64cc) immediately before this
  # change: "phylo(1 + x | species) is not implemented on the univariate
  # routes -- only `phylo(1 | species)` (intercept) is; drmTMB fits a two-SD
  # phylogenetic random slope on Gaussian only, tracked as a follow-up."
  #
  # drmTMB#1146 asked for that SAME refusal defense-in-depth, moved BEFORE any
  # Julia interaction (`drm_julia_refuse_marker_slope_unsupported()`,
  # R/julia-bridge.R), so a future re-pin or DRM.jl refactor cannot reopen the
  # gap this test polices. The construct is still refused; it is refused one
  # layer earlier and in the R bridge's own words instead of DRM.jl's. The
  # Julia-boots-and-refuses behaviour this test used to pin is now covered,
  # with no Julia required, by
  # tests/testthat/test-julia-marker-slope-guard.R.
  #
  # The #1127 principle is PRESERVED, not weakened: engine availability is
  # still decided by drm_skip_live_julia() above, an engine error is still a
  # test error rather than a skip, and this does not catch-and-ignore. It
  # asserts the SPECIFIC refusal, so any OTHER engine failure -- a
  # marshalling fault, a coef_labels gap, a numerical abort -- still fails
  # the test rather than being absorbed by a bare expect_error().
  cnd <- tryCatch(drm_phylo_slope_gamma_fit(), error = function(e) e)
  expect_s3_class(cnd, "error")
  msg <- conditionMessage(cnd)

  # The R bridge's own words, from
  # drm_julia_refuse_marker_slope_unsupported() (R/julia-bridge.R).
  expect_true(grepl("cannot fit a random slope", msg, fixed = TRUE))
  expect_true(grepl("phylo", msg, fixed = TRUE))
  expect_true(grepl("engine = \"tmb\"", msg, fixed = TRUE))
  expect_true(grepl("DRM.jl#620", msg, fixed = TRUE))

  # NEGATIVE CONTROLS: the failures this test must NOT silently pass on.
  # `coef_labels` was the previous live breakage on this exact cell (N9,
  # 2026-09-03); a regression there must not be mistaken for the refusal.
  # This refusal is now an R-side check, so it should never even reach
  # JuliaCall -- if it does, that is itself a regression worth catching.
  expect_false(grepl("coef_labels", msg, fixed = TRUE))
  expect_false(grepl("Failed to precompile", msg, fixed = TRUE))
  expect_false(grepl("Package DRM not found", msg, fixed = TRUE))
  expect_false(grepl("Error happens in Julia", msg, fixed = TRUE))
})

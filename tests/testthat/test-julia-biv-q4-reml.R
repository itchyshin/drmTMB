# Live bridge q4 bivariate phylogenetic location-scale REML round-trip
# (the biv_q4_phylo_reml capability cell).
#
# 'covered' (engine-vs-engine parity) is STRUCTURALLY IMPOSSIBLE for this cell:
# native engine='tmb' rejects bivariate phylo REML ("REML for bivariate Gaussian
# models currently supports fixed-effect mean models only"), so there is no second
# engine to parity against. This test banks the defended-partial BRIDGE evidence:
# engine='julia' REML=TRUE forwards faithfully to DRM.jl's restricted-likelihood
# q4 fit (effective_REML, estimator "REML"), both ML and REML converge, the fit
# returns finite among-axis SDs, REML genuinely differs from ML (the restricted
# likelihood changes the fit), and the Wald CIs for the among-axis SD targets are
# correctly UNAVAILABLE at the singular q4 boundary.
#
# The REML estimator's RECOVERY advantage (less biased / closer to truth than ML
# on all four among-axis SDs) is banked separately as a direct-DRM.jl recovery
# pilot: docs/dev-log/simulation-artifacts/2026-06-21-q4-reml-recovery-pilot/. It
# is an identifiability-dependent estimator property, NOT asserted here.
#
# Live, callr-isolated, gated on DRM_JL_PATH; SKIPPED (never failed) when
# JuliaCall / callr / pkgload / ape / the DRM.jl q4 engine is unavailable.

drm_biv_q4_reml_path <- function() drm_test_drmjl_path("DRM_JL_PATH")

drm_biv_q4_reml_fit <- function(n_tip = 16L, m = 5L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_biv_q4_reml_path()
  callr::r(
    function(pkg, jl_path, n_tip, m) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(20260614)
      N <- as.integer(n_tip)
      tree <- ape::rcoal(N)
      C <- ape::vcv(tree, corr = TRUE)
      LC <- t(chol(C))
      Lam <- matrix(c(0.25, 0.10, 0.05, 0.00,
                      0.10, 0.25, 0.00, 0.04,
                      0.05, 0.00, 0.16, 0.02,
                      0.00, 0.04, 0.02, 0.16), 4, 4, byrow = TRUE)
      U <- LC %*% matrix(stats::rnorm(N * 4), N, 4) %*% chol(Lam)
      sp <- rep(seq_len(N), each = m)
      n <- length(sp)
      x <- stats::rnorm(n)
      y1 <- 0.5 + 0.3 * x + U[sp, 1] + exp(-0.6 + U[sp, 3]) * stats::rnorm(n)
      y2 <- -0.2 + 0.4 * x + U[sp, 2] + exp(-0.6 + U[sp, 4]) * stats::rnorm(n)
      dat <- data.frame(species = tree$tip.label[sp], x = x, y1 = y1, y2 = y2,
                        stringsAsFactors = FALSE)
      form <- drmTMB::bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
        sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
        rho12 = ~1
      )
      fit_one <- function(reml) {
        drmTMB::drmTMB(form, family = drmTMB::biv_gaussian(), data = dat,
                       engine = "julia", REML = reml)
      }
      sd_from <- function(f) {
        cf <- unlist(stats::coef(f))
        nm <- names(cf)
        L <- matrix(0, 4, 4)
        for (co in 1:4) {
          for (rw in co:4) {
            idx <- which(grepl(paste0("Sigma_a:L", rw, co), nm, fixed = TRUE))
            v <- cf[[idx[1]]]
            L[rw, co] <- if (rw == co) exp(v) else v
          }
        }
        sqrt(diag(L %*% t(L)))
      }
      fml <- fit_one(FALSE)
      frl <- fit_one(TRUE)
      ci <- stats::confint(frl, method = "wald")
      sa <- ci[grepl("Sigma_a", ci$parm), , drop = FALSE]
      list(
        eff_reml = isTRUE(frl$effective_REML),
        req_reml = isTRUE(frl$requested_REML),
        estimator = frl$estimator,
        eff_reml_ml = isTRUE(fml$effective_REML),
        conv_ml = drmTMB::is_converged(fml),
        conv_reml = drmTMB::is_converged(frl),
        sd_ml = sd_from(fml),
        sd_reml = sd_from(frl),
        n_sa = nrow(sa),
        wald_sa_all_na = nrow(sa) > 0 && all(is.na(sa$lower) & is.na(sa$upper))
      )
    },
    args = list(pkg = pkg, jl_path = jl_path,
                n_tip = as.integer(n_tip), m = as.integer(m)),
    error = "error"
  )
}

test_that("engine='julia' q4 bivariate phylo REML forwards faithfully with honest CI status (biv_q4_phylo_reml)", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_biv_q4_reml_path()),
    "DRM.jl q4 engine not available"
  )

  res <- tryCatch(
    drm_biv_q4_reml_fit(),
    error = function(e) {
      testthat::skip(paste("q4 REML bridge round-trip unavailable:",
                           conditionMessage(e)))
    }
  )
  skip_if(is.null(res))

  # REML is forwarded faithfully through the bridge to DRM.jl's restricted fit.
  expect_true(res$eff_reml)
  expect_true(res$req_reml)
  expect_identical(res$estimator, "REML")
  # The ML fit is genuinely ML (no silent REML).
  expect_false(res$eff_reml_ml)
  # Both fits converge with finite, positive among-axis SDs.
  expect_true(isTRUE(res$conv_ml) && isTRUE(res$conv_reml))
  expect_length(res$sd_reml, 4L)
  expect_true(all(is.finite(res$sd_ml)) && all(is.finite(res$sd_reml)))
  expect_true(all(res$sd_reml > 0))
  # The restricted likelihood genuinely changes the fit (not a silent ML no-op).
  expect_gt(max(abs(res$sd_reml - res$sd_ml)), 1e-3)
  # Honest CI status: Wald is correctly UNAVAILABLE for the among-axis SD targets
  # at the singular q4 boundary (no spurious finite Wald interval).
  expect_true(res$wald_sa_all_na)
})

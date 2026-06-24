# Private q2 phylogenetic point-export bridge primitive. This is deliberately a
# diagnostic helper, not public `engine = "julia"` q2 support.

drm_q2_phylo_path <- function() {
  drm_test_drmjl_path("DRM_JL_PATH")
}

drm_q2_phylo_point_export <- function(n_tip = 12L, nrep = 2L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_q2_phylo_path()
  callr::r(
    function(pkg, jl_path, n_tip, nrep) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(20260624L)
      tree <- ape::rcoal(n_tip)
      species <- rep(tree$tip.label, each = nrep)
      n <- length(species)
      x <- stats::rnorm(n)
      species_effect <- stats::setNames(
        matrix(stats::rnorm(n_tip * 2L, sd = 0.35), n_tip, 2L),
        NULL
      )
      row_id <- match(species, tree$tip.label)
      X <- cbind(`(Intercept)` = 1, x = x)
      Y <- cbind(
        y1 = 0.25 +
          0.35 * x +
          species_effect[row_id, 1L] +
          stats::rnorm(n, sd = 0.30),
        y2 = -0.15 +
          0.20 * x +
          species_effect[row_id, 2L] +
          stats::rnorm(n, sd = 0.35)
      )

      drmTMB:::drm_julia_call_q2_phylo_point_export(
        Y = Y,
        X = X,
        species = species,
        tree = tree,
        options = list(iterations = 80L, g_tol = 1e-4)
      )
    },
    args = list(
      pkg = pkg,
      jl_path = jl_path,
      n_tip = n_tip,
      nrep = nrep
    ),
    error = "error"
  )
}

test_that("private q2 phylo point-export bridge primitive returns diagnostic payload", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_q2_phylo_path()),
    "DRM.jl q2 diagnostic engine path not available"
  )

  out <- tryCatch(
    drm_q2_phylo_point_export(),
    error = function(e) {
      testthat::skip(paste(
        "q2 phylo point-export bridge primitive unavailable:",
        conditionMessage(e)
      ))
    }
  )

  expect_equal(
    out$target,
    "gaussian_q2_mu1_mu2_phylo_restricted_diagonal_residual"
  )
  expect_equal(out$dimension, "q2")
  expect_equal(out$structured_type, "phylo")
  expect_equal(out$axes, c("mu1", "mu2"))
  expect_equal(dim(out$sigma_a), c(2L, 2L))
  expect_equal(dim(out$correlation), c(2L, 2L))
  expect_equal(diag(out$correlation), c(1, 1), tolerance = 1e-8)
  expect_true(is.finite(out$loglik))
  expect_match(out$claim_boundary, "restricted point export", fixed = TRUE)
  expect_match(
    out$claim_boundary,
    "no R-via-Julia q2 bridge support",
    fixed = TRUE
  )
  expect_match(out$claim_boundary, "interval coverage", fixed = TRUE)
})

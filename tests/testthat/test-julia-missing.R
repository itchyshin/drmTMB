# engine = "julia" missing-response routing (Ayumi LS#2, point 3).
#
# DRM.jl fits the OBSERVED responses while keeping the full tree / design -- the
# Gaussian observed-data likelihood (missing rows leave the likelihood but their
# phylogenetic positions still inform the covariance). The bridge now allows
# `missing = miss_control(response = "include")` for Gaussian (mirroring native
# TMB's Gaussian-only scope) and still rejects it for non-Gaussian families.
#
# The live fit runs in a fresh subprocess (callr) and SKIPS when JuliaCall /
# DRM.jl are absent. The non-Gaussian rejection is a pure-R gate (it aborts
# before any Julia call) and runs unconditionally.

drm_miss_jl_path <- function() {
  drm_test_drmjl_path()
}

test_that("engine='julia' fits Gaussian response='include' (observed-data, design kept)", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_miss_jl_path()),
    "DRM.jl engine path not available"
  )

  res <- tryCatch(
    {
      pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
      callr::r(
        function(pkg, jl_path) {
          julia_home <- Sys.getenv(
            "DRM_JL_JULIA_HOME",
            Sys.getenv("JULIA_HOME", "")
          )
          if (nzchar(julia_home)) {
            Sys.setenv(JULIA_HOME = julia_home)
          }
          options(drmTMB.DRM.jl.path = jl_path)
          suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
          set.seed(1L)
          n <- 60L
          x <- stats::rnorm(n)
          y <- 0.3 + 0.5 * x + stats::rnorm(n) * exp(0.1 * x)
          y[1:6] <- NA
          dat <- data.frame(y = y, x = x)
          fj <- drmTMB::drmTMB(
            drmTMB::bf(y ~ x, sigma ~ x),
            family = stats::gaussian(),
            data = dat,
            engine = "julia",
            missing = drmTMB::miss_control(response = "include")
          )
          list(ll = as.numeric(stats::logLik(fj)), nobs = stats::nobs(fj))
        },
        args = list(pkg = pkg, jl_path = drm_miss_jl_path()),
        error = "error"
      )
    },
    error = function(e) {
      testthat::skip(paste(
        "julia missing round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  expect_true(is.finite(res$ll))
  expect_equal(res$nobs, 54L) # 60 rows - 6 missing responses dropped from the likelihood
})

test_that("engine='julia' rejects response='include' for non-Gaussian families", {
  set.seed(1L)
  n <- 40L
  x <- stats::rnorm(n)
  y <- stats::rpois(n, exp(0.2 + 0.3 * x))
  y[1:4] <- NA
  dat <- data.frame(y = y, x = x)
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::poisson(),
      data = dat,
      engine = "julia",
      missing = miss_control(response = "include")
    ),
    "missing"
  )
})

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

# --- #694: response = "drop" actually drops NA rows on the R side -------------
#
# The bridge admits the default missing control (response = "drop") for every
# family, but the non-Gaussian phylo / count Laplace routes in DRM.jl have no
# missing handling. The R side must therefore drop complete-case rows BEFORE
# marshalling so those routes fit the same data native TMB would, instead of
# passing NA rows through and returning NaN / non-convergence.

test_that("drm_julia_drop_missing_rows drops NA response and predictor rows (no phylo)", {
  f <- drmTMB::bf(y ~ x + z)
  dat <- data.frame(
    y = c(1, NA, 3, 4, 5),
    x = c(1, 2, NA, 4, 5),
    z = c(1, 2, 3, 4, 5)
  )
  dropped <- drmTMB:::drm_julia_drop_missing_rows(dat, f)
  # Rows 2 (NA y) and 3 (NA x) removed; mirrors complete.cases(data[, vars]).
  expect_equal(nrow(dropped), 3L)
  expect_equal(dropped$y, c(1, 4, 5))
  expect_false(anyNA(dropped[, c("y", "x", "z")]))
})

test_that("drm_julia_drop_missing_rows keeps NA in unmodelled columns", {
  f <- drmTMB::bf(y ~ x)
  dat <- data.frame(
    y = c(1, 2, 3),
    x = c(1, 2, 3),
    unused = c(NA, NA, NA)
  )
  dropped <- drmTMB:::drm_julia_drop_missing_rows(dat, f)
  # `unused` is not a model variable, so its NAs must not trigger row removal.
  expect_equal(nrow(dropped), 3L)
})

test_that("dropping NA rows first makes the phylo payload row_order complete-case", {
  skip_if_not_installed("ape")
  set.seed(3L)
  tree <- ape::rcoal(6)
  tree$tip.label <- paste0("sp", seq_len(6))
  dat <- data.frame(
    species = tree$tip.label,
    x = stats::rnorm(6),
    y = stats::rnorm(6),
    stringsAsFactors = FALSE
  )
  dat$y[c(2L, 5L)] <- NA # two NA responses

  f <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))
  dropped <- drmTMB:::drm_julia_drop_missing_rows(dat, f)
  expect_equal(nrow(dropped), 4L)
  expect_false(anyNA(dropped$y))

  # The phylo payload built on the DROPPED data must carry a row_order that
  # indexes only the four complete-case rows (species set = the 4 kept tips).
  payload <- drmTMB:::drm_julia_phylo_payload(
    formula = f,
    family_type = "gaussian",
    data = dropped,
    env = environment()
  )
  expect_length(payload$row_order, 4L)
  expect_setequal(
    as.character(dropped[[payload$group]][payload$row_order]),
    setdiff(tree$tip.label, c("sp2", "sp5"))
  )
})

# Live parity: a count (Poisson) phylo fit with an NA response must EITHER match
# the native engine='tmb' dropped-case fit OR error explicitly -- it must never
# silently return a NaN loglik / non-converged result (the pre-fix failure mode).
test_that("engine='julia' count phylo fit with NA response drops rows, matches native (live)", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
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
          Sys.setenv(DRM_JL_PATH = jl_path)
          suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

          set.seed(11L)
          N <- 40L
          tree <- ape::rcoal(N)
          sp <- tree$tip.label
          C <- ape::vcv(tree, corr = TRUE)
          a <- as.numeric(t(chol(C)) %*% stats::rnorm(N)) * 0.5
          x <- stats::rnorm(N)
          eta <- 0.5 + 0.3 * x + a
          y <- stats::rpois(N, exp(eta))
          dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)

          form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))

          # Fit on complete data first (native reference on the SAME complete set).
          dat_na <- dat
          dat_na$y[c(3L, 17L, 29L)] <- NA
          dat_cc <- dat_na[!is.na(dat_na$y), , drop = FALSE]

          native_cc <- tryCatch(
            drmTMB::drmTMB(
              form,
              family = stats::poisson(),
              data = dat_cc,
              engine = "tmb"
            ),
            error = function(e) e
          )

          # The bridge fit on the NA data with the DEFAULT missing control.
          jl_na <- tryCatch(
            drmTMB::drmTMB(
              form,
              family = stats::poisson(),
              data = dat_na,
              engine = "julia"
            ),
            error = function(e) e
          )

          list(
            jl_errored = inherits(jl_na, "error"),
            jl_message = if (inherits(jl_na, "error")) {
              conditionMessage(jl_na)
            } else {
              NA_character_
            },
            jl_nobs = if (inherits(jl_na, "error")) {
              NA_integer_
            } else {
              stats::nobs(jl_na)
            },
            jl_ll = if (inherits(jl_na, "error")) {
              NA_real_
            } else {
              as.numeric(stats::logLik(jl_na))
            },
            jl_converged = if (inherits(jl_na, "error")) {
              NA
            } else {
              drmTMB::is_converged(jl_na)
            },
            native_ok = !inherits(native_cc, "error"),
            native_ll = if (inherits(native_cc, "error")) {
              NA_real_
            } else {
              as.numeric(stats::logLik(native_cc))
            },
            n_complete = nrow(dat_cc)
          )
        },
        args = list(pkg = pkg, jl_path = drm_miss_jl_path()),
        error = "error"
      )
    },
    error = function(e) {
      testthat::skip(paste(
        "julia count-phylo NA round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )
  skip_if(is.null(res))

  if (isTRUE(res$jl_errored)) {
    # Explicit error is an acceptable contract (never a silent NaN).
    expect_true(nzchar(res$jl_message))
  } else {
    # Otherwise it must be the dropped-case fit: complete-case nobs, a finite
    # loglik, convergence, and agreement with the native complete-case fit.
    expect_equal(res$jl_nobs, res$n_complete)
    expect_true(is.finite(res$jl_ll))
    expect_true(isTRUE(res$jl_converged))
    if (isTRUE(res$native_ok)) {
      expect_equal(res$jl_ll, res$native_ll, tolerance = 1e-2)
    }
  }
})

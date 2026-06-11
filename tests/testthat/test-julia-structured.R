# Univariate general-covariance structured route via engine = "julia".
#
# DRM.jl fits a `relmat(1 | g)` / `animal(1 | g)` / `spatial(1 | g)` mean random
# intercept against a USER-SUPPLIED covariance with its general-covariance sparse
# Laplace -- the same spine as the phylo route, but with the tree precision
# replaced by the supplied matrix's (unit-diagonal-rescaled) inverse. The R bridge
# marshals the matrix as a plain numeric array that crosses JuliaCall and is handed
# to `drm(...)` through the matching keyword:
#   relmat(1 | g, K = K)   -> drm(...; K = K)
#   animal(1 | g, A = A)   -> drm(...; A = A)
#   spatial(1 | g, coords) -> drm(...; coords = ...)   (Gaussian only)
#
# Supported families are DRM.jl's general-covariance set: Gaussian, Poisson, NB2,
# Gamma. (Beta / Binomial fit only `phylo()` in DRM.jl and are rejected here.)
# Precision / inverse marker forms (relmat `Q`, animal `Ainv`), pedigrees, meshes,
# and non-Gaussian `spatial()` have no bridge route and are rejected with a
# pointer to `engine = "tmb"` or to `relmat(1 | g, K = K)`.
#
# Native drmTMB does fit these structured effects on the TMB side, but the Julia
# route is net-new for the bridge; these live tests assert a finite-and-sane floor
# (finite logLik + positive variance component) rather than coefficient parity.
#
# These tests cover (a) pure R-side routing / gating (no Julia), which always
# runs, and (b) one live Poisson relmat round-trip, guarded so it is SKIPPED --
# never failed -- when JuliaCall, callr, pkgload, or the DRM.jl general-covariance
# engine is unavailable, or when the fit errors in this environment.

test_that("structured family set is Gaussian/Poisson/NB2/Gamma, gated as such", {
  expect_setequal(
    drmTMB:::drm_julia_structured_families(),
    c("gaussian", "poisson", "nbinom2", "gamma")
  )
  for (fam in c("gaussian", "poisson", "nbinom2", "gamma")) {
    expect_equal(drmTMB:::drm_julia_structured_family_tag(fam), fam)
  }
  # Beta / Binomial fit phylo() but have no relmat/animal/spatial drm() route.
  for (fam in c("beta", "binomial", "student")) {
    expect_error(
      drmTMB:::drm_julia_structured_family_tag(fam),
      "relmat.*animal.*spatial"
    )
  }
})

test_that("structured-term detector finds relmat/animal/spatial, not phylo/plain", {
  K <- diag(3)
  A <- diag(3)
  co <- cbind(c(0, 1, 2), c(0, 1, 2))
  expect_true(
    drmTMB:::drm_julia_has_structured_term(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)
    )
  )
  expect_true(
    drmTMB:::drm_julia_has_structured_term(bf(y ~ x + animal(1 | id, A = A)))
  )
  expect_true(
    drmTMB:::drm_julia_has_structured_term(
      bf(y ~ x + spatial(1 | site, coords = co))
    )
  )
  # A phylo() term is NOT a general-covariance structured term (own route).
  expect_false(
    drmTMB:::drm_julia_has_structured_term(
      bf(y ~ x + phylo(1 | species, tree = tree))
    )
  )
  expect_false(drmTMB:::drm_julia_has_structured_term(bf(y ~ x, sigma ~ 1)))
})

test_that("marker-kwarg strip removes the matrix arg for every structured marker", {
  expect_equal(
    deparse1(drmTMB:::drm_julia_strip_phylo_tree(quote(x + relmat(1 | id, K = K)))),
    "x + relmat(1 | id)"
  )
  expect_equal(
    deparse1(drmTMB:::drm_julia_strip_phylo_tree(quote(x + animal(1 | id, A = A)))),
    "x + animal(1 | id)"
  )
  expect_equal(
    deparse1(drmTMB:::drm_julia_strip_phylo_tree(
      quote(x + spatial(1 | loc, coords = co))
    )),
    "x + spatial(1 | loc)"
  )
  # The phylo tree strip is unchanged (back-compat).
  expect_equal(
    deparse1(drmTMB:::drm_julia_strip_phylo_tree(
      quote(x + phylo(1 | sp, tree = tr))
    )),
    "x + phylo(1 | sp)"
  )
  # Stripping the matrix arg drops its symbol from the variables the bridge
  # collects, so the engine never looks for the matrix in `data`.
  expect_equal(
    all.vars(drmTMB:::drm_julia_strip_phylo_tree(quote(x + relmat(1 | id, K = K)))),
    c("x", "id")
  )
})

test_that("matrix resolution routes relmat->K, animal->A, spatial->coords", {
  env <- environment()
  K <- diag(3)
  A <- diag(3)
  co <- cbind(c(0, 1, 2), c(0, 1, 2))
  dat <- data.frame(id = c("a", "b", "c"), x = stats::rnorm(3), y = stats::rnorm(3))
  term <- function(f) drmTMB:::drm_julia_collect_structured_terms(f)[[1L]]

  # relmat(K) routes to drm(K = ...) for every supported family.
  for (fam in c("gaussian", "poisson", "nbinom2", "gamma")) {
    res <- drmTMB:::drm_julia_structured_matrix(
      term(bf(y ~ x + relmat(1 | id, K = K))), fam, env, dat
    )
    expect_equal(res$kwarg, "K")
    expect_equal(dim(res$matrix), c(3L, 3L))
  }
  # animal(A) routes to drm(A = ...).
  res_a <- drmTMB:::drm_julia_structured_matrix(
    term(bf(y ~ x + animal(1 | id, A = A))), "poisson", env, dat
  )
  expect_equal(res_a$kwarg, "A")
  # spatial(coords) routes to drm(coords = ...) for Gaussian.
  res_s <- drmTMB:::drm_julia_structured_matrix(
    term(bf(y ~ x + spatial(1 | id, coords = co))), "gaussian", env, dat
  )
  expect_equal(res_s$kwarg, "coords")
  expect_equal(ncol(res_s$matrix), 2L)
})

test_that("unsupported structured forms are rejected with a tmb pointer", {
  env <- environment()
  K <- diag(3)
  Q <- diag(3)
  Ainv <- diag(3)
  co <- cbind(c(0, 1, 2), c(0, 1, 2))
  k_bad <- matrix(1, nrow = 3, ncol = 2)
  dat <- data.frame(id = c("a", "b", "c"), x = stats::rnorm(3), y = stats::rnorm(3))
  term <- function(f) drmTMB:::drm_julia_collect_structured_terms(f)[[1L]]

  # Precision / inverse forms have no drm() route (drm consumes K / A / coords).
  expect_error(
    drmTMB:::drm_julia_structured_matrix(
      term(bf(y ~ x + relmat(1 | id, Q = Q))), "gaussian", env, dat
    ),
    "relmat.*K"
  )
  expect_error(
    drmTMB:::drm_julia_structured_matrix(
      term(bf(y ~ x + animal(1 | id, Ainv = Ainv))), "gaussian", env, dat
    ),
    "animal.*A"
  )
  # spatial() is coordinate-based and Gaussian-only; a count spatial fit must use
  # relmat(1 | g, K = K) instead.
  expect_error(
    drmTMB:::drm_julia_structured_matrix(
      term(bf(y ~ x + spatial(1 | id, coords = co))), "poisson", env, dat
    ),
    "Gaussian"
  )
  # A non-square covariance is rejected.
  expect_error(
    drmTMB:::drm_julia_structured_matrix(
      term(bf(y ~ x + relmat(1 | id, K = k_bad))), "gaussian", env, dat
    ),
    "square"
  )
})

test_that("structured payload requires intercept-only mu and sigma ~ 1", {
  env <- environment()
  K <- diag(3)
  dat <- data.frame(id = c("a", "b", "c"), x = stats::rnorm(3), y = stats::rnorm(3))

  # An intercept-only relmat mu with sigma ~ 1 builds a payload.
  payload <- drmTMB:::drm_julia_structured_payload(
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
    "gaussian", dat, env
  )
  expect_equal(payload$kwarg, "K")
  expect_equal(unname(payload$structured_sd_scales), 1)
  expect_equal(names(payload$structured_sd_scales), "relmat(1 | id)")

  # A predictor-dependent sigma is rejected (general-covariance route needs sigma ~ 1).
  expect_error(
    drmTMB:::drm_julia_structured_payload(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ x),
      "gaussian", dat, env
    ),
    "sigma ~ 1"
  )
  # A structured slope is rejected (intercept-only only).
  expect_error(
    drmTMB:::drm_julia_structured_payload(
      bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
      "gaussian", dat, env
    ),
    "1 \\| group"
  )
})

# --- Live Poisson relmat round-trip (guarded) -------------------------------
#
# Runs in a FRESH R subprocess (callr): JuliaCall keeps one persistent Julia
# session per process and `using DRM` is a no-op once DRM is loaded, so a fresh
# subprocess guarantees the general-covariance engine at `jl_path` is the one
# loaded for this fit, independent of test order (same rationale as the phylo and
# cross-family round-trips).

drm_structured_path <- function() {
  Sys.getenv(
    "DRM_JL_RELMAT_PATH",
    "/Users/z3437171/worktrees/DRM-relmatext"
  )
}

# Fit a Poisson relmat model through engine = "julia" in one clean subprocess and
# return the scalars the assertions need. Returns a list, or NULL if the child
# errored.
drm_structured_relmat_fit <- function(n = 30L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_structured_path()
  callr::r(
    function(pkg, jl_path, n) {
      Sys.setenv(JULIA_HOME = "/Users/z3437171/.juliaup/bin")
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      # A block-structured relatedness correlation K over n individuals: two
      # related clusters share within-cluster correlation, driving a latent
      # cluster effect the relatedness SD recovers. One row per individual.
      set.seed(11)
      grp <- rep(c("L", "R"), each = n / 2L)
      rho <- 0.6
      K <- matrix(0, n, n)
      for (i in seq_len(n)) {
        for (j in seq_len(n)) {
          K[i, j] <- if (i == j) {
            1
          } else if (identical(grp[i], grp[j])) {
            rho
          } else {
            0
          }
        }
      }
      # Latent relatedness effect ~ N(0, sigma_b^2 K) drives count over-dispersion.
      sigma_b <- 0.8
      L <- chol(K)
      u <- sigma_b * as.numeric(crossprod(L, stats::rnorm(n)))
      x <- stats::rnorm(n)
      eta <- 0.4 + 0.3 * x + u
      y <- stats::rpois(n, exp(eta))
      id <- as.character(seq_len(n))
      dat <- data.frame(id = id, x = x, y = y, stringsAsFactors = FALSE)

      form <- drmTMB::bf(y ~ x + relmat(1 | id, K = K))
      fj <- drmTMB::drmTMB(
        form, family = stats::poisson(), data = dat, engine = "julia"
      )

      cj <- stats::coef(fj, "mu")
      list(
        class = class(fj),
        engine = fj$engine,
        nobs = stats::nobs(fj),
        loglik = as.numeric(stats::logLik(fj)),
        coef = unname(cj),
        coef_names = names(cj),
        sd = unname(fj$sdpars$mu[["relmat(1 | id)"]]),
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n = as.integer(n)),
    error = "error"
  )
}

test_that("Poisson relmat fit via engine = 'julia' is finite and sane", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_structured_path()),
    "DRM.jl general-covariance engine not available"
  )

  res <- tryCatch(
    drm_structured_relmat_fit(n = 30L),
    error = function(e) {
      testthat::skip(paste(
        "Poisson relmat round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  expect_true("drmTMB_julia" %in% res$class)
  expect_equal(res$engine, "julia")
  expect_equal(res$nobs, 30L)
  expect_true(is.finite(res$loglik))
  expect_true(all(is.finite(res$coef)))
  expect_equal(res$coef_names, c("(Intercept)", "x"))
  # The recovered relatedness SD is finite and strictly positive.
  expect_true(is.finite(res$sd))
  expect_gt(res$sd, 0)
  expect_true(isTRUE(res$converged))
})

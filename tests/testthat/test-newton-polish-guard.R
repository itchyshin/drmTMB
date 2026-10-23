# #1441: `drm_newton_polish()` (R/drmTMB.R) ran an UNGUARDED full Newton step
# -- `par - solve(he, grad)` -- with no trust region, line search, or step
# bound, then decided whether to accept it by calling `obj$fn()`/`obj$gr()`
# at the new point. On the Tweedie y = 0.01 fixture below (the same fixture
# as test-numeric-kernel-oracle.R:552), that step moved beta_sigma from
# -6.35 to -23.6 and beta_nu from 2.44 to -24.4 (about 27x the trust radius
# below). At that point TMB's dtweedie bound-search loops for ~1e9
# iterations, so fn()/gr() never return and the whole fit process hangs.
# This is a hazard for every family, not only Tweedie: any ill-conditioned
# Hessian at the nlminb optimum can produce an oversized step.
#
# The fix caps the step (trust region) and backtracks (halves, up to a few
# times) before falling back to the unpolished optimum -- see
# drm_newton_polish() in R/drmTMB.R. These tests check:
#   1. the previously-hanging Tweedie fixture now returns within 30s with a
#      finite logLik under the package default (`newton_polish = TRUE`);
#   2. on ordinary, well-conditioned fixtures (gaussian, poisson, and a
#      location-scale model), the new safeguarded polish reproduces the old
#      unguarded polish to 1e-8 -- i.e. the guard changes nothing when it is
#      not needed.
#
# Every call below that could in principle hang runs in a `callr::r()`
# subprocess with a hard `timeout`, so a regression here fails the test
# instead of hanging the test run.

drm_pkg_path <- normalizePath(test_path("..", ".."), mustWork = TRUE)

# Runs `expr_fn(pkg)` in a fresh subprocess that loads this package from
# source (via `pkgload::load_all()`, not the installed copy), under a hard
# kill at `timeout` seconds. Returns `expr_fn`'s value, or throws (which
# testthat reports as a test failure) if the subprocess times out or errors.
drm_run_guarded <- function(expr_fn, timeout = 30) {
  callr::r(
    expr_fn,
    args = list(pkg = drm_pkg_path),
    timeout = timeout
  )
}

test_that("tweedie y = 0.01 fixture with default newton_polish returns within 30s (#1441)", {
  skip_on_cran()
  testthat::skip_if_not_installed("callr")

  elapsed <- system.time({
    res <- tryCatch(
      drm_run_guarded(
        function(pkg) {
          suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
          dat <- data.frame(y = 0.01)
          fit <- suppressWarnings(drmTMB::drmTMB(
            drmTMB::bf(y ~ 1, sigma ~ 1, nu ~ 1),
            data = dat,
            family = drmTMB::tweedie(),
            control = drmTMB::drm_control(se = FALSE, logsigma_clamp = NULL)
          ))
          as.numeric(stats::logLik(fit))
        },
        timeout = 30
      ),
      error = function(e) {
        fail(paste("subprocess timed out or errored:", conditionMessage(e)))
        NA_real_
      }
    )
  })

  expect_lt(elapsed[["elapsed"]], 30)
  expect_true(is.finite(res))
})

# Frozen copy of `drm_newton_polish()` exactly as it existed before the
# #1441 trust-region / backtracking fix (an unguarded full Newton step,
# accepted only if `fn` was finite and non-increasing). Kept here ONLY as a
# regression reference -- not maintained in sync with R/drmTMB.R -- to check
# that the safeguarded version below reproduces it on well-conditioned
# fixtures where the cap and backtracking never bind.
old_newton_polish_reference <- function(opt, fn, gr, grad_tol = 1e-8, max_iter = 3L) {
  par <- opt$par
  grad <- tryCatch(as.numeric(gr(par)), error = function(e) NULL)
  if (is.null(grad) || !all(is.finite(grad))) {
    return(opt)
  }
  if (max(abs(grad)) <= grad_tol) {
    return(opt)
  }
  objective <- as.numeric(opt$objective)
  polished <- FALSE
  for (i in seq_len(max_iter)) {
    he <- tryCatch(stats::optimHess(par, fn, gr), error = function(e) NULL)
    if (is.null(he) || !all(is.finite(he))) {
      break
    }
    step <- tryCatch(solve(he, grad), error = function(e) NULL)
    if (is.null(step) || !all(is.finite(step))) {
      break
    }
    par_new <- par - step
    grad_new <- tryCatch(as.numeric(gr(par_new)), error = function(e) NULL)
    objective_new <- tryCatch(as.numeric(fn(par_new)), error = function(e) NA_real_)
    if (
      is.null(grad_new) ||
        !all(is.finite(grad_new)) ||
        !is.finite(objective_new) ||
        objective_new > objective + 1e-8
    ) {
      break
    }
    par <- par_new
    grad <- grad_new
    objective <- objective_new
    polished <- TRUE
    if (max(abs(grad)) <= grad_tol) {
      break
    }
  }
  if (!polished) {
    return(opt)
  }
  opt$par <- stats::setNames(par, names(opt$par))
  opt$objective <- objective
  opt
}

# Fits `formula`/`family` on `dat` with `newton_polish = FALSE` (the raw
# nlminb optimum), then checks that applying the new safeguarded polish and
# the frozen old unguarded polish to that same optimum agree to 1e-8 in both
# parameters and objective.
expect_polish_unchanged <- function(formula, dat, family = gaussian()) {
  fit <- suppressWarnings(drmTMB(
    formula,
    data = dat,
    family = family,
    control = drm_control(newton_polish = FALSE, se = FALSE)
  ))
  grad0 <- fit$obj$gr(fit$opt$par)
  # Sanity check that the fixture actually exercises the polish loop (a
  # gradient already at grad_tol would make old-vs-new agreement trivial).
  expect_gt(max(abs(grad0)), 1e-8)

  new <- drmTMB:::drm_newton_polish(fit$opt, fit$obj$fn, fit$obj$gr)
  old <- old_newton_polish_reference(fit$opt, fit$obj$fn, fit$obj$gr)

  expect_lt(max(abs(new$par - old$par)), 1e-8)
  expect_lt(abs(new$objective - old$objective), 1e-8)
}

test_that("newton_polish guard is unchanged on an ordinary gaussian fixture (#1441)", {
  set.seed(20260927L)
  n <- 60
  x <- runif(n, -1, 1)
  y <- 0.5 + 1.2 * x + rnorm(n, sd = 0.4)
  dat <- data.frame(y = y, x = x)
  expect_polish_unchanged(bf(y ~ x), dat, family = gaussian())
})

test_that("newton_polish guard is unchanged on an ordinary poisson fixture (#1441)", {
  set.seed(20260927L)
  n <- 60
  x <- runif(n, -1, 1)
  y <- rpois(n, exp(0.3 + 0.5 * x))
  dat <- data.frame(y = y, x = x)
  expect_polish_unchanged(bf(y ~ x), dat, family = poisson())
})

test_that("newton_polish guard is unchanged on a location-scale fixture (#1441)", {
  set.seed(20260927L)
  n <- 80
  x <- runif(n, -1, 1)
  y <- 0.2 + 0.8 * x + rnorm(n, sd = exp(-0.3 + 0.4 * x))
  dat <- data.frame(y = y, x = x)
  expect_polish_unchanged(bf(y ~ x, sigma ~ x), dat, family = gaussian())
})

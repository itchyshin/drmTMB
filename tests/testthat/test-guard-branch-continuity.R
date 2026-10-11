# Arc B slice S3: CondExp branch-continuity and AD-safety audit.
#
# Scope: every `CppAD::CondExp*` site in src/drmTMB.cpp and the drm_*.h
# headers. Each site is declared a smoothness class BEFORE testing (see the
# per-`test_that` header comments), because a blanket "value and derivative
# must both be continuous" is false by design for the guard/floor sites: a
# floor that clamps a shape parameter or a normalizing constant is meant to
# have a derivative that jumps to zero once the floor engages. Asserting C1
# there would red-flag a deliberate, correct guard. Only the series/direct
# approximation switches (drm_log1mexp, the NB2 series, drm_log1p_nonnegative)
# and the identity-preserving softclamp are expected to be C1.
#
# Pre-registered tolerances (fixed before any result was inspected):
#   VALUE_TOL <- 1e-9   (relative, value continuity, every site)
#   DERIV_TOL <- 1e-6   (relative, first-derivative continuity, C1 sites only)
# A finite-difference cross-check at two step sizes is also run for the three
# series/direct sites; it is corroborating evidence (its own, looser,
# truncation-scaled tolerance), never the primary gate -- the primary gate is
# always the analytic derivative of each closed-form branch, which avoids the
# catastrophic-cancellation noise that a too-small finite-difference step
# would inject right at these thresholds (that noise is exactly why the
# series branches exist).
#
# No skip_*() anywhere in this file.

VALUE_TOL <- 1e-9
DERIV_TOL <- 1e-6

rel_diff <- function(a, b) abs(a - b) / abs(b)

# The C++ sources sit at different relative locations depending on how this
# suite is invoked. Under `test_check()` (R CMD check), `testthat::test_path()`
# returns paths relative to getwd(), and getwd() is `<pkg>.Rcheck/tests/` — not
# `tests/testthat/`. The historical `../../00_pkg_src/...` candidate therefore
# overshoots the Rcheck tree (it looks beside Rcheck, not inside it). Local
# macOS checks still "passed" only when the Rcheck lived inside a source
# checkout, so `../../src` accidentally hit that checkout's `src/`; win-builder
# has no such sibling and both candidates missed.
#
# Layouts we must hit:
#   - source checkout, cwd = pkg/tests/testthat  -> ../../src
#   - Unix/macOS R CMD check, cwd = *.Rcheck/tests -> ../00_pkg_src/drmTMB/src
#   - win-builder, cwd = *.Rcheck/tests, often no usable 00_pkg_src under the
#     relative path the old helper tried -> ../../drmTMB/src (unpacked tarball
#     sibling of *.Rcheck)
#
# Deliberately no skip_*() when the file is absent: if no candidate resolves,
# fail loudly. A drift guard that quietly opts out when it cannot find its
# subject is worse than no guard at all.
drm_src_candidates <- function(rel, start_dir = getwd()) {
  rel <- as.character(rel)[[1L]]
  start_dir <- normalizePath(start_dir, winslash = "/", mustWork = FALSE)

  out <- c(
    # Relative to tests/testthat (devtools::test / test_dir).
    file.path(start_dir, "..", "..", "src", rel),
    file.path(start_dir, "..", "..", "00_pkg_src", "drmTMB", "src", rel),
    # Relative to *.Rcheck/tests (test_check / R CMD check).
    file.path(start_dir, "..", "src", rel),
    file.path(start_dir, "..", "00_pkg_src", "drmTMB", "src", rel),
    # win-builder / CRAN Windows: unpacked source sits beside *.Rcheck.
    file.path(start_dir, "..", "..", "drmTMB", "src", rel),
    file.path(start_dir, "..", "..", "..", "drmTMB", "src", rel)
  )

  # Walk upward: prefer dir/src/<rel>, then 00_pkg_src, then a non-Rcheck
  # sibling named drmTMB* (the unpacked tarball next to *.Rcheck).
  dir <- start_dir
  for (i in seq_len(6L)) {
    out <- c(
      out,
      file.path(dir, "src", rel),
      file.path(dir, "00_pkg_src", "drmTMB", "src", rel)
    )
    parent <- dirname(dir)
    if (!identical(parent, dir) && dir.exists(parent)) {
      sibs <- list.files(parent, full.names = TRUE)
      sibs <- sibs[basename(sibs) == "drmTMB" | startsWith(basename(sibs), "drmTMB_")]
      sibs <- sibs[!grepl("\\.Rcheck$", sibs)]
      out <- c(out, file.path(sibs, "src", rel))
    }
    if (identical(parent, dir)) {
      break
    }
    dir <- parent
  }

  # Keep raw relatives from test_path for the error message / older callers.
  out <- c(
    out,
    testthat::test_path("..", "..", "src", rel),
    testthat::test_path("..", "..", "00_pkg_src", "drmTMB", "src", rel),
    testthat::test_path("..", "00_pkg_src", "drmTMB", "src", rel),
    testthat::test_path("..", "..", "drmTMB", "src", rel)
  )

  unique(out)
}

drm_src_path <- function(rel, start_dir = getwd()) {
  candidates <- drm_src_candidates(rel, start_dir = start_dir)
  exists <- file.exists(candidates)
  hit <- candidates[exists]
  if (length(hit) == 0L) {
    stop(
      "Cannot locate C++ source '", rel, "'. Tried:\n  ",
      paste(candidates, collapse = "\n  "),
      call. = FALSE
    )
  }
  normalizePath(hit[[1L]], winslash = "/", mustWork = TRUE)
}

read_src <- function(rel) {
  readLines(drm_src_path(rel), warn = FALSE)
}

test_that("drm_src_path resolves checkout, Rcheck 00_pkg_src, and win-builder sibling layouts", {
  tmp <- tempfile("drm-src-layouts-")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  write_cpp <- function(path) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    writeLines("// layout probe", path)
    normalizePath(path, winslash = "/", mustWork = TRUE)
  }

  # A: source checkout; cwd = pkg/tests/testthat
  pkg_a <- file.path(tmp, "checkout", "drmTMB")
  src_a <- write_cpp(file.path(pkg_a, "src", "drmTMB.cpp"))
  dir.create(file.path(pkg_a, "tests", "testthat"), recursive = TRUE)
  expect_equal(
    drm_src_path("drmTMB.cpp", start_dir = file.path(pkg_a, "tests", "testthat")),
    src_a
  )

  # B: Unix/macOS R CMD check; cwd = *.Rcheck/tests; sources in 00_pkg_src
  rcheck_b <- file.path(tmp, "unix", "drmTMB.Rcheck")
  src_b <- write_cpp(file.path(rcheck_b, "00_pkg_src", "drmTMB", "src", "drmTMB.cpp"))
  dir.create(file.path(rcheck_b, "tests", "testthat"), recursive = TRUE)
  expect_equal(
    drm_src_path("drmTMB.cpp", start_dir = file.path(rcheck_b, "tests")),
    src_b
  )

  # C: win-builder; cwd = *.Rcheck/tests; no 00_pkg_src; sibling unpacked src
  root_c <- file.path(tmp, "winbuilder")
  src_c <- write_cpp(file.path(root_c, "drmTMB", "src", "drmTMB.cpp"))
  rcheck_c <- file.path(root_c, "drmTMB.Rcheck")
  dir.create(file.path(rcheck_c, "tests", "testthat"), recursive = TRUE)
  expect_equal(
    drm_src_path("drmTMB.cpp", start_dir = file.path(rcheck_c, "tests")),
    src_c
  )
})

test_that("drm_pkg_path resolves checkout, Rcheck 00_pkg_src, and win-builder sibling layouts", {
  tmp <- tempfile("drm-pkg-layouts-")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  write_pkg_file <- function(path) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    writeLines("# layout probe", path)
    normalizePath(path, winslash = "/", mustWork = TRUE)
  }

  rel <- "R/drmTMB.R"

  pkg_a <- file.path(tmp, "checkout", "drmTMB")
  r_a <- write_pkg_file(file.path(pkg_a, rel))
  dir.create(file.path(pkg_a, "tests", "testthat"), recursive = TRUE)
  expect_equal(
    drm_pkg_path(rel, start_dir = file.path(pkg_a, "tests", "testthat")),
    r_a
  )

  rcheck_b <- file.path(tmp, "unix", "drmTMB.Rcheck")
  r_b <- write_pkg_file(file.path(rcheck_b, "00_pkg_src", "drmTMB", rel))
  dir.create(file.path(rcheck_b, "tests", "testthat"), recursive = TRUE)
  expect_equal(
    drm_pkg_path(rel, start_dir = file.path(rcheck_b, "tests")),
    r_b
  )

  root_c <- file.path(tmp, "winbuilder")
  r_c <- write_pkg_file(file.path(root_c, "drmTMB", rel))
  rcheck_c <- file.path(root_c, "drmTMB.Rcheck")
  dir.create(file.path(rcheck_c, "tests", "testthat"), recursive = TRUE)
  expect_equal(
    drm_pkg_path(rel, start_dir = file.path(rcheck_c, "tests")),
    r_c
  )
})

# ---------------------------------------------------------------------------
# Part A anchor: the enumeration this suite is built against. If a future
# edit adds/removes a CondExp site, this count changes and flags that the
# enumeration (and this suite) needs revisiting -- it is not a correctness
# check on its own, just a drift guard.
# ---------------------------------------------------------------------------
test_that("the CondExp enumeration this suite audits has not silently drifted", {
  n_cpp <- sum(grepl("CppAD::CondExp", read_src("drmTMB.cpp")))
  n_numeric <- sum(grepl("CppAD::CondExp", read_src("drm_numeric.h")))
  n_count <- sum(grepl("CppAD::CondExp", read_src("drm_count_kernels.h")))
  n_response <- sum(grepl("CppAD::CondExp", read_src("drm_response_kernels.h")))
  n_mi_quad <- sum(grepl("CppAD::CondExp", read_src("drm_mi_quadrature.h")))

  # Arc D Design 1 adds three overflow-only direct-SD guards: two CondExpGt
  # calls in the shared helper and one CondExpGt fail-closed objective gate.
  # They are intentionally C0/C1-unclassified here because their separate
  # overflow and AD behavior is exercised in test-arc-d-sd-overflow-guard.R.
  # Experimental MSPL adds four audited source sites to drmTMB.cpp: stable
  # abs(log-sech), negative-Huber abs and knot selection, and log-weight max
  # scaling. Their numerical contracts are exercised in test-mspl-kernels.R
  # and test-mspl-estimator.R. A3 beta-binomial finite-shape handling adds two
  # beta_shape_floor guards to drmTMB.cpp, so n_cpp = 30L. The binomial link
  # generalisation below did not add any drmTMB.cpp sites.
  #
  # The binomial link generalisation (probit/cloglog) separately adds THREE
  # CondExp sites to drm_numeric.h, all inside drm_log_pnorm() -- the
  # tail-safe log-Phi the probit link needs. They are the branch-selects
  # between the direct log(pnorm(x)) form and the Mills-ratio asymptotic
  # expansion below x = -20. This anchor is bumped 2L -> 5L DELIBERATELY,
  # together with the paired continuity test for that switch point below.
  # Bumping the anchor WITHOUT the paired test would be precisely the silent
  # normalisation this guard exists to prevent.
  #
  # A3 response-kernel parity brings drm_response_kernels.h to four
  # shape-floor guards: two for beta and two for beta-binomial. These mirror
  # the already-audited beta_shape_floor C0 contract below.
  #
  # #1472 adds two argument clamps inside drm_log1mexp() and two inside
  # drm_log1p_nonnegative(), so each unselected branch stays finite. The
  # selected value is unchanged; continuity at the existing switch points
  # is still the paired check below, and the Hessian at the cloglog and
  # truncated-NB edge is test-log1mexp-ad.R. n_numeric is therefore 9L.
  # #1462 adds four clamps in drm_student_log_density() (the lgamma branch,
  # the Stirling branch, the switch, and the kernel cap). Value continuity
  # across nu = 1e4 is test-student-large-nu.R. n_response is therefore 8L.
  # The mi() prior quadrature rewrite (#1476, #1477) removed the three
  # prior_norm floors of the Beta, zero-one-Beta and Gamma branches from
  # drmTMB.cpp (both-missing rows now use the exact prior mean; the paired
  # test is "Beta mi() both-missing rows report the exact prior mean ..."
  # below), so n_cpp = 27L. It adds five sites in drm_mi_quadrature.h: two
  # bisection selects for the Beta posterior mode (the bracket only places
  # the nodes; two Newton steps after it carry the derivative), one curvature
  # floor at 1e-300 (active only at a degenerate posterior), and two selects
  # for the cancellation-free Gamma mode root, whose branches are the same
  # root written two ways (paired test: "Gamma mi() closed-form mode is
  # smooth across the B = 0 branch switch" below).
  # The nbinom2 x Gaussian mi() case-weight correction (#1459) adds two
  # step caps (CondExpGt/CondExpLt) to its fixed-parameter Newton iteration;
  # they only bound the step, leave the selected value unchanged inside the
  # cap, and the fixed point is the analytic mode, so n_cpp = 29L.
  expect_equal(n_cpp, 29L)
  expect_equal(n_numeric, 9L)
  expect_equal(n_count, 1L)
  expect_equal(n_response, 8L)
  expect_equal(n_mi_quad, 5L)
})

# ---------------------------------------------------------------------------
# Site: Gamma mi() posterior-mode root (src/drm_mi_quadrature.h,
# drm_mi_gamma_marginal). The mode x_hat is the positive root of
# A x^2 + B x - k; it is written 2k / (B + D) for B >= 0 and
# (D - B) / (2A) for B < 0, the same number in exact arithmetic. Class:
# C-infinity by algebraic identity. Tested through the fitted TMB objective:
# move the mi() slope beta_mu[x] across the value where B = 0 for one
# missing-x row and require the objective and its gradient to be continuous.
# ---------------------------------------------------------------------------
test_that("Gamma mi() closed-form mode is smooth across the B = 0 branch switch", {
  n <- 60
  z <- seq(-1.5, 1.5, length.out = n)
  mean_x <- exp(0.4 + 0.3 * z)
  x <- mean_x * (1 + 0.2 * sin(seq_len(n)))
  y <- 0.5 + 0.8 * x + 0.1 * cos(seq_len(n) / 3)
  dat <- data.frame(y = y, z = z, x = x)
  dat$x[c(7, 22, 41)] <- NA_real_
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ mi(x), sigma ~ 1),
    data = dat,
    impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  ))
  par0 <- fit$obj$env$last.par.best
  model <- fit$model$missing_predictor
  row <- 7L
  mu_idx <- which(names(par0) == "beta_mu")
  slope_idx <- mu_idx[[model$mu_col]]
  par_list <- fit$obj$env$parList(par0)
  k <- exp(-2 * par_list$log_sigma_mi[[1L]])
  theta <- exp(sum(model$X[row, ] * par_list$beta_mi)) / k
  sd_y <- exp(par_list$beta_sigma[[1L]])
  intercept <- par_list$beta_mu[[1L]]
  # With mu = b0 + b1 * x and x0 the placeholder, r0 = y - b0, so
  # B(b1) = 1/theta - b1 * (y - b0) / sd_y^2 crosses zero at b1 = sd_y^2 / (theta * (y - b0)).
  b_cross <- sd_y^2 / (theta * (dat$y[[row]] - intercept))
  expect_true(is.finite(b_cross))
  at <- function(b1) {
    par <- par0
    par[slope_idx] <- b1
    list(f = fit$obj$fn(par), g = as.numeric(fit$obj$gr(par)))
  }
  for (h in c(1e-4, 1e-6)) {
    # A jump at the switch would make the step ACROSS b_cross much larger
    # than an equal step on one side of it; for a smooth objective the two
    # are about the same size.
    p_m <- at(b_cross - h)
    p_p <- at(b_cross + h)
    p_pp <- at(b_cross + 3 * h)
    expect_true(all(is.finite(c(p_m$f, p_p$f, p_pp$f, p_m$g, p_p$g, p_pp$g))))
    expect_lt(abs(p_p$f - p_m$f), 2 * abs(p_pp$f - p_p$f) + 1e-9)
    expect_lt(max(abs(p_p$g - p_m$g)), 2 * max(abs(p_pp$g - p_p$g)) + 1e-7)
  }
})

# ---------------------------------------------------------------------------
# Site: drm_log_pnorm (src/drm_numeric.h), threshold x = -20.
# Class: C1 expected. Below the threshold the direct form log(pnorm(x))
# underflows -- pnorm(-100) is zero in double precision -- so a Mills-ratio
# asymptotic expansion takes over. This test confirms the branches still agree
# in value AND derivative at the switch point, which is what makes the branch
# safe to differentiate through under AD.
# ---------------------------------------------------------------------------
test_that("drm_log_pnorm: direct and Mills-ratio branches agree at x = -20", {
  x0 <- -20

  mills <- function(x) {
    -x^2 / 2 - log(-x) - log(sqrt(2 * pi)) +
      log(1 - 1 / x^2 + 3 / x^4 - 15 / x^6 + 105 / x^8)
  }
  direct <- function(x) log(stats::pnorm(x))

  expect_lt(rel_diff(mills(x0), direct(x0)), VALUE_TOL)

  # Derivative agreement. d/dx log(pnorm(x)) is the inverse Mills ratio
  # dnorm(x)/pnorm(x); compare against a central difference of the asymptotic
  # branch at two step sizes, matching the drm_log1mexp pattern above.
  direct_der <- stats::dnorm(x0) / stats::pnorm(x0)
  for (h in c(1e-4, 1e-5)) {
    mills_der <- (mills(x0 + h) - mills(x0 - h)) / (2 * h)
    expect_lt(rel_diff(mills_der, direct_der), DERIV_TOL)
  }

  # Why the branch exists at all: the direct form dies further out, while the
  # asymptotic branch stays finite and accurate.
  expect_true(is.finite(mills(-100)))
  expect_false(is.finite(direct(-100)))
})

# ---------------------------------------------------------------------------
# Site: drm_log1mexp (src/drm_numeric.h:28-35), threshold u = 1e-6.
# Class: C1 expected. Per the recon pass this threshold is already measured
# and defensible (naive vs exact log(1-exp(-u)) over u in [1e-7,1e-1]: max
# rel error 3.0e-11); this test only confirms the two branches are still
# consistent at the switch point (a regression guard), it does not
# re-investigate the threshold choice.
# ---------------------------------------------------------------------------
test_that("drm_log1mexp: series and direct branches agree at u = 1e-6 (confirm and close)", {
  u0 <- 1e-6
  series_val <- log(u0 - u0^2 / 2 + u0^3 / 6)
  direct_val <- log(1 - exp(-u0))
  series_der <- (1 - u0 + u0^2 / 2) / (u0 - u0^2 / 2 + u0^3 / 6)
  direct_der <- exp(-u0) / (1 - exp(-u0))

  expect_lt(rel_diff(series_val, direct_val), VALUE_TOL)
  expect_lt(rel_diff(series_der, direct_der), DERIV_TOL)

  # Corroborating finite-difference cross-check at two step sizes (moderate,
  # away from the cancellation regime the series branch exists to avoid).
  f_series <- function(u) log(u - u^2 / 2 + u^3 / 6)
  f_direct <- function(u) log(1 - exp(-u))
  for (h in c(1e-2 * u0, 1e-3 * u0)) {
    fd_s <- (f_series(u0 + h) - f_series(u0 - h)) / (2 * h)
    fd_d <- (f_direct(u0 + h) - f_direct(u0 - h)) / (2 * h)
    expect_lt(rel_diff(fd_s, fd_d), 1e-4)
  }
})

# ---------------------------------------------------------------------------
# Site: drm_log1p_nonnegative (src/drm_numeric.h:19-25), threshold x = 1e-5.
# Class: C1 expected.
# ---------------------------------------------------------------------------
test_that("drm_log1p_nonnegative: series and direct branches are C1 at x = 1e-5", {
  x0 <- 1e-5
  series_val <- x0 - x0^2 / 2 + x0^3 / 3
  direct_val <- log(1 + x0)
  series_der <- 1 - x0 + x0^2
  direct_der <- 1 / (1 + x0)

  expect_lt(rel_diff(series_val, direct_val), VALUE_TOL)
  expect_lt(rel_diff(series_der, direct_der), DERIV_TOL)

  f_series <- function(x) x - x^2 / 2 + x^3 / 3
  f_direct <- function(x) log(1 + x)
  for (h in c(1e-2 * x0, 1e-3 * x0)) {
    fd_s <- (f_series(x0 + h) - f_series(x0 - h)) / (2 * h)
    fd_d <- (f_direct(x0 + h) - f_direct(x0 - h)) / (2 * h)
    expect_lt(rel_diff(fd_s, fd_d), 1e-4)
  }
})

# ---------------------------------------------------------------------------
# Site: NB2 count-normalizer series (src/drm_count_kernels.h:6-27), threshold
# alpha * y = 1e-2. Class: C1 expected. This is also the switch implicated in
# Part D below.
# ---------------------------------------------------------------------------
nb2_series <- function(alpha, y) {
  y1 <- y - 1
  sj <- y * y1 / 2
  sj2 <- y * y1 * (2 * y - 1) / 6
  sj3 <- sj^2
  sj4 <- y * y1 * (2 * y - 1) * (3 * y^2 - 3 * y - 1) / 30
  sj5 <- y^2 * y1^2 * (2 * y^2 - 2 * y - 1) / 12
  a2 <- alpha^2
  alpha * sj - a2 * sj2 / 2 + a2 * alpha * sj3 / 3 -
    a2 * a2 * sj4 / 4 + a2 * a2 * alpha * sj5 / 5
}
nb2_lgamma_ratio <- function(alpha, y) {
  inv_a <- 1 / alpha
  lgamma(y + inv_a) - lgamma(inv_a) + y * log(alpha)
}

test_that("NB2 series and lgamma-ratio branches are C1 at alpha * y = 1e-2", {
  y0 <- 5
  alpha0 <- 1e-2 / y0
  series_val <- nb2_series(alpha0, y0)
  lr_val <- nb2_lgamma_ratio(alpha0, y0)
  y1 <- y0 - 1
  sj <- y0 * y1 / 2
  sj2 <- y0 * y1 * (2 * y0 - 1) / 6
  sj3 <- sj^2
  sj4 <- y0 * y1 * (2 * y0 - 1) * (3 * y0^2 - 3 * y0 - 1) / 30
  sj5 <- y0^2 * y1^2 * (2 * y0^2 - 2 * y0 - 1) / 12
  series_der <- sj - alpha0 * sj2 + alpha0^2 * sj3 - alpha0^3 * sj4 + alpha0^4 * sj5
  inv_a <- 1 / alpha0
  lr_der <- (-1 / alpha0^2) * (digamma(y0 + inv_a) - digamma(inv_a)) + y0 / alpha0

  expect_lt(rel_diff(series_val, lr_val), VALUE_TOL)
  expect_lt(rel_diff(series_der, lr_der), DERIV_TOL)

  for (h in c(1e-2 * alpha0, 1e-3 * alpha0)) {
    fd_s <- (nb2_series(alpha0 + h, y0) - nb2_series(alpha0 - h, y0)) / (2 * h)
    fd_d <- (nb2_lgamma_ratio(alpha0 + h, y0) - nb2_lgamma_ratio(alpha0 - h, y0)) / (2 * h)
    expect_lt(rel_diff(fd_s, fd_d), 1e-4)
  }
})

# ---------------------------------------------------------------------------
# Site: drm_softclamp_log_sigma (src/drmTMB.cpp:26-36). Class: C1 by
# construction (hi + margin*tanh((x-hi)/margin) equals hi with derivative 1
# at x = hi, algebraically). Expected to pass; confirmed both analytically
# and through the compiled model's own REPORT(log_sigma).
# ---------------------------------------------------------------------------
test_that("drm_softclamp_log_sigma is C1 by construction at the hi/lo boundary", {
  softclamp_above <- function(x, hi, margin) hi + margin * tanh((x - hi) / margin)
  hi <- 12
  margin <- 3
  expect_equal(softclamp_above(hi, hi, margin), hi, tolerance = 1e-15)
  h <- 1e-6
  der_below <- 1 # identity branch, exact
  der_above <- (softclamp_above(hi + h, hi, margin) - softclamp_above(hi - h, hi, margin)) / (2 * h)
  expect_lt(abs(der_above - der_below), 1e-9)
})

test_that("drm_softclamp_log_sigma keeps REPORT(log_sigma) within the clamped band from the public API", {
  set.seed(1)
  n <- 20
  dat <- data.frame(y = stats::rpois(n, 3))
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  par0 <- fit$obj$par
  sig_idx <- which(names(par0) == "beta_sigma")

  # Sweep the raw (unconstrained) intercept dense across the upper boundary
  # hi = 12 (margin 3, saturating band (-15, 15)) and confirm the reported,
  # post-clamp log_sigma is continuous.
  grid <- seq(12 - 1.2, 12 + 1.2, length.out = 41)
  reported <- vapply(grid, function(v) {
    par <- par0
    par[sig_idx] <- v
    fit$obj$report(par)$log_sigma[[1]]
  }, numeric(1))
  step <- diff(grid)[[1]]
  jumps <- abs(diff(reported))
  expect_true(all(jumps < 5 * step)) # no discontinuity: consecutive steps stay O(step)
  expect_true(all(reported <= 15 + 1e-8))
})

# ---------------------------------------------------------------------------
# Site: beta_shape_floor (src/drmTMB.cpp:2901-2910, byte-identical at
# 2984-2993, 1363-1374, 1479-1490, 1618-1629, and
# src/drm_response_kernels.h:64-67 -- verified identical via the shared
# `shape_floor`/`beta_shape_floor` constant and CondExpLt form). Class: C0
# only. Both CondExp branches equal the floor constant exactly at the switch
# point (`alpha_raw == shape_floor`), so value continuity holds by
# construction; a derivative jump from 1 (identity branch) to 0 (floor
# branch) is expected and is NOT asserted.
# ---------------------------------------------------------------------------
test_that("beta_shape_floor: REPORT(alpha) is continuous at alpha_raw = 1e-8 from the public API", {
  set.seed(1)
  n <- 20
  dat <- data.frame(y = stats::rbeta(n, 5, 5))
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = beta_family(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  par0 <- fit$obj$par
  par0[names(par0) == "beta_mu"] <- 0 # eta_mu = 0 -> mu = 0.5 exactly
  sig_idx <- which(names(par0) == "beta_sigma")

  # alpha_raw = mu * phi = 0.5 * exp(-2*log_sigma) crosses 1e-8 at:
  target <- -0.5 * log(1e-8 / 0.5)

  for (h in c(1e-2, 1e-5)) {
    par_below <- par0
    par_below[sig_idx] <- target - h
    par_above <- par0
    par_above[sig_idx] <- target + h
    a_below <- fit$obj$report(par_below)$alpha[[1]]
    a_above <- fit$obj$report(par_above)$alpha[[1]]
    # Both sides sit at (or a hair below/above) the floor: value gap must
    # shrink with h, not sit at a fixed offset.
    expect_lt(abs(a_below - a_above), 5 * h * 1e-8)
  }
  # At the floor itself, alpha_raw and shape_floor are numerically identical.
  par_at <- par0
  par_at[sig_idx] <- target
  expect_equal(fit$obj$report(par_at)$alpha[[1]], 1e-8, tolerance = VALUE_TOL)
})

# ---------------------------------------------------------------------------
# Site: both-missing rows of the Beta mi() branch. This used to be the
# prior_norm floor (`CondExpGt(prior_norm, 1e-300, prior_norm, 1e-300)`): the
# plug-in was a 15-node quadrature mean that underflowed for concentrated
# priors. Since #1476 the Beta, zero-one-Beta and Gamma branches use the exact
# prior mean for rows whose predictor and response are both missing, so the
# reported value is alpha / (alpha + beta) for every log_sigma_mi, including
# the steep region where the old normaliser crossed the floor. (The remaining
# prior_norm floors in the other quadrature families are unchanged.)
# ---------------------------------------------------------------------------
test_that("Beta mi() both-missing rows report the exact prior mean across the old prior_norm floor", {
  set.seed(1)
  n <- 40
  z <- seq(-1.5, 1.5, length.out = n)
  cover <- stats::plogis(-0.2 + 0.8 * z)
  y <- 0.3 + 1.1 * cover - 0.2 * z + stats::rnorm(n, 0, 0.05)
  dat <- data.frame(y = y, z = z, cover = cover)
  both_missing <- c(5, 15, 25)
  dat$cover[both_missing] <- NA_real_
  dat$y[both_missing] <- NA_real_

  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(cover = impute_model(cover ~ z, family = beta_family())),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  target_row <- both_missing[[1]]
  z_row <- dat$z[[target_row]]
  par0 <- fit$obj$par
  beta_mi_idx <- which(names(par0) == "beta_mi")
  log_sigma_mi_idx <- which(names(par0) == "log_sigma_mi")
  eta <- par0[[beta_mi_idx[[1]]]] + par0[[beta_mi_idx[[2]]]] * z_row
  eps <- 1e-12
  mu <- eps + (1 - 2 * eps) * stats::plogis(eta)

  grid <- seq(-20, 5, length.out = 101)
  reported <- vapply(grid, function(ls) {
    par <- par0
    par[log_sigma_mi_idx] <- ls
    fit$obj$report(par)$mi_x_full[[target_row]]
  }, numeric(1))
  expected <- vapply(grid, function(ls) {
    phi <- exp(-2 * ls)
    alpha <- max(mu * phi, 1e-8)
    beta_ <- max((1 - mu) * phi, 1e-8)
    alpha / (alpha + beta_)
  }, numeric(1))
  expect_true(all(is.finite(reported)))
  expect_equal(reported, expected, tolerance = 1e-12)
})

# ---------------------------------------------------------------------------
# Site: max_eta running-max for the categorical mi() logsumexp
# (src/drmTMB.cpp:1284-1286). Not a series/direct or floor switch: it is a
# numerically-stable log-sum-exp (softmax normalizer), where
# log(sum_i exp(eta_i)) = M + log(sum_i exp(eta_i - M)) is an exact algebraic
# identity for ANY M, so the reported quantity is invariant to which state's
# eta the running-max CondExp happens to select. Class: C-infinity by
# algebraic identity (stronger than C1-expected); confirmed here across a
# genuine argmax tie between two states.
# ---------------------------------------------------------------------------
test_that("categorical mi() state-probability logsumexp is smooth across an argmax tie", {
  set.seed(1)
  n <- 30
  z <- seq(-1.5, 1.5, length.out = n)
  score <- 0.4 * z
  habitat_full <- factor(
    ifelse(score < -0.2, "forest", ifelse(score < 0.3, "grass", "wetland")),
    levels = c("forest", "grass", "wetland")
  )
  y <- 0.2 + 0.5 * z + stats::rnorm(n, 0, 0.1)
  dat <- data.frame(y = y, z = z, habitat = habitat_full)
  miss_rows <- c(5, 15, 25)
  dat$habitat[miss_rows] <- NA

  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ z + mi(habitat), sigma ~ 1),
    data = dat,
    impute = list(habitat = impute_model(habitat ~ z, family = categorical())),
    missing = miss_control(predictor = "model"),
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  par0 <- fit$obj$par
  mi_idx <- which(names(par0) == "beta_mi")
  target_row <- miss_rows[[1]]
  z_row <- dat$z[[target_row]]

  # beta_mi layout: [state1_intercept, state1_z, state2_intercept, state2_z].
  # Solve for the state2 intercept that ties eta_state(1) == eta_state(2) at
  # this row, forcing the running-max CondExp to switch which state it
  # selects as the max.
  eta1 <- par0[[mi_idx[[1]]]] + par0[[mi_idx[[2]]]] * z_row
  target <- eta1 - par0[[mi_idx[[4]]]] * z_row

  for (h in c(1e-3, 1e-6)) {
    par_below <- par0
    par_below[mi_idx[[3]]] <- target - h
    par_above <- par0
    par_above[mi_idx[[3]]] <- target + h
    prob_below <- fit$obj$report(par_below)$mi_state_probability[target_row, ]
    prob_above <- fit$obj$report(par_above)$mi_state_probability[target_row, ]
    expect_true(all(is.finite(prob_below)))
    expect_true(all(is.finite(prob_above)))
    expect_lt(max(abs(prob_below - prob_above)), 50 * h) # shrinks with h: smooth, not a jump
  }
})

# ---------------------------------------------------------------------------
# Part D: NB2 unselected-branch NaN hazard, drm_nbinom2_log_count_product
# (src/drm_count_kernels.h:6-28). Hypothesis: for alpha lesssim 1e-154
# (log_sigma lesssim -177, since alpha = exp(2*log_sigma) + 1e-300), the
# unselected lgamma_ratio branch's inv_alpha = 1/alpha node has reverse-mode
# local derivative -1/alpha^2 -> -Inf, multiplied by the CondExp-selected
# zero adjoint of the unselected branch, giving 0 * (-Inf) = NaN that would
# poison d(nll)/d(log_sigma).
# ---------------------------------------------------------------------------
test_that("nbinom2 REPORT(log_sigma) is bounded by the default softclamp even at an extreme raw intercept", {
  set.seed(1)
  n <- 20
  dat <- data.frame(y = stats::rpois(n, 3))
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(se = FALSE, optimizer = list(eval.max = 1, iter.max = 1))
    # logsigma_clamp left at its drm_control() default, c(-12, 12), margin 3
    # -> saturating band (-15, 15). This is the default public-API config.
  ))
  par <- fit$obj$par
  par[names(par) == "beta_sigma"] <- -177
  reported <- fit$obj$report(par)$log_sigma[[1]]
  expect_true(is.finite(reported))
  expect_gt(reported, -15 - 1e-6) # never reaches the hazard region by default
  g <- fit$obj$gr(par)
  expect_false(anyNA(g))
  expect_true(all(is.finite(g)))
})

test_that("Part D: with the softclamp explicitly disabled, log_sigma = -177 IS reachable, and obj$gr stays finite", {
  set.seed(1)
  n <- 20
  dat <- data.frame(y = stats::rpois(n, 3))
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(
      se = FALSE,
      logsigma_clamp = NULL, # user explicitly disables the guard
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  par0 <- fit$obj$par
  sig_idx <- names(par0) == "beta_sigma"

  for (log_sigma_val in c(-177, -200, -400)) {
    par <- par0
    par[sig_idx] <- log_sigma_val
    reported <- fit$obj$report(par)$log_sigma[[1]]
    expect_equal(reported, log_sigma_val) # confirms the hazard region really is reached

    fn <- fit$obj$fn(par)
    g <- fit$obj$gr(par)
    expect_true(is.finite(fn))
    expect_false(anyNA(g))
    expect_true(all(is.finite(g)))
  }
})

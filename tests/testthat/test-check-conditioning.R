test_that("check_drm() reports hessian_conditioning as an ok row for a well-conditioned fit", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "ok")
  expect_match(row$value, "min_eig=")
  expect_match(row$value, "cond=")

  # existing checks are untouched (additive only)
  expect_true("hessian_positive_definite" %in% chk$check)
})

test_that("check_drm() reports hessian_conditioning as a warning for a genuinely (resolvably) indefinite fit", {
  # Real (not injected) construction: two predictors close enough to
  # collinear that on SOME platforms TMB's own sdreport() does not reach a
  # positive-definite Hessian (pdHess = FALSE) and sdr$cov.fixed carries a
  # robustly, hugely negative eigenvalue rather than roundoff dust -- on
  # this Mac, -2.1014056e+11 against a positive spectrum of 6.2536453e-03,
  # 2.8825706e-03 and 1.6295414e-03 (measured 2026-09-05). Where that
  # happens, hessian_conditioning must catch it via sdr$cov.fixed's own most
  # negative eigenvalue, without ever calling obj$he(). Whether it happens
  # is a platform question, which the premise guard below settles; see also
  # docs/dev-log/after-task/2026-09-01-b2-check-conditioning.md sec 13.
  set.seed(20260901)
  n <- 80
  x1 <- stats::rnorm(n)
  x2 <- x1 + stats::rnorm(n, sd = 1e-7)
  y <- 0.5 + 0.3 * x1 + stats::rnorm(n, sd = 0.5)
  dat <- data.frame(y = y, x1 = x1, x2 = x2)

  fit <- suppressWarnings(drmTMB(
    bf(y ~ x1 + x2, sigma ~ 1),
    family = gaussian(),
    data = dat
  ))
  # Premise guard. The property under test is "a fit whose sdreport()
  # fixed-effect covariance is genuinely, resolvably indefinite earns a
  # hessian_conditioning warning". Whether THIS seeded near-collinear design
  # lands there is decided by the platform's LAPACK, and three distinct
  # outcomes exist for this exact seed:
  #
  #   * macOS (R 4.6.0, reference libRblas/libRlapack): pdHess = FALSE and
  #     cov.fixed is finite with eigenvalues 6.2536453e-03, 2.8825706e-03,
  #     1.6295414e-03 and -2.1014056e+11. The premise holds; this test runs
  #     and asserts (measured 2026-09-05).
  #   * Totoro (R 4.5.3, Linux, /usr/lib/x86_64-linux-gnu reference
  #     BLAS/LAPACK): pdHess = FALSE AND sdr$cov.fixed is entirely NaN, 16 of
  #     16 entries (measured 2026-09-05).
  #   * A GitHub Actions Linux runner resolved this same fit as positive
  #     definite (pdHess = TRUE), which is why a premise guard exists at all
  #     (reported on the 2026-09-02 CI run; not re-measured here).
  #
  # The Totoro outcome is a separate LAPACK verdict, not a shade of the
  # GitHub-Actions one: TMB::sdreport() sets pdHess from a Cholesky of the
  # fixed-effect Hessian but cov.fixed from a solve of it, and on a failure
  # there it leaves cov.fixed as the Hessian times NaN. So the Hessian can be
  # non-PD AND too singular to invert, leaving no covariance for the
  # indefinite premise to hold of. check_drm() then correctly reports
  # "note"/NA for this row, and the assertions below are inapplicable rather
  # than violated.
  #
  # The earlier guard tested pdHess alone, so it caught the GitHub-Actions
  # outcome and not the Totoro one: there the test proceeded to assert a
  # warning the fit does not justify, and failed twice (measured 2026-09-05
  # by reproducing the all-NaN cov.fixed: row$status was "note", not
  # "warning"; row$value was NA, not matching "min_eig=-"; the two
  # attr(chk, "ok") and nrow() assertions still held).
  # check_hessian_conditioning() (R/check.R) never reads pdHess -- for a
  # non-MSPL fit it reads sdr$cov.fixed and nothing else -- so the premise
  # has to be established on cov.fixed itself, which is what the two guards
  # below do.
  #
  # Nothing is given up by skipping here: the "warning" property itself is
  # covered unconditionally on every platform by the injected-indefinite
  # covariance test immediately below, which drives the identical code path
  # deterministically. What only this test can add is that a REAL fit can
  # reach that state, so it stays a real fit and skips honestly.
  cov_fixed <- fit$sdr$cov.fixed
  testthat::skip_if(
    is.null(cov_fixed) ||
      !is.matrix(cov_fixed) ||
      nrow(cov_fixed) == 0L ||
      !all(is.finite(cov_fixed)),
    paste(
      "platform LAPACK left TMB::sdreport() unable to invert this fit's",
      "Hessian, so sdr$cov.fixed is absent, empty, or non-finite and there is",
      "no covariance for the indefinite premise to hold of; the resolvably",
      "indefinite fit is not reproducible here"
    )
  )
  cov_eigen <- eigen(
    (cov_fixed + t(cov_fixed)) / 2,
    symmetric = TRUE,
    only.values = TRUE
  )$values
  # "Resolvably indefinite" is stated here independently of the package,
  # rather than read back out of it, so that establishing the premise cannot
  # become the same act as asserting the conclusion. A symmetric eigensolver
  # is backward stable, so its eigenvalue error is bounded by a small
  # multiple of .Machine$double.eps times the matrix norm, which for a
  # symmetric matrix is max|mu|; requiring the most negative eigenvalue to
  # clear 1e-6 * max(max|mu|, 1) therefore leaves no roundoff story that
  # explains its sign. That margin is deliberately about 67x stricter than
  # the sqrt(.Machine$double.eps)-scaled floor check_drm() itself uses, so
  # wherever this guard passes "warning" is the unambiguously correct answer
  # and the assertions below keep their teeth -- the guard cannot make the
  # test vacuous, and a regression that stopped warning here would still
  # fail it.
  testthat::skip_if_not(
    min(cov_eigen) < -1e-6 * max(abs(cov_eigen), 1),
    paste0(
      "platform LAPACK did not resolve the 1e-7 collinearity into a robustly ",
      "indefinite sdr$cov.fixed (pdHess = ",
      format(isTRUE(fit$sdr$pdHess)),
      ", smallest covariance eigenvalue = ",
      format(min(cov_eigen), digits = 4),
      " against max|eigenvalue| = ",
      format(max(abs(cov_eigen)), digits = 4),
      "); the indefinite premise is not reproducible here"
    )
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]

  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "warning")
  expect_match(row$value, "min_eig=-")
  expect_false(attr(chk, "ok"))
})

test_that("check_drm() reports hessian_conditioning as a warning for a deterministic injected-indefinite covariance", {
  # Platform-independent replacement for the resolvably-indefinite test
  # above: rather than relying on a collinear design landing on the
  # non-PD side of the boundary (Linux LAPACK vs macOS LAPACK disagree
  # on that fit, hence the premise guard there), this injects a
  # covariance matrix with one robustly negative eigenvalue directly
  # into a COPY of an ordinary well-conditioned fit's sdr$cov.fixed.
  # check_hessian_conditioning() (R/check.R) reads only
  # object$sdr$cov.fixed for a non-MSPL fit, decomposes it with
  # eigen(), and reports a "warning" whenever the smallest eigenvalue
  # is negative well beyond the sqrt(.Machine$double.eps)-scaled
  # roundoff floor -- it never calls obj$he() and never inspects
  # sdr$pdHess, so this construction exercises the exact same code
  # path deterministically on every platform.
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  fit2 <- fit
  p <- nrow(fit2$sdr$cov.fixed)
  indefinite_cov <- diag(c(-1, rep(1, p - 1)))
  fit2$sdr$cov.fixed <- indefinite_cov
  fit2$sdr$pdHess <- FALSE

  chk <- suppressWarnings(check_drm(fit2))
  row <- chk[chk$check == "hessian_conditioning", ]

  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "warning")
  expect_match(row$value, "min_eig=-")
  expect_false(attr(chk, "ok"))
})

test_that("check_drm() reports a stable, non-warning hessian_conditioning row for round-off-scale near-singular collinearity", {
  # Reproduces the false-positive originally reported against B2-G3: two
  # predictors so close to collinear that a direct AD Hessian's smallest
  # eigenvalue was governed by floating-point roundoff. Computing from
  # sdr$cov.fixed instead (an already-materialized numeric matrix; no C++
  # call at all) removes the sign ambiguity that produced the false
  # "warning" -- this fit's covariance eigenvalues are all resolvably
  # positive, so the implied minimum Hessian eigenvalue is a stable,
  # reproducible tiny positive number (not roundoff-noisy), and the huge
  # (but now reliable) condition number correctly earns a "note", never a
  # "warning". attr(ck, "ok") stays TRUE because "note" does not flip it.
  set.seed(1)
  n <- 200
  x <- stats::rnorm(n)
  x2 <- x + 1e-9 * stats::rnorm(n)
  y <- 1 + 2 * x + stats::rnorm(n)
  dat <- data.frame(y = y, x = x, x2 = x2)

  fit <- drmTMB(
    bf(y ~ x + x2, sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  # The 1e-9 collinearity sits at the edge of what a platform's BLAS/LAPACK
  # resolves: on this Mac the fit is PD and the row must be "ok"/"note"; on
  # some Linux builds TMB reports pdHess = FALSE for the same data, which is
  # a different (and correctly warned) situation this test does not grade.
  testthat::skip_if_not(
    isTRUE(fit$sdr$pdHess),
    "platform LAPACK resolved the 1e-9 collinearity as non-PD; the round-off-scale case is not reproducible here"
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]

  expect_equal(nrow(row), 1L)
  expect_true(row$status %in% c("ok", "note"))
  expect_match(row$value, "^min_eig=0\\.0")
  expect_true(attr(chk, "ok"))
  expect_true(all(chk$status != "warning"))
  expect_true(all(chk$status != "error"))
})

test_that("check_drm() reports hessian_conditioning as a note when sdreport was skipped", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(40),
    x = stats::rnorm(40)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "note")
  expect_true(is.na(row$value))
  expect_match(row$message, "se = FALSE", fixed = TRUE)
})

test_that("check_drm() reports hessian_conditioning as a real number even when the TMB object was not retained", {
  # sdr$cov.fixed lives on the sdreport, independent of drm_control(keep_tmb_object);
  # this is a further benefit of never calling obj$he().
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = FALSE)
  )
  expect_true(is.null(fit$obj))

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_true(row$status %in% c("ok", "note"))
  expect_false(is.na(row$value))
})

test_that("check_drm() reports hessian_conditioning as a note for incomplete sdr$cov.fixed", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(40),
    x = stats::rnorm(40)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  broken <- fit
  broken$sdr$cov.fixed[1, 1] <- Inf
  chk <- check_drm(broken)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "note")
  expect_true(is.na(row$value))
  expect_match(row$message, "cov.fixed")
})

test_that("check_drm() reports hessian_conditioning as a real number for a random-effect fit", {
  # This is the closed scope gap: obj$he() has no Laplace support, so this
  # row used to be a permanent note/NA for every random-effect fit -- the
  # model class the R/Julia parity programme is mostly about. sdr$cov.fixed
  # IS populated for a random-effect fit, so this now reports a computed
  # number, not a stated absence.
  set.seed(20260901)
  n_id <- 20
  id <- factor(rep(seq_len(n_id), each = 5))
  x <- stats::rnorm(length(id))
  y <- 0.3 * x + stats::rnorm(length(id), sd = 0.5) +
    stats::rnorm(n_id, sd = 0.4)[id]
  dat <- data.frame(y = y, x = x, id = id)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_true(row$status %in% c("ok", "note"))
  expect_false(is.na(row$value))
  expect_match(row$value, "min_eig=")
  expect_match(row$value, "cond=")
  expect_match(row$message, "sdreport\\(\\) fixed-effect covariance")
})

test_that("check_drm() computes hessian_conditioning without crashing after a saveRDS/readRDS round trip", {
  # This is the file/scenario that segfaulted R under obj$he() -- see
  # test-reader-oldfit-compat.R and
  # docs/dev-log/after-task/2026-09-01-b2-check-conditioning.md sec 13.
  # check_drm() must return normally (no C++ call at all in this row now)
  # and reproduce the pre-serialization values exactly, since sdr$cov.fixed
  # is an ordinary numeric matrix that round-trips through saveRDS/readRDS
  # unchanged.
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )
  checks_before <- check_drm(fit)

  tf <- withr::local_tempfile(fileext = ".rds")
  saveRDS(fit, tf)
  fit2 <- readRDS(tf)

  checks_after <- check_drm(fit2)
  expect_equal(checks_after, checks_before)

  row <- checks_after[checks_after$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_true(row$status %in% c("ok", "note", "warning"))
})

test_that("check_drm() existing check names are unchanged by hessian_conditioning", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  expect_true(all(
    c(
      "optimizer_convergence",
      "optimizer_budget",
      "finite_objective",
      "fixed_gradient",
      "sdreport_status",
      "hessian_positive_definite",
      "hessian_conditioning",
      "standard_errors_finite",
      "dropped_rows",
      "positive_scale"
    ) %in%
      chk$check
  ))
})

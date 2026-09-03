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
  # Deterministic-enough real construction: two predictors so close to
  # collinear that TMB's own sdreport() does not reach a positive-definite
  # Hessian (pdHess = FALSE), so sdr$cov.fixed carries a robustly, hugely
  # negative eigenvalue (not roundoff dust -- see
  # docs/dev-log/after-task/2026-09-01-b2-check-conditioning.md sec 13 for
  # the measured value, ~ -2.1e11 against a normal-scale ~600 elsewhere in
  # the same matrix). hessian_conditioning must still catch this via
  # sdr$cov.fixed's own most negative eigenvalue, without ever calling
  # obj$he().
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
  # Premise guard: the 1e-7 collinearity is non-PD on macOS (and on some Linux
  # runners) but Linux LAPACK has also resolved this exact seeded fit as PD with
  # min_eig ~ +2e-12 (observed on the 2026-09-02 CI run). The property under
  # test is "a resolvably indefinite fit earns a warning"; where the platform
  # does not produce the indefinite fit, the premise is absent, not the property.
  testthat::skip_if(
    isTRUE(fit$sdr$pdHess),
    "platform LAPACK resolved the 1e-7 collinearity as PD; the indefinite premise is not reproducible here"
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

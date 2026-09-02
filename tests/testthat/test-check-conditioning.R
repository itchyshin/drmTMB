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

test_that("check_drm() reports hessian_conditioning as a warning for a genuinely (resolvably) indefinite Hessian", {
  # Deterministic, reproducible construction: mock obj$he() to return a
  # matrix whose negative eigenvalue is orders of magnitude larger than the
  # AD-roundoff tolerance (see hessian_conditioning_eps_multiplier), so this
  # is unambiguously "genuinely negative", not floating-point dust. This
  # replaces an earlier near-duplicate-predictor construction whose min_eig
  # sat at the ~1e-14 roundoff floor and was, empirically, indistinguishable
  # run-to-run from the round-off-only case now regression-tested below --
  # see docs/dev-log/after-task/2026-09-01-b2-check-conditioning.md sec 6b.
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

  indefinite <- fit
  indefinite$obj$he <- function(par) {
    diag(c(500, 300, 150, -50))
  }
  chk <- check_drm(indefinite)
  row <- chk[chk$check == "hessian_conditioning", ]

  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "warning")
  expect_match(row$value, "min_eig=-50")
  expect_false(attr(chk, "ok"))
})

test_that("check_drm() does not flag round-off-scale near-singular collinearity as hessian_conditioning warning or note", {
  # Reproduces the false-positive reported against B2-G3: two predictors so
  # close to collinear that the TMB-AD Hessian's smallest eigenvalue is
  # governed by floating-point roundoff (|min_eig| ~ 1e-14), not by any
  # resolvable curvature. pdHess = TRUE, all standard errors finite, and the
  # gradient check is ok; hessian_conditioning must not be the only thing
  # that disagrees.
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
  expect_true(isTRUE(fit$sdr$pdHess))

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]

  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "ok")
  expect_true(attr(chk, "ok"))
  expect_true(all(chk$status != "warning"))
  expect_true(all(chk$status != "error"))
})

test_that("check_drm() reports hessian_conditioning as a note when the TMB object is not retained", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(40),
    x = stats::rnorm(40)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = FALSE)
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "note")
  expect_true(is.na(row$value))
  expect_match(row$message, "not retained")
})

test_that("check_drm() reports hessian_conditioning as a warning when obj$he() errors", {
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
  broken$obj$he <- function(par) stop("test hessian failure")
  chk <- check_drm(broken)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "warning")
  expect_match(row$message, "test hessian failure")
})

test_that("check_drm() reports hessian_conditioning as an explicit note for random-effect fits", {
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
  expect_equal(row$status, "note")
  expect_true(is.na(row$value))
  expect_match(row$message, "NOT AVAILABLE")
  expect_match(row$message, "random effects")
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

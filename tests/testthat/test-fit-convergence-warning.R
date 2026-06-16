# Wave 1 honesty guard 1: a fit the optimizer reports as non-converged must not
# look fine. A pure label interprets the nlminb code; the fit path warns when it
# is non-zero; print() surfaces the interpreted code. The warning path is tested
# with a synthetic `opt` list (deterministic) rather than a forced bad fit, whose
# convergence code is optimizer/BLAS-path dependent.

test_that("drm_convergence_label returns NULL for a converged code", {
  expect_null(drm_convergence_label(0L, "relative convergence (4)"))
  expect_null(drm_convergence_label(0L, NULL))
})

test_that("drm_convergence_label interprets a non-zero code with its message", {
  lab <- drm_convergence_label(1L, "false convergence (8)")
  expect_type(lab, "character")
  expect_match(lab, "non-convergence")
  expect_match(lab, "false convergence (8)", fixed = TRUE)
})

test_that("drm_convergence_label is robust to a missing message and NA/empty code", {
  expect_match(drm_convergence_label(1L, NULL), "non-convergence")
  expect_match(drm_convergence_label(1L, ""), "non-convergence")
  expect_null(drm_convergence_label(NA_integer_, "x"))
  expect_null(drm_convergence_label(integer(0), "x"))
})

test_that("drm_warn_if_not_converged is silent on a converged fit and warns otherwise", {
  expect_no_warning(
    drm_warn_if_not_converged(list(
      convergence = 0L,
      message = "relative convergence (4)"
    ))
  )
  expect_warning(
    drm_warn_if_not_converged(list(
      convergence = 1L,
      message = "false convergence (8)"
    )),
    "non-convergence"
  )
})

test_that("a clean Gaussian fit converges and emits no convergence warning", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.5), x = x)
  fit <- expect_no_warning(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  )
  expect_equal(fit$opt$convergence, 0L)
})

test_that("drm_warn_if_nonfinite_objective is silent on a finite objective and warns otherwise", {
  expect_no_warning(drm_warn_if_nonfinite_objective(list(objective = -123.4)))
  expect_warning(
    drm_warn_if_nonfinite_objective(list(objective = NaN)),
    "not finite"
  )
  expect_warning(
    drm_warn_if_nonfinite_objective(list(objective = Inf)),
    "not finite"
  )
})

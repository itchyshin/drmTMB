# Each acceptance gate of drm_restart_false_convergence() is exercised on its
# own, so that removing one gate fails a test. Companion to
# test-optimizer-false-convergence-restart.R, which covers the accepted path
# and the untouched paths.

quad_obj <- function() {
  list(
    fn = function(p) sum((p - c(1, -2))^2),
    gr = function(p) 2 * (p - c(1, -2))
  )
}

false_conv <- function(par, objective) {
  list(
    par = par,
    objective = objective,
    convergence = 1L,
    message = "false convergence (8)"
  )
}

test_that("a restart that cleanly reaches the optimum is accepted at the default gradient bound", {
  opt <- false_conv(c(a = 1 + 1e-9, b = -2), 1e-18)
  out <- drmTMB:::drm_restart_false_convergence(opt, quad_obj())
  expect_identical(out$convergence, 0L)
  expect_lte(max(abs(quad_obj()$gr(out$par))), 1e-6)
})

test_that("the gradient gate alone refuses an otherwise clean restart", {
  opt <- false_conv(c(a = 1 + 1e-9, b = -2), 1e-18)
  # Same restart as above, but an impossibly tight bound: only the gradient
  # gate can reject it, because nlminb itself returns code 0.
  out <- drmTMB:::drm_restart_false_convergence(
    opt, quad_obj(), grad_tol = 1e-30
  )
  expect_identical(out, opt)
})

test_that("the objective gate refuses a restart that does not improve on the endpoint", {
  obj <- quad_obj()
  par <- c(a = 1 + 1e-9, b = -2)
  # The claimed endpoint objective is lower than anything the restart can
  # reach, so the restart's objective exceeds it by more than 1e-8.
  opt <- false_conv(par, obj$fn(par) - 1)
  out <- drmTMB:::drm_restart_false_convergence(opt, obj)
  expect_identical(out, opt)
})

test_that("an error inside the restart returns the original result unchanged", {
  obj <- quad_obj()
  par <- c(a = 1 + 1e-9, b = -2)
  opt <- false_conv(par, obj$fn(par))
  broken <- list(
    fn = function(p) stop("objective failed"),
    gr = obj$gr
  )
  expect_identical(drmTMB:::drm_restart_false_convergence(opt, broken), opt)
})

# The cases below need a restart that looks clean on every criterion except
# one, which real nlminb runs do not produce on demand, so the restart result is
# supplied directly.
mock_restart <- function(...) {
  fields <- list(
    par = c(1, -2), objective = 0, convergence = 0L, message = "relative convergence (4)",
    iterations = 1L, evaluations = c(1L, 1L)
  )
  replacement <- list(...)
  fields[names(replacement)] <- replacement
  force(fields)
  function(...) fields
}

test_that("the code-0 gate refuses a restart nlminb itself did not call converged", {
  obj <- quad_obj()
  opt <- false_conv(c(a = 1 + 1e-9, b = -2), 1e-18)
  testthat::local_mocked_bindings(
    nlminb = mock_restart(convergence = 1L, message = "false convergence (8)"),
    .package = "stats"
  )
  expect_identical(drmTMB:::drm_restart_false_convergence(opt, obj), opt)
})

test_that("the finite-objective gate refuses a restart reporting a non-finite objective", {
  obj <- quad_obj()
  opt <- false_conv(c(a = 1 + 1e-9, b = -2), 1e-18)
  testthat::local_mocked_bindings(
    nlminb = mock_restart(objective = -Inf),
    .package = "stats"
  )
  expect_identical(drmTMB:::drm_restart_false_convergence(opt, obj), opt)
})

test_that("the length gate refuses a restart with a vector objective", {
  obj <- quad_obj()
  opt <- false_conv(c(a = 1 + 1e-9, b = -2), 1e-18)
  testthat::local_mocked_bindings(
    nlminb = mock_restart(objective = c(0, 0)),
    .package = "stats"
  )
  expect_identical(drmTMB:::drm_restart_false_convergence(opt, obj), opt)
})

test_that("the mocked clean restart is accepted, so the refusals above are the gates", {
  obj <- quad_obj()
  opt <- false_conv(c(a = 1 + 1e-9, b = -2), 1e-18)
  testthat::local_mocked_bindings(nlminb = mock_restart(), .package = "stats")
  out <- drmTMB:::drm_restart_false_convergence(opt, obj)
  expect_identical(out$convergence, 0L)
  expect_match(out$message, "nlminb restart after false convergence")
})

test_that("the restart never edits the original result in place", {
  opt <- false_conv(c(a = 1 + 1e-9, b = -2), 1e-18)
  before <- opt
  invisible(drmTMB:::drm_restart_false_convergence(opt, quad_obj()))
  expect_identical(opt, before)
})

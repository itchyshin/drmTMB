# Wave 3 (optimizer escalation): drm_optimize_with_preset_retry must escalate
# through the default -> careful -> robust ladder when a preset returns a
# NON-converged result (convergence != 0), not only when it throws an error, so
# the robust preset is reachable for false-convergence cases (audit F1 / Hao Qin).
# It returns the first cleanly-converged attempt, or the best (lowest-objective)
# candidate if none converge. The injectable `optimizer` argument lets us drive
# the ladder deterministically with a fake optimizer.

fake_retry_obj <- function() {
  list(par = c(a = 0), fn = function(p) 0, gr = function(p) 0)
}

test_that("escalates past a non-converged preset to a converged one", {
  calls <- 0L
  fake_opt <- function(start, objective, gradient, control) {
    calls <<- calls + 1L
    if (calls == 1L) {
      list(
        par = start,
        objective = 10,
        convergence = 1L,
        message = "false convergence (8)"
      )
    } else {
      list(
        par = start,
        objective = 8,
        convergence = 0L,
        message = "relative convergence (4)"
      )
    }
  }
  res <- drm_optimize_with_preset_retry(
    fake_retry_obj(),
    drm_control(),
    optimizer = fake_opt,
    warn = FALSE
  )
  expect_equal(res$opt$convergence, 0L)
  expect_equal(res$opt$objective, 8)
  expect_gte(calls, 2L)
})

test_that("returns the lowest-objective candidate when no preset converges", {
  objs <- c(10, 7, 9) # the careful (2nd) attempt is the best non-converged fit
  calls <- 0L
  fake_opt <- function(start, objective, gradient, control) {
    calls <<- calls + 1L
    list(
      par = start,
      objective = objs[calls],
      convergence = 1L,
      message = "false convergence (8)"
    )
  }
  res <- drm_optimize_with_preset_retry(
    fake_retry_obj(),
    drm_control(),
    optimizer = fake_opt,
    warn = FALSE
  )
  expect_equal(res$opt$objective, 7)
  expect_equal(calls, 3L)
})

test_that("a cleanly converged first attempt does not escalate", {
  calls <- 0L
  fake_opt <- function(start, objective, gradient, control) {
    calls <<- calls + 1L
    list(
      par = start,
      objective = 5,
      convergence = 0L,
      message = "relative convergence (4)"
    )
  }
  res <- drm_optimize_with_preset_retry(
    fake_retry_obj(),
    drm_control(),
    optimizer = fake_opt,
    warn = FALSE
  )
  expect_equal(calls, 1L)
  expect_equal(res$opt$convergence, 0L)
})

test_that("a non-finite objective is escalated past, not accepted", {
  calls <- 0L
  fake_opt <- function(start, objective, gradient, control) {
    calls <<- calls + 1L
    if (calls == 1L) {
      list(
        par = start,
        objective = NaN,
        convergence = 0L,
        message = "relative convergence (4)"
      )
    } else {
      list(
        par = start,
        objective = 6,
        convergence = 0L,
        message = "relative convergence (4)"
      )
    }
  }
  res <- drm_optimize_with_preset_retry(
    fake_retry_obj(),
    drm_control(),
    optimizer = fake_opt,
    warn = FALSE
  )
  expect_equal(res$opt$objective, 6)
  expect_gte(calls, 2L)
})

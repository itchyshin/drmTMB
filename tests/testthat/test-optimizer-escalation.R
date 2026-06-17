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

# Wave 3 (C3): opt-in fallback optimizer, tried only when no nlminb preset
# converges. The fallback is injected (fallback_fn) so it can be driven
# deterministically.

nlminb_nonconverged <- function(start, objective, gradient, control) {
  list(
    par = start,
    objective = 10,
    convergence = 1L,
    message = "false convergence (8)"
  )
}

test_that("drm_control validates fallback_optimizer", {
  expect_null(drm_control()$fallback_optimizer)
  expect_equal(
    drm_control(fallback_optimizer = "BFGS")$fallback_optimizer,
    "BFGS"
  )
  expect_error(drm_control(fallback_optimizer = "newton"), "fallback_optimizer")
  expect_error(
    drm_control(fallback_optimizer = c("BFGS", "CG")),
    "fallback_optimizer"
  )
})

test_that("the fallback optimizer is tried and used when no nlminb preset converges", {
  fb_calls <- 0L
  optim_fake <- function(par, fn, gr, method, control) {
    fb_calls <<- fb_calls + 1L
    list(par = par, value = 3, convergence = 0L, message = NULL)
  }
  res <- drm_optimize_with_preset_retry(
    fake_retry_obj(),
    drm_control(fallback_optimizer = "BFGS"),
    optimizer = nlminb_nonconverged,
    fallback_fn = optim_fake,
    warn = FALSE
  )
  expect_equal(fb_calls, 1L)
  expect_equal(res$opt$objective, 3)
  expect_equal(res$opt$convergence, 0L)
})

test_that("the fallback is not tried when a preset converges or when disabled", {
  conv_fake <- function(start, objective, gradient, control) {
    list(par = start, objective = 5, convergence = 0L, message = "ok")
  }
  fb_called <- FALSE
  optim_spy <- function(par, fn, gr, method, control) {
    fb_called <<- TRUE
    list(par = par, value = 1, convergence = 0L, message = NULL)
  }
  drm_optimize_with_preset_retry(
    fake_retry_obj(),
    drm_control(fallback_optimizer = "BFGS"),
    optimizer = conv_fake,
    fallback_fn = optim_spy,
    warn = FALSE
  )
  expect_false(fb_called)

  fb_called2 <- FALSE
  optim_spy2 <- function(par, fn, gr, method, control) {
    fb_called2 <<- TRUE
    list(par = par, value = 1, convergence = 0L, message = NULL)
  }
  drm_optimize_with_preset_retry(
    fake_retry_obj(),
    drm_control(),
    optimizer = nlminb_nonconverged,
    fallback_fn = optim_spy2,
    warn = FALSE
  )
  expect_false(fb_called2)
})

test_that("a non-converged fallback competes as a candidate by objective", {
  optim_fake <- function(par, fn, gr, method, control) {
    list(par = par, value = 4, convergence = 1L, message = "not converged")
  }
  res <- drm_optimize_with_preset_retry(
    fake_retry_obj(),
    drm_control(fallback_optimizer = "BFGS"),
    optimizer = nlminb_nonconverged,
    fallback_fn = optim_fake,
    warn = FALSE
  )
  expect_equal(res$opt$objective, 4)
})

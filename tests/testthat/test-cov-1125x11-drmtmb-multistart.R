# Coverage: multistart and optim-adapter helpers in R/drmTMB.R.

test_that("drm_perturbed_starts preserves the first start and reproduces length", {
  par <- c(a = 0, b = 1)
  one <- drmTMB:::drm_perturbed_starts(par, 1L)
  expect_length(one, 1L)
  expect_equal(one[[1L]], par)
  many <- drmTMB:::drm_perturbed_starts(par, 4L)
  expect_length(many, 4L)
  expect_equal(many[[1L]], par)
  expect_equal(length(many[[2L]]), 2L)
  expect_false(identical(many[[2L]], par))
  empty <- drmTMB:::drm_perturbed_starts(numeric(), 3L)
  expect_length(empty, 1L)
})

test_that("drm_multistart_plan disables parallel for single starts", {
  ctl <- drm_control(multi_start = 1L, parallel = "multicore", workers = 4L)
  plan <- drmTMB:::drm_multistart_plan(ctl, 1L)
  expect_equal(plan$backend, "none")
  expect_equal(plan$workers, 1L)
  ctl2 <- drm_control(multi_start = 3L, parallel = "none")
  plan2 <- drmTMB:::drm_multistart_plan(ctl2, 3L)
  expect_equal(plan2$backend, "none")
})

test_that("drm_optim_adapter maps optim results to nlminb shape", {
  fake <- function(par, fn, gr, method, control) {
    list(par = par + 0.1, value = fn(par), convergence = 0L, message = "ok",
         counts = c("function" = 3L, "gradient" = 2L))
  }
  adapt <- drmTMB:::drm_optim_adapter("BFGS", fake)
  out <- adapt(c(0, 0), function(p) sum(p^2), function(p) 2 * p, list())
  expect_equal(out$objective, 0)
  expect_equal(out$convergence, 0L)
  expect_equal(out$evaluations[["function"]], 3L)
  nm <- drmTMB:::drm_optim_adapter("Nelder-Mead", fake)
  out2 <- nm(c(1), function(p) p^2, NULL, list())
  expect_equal(out2$par, 1.1)
})

test_that("drm_optimize_multistart picks the lowest objective", {
  calls <- 0L
  obj <- list(
    par = c(0, 0),
    fn = function(p) {
      calls <<- calls + 1L
      sum((p - calls)^2)
    },
    gr = function(p) 2 * (p - calls)
  )
  optimizer <- function(start, objective, gradient, control) {
    list(par = start, objective = objective(start), convergence = 0L, message = NA_character_)
  }
  opt <- drmTMB:::drm_optimize_multistart(
    obj = obj,
    optimizer = optimizer,
    control_opt = list(),
    n_start = 3L
  )
  expect_equal(length(opt$par), 2L)
  expect_true(is.finite(opt$objective))
  explicit <- drmTMB:::drm_optimize_multistart(
    obj, optimizer, list(), n_start = 2L, starts = list(c(0, 0), c(5, 5))
  )
  expect_true(!is.null(attr(explicit, "drm_start_attempts")))
})

test_that("drm_perturbed_starts does not advance the global RNG stream", {
  par <- c(0.5, -0.5)
  before <- if (exists(".Random.seed", envir = globalenv())) {
    get(".Random.seed", envir = globalenv())
  } else {
    NULL
  }
  drmTMB:::drm_perturbed_starts(par, 3L)
  after <- if (exists(".Random.seed", envir = globalenv())) {
    get(".Random.seed", envir = globalenv())
  } else {
    NULL
  }
  expect_identical(before, after)
})

test_that("drm_optimize_multistart re-raises when every start errors", {
  obj <- list(par = 1, fn = function(p) p, gr = function(p) 1)
  bad <- function(start, objective, gradient, control) stop("boom", call. = FALSE)
  expect_error(
    drmTMB:::drm_optimize_multistart(obj, bad, list(), n_start = 2L),
    "boom"
  )
})
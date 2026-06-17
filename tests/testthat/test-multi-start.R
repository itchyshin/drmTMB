# Wave 3 (C2): drm_control(multi_start = K) fits each optimizer preset from K
# starting points (the principled start + K-1 reproducibly perturbed starts) and
# keeps the lowest-objective result. Opt-in: multi_start = 1 (default) is the
# single-start fit, unchanged.

test_that("drm_control accepts and validates multi_start", {
  expect_equal(drm_control(multi_start = 3L)$multi_start, 3L)
  expect_equal(drm_control()$multi_start, 1L)
  expect_error(drm_control(multi_start = 0L), "multi_start")
  expect_error(drm_control(multi_start = 2.5), "multi_start")
  expect_error(drm_control(multi_start = c(1L, 2L)), "multi_start")
})

test_that("drm_perturbed_starts returns the unperturbed start first and is reproducible", {
  par <- c(a = 1, b = -2, c = 0.5)
  expect_equal(drm_perturbed_starts(par, 1L), list(par))
  s1 <- drm_perturbed_starts(par, 4L)
  expect_length(s1, 4L)
  expect_equal(s1[[1L]], par)
  expect_false(isTRUE(all.equal(s1[[2L]], par)))
  s2 <- drm_perturbed_starts(par, 4L)
  expect_equal(s1, s2)
})

test_that("drm_perturbed_starts restores the caller's RNG stream", {
  set.seed(99)
  before <- get(".Random.seed", envir = globalenv())
  invisible(drm_perturbed_starts(c(a = 1, b = 2), 5L))
  expect_equal(get(".Random.seed", envir = globalenv()), before)
})

test_that("drm_optimize_multistart keeps the lowest-objective start", {
  obj <- list(par = c(a = 0, b = 0), fn = function(p) 0, gr = function(p) 0)
  objs <- c(5, 2, 8)
  calls <- 0L
  fake_opt <- function(start, objective, gradient, control) {
    calls <<- calls + 1L
    list(par = start, objective = objs[calls], convergence = 0L, message = "ok")
  }
  res <- drm_optimize_multistart(obj, fake_opt, list(), n_start = 3L)
  expect_equal(res$objective, 2)
  expect_equal(calls, 3L)
})

test_that("multi_start = 1 makes a single optimizer call (default unchanged)", {
  obj <- list(par = c(a = 0), fn = function(p) 0, gr = function(p) 0)
  calls <- 0L
  fake_opt <- function(start, objective, gradient, control) {
    calls <<- calls + 1L
    list(par = start, objective = 1, convergence = 0L, message = "ok")
  }
  drm_optimize_multistart(obj, fake_opt, list(), n_start = 1L)
  expect_equal(calls, 1L)
})

test_that("a real multi-start fit agrees with the single-start fit at an identified optimum", {
  set.seed(1)
  n <- 200
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.6), x = x)
  fit1 <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  fit3 <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(multi_start = 3L)
  )
  expect_equal(
    as.numeric(logLik(fit3)),
    as.numeric(logLik(fit1)),
    tolerance = 1e-6
  )
})

# Issue #1247: profile() accepts the same parallel = "none" | "multicore"
# contract as confint(). Multicore curves must equal the serial curves apart
# from the per-target elapsed time.

test_that("profile() multicore curves are identical to the serial curves", {
  testthat::skip_on_os("windows")
  set.seed(20261011)
  n <- 40
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.7), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  parm <- c("fixef:mu:(Intercept)", "fixef:mu:x", "sigma")

  serial <- profile(fit, parm = parm, profile_precision = "fast")
  multicore <- profile(
    fit,
    parm = parm,
    profile_precision = "fast",
    parallel = "multicore",
    workers = 2
  )
  serial$elapsed <- NULL
  multicore$elapsed <- NULL
  expect_identical(multicore, serial)
})

test_that("profile() validates its parallel arguments", {
  dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4, 0.9), x = c(-1, 0, 1, 2, 3))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
  expect_error(
    profile(fit, parm = "sigma", parallel = "threads"),
    "should be one of"
  )
  expect_error(
    profile(fit, parm = "sigma", parallel = "multicore", workers = 0),
    "workers"
  )
})

test_that("a dead forked worker is a classed error, not a dropped profile row", {
  plan <- list(backend = "none", workers = 1L)
  worker <- function(i) {
    if (i == 2L) {
      return(NULL)
    }
    data.frame(i = i)
  }
  expect_error(
    drmTMB:::profile_lapply(1:3, worker, plan),
    class = "drmTMB_parallel_worker_died"
  )
  expect_error(
    drmTMB:::drm_rbind_profile_rows(list(data.frame(i = 1), NULL, data.frame(i = 3))),
    class = "drmTMB_parallel_worker_died"
  )
})

test_that("a dead forked mclapply child is a classed profile error", {
  testthat::skip_on_os("windows")
  plan <- list(backend = "multicore", workers = 2L)
  expect_error(
    suppressWarnings(drmTMB:::profile_lapply(1:3, function(i) {
      if (i == 2L) quit("no", status = 1L, runLast = FALSE)
      data.frame(i = i)
    }, plan)),
    class = "drmTMB_parallel_worker_died"
  )
})

test_that("a dead bootstrap worker is a recorded failure, not a dropped row", {
  target <- "fixef:mu:x"
  rows <- list(
    drmTMB:::bootstrap_empty_draws(1L, target),
    NULL,
    drmTMB:::bootstrap_empty_draws(3L, target)
  )
  dropped <- do.call(rbind, rows)
  expect_equal(nrow(dropped), 2L)

  filled <- drmTMB:::drm_bootstrap_retain_dead_workers(rows, 1:3, target)
  bound <- do.call(rbind, filled)
  expect_equal(nrow(bound), 3L)
  expect_equal(bound$bootstrap, 1:3)
  expect_equal(bound$refit_status[bound$bootstrap == 2L], "worker_died")
  expect_false(any(bound$refit_ok[bound$bootstrap == 2L]))
  expect_equal(length(unique(bound$bootstrap)), 3L)

  plan <- list(backend = "none", workers = 1L)
  collected <- drmTMB:::bootstrap_lapply(1:3, function(i) {
    if (i == 2L) NULL else drmTMB:::bootstrap_empty_draws(i, target)
  }, plan)
  retained <- drmTMB:::drm_bootstrap_retain_dead_workers(collected, 1:3, target)
  expect_equal(length(retained), 3L)
  expect_equal(retained[[2L]]$refit_status, "worker_died")
})

test_that("multicore worker errors abort like the serial path", {
  testthat::skip_on_os("windows")
  plan <- list(backend = "multicore", workers = 2L)
  worker <- function(i) {
    if (i == 2L) stop("boom in worker ", i)
    i
  }
  expect_error(
    suppressWarnings(drmTMB:::profile_lapply(1:3, worker, plan)),
    "boom in worker 2"
  )
  expect_equal(drmTMB:::profile_lapply(1:3, function(i) i * 2, plan), list(2, 4, 6))
})

# Issue #1236: parallel = "cluster" (PSOCK) workers load the installed drmTMB
# build, so these tests need a real installation, not a pkgload dev namespace.
skip_unless_installed_build <- function() {
  # An installed package ships its compiled library under libs/; a
  # pkgload::load_all() dev namespace has none for a PSOCK worker to load.
  testthat::skip_if(
    !nzchar(system.file("libs", package = "drmTMB")),
    "cluster workers need an installed drmTMB build"
  )
}

test_that("profile() and confint() cluster results match the serial results", {
  testthat::skip_on_cran()
  skip_unless_installed_build()
  set.seed(20261012)
  n_id <- 12
  id <- factor(rep(seq_len(n_id), each = 4))
  x <- stats::rnorm(length(id))
  dat <- data.frame(
    y = 0.3 * x + stats::rnorm(n_id, sd = 0.5)[id] + stats::rnorm(length(id), sd = 0.6),
    x = x,
    id = id
  )
  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = gaussian(), data = dat)
  parm <- c("fixef:mu:x", "sigma")

  serial <- profile(fit, parm = parm, profile_precision = "fast")
  cluster <- profile(
    fit,
    parm = parm,
    profile_precision = "fast",
    parallel = "cluster",
    workers = 2
  )
  serial$elapsed <- NULL
  cluster$elapsed <- NULL
  expect_identical(cluster, serial)

  ci_serial <- confint(fit, parm = parm, method = "profile", ystep = 0.3)
  ci_cluster <- confint(
    fit,
    parm = parm,
    method = "profile",
    ystep = 0.3,
    parallel = "cluster",
    workers = 2
  )
  expect_identical(ci_cluster$lower, ci_serial$lower)
  expect_identical(ci_cluster$upper, ci_serial$upper)
})

test_that("bootstrap cluster refits match the serial refits", {
  testthat::skip_on_cran()
  skip_unless_installed_build()
  set.seed(20261013)
  x <- stats::rnorm(40)
  dat <- data.frame(y = 0.2 + 0.5 * x + stats::rnorm(40, sd = 0.7), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  serial <- confint(fit, parm = "fixef:mu:x", method = "bootstrap", R = 3, seed = 7)
  cluster <- confint(
    fit,
    parm = "fixef:mu:x",
    method = "bootstrap",
    R = 3,
    seed = 7,
    parallel = "cluster",
    workers = 2
  )
  expect_identical(cluster$lower, serial$lower)
  expect_identical(cluster$upper, serial$upper)
  expect_equal(cluster$bootstrap.parallel, "cluster")
})

test_that("drm_control() validates the multi-start parallel arguments", {
  expect_equal(drm_control()$parallel, "none")
  expect_null(drm_control()$workers)
  expect_equal(drm_control(parallel = "multicore", workers = 3)$workers, 3L)
  expect_error(drm_control(parallel = "threads"), "should be one of")
  expect_error(drm_control(parallel = "cluster", workers = 0), "workers")
})

test_that("parallel multi-start reproduces the serial fixed-effect fit", {
  testthat::skip_on_os("windows")
  set.seed(20261014)
  x <- stats::rnorm(80)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(80, sd = exp(0.3 * x)), x = x)
  f <- bf(y ~ x, sigma ~ x)
  serial <- drmTMB(f, data = dat, control = drm_control(multi_start = 3L, se = FALSE))
  forked <- drmTMB(
    f,
    data = dat,
    control = drm_control(multi_start = 3L, se = FALSE, parallel = "multicore", workers = 2)
  )
  # Without random effects there is no inner solve to warm-start, so each
  # start is a pure function of its start vector.
  expect_identical(forked$opt$par, serial$opt$par)
  expect_identical(forked$opt$objective, serial$opt$objective)
})

test_that("parallel multi-start matches the serial random-effect fit numerically", {
  testthat::skip_on_os("windows")
  set.seed(20261015)
  n_id <- 20
  id <- factor(rep(seq_len(n_id), each = 5))
  x <- stats::rnorm(length(id))
  dat <- data.frame(
    y = 0.4 * x + stats::rnorm(n_id, sd = 0.6)[id] + stats::rnorm(length(id), sd = 0.5),
    x = x,
    id = id
  )
  f <- bf(y ~ x + (1 | id), sigma ~ 1)
  serial <- drmTMB(f, data = dat, control = drm_control(multi_start = 3L))
  forked <- drmTMB(
    f,
    data = dat,
    control = drm_control(multi_start = 3L, parallel = "multicore", workers = 2)
  )
  expect_equal(forked$opt$par, serial$opt$par, tolerance = 1e-6)
  expect_equal(forked$opt$objective, serial$opt$objective, tolerance = 1e-8)
  expect_equal(unname(sqrt(diag(vcov(forked)))), unname(sqrt(diag(vcov(serial)))), tolerance = 1e-5)
})

test_that("multicore is refused on Windows with a pointer to cluster", {
  testthat::skip_if_not(.Platform$OS.type == "windows")
  expect_error(
    drmTMB:::bootstrap_parallel_plan(2L, parallel = "multicore", workers = 2L),
    "cluster"
  )
})

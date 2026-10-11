#' Parallel computing and thread policy in drmTMB
#'
#' @description
#' This page is for users who want to use several CPU cores with `drmTMB`. It
#' says which work can run in parallel today, which work is serial by design,
#' and how to avoid oversubscribing a machine when several layers of
#' parallelism are available.
#'
#' @section One fit uses one core:
#' A single [drmTMB()] fit runs on one core. The package's compiled objective
#' is built without OpenMP, so `TMB::openmp()`, `TMB_NTHREADS`, and
#' `OMP_NUM_THREADS` do not speed up the optimizer for one fit. Fit-level
#' threading is deferred.
#'
#' @section Backends:
#' Parallelism in `drmTMB` is across independent jobs, selected with
#' `parallel` and `workers`:
#'
#' * `"none"` (the default) runs the jobs one after another.
#' * `"multicore"` forks worker processes with [parallel::mclapply()]. It is
#'   cheap to start but available on Unix-alikes only.
#' * `"cluster"` starts socket (PSOCK) workers with
#'   [parallel::makePSOCKcluster()] and works on every platform, including
#'   Windows. Each worker loads the same installed `drmTMB` build. A fitted
#'   TMB object reaches the worker with a dead external pointer, and TMB
#'   rebuilds it from the stored data and parameters on first use, so no
#'   refit is needed. Starting the workers costs about a second, so
#'   `"cluster"` pays off only when each job takes longer than that.
#'
#' `workers = NULL` uses about half the detected cores, capped at the number
#' of jobs and at 10.
#'
#' @section What can run in parallel:
#' * Profile-likelihood intervals for several targets or `newdata` rows, and
#'   the two endpoint arms of a single scalar target, in [confint.drmTMB()].
#' * Parametric-bootstrap refits in `confint(method = "bootstrap")`. The
#'   replicate data are drawn once, before the workers start.
#' * Profile curves for several targets in [profile.drmTMB()].
#' * The starts of `drm_control(multi_start = k, parallel = ...)`.
#'
#' Profile and bootstrap jobs all start from the same fitted optimum, so every
#' backend returns the serial result apart from elapsed-time columns. Parallel
#' multi-start is the one exception. A serial multi-start warm-starts each
#' start's inner random-effect solve from the previous start, but parallel
#' starts all begin from the same initial state. With random effects the
#' estimates therefore agree with the serial run to the inner solver's
#' tolerance (about `1e-7` in local checks); fixed-effect fits are identical.
#'
#' [simulate.drmTMB()] stays serial. In a local check with 10,000 rows and 500
#' marginal draws, forked per-draw workers were slower than the vectorised
#' serial draw (0.89 s against 1.20 s serial, and 0.70 s for serial per-draw
#' calls). One random-number stream also keeps `set.seed()` reproducibility
#' simple.
#'
#' @section Do not nest parallel layers:
#' Use either outer jobs or inner threads, not both. When you run
#' `parallel = "multicore"` or `"cluster"`, or run many fits at once from a
#' cluster array or `mclapply()` loop, keep every inner layer at one thread so the worker count
#' does not multiply:
#'
#' ```
#' Sys.setenv(
#'   OMP_NUM_THREADS = 1, OPENBLAS_NUM_THREADS = 1,
#'   MKL_NUM_THREADS = 1, TMB_NTHREADS = 1
#' )
#' ```
#'
#' Set these before R starts (for example in a job script) when your BLAS
#' reads them only at load time. A multithreaded BLAS is the one inner layer
#' that can matter for a single `drmTMB` fit, through dense matrix work in
#' [TMB::sdreport()] and in large fixed-effect designs; it is the layer to pin
#' when you parallelise across jobs.
#'
#' @section Dead forked workers:
#' [parallel::mclapply()] returns `NULL` for a child that exits without a
#' value, for example after `quit()` or a crash. `rbind()` would then drop
#' that element. [profile.drmTMB()] and `confint(method = "profile")` abort
#' with class `drmTMB_parallel_worker_died` instead. `confint(method =
#' "bootstrap")` records the missing replicate as a failed refit, so
#' `bootstrap.n + bootstrap.failed` still equals the requested `R`.
#'
#' @section Windows:
#' `parallel = "multicore"` is not available on Windows because it relies on
#' process forking; use `parallel = "cluster"` instead. Bootstrap refits never
#' start their own multi-start workers inside parallel bootstrap workers.
#'
#' @seealso [confint.drmTMB()], [profile.drmTMB()], [drm_control()],
#'   [simulate.drmTMB()].
#' @name drmTMB-parallel
#' @aliases drm_parallel
NULL

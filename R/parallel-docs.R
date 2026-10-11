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
#' `OMP_NUM_THREADS` do not speed up the optimizer for one fit, and
#' [drm_control()] has no thread argument. `drm_control(multi_start = k)` also
#' runs its `k` starts one after another: the starts share one TMB object
#' whose inner random-effect solve is warm-started from the previous start, so
#' running them in separate processes would not reproduce the serial result
#' exactly.
#'
#' @section Parallel jobs after the fit:
#' Parallelism in `drmTMB` is across independent jobs. On Unix-alikes,
#' `parallel = "multicore"` forks worker processes with
#' [parallel::mclapply()] for:
#'
#' * profile-likelihood intervals for several targets or `newdata` rows, and
#'   the two endpoint arms of a single scalar target, in [confint.drmTMB()];
#' * parametric-bootstrap refits in `confint(method = "bootstrap")`;
#' * profile curves for several targets in [profile.drmTMB()].
#'
#' Every worker starts from the same fitted optimum, so the multicore result
#' equals the serial result apart from elapsed-time columns. `workers = NULL`
#' uses about half the detected cores, capped at the number of jobs and at 10.
#'
#' [simulate.drmTMB()] stays serial: it draws from the fitted distribution
#' without refitting, so it is fast, and one random-number stream keeps
#' `set.seed()` reproducibility simple.
#'
#' @section Do not nest parallel layers:
#' Use either outer jobs or inner threads, not both. When you run
#' `parallel = "multicore"`, or run many fits at once from a cluster array or
#' `mclapply()` loop, keep every inner layer at one thread so the worker count
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
#' @section Windows:
#' `parallel = "multicore"` is not available on Windows because it relies on
#' process forking. There is no socket-cluster (PSOCK) backend: a fitted TMB
#' object holds external pointers that do not survive being copied to another
#' R process, so a cluster worker would have to rebuild and refit the model.
#' On Windows, run independent jobs (for example separate bootstrap shards
#' with distinct seeds) in separate R sessions instead.
#'
#' @seealso [confint.drmTMB()], [profile.drmTMB()], [drm_control()],
#'   [simulate.drmTMB()].
#' @name drmTMB-parallel
#' @aliases drm_parallel
NULL

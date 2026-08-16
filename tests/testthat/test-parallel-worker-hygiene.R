# Guard: the fitted-model route spawns no operating-system worker processes.
#
# WHY THIS FILE EXISTS. A 2026-08-15 report attributed a set of orphaned PSOCK
# workers (`parallel:::.workRSOCK`, PPID 1, TIMEOUT=2592000, 30-90% CPU, dead
# master) to `drmTMB()` fits run with `drm_control(se = TRUE)`. That
# attribution did not reproduce: three consecutive `se = TRUE` fits of the
# mc-0596 fixture and three consecutive runs of `test-profile-targets.R` each
# left zero worker processes behind, and the workers observed live on the same
# machine belonged to a different project's benchmark script sharing the host.
# See docs/dev-log/after-task/2026-08-16-se-path-worker-leak-nonrepro.md.
#
# The `se = TRUE` path is a single in-process `TMB::sdreport()` call
# (`drm_compute_uncertainty()`, R/drmTMB.R) and creates no cluster. drmTMB's
# only parallel mechanism is fork-based `parallel::mclapply()`, confined to the
# opt-in bootstrap and profile helpers; PSOCK is deliberately unsupported
# because fitted TMB objects carry external pointers that do not survive
# serialisation to a fresh worker (docs/design/43-phase-18-interval-producer-
# contract.md).
#
# FALSIFICATION STATUS. These tests do NOT falsify: they pass against the
# current sources because the defect they describe is not present. They are
# regression guards for the invariant, not evidence that a bug was fixed. The
# second test would have caught the reported symptom had it been real; the
# first catches the likelier future regression, which is a cluster added
# without teardown rather than a teardown that fails.

test_that("no drmTMB function constructs a PSOCK cluster", {
  ns <- asNamespace("drmTMB")
  sources <- vapply(
    ls(ns, all.names = TRUE),
    function(nm) {
      object <- get(nm, envir = ns)
      if (!is.function(object)) {
        return("")
      }
      paste(deparse(object), collapse = "\n")
    },
    character(1)
  )
  # `makeForkCluster()` is listed too: it is not PSOCK, but it returns a
  # cluster object that leaks identically when `stopCluster()` is skipped.
  constructors <- c(
    "makeCluster",
    "makePSOCKcluster",
    "makeForkCluster",
    "makeClusterPSOCK"
  )
  offenders <- Filter(
    function(fn) any(vapply(
      constructors,
      function(ctor) grepl(ctor, sources[[fn]], fixed = TRUE),
      logical(1)
    )),
    names(sources)
  )
  expect_equal(offenders, character(0))
})

test_that("an se = TRUE fit leaves no new child processes", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if(
    !nzchar(Sys.which("ps")),
    "`ps` is unavailable, so child processes cannot be counted."
  )

  # Count only children of THIS process. A bare `workRSOCK` census would be
  # contaminated by anything else running on the same machine, which is
  # precisely how the original report reached the wrong culprit.
  own_children <- function() {
    ppids <- system2("ps", c("-eo", "ppid="), stdout = TRUE, stderr = FALSE)
    sum(suppressWarnings(as.integer(trimws(ppids))) == Sys.getpid(), na.rm = TRUE)
  }

  set.seed(20260816)
  n <- 200L
  data <- data.frame(y = stats::rnorm(n), x = stats::rnorm(n))

  # `own_children()` itself runs `ps` as a child, so the absolute count is
  # never zero. Compare the two measurements, not the count against zero.
  before <- own_children()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = data,
    control = drm_control(se = TRUE)
  )
  after <- own_children()

  # Pin that the fit really took the sdreport path; a skipped sdreport would
  # make the process count trivially true.
  expect_false(is.null(fit$sdr))
  expect_equal(after, before)
})

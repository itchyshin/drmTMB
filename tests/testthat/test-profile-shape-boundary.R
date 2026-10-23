# Profile shape boundary (issue #859, slice S5).
#
# `lme4`'s testdata/badprof.rds is a stored, pathological profile object
# (class "thpr"/data.frame) that lme4's own confint.thpr() flags via warnings
# about non-monotone and badly-splined variance-component traces. This file
# does three things:
#
#  1. Documents (via find.package(), not a vendored copy) that badprof.rds
#     cannot be "run through drmTMB's profile CI code": it is a stored
#     lme4 result, not a refittable dataset, and no accompanying model/data
#     ships alongside it.
#  2. Uses badprof.rds as a diagnostic-only SHAPE ORACLE: it independently
#     reproduces lme4's own non-monotonicity finding on badprof$.zeta, then
#     pins that drmTMB's profile_interval_diagnostics() cannot see that
#     shape at all (it takes only interval endpoints, never a trace).
#  3. Verifies the zeta^2 == delta_deviance correspondence on a drmTMB
#     profile we CAN compute: a small Gaussian random-intercept-SD fixture,
#     with delta_deviance independently recomputed against fit$opt$objective
#     (not the internal min(objective) baseline the package formula uses).
#
# See docs/dev-log/external-oracle/profile-shape-boundary.md for the full
# investigation and numbers.

test_that("badprof.rds cannot be run through drmTMB's profile CI code", {
  skip_if_not_installed("lme4")

  testdata_dir <- file.path(find.package("lme4"), "testdata")
  expect_true(file.exists(file.path(testdata_dir, "badprof.rds")))

  bp <- readRDS(file.path(testdata_dir, "badprof.rds"))
  expect_s3_class(bp, "thpr")
  expect_s3_class(bp, "data.frame")
  expect_identical(dim(bp), c(360L, 8L))

  # It is a stored profile, not a model: no formula, no call, no data.frame
  # of the original observations lives on the object or its attributes.
  expect_null(bp$call)
  expect_false("formula" %in% names(attributes(bp)))
  expect_false("data" %in% names(attributes(bp)))

  # No sibling file in lme4's testdata/ supplies the originating dataset for
  # badprof.rds's fixed effects ("(Intercept)", "cYear"). Without the data,
  # drmTMB has nothing to call drmTMB() on, so the object cannot enter
  # drm_profile_curve() or profile_interval_diagnostics() at all -- there is
  # no drmTMB fit for it to be an attribute of.
  siblings <- list.files(testdata_dir)
  expect_false(any(grepl("badprof", siblings, ignore.case = TRUE) &
    !grepl("badprof\\.rds$", siblings)))
})

test_that("lme4 confirms non-monotonicity in badprof$.zeta that drmTMB cannot see", {
  skip_if_not_installed("lme4")

  bp <- readRDS(file.path(find.package("lme4"), "testdata", "badprof.rds"))

  # Reproduce lme4's OWN internal non-monotonicity check (lme4:::confint.thpr,
  # profile.R) directly on the stored trace, independent of calling
  # lme4::confint() itself: for a fixed-effect column, .zeta must increase
  # (up to a small tolerance) as the profiled parameter increases.
  cyear <- bp[bp$.par == "cYear", c("cYear", ".zeta")]
  # Almost the entire cYear trace is NaN (the inner optimizer stalled); the
  # single finite anchor point is the fitted estimate itself (zeta = 0).
  expect_equal(sum(is.na(cyear$.zeta)), nrow(cyear) - 1L)
  expect_true(any(cyear$.zeta == 0, na.rm = TRUE))
  # lme4's own confint() independently confirms this shape pathology.
  msgs <- character(0)
  withCallingHandlers(
    invisible(stats::confint(bp)),
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_true(any(grepl("non-monotonic profile for cYear", msgs, fixed = TRUE)))
})

test_that("profile_interval_diagnostics() is structurally endpoint-only, not shape-aware", {
  # This is the load-bearing pin: it runs unconditionally (no lme4 needed,
  # no docs/ needed) so it holds under R CMD check, not only local devtools::test().
  #
  # drmTMB's classifier can only ever see a 2-number interval plus fit-level
  # scalars, never the per-row zeta/objective trace a monotonicity check
  # would need. Pin the argument list so a future PR that threads a trace in
  # has to touch this test.
  diag_args <- names(formals(profile_interval_diagnostics))
  expect_identical(
    diag_args,
    c(
      "interval", "transformation", "estimate", "sd_boundary",
      "correlation_boundary", "profile_min_objective", "fit_objective",
      "profile_below_fit_tol"
    )
  )
  trace_like_args <- c(
    "zeta", "trace", "profile_data", "delta_deviance", "profile_value",
    "profile_value_link", "values", "objective_trace"
  )
  expect_false(any(trace_like_args %in% diag_args))

  # The fixed, known message vocabulary contains nothing shape-related. If a
  # future PR adds monotonicity/shape detection without renaming this
  # function's implementation, it would almost certainly add a string
  # containing "monoton" or "shape" to the body -- catch that directly.
  body_text <- paste(deparse(body(profile_interval_diagnostics)), collapse = "\n")
  expect_false(grepl("monoton", body_text, ignore.case = TRUE))
  expect_false(grepl("\\bshape\\b", body_text, ignore.case = TRUE))

  known_messages <- c(
    profile_interval_diagnostics(c(NA, 1), "exp")$message,
    profile_interval_diagnostics(
      c(0.1, 0.9), "exp",
      estimate = 0.5, profile_min_objective = 10, fit_objective = 12
    )$message,
    profile_interval_diagnostics(
      c(0.1, 0.4), "linear_predictor",
      estimate = 0.5
    )$message,
    profile_interval_diagnostics(c(1e-10, 0.9), "exp", estimate = 0.5)$message,
    profile_interval_diagnostics(c(-0.99, 0.5), "tanh", estimate = 0.2)$message,
    profile_interval_diagnostics(c(0.1, 0.9), "exp", estimate = 0.5)$message
  )
  expect_identical(
    known_messages[1:3],
    c(
      "nonfinite_interval",
      "profile_below_fit_objective (gap=2 nll)",
      "point_estimate_outside_interval"
    )
  )
  expect_identical(known_messages[4:6], c("near_sd_boundary", "near_correlation_boundary", "ok"))
})

test_that("known-limitations.md still documents the non-monotone-profile boundary", {
  # Supplementary, not load-bearing: docs/ is .Rbuildignore-excluded
  # (^docs$), so this file does not exist inside an R CMD check tree or an
  # installed package -- only in a full git checkout such as this worktree.
  # The structural pin above (formals()/body() introspection) is what
  # actually holds under R CMD check; this assertion just keeps the
  # human-readable caveat honest when it CAN be read, so the prose cannot
  # silently claim the limitation is gone while the code above is unchanged.
  limitations_path <- testthat::test_path("..", "..", "docs", "dev-log", "known-limitations.md")
  skip_if_not(
    file.exists(limitations_path),
    "docs/ is not present in this check tree (excluded via .Rbuildignore)"
  )
  limitations_text <- paste(readLines(limitations_path, warn = FALSE), collapse = " ")
  expect_true(grepl(
    "not a full profile-shape classifier",
    limitations_text,
    fixed = TRUE
  ))
  expect_true(grepl(
    "non-monotone profiles remain",
    limitations_text,
    fixed = TRUE
  ))
})

test_that("zeta^2 == delta_deviance on a drmTMB profile we can actually compute", {
  set.seed(20260814)
  n_id <- 12L
  n_each <- 5L
  ID <- factor(rep(seq_len(n_id), each = n_each))
  n <- n_id * n_each
  x <- stats::rnorm(n)
  z0 <- stats::rnorm(n_id)
  sd0 <- 0.6
  u0 <- sd0 * z0
  y <- 0.3 + 0.5 * x + u0[ID] + stats::rnorm(n, sd = 0.4)
  dat <- data.frame(y = y, x = x, ID = ID)

  fit <- drmTMB(bf(y ~ x + (1 | ID)), family = gaussian(), data = dat)
  targets <- drm_profile_targets(fit)
  sd_row <- targets[targets$target_class == "random-effect-sd", , drop = FALSE][1L, ]
  expect_true(nrow(sd_row) == 1L)

  prof <- profile(
    fit,
    parm = sd_row$parm,
    profile_precision = "fast",
    trace = FALSE
  )
  expect_s3_class(prof, "profile.drmTMB")
  expect_true(nrow(prof) > 5L)

  # (1) Independent recomputation: drm_profile_curve() derives delta_deviance
  # from 2 * (objective - min(trace objective)). Recompute it here against
  # fit$opt$objective -- the FIT's own reported deviance/2, an independent
  # baseline the profile trace formula never references directly -- and
  # confirm they agree. This is the actual mathematical content of
  # "the profile's zero is the MLE": if the profile's warm-started inner
  # optimizer ever beat the fit (the pathology issue #1009 guards against),
  # this equality would break.
  recomputed_delta_deviance <- 2 * (prof$objective - fit$opt$objective)
  expect_equal(prof$delta_deviance, recomputed_delta_deviance, tolerance = 1e-8)

  # (2) The signed likelihood root lme4 calls .zeta is never formed inside
  # drmTMB, but can be recovered from delta_deviance exactly as documented:
  # zeta = sign(profile_value - estimate) * sqrt(delta_deviance). Squaring
  # it back must reproduce delta_deviance to numerical precision.
  zeta <- sign(prof$profile_value_link - prof$link_estimate) *
    sqrt(pmax(prof$delta_deviance, 0))
  expect_equal(zeta^2, prof$delta_deviance, tolerance = 1e-8)

  # (3) Positive control: on this clean, well-identified fixture (unlike
  # badprof's cYear column) the recovered zeta is monotone in the profiled
  # value, so a genuine regression here (a real non-monotone drmTMB profile)
  # would be caught by this assertion, not silently swallowed.
  ord <- order(prof$profile_value_link)
  expect_true(!is.unsorted(zeta[ord]))
})

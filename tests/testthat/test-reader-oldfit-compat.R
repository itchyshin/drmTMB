# Backward-compatibility regression test for the native reader contract
# (issue #859), adapted from glmmTMB's stored-old-fit pattern
# (`old_fit.rds` / `oldfit.rds` in glmmTMB's `test_data/`). See
# docs/dev-log/external-oracle/oldfit-compat.md for the full investigation.
#
# KEY FINDING: a drmTMB fit's TMB pointer (`fit$obj$env$ADFun$ptr`) genuinely
# dies across saveRDS()/readRDS() -- even round-tripping inside the SAME R
# session, because R's serializer never preserves raw external-pointer
# addresses. TMB's own MakeADFun()-created closures detect this
# (`isNullPointer()`) and transparently retape from the retained
# `data`/`parameters`/`map` (plain R objects, not pointers) the first time
# `obj$fn()`/`obj$gr()` is called after restore. That makes the round trip
# testable in-process, with no stored binary fixture: build a fit, serialize
# it, and exercise the reader contract on the restored copy.
#
# This test asserts the ACTUAL supported behaviour:
#  - the TMB pointer is provably dead immediately after readRDS();
#  - check_drm(), summary(), ranef(), fitted(), and predict_parameters() --
#    the reader-contract verbs documented in R/reader-contracts.R -- return
#    the same values after the round trip as before it;
#  - obj$gr() itself reproduces the pre-serialization gradient once retaped;
#  - a fit saved with keep_tmb_object = FALSE degrades to a "note", not an
#    error, on the one check that needs the TMB object.
#
# Scope: this is a within-version guarantee (same drmTMB build on both sides
# of the round trip). It is NOT evidence that a fit serialized by an older
# drmTMB release still reads under a newer one once the internal TMB
# data/parameter/map structure has changed; no such older-release artifact
# exists in this repository to test against (see the findings note).

test_that("a saveRDS/readRDS round trip kills the TMB pointer but the reader contract survives it", {
  set.seed(20260814)
  dat <- data.frame(x = seq(-1, 1, length.out = 40L))
  dat$y <- 0.4 + 0.6 * dat$x + stats::rnorm(nrow(dat), sd = 0.3)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), gaussian(), data = dat)

  checks_before <- check_drm(fit)
  summary_before <- summary(fit)
  ranef_before <- ranef(fit)
  fitted_before <- fitted(fit)
  params_before <- predict_parameters(fit, dpar = "mu")
  gr_before <- as.numeric(fit$obj$gr(fit$opt$par))

  expect_false(TMB:::isNullPointer(fit$obj$env$ADFun$ptr))

  tf <- withr::local_tempfile(fileext = ".rds")
  saveRDS(fit, tf)
  fit2 <- readRDS(tf)

  # The crux finding: serialization genuinely invalidates the TMB pointer,
  # even round-tripping inside the same R process.
  expect_true(TMB:::isNullPointer(fit2$obj$env$ADFun$ptr))

  expect_equal(check_drm(fit2), checks_before)
  expect_equal(summary(fit2), summary_before)
  expect_equal(ranef(fit2), ranef_before)
  expect_equal(fitted(fit2), fitted_before)
  expect_equal(predict_parameters(fit2, dpar = "mu"), params_before)

  # obj$gr() retapes transparently from the retained data/parameters/map and
  # reproduces the pre-serialization gradient.
  gr_after <- as.numeric(fit2$obj$gr(fit2$opt$par))
  expect_equal(gr_after, gr_before)
  expect_false(TMB:::isNullPointer(fit2$obj$env$ADFun$ptr))
})

test_that("a fit saved without the TMB object degrades gracefully across the round trip", {
  set.seed(20260814)
  dat <- data.frame(x = seq(-1, 1, length.out = 40L))
  dat$y <- 0.4 + 0.6 * dat$x + stats::rnorm(nrow(dat), sd = 0.3)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = FALSE)
  )
  expect_null(fit$obj)

  tf <- withr::local_tempfile(fileext = ".rds")
  saveRDS(fit, tf)
  fit2 <- readRDS(tf)

  checks <- check_drm(fit2)
  gradient_row <- checks[checks$check == "fixed_gradient", ]
  expect_identical(gradient_row$status, "note")
  expect_match(gradient_row$message, "TMB object was not retained")
  expect_false(any(checks$status %in% c("warning", "error")))

  expect_s3_class(summary(fit2), "summary.drmTMB")
  expect_length(fitted(fit2), nrow(dat))
})

# DRM.jl #569 comparability clause, R-side gradient half.
#
# The final outer gradient at the optimum is computed lazily inside
# `check_drm()` (`check_fixed_gradient()`, `R/check.R`) via
# `object$obj$gr(object$opt$par)`, and only when `object$obj` was retained.
# This means gradient diagnosis is opt-in and storage-dependent rather than a
# property of the fit. These tests assert `drmTMB()` stores the final
# gradient at `opt$par`, and its worst (largest |.|) component label, at fit
# time -- so it survives `drm_control(keep_tmb_object = FALSE)` and agrees
# exactly with what `check_drm()` computes live.

stored_gradient_test_data <- function() {
  data.frame(
    y = c(-0.2, 0.1, 0.4, 0.7, 1.0, 1.2, 1.6, 1.9),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5, 2, 2.5)
  )
}

test_that("drmTMB() stores the final gradient and its worst component", {
  dat <- stored_gradient_test_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(optimizer = list(eval.max = 200, iter.max = 200))
  )

  expect_true(!is.null(fit$gradient))
  expect_true(is.numeric(fit$gradient))
  expect_length(fit$gradient, length(fit$opt$par))
  expect_true(is.character(fit$gradient_max_component))
  expect_length(fit$gradient_max_component, 1L)

  live_gradient <- as.numeric(fit$obj$gr(fit$opt$par))
  expect_equal(as.numeric(fit$gradient), live_gradient)
})

test_that("the stored gradient survives keep_tmb_object = FALSE", {
  dat <- stored_gradient_test_data()
  fit_kept <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 200, iter.max = 200),
      keep_tmb_object = TRUE
    )
  )
  fit_dropped <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 200, iter.max = 200),
      keep_tmb_object = FALSE
    )
  )

  expect_null(fit_dropped$obj)
  expect_true(!is.null(fit_dropped$gradient))
  expect_true(!is.null(fit_dropped$gradient_max_component))
  expect_equal(
    as.numeric(fit_dropped$gradient),
    as.numeric(fit_kept$gradient)
  )
  expect_identical(
    fit_dropped$gradient_max_component,
    fit_kept$gradient_max_component
  )
})

test_that("the stored gradient agrees with check_drm()'s live fixed_gradient row", {
  dat <- stored_gradient_test_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 200, iter.max = 200),
      keep_tmb_object = TRUE
    )
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "fixed_gradient", , drop = FALSE]
  expect_equal(nrow(row), 1L)

  live_gradient <- as.numeric(fit$obj$gr(fit$opt$par))
  live_max_abs <- max(abs(live_gradient), 0)
  expect_equal(max(abs(fit$gradient), 0), live_max_abs)
  expect_match(row$value, fit$gradient_max_component, fixed = TRUE)
})

test_that("storing the gradient does not perturb the reported optimum", {
  # `check_fixed_gradient()`'s live path already calls `obj$gr(opt$par)` after
  # the fit exists (a read the design doc 35 selected-optimum invariant must
  # tolerate), so re-running it here after the object was fit must reproduce
  # the same stored gradient and leave the report-derived logLik untouched --
  # confirming the fit-time `obj$gr()` call was re-pinned rather than leaking
  # a perturbed `last.par` into what `report()` at `tmb_state$last.par.best`
  # sees.
  dat <- stored_gradient_test_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 200, iter.max = 200),
      keep_tmb_object = TRUE
    )
  )

  live_gradient_after_fit <- as.numeric(fit$obj$gr(fit$opt$par))
  expect_equal(as.numeric(fit$gradient), live_gradient_after_fit)

  objective_report <- fit$obj$report(fit$tmb_state$last.par.best)
  reported_phylo_penalty <- if (is.null(objective_report$phylo_penalty)) {
    0
  } else {
    as.numeric(objective_report$phylo_penalty)
  }
  expect_equal(reported_phylo_penalty, fit$phylo_penalty)
})

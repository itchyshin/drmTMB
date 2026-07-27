new_arc_d_profile_trace_data <- function(n_id, n_each, seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(length(id))
  b <- stats::rnorm(n_id, sd = 0.4)
  data.frame(
    y = 0.2 + 0.5 * x + b[id] + stats::rnorm(length(id), sd = 0.5),
    x = x,
    ID = id
  )
}

test_that("full TMB profiles retain a private objective-evaluation trace", {
  dat <- new_arc_d_profile_trace_data(12, 5, 20260727)
  fit <- drmTMB(
    bf(y ~ x + (1 | p | ID)),
    family = gaussian(),
    data = dat
  )
  target <- profile_targets(fit)
  target <- target[target$parm == "fixef:mu:x", , drop = FALSE]
  lincomb <- profile_lincomb(fit, target)

  prof <- drm_tmbprofile(
    object = fit,
    target_name = target$parm,
    lincomb = lincomb,
    trace = FALSE,
    ystep = 0.3
  )
  profile_trace <- attr(prof, "drmTMB_profile_trace")

  expect_type(profile_trace, "list")
  expect_equal(profile_trace$target_name, target$parm)
  expect_equal(profile_trace$lincomb, as.numeric(lincomb))
  expect_equal(profile_trace$baseline$par, fit$opt$par)
  expect_equal(profile_trace$baseline$objective, fit$opt$objective)
  expect_gt(length(profile_trace$evaluations), 0L)
  expect_true(all(vapply(
    profile_trace$evaluations,
    function(entry) identical(names(entry$par), names(fit$opt$par)),
    logical(1)
  )))
  expect_true(all(vapply(
    profile_trace$evaluations,
    function(entry) {
      is.numeric(entry$objective) && length(entry$objective) == 1L
    },
    logical(1)
  )))
})

test_that("profile trace records nonfinite objective evaluations", {
  dat <- new_arc_d_profile_trace_data(8, 4, 20260728)
  fit <- drmTMB(
    bf(y ~ x + (1 | p | ID)),
    family = gaussian(),
    data = dat
  )
  trace_state <- drm_profile_trace_object(
    object = fit,
    target_name = "test_target",
    lincomb = rep(0, length(fit$opt$par))
  )
  bad_par <- fit$opt$par
  bad_par[[1L]] <- NA_real_

  value <- trace_state$obj$fn(bad_par)
  profile_trace <- trace_state$snapshot()

  expect_length(profile_trace$evaluations, 1L)
  expect_equal(profile_trace$evaluations[[1L]]$par, bad_par)
  expect_equal(profile_trace$evaluations[[1L]]$objective, as.numeric(value))
  expect_null(profile_trace$evaluations[[1L]]$error)
})

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
  expect_gt(profile_trace$n_evaluations, 0L)
  expect_length(profile_trace$objective, profile_trace$n_evaluations)
  expect_length(profile_trace$error, profile_trace$n_evaluations)
  expect_type(profile_trace$objective, "double")
  # Issue #1387: the default trace must not keep the fixed vector per call.
  expect_null(profile_trace$evaluations)
  expect_equal(profile_trace$clamp, c(active = 0L, unavailable = 0L))
})

test_that("profile trace memory stays constant in length(par) by default (#1387)", {
  dat <- new_arc_d_profile_trace_data(8, 4, 20260731)
  fit <- drmTMB(
    bf(y ~ x + (1 | p | ID)),
    family = gaussian(),
    data = dat
  )
  run_calls <- function(keep_par, n_calls) {
    trace_state <- drm_profile_trace_object(
      object = fit,
      target_name = "test_target",
      lincomb = rep(0, length(fit$opt$par)),
      keep_par = keep_par
    )
    for (i in seq_len(n_calls)) {
      trace_state$obj$fn(fit$opt$par + i * 1e-4)
    }
    trace_state$snapshot()
  }
  lean <- run_calls(FALSE, 25L)
  full <- run_calls(TRUE, 25L)
  expect_equal(lean$n_evaluations, 25L)
  expect_null(lean$evaluations)
  expect_length(full$evaluations, 25L)
  expect_equal(
    full$evaluations[[3L]]$par,
    stats::setNames(fit$opt$par + 3e-4, names(fit$opt$par))
  )
  expect_identical(
    vapply(full$evaluations, `[[`, numeric(1), "objective"),
    lean$objective
  )
  # The lean trace stores one double and one string per call; the full trail
  # stores a length(par) vector per call on top of that.
  expect_lt(
    as.numeric(utils::object.size(lean)),
    as.numeric(utils::object.size(full)) / 2
  )
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

  expect_equal(profile_trace$n_evaluations, 1L)
  expect_equal(profile_trace$objective, as.numeric(value))
  expect_true(is.na(profile_trace$error))
})

test_that("streamed direct-SD clamp counts match the per-par classification", {
  dat <- new_arc_d_profile_trace_data(10, 4, 20260729)
  dat$x <- rep(seq(-0.8, 0.8, length.out = nlevels(dat$ID)), each = 4L)
  fit <- drmTMB(
    bf(y ~ x + (1 | ID), sigma ~ 1, sd(ID) ~ x),
    family = gaussian(),
    data = dat,
    control = drm_control(logsigma_clamp = c(-3, 3))
  )
  clamped_par <- fit$opt$par
  clamped_par[names(clamped_par) == "beta_sd_mu"] <- c(0, 20)
  trace_state <- drm_profile_trace_object(
    object = fit,
    target_name = "test_target",
    lincomb = rep(0, length(fit$opt$par))
  )
  trace_state$obj$fn(fit$opt$par)
  clean <- structure(list(), drmTMB_profile_trace = trace_state$snapshot())
  expect_equal(
    attr(clean, "drmTMB_profile_trace")$clamp,
    c(active = 0L, unavailable = 0L)
  )
  expect_equal(drmTMB:::drm_profile_direct_sd_clamp_trace(fit, clean)$status, "ok")

  trace_state$obj$fn(clamped_par)
  clamped <- structure(list(), drmTMB_profile_trace = trace_state$snapshot())
  expect_equal(
    attr(clamped, "drmTMB_profile_trace")$clamp,
    c(active = 1L, unavailable = 0L)
  )
  expect_null(attr(clamped, "drmTMB_profile_trace")$evaluations)
  expect_equal(
    drmTMB:::drm_profile_direct_sd_clamp_trace(fit, clamped)$status,
    "clamp_limited"
  )
})

test_that("direct-SD profile tracing fails closed on clamp contact", {
  dat <- new_arc_d_profile_trace_data(10, 4, 20260729)
  dat$x <- rep(seq(-0.8, 0.8, length.out = nlevels(dat$ID)), each = 4L)
  fit <- drmTMB(
    bf(y ~ x + (1 | ID), sigma ~ 1, sd(ID) ~ x),
    family = gaussian(),
    data = dat
  )
  clean_profile <- structure(
    list(),
    drmTMB_profile_trace = list(
      baseline = list(par = fit$opt$par),
      evaluations = list()
    )
  )
  expect_equal(
    drmTMB:::drm_profile_direct_sd_clamp_trace(fit, clean_profile)$status,
    "ok"
  )

  clamped_par <- fit$opt$par
  clamped_par[names(clamped_par) == "beta_sd_mu"] <- c(0, 20)
  clamped_profile <- structure(
    list(),
    drmTMB_profile_trace = list(
      baseline = list(par = fit$opt$par),
      evaluations = list(list(par = clamped_par))
    )
  )
  expect_equal(
    drmTMB:::drm_profile_direct_sd_clamp_trace(fit, clamped_profile)$status,
    "clamp_limited"
  )
})

test_that("a clamp-touched full profile withholds its public interval", {
  dat <- new_arc_d_profile_trace_data(12, 4, 20260730)
  dat$x <- rep(seq(-0.6, 0.6, length.out = nlevels(dat$ID)), each = 4L)
  fit <- drmTMB(
    bf(y ~ x + (1 | ID), sigma ~ 1, sd(ID) ~ x),
    family = gaussian(),
    data = dat,
    control = drm_control(logsigma_clamp = c(-0.1, 0.1))
  )
  interval <- confint(
    fit,
    parm = "fixef:sd(ID):(Intercept)",
    method = "profile",
    ystep = 0.5,
    ytol = 2
  )
  expect_equal(interval$conf.status, "clamp_limited")
  expect_true(interval$profile.boundary)
  expect_equal(interval$profile.message, "clamp_limited")
  expect_true(all(is.na(interval[, c("lower", "upper")])))
})

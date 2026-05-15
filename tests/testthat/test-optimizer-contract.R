test_that("future optimizer contract names are reserved in plain control lists", {
  dat <- data.frame(y = c(-0.2, 0.0, 0.3, 0.6), x = c(-1, 0, 1, 2))
  reserved <- c(
    "start",
    "starts",
    "map",
    "fixed",
    "fallback_optimizer",
    "multi_start",
    "multistart"
  )

  for (name in reserved) {
    control <- stats::setNames(list(TRUE), name)
    expect_error(
      drmTMB(
        bf(y ~ x, sigma ~ 1),
        data = dat,
        control = control
      ),
      "reserved"
    )
    expect_error(
      drm_control(optimizer = control),
      "reserved"
    )
  }

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = list(start = TRUE, map = TRUE)
    ),
    "start"
  )
})

test_that("reported parameters are split from the selected optimum", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )

  par_list <- fit$obj$env$parList(fit$opt$par)
  expect_equal(
    fit$coefficients,
    drmTMB:::split_tmb_parameters(
      par_list,
      fit$model
    )
  )
  expect_equal(fit$sdpars, drmTMB:::split_tmb_sdpars(par_list, fit$model))
  expect_equal(fit$corpars, drmTMB:::split_tmb_corpars(par_list, fit$model))
  expect_equal(fit$uncertainty$status, "ok")
})

test_that("profile intervals re-pin the TMB object to the selected optimum", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  bad_par <- fit$opt$par + seq_along(fit$opt$par)
  fit$obj$env$last.par <- bad_par
  fit$obj$env$last.par.best <- bad_par

  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  expect_equal(unname(fit$obj$env$last.par), unname(fit$opt$par))
  expect_equal(unname(fit$obj$env$last.par.best), unname(fit$opt$par))

  fit$obj$env$last.par <- bad_par
  fit$obj$env$last.par.best <- bad_par
  ci <- stats::confint(
    fit,
    parm = "fixef:mu:(Intercept)",
    method = "profile",
    trace = FALSE
  )
  expect_equal(ci$conf.status, "profile")
  expect_lt(ci$lower, unname(fit$coefficients$mu[["(Intercept)"]]))
  expect_gt(ci$upper, unname(fit$coefficients$mu[["(Intercept)"]]))
})

test_that("pinning preserves random-effect slots in the TMB object", {
  set.seed(20260515)
  id <- factor(rep(seq_len(8), each = 5))
  x <- rep(seq(-1, 1, length.out = 5), times = 8)
  u <- stats::rnorm(8, sd = 0.4)
  dat <- data.frame(
    y = 0.2 + 0.5 * x + u[id] + stats::rnorm(length(id), sd = 0.35),
    x = x,
    id = id
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  original_last <- fit$obj$env$last.par
  fit$obj$env$last.par <- original_last + seq_along(original_last)
  fit$obj$env$last.par.best <- fit$obj$env$last.par.best +
    seq_along(fit$obj$env$last.par.best)

  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  fixed <- fit$obj$env$lfixed()
  expect_equal(length(fit$obj$env$last.par), length(fit$tmb_state$last.par))
  expect_equal(unname(fit$obj$env$last.par[fixed]), unname(fit$opt$par))
  expect_equal(
    unname(fit$obj$env$last.par[!fixed]),
    unname(fit$tmb_state$last.par[!fixed])
  )
  expect_equal(
    unname(fit$obj$env$last.par.best),
    unname(fit$tmb_state$last.par.best)
  )
  expect_true(all(is.finite(ranef(fit)$mu$values)))
})

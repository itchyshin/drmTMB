test_that("unknown nlminb control names warn with did-you-mean and still fit", {
  dat <- data.frame(
    y = c(-0.2, 0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )
  other <- character()
  withCallingHandlers(
    fit <- drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = gaussian(),
      data = dat,
      control = list(eval.maxx = 10)
    ),
    warning = function(w) {
      other <<- c(other, conditionMessage(w))
      if (inherits(w, "drmTMB_unknown_optimizer_control")) {
        invokeRestart("muffleWarning")
      }
    }
  )
  expect_null(fit$control$optimizer$eval.maxx)
  expect_equal(fit$opt$convergence, 0L)
  expect_match(
    paste(other, collapse = "\n"),
    "Did you mean.*eval\\.max",
    perl = TRUE
  )
  expect_false(any(grepl("unrecognized control element", other, fixed = TRUE)))
})

test_that("drmTMB_unknown_optimizer_control is a distinct warning class", {
  set.seed(1734L)
  dat <- data.frame(y = rnorm(12), x = rnorm(12))
  expect_warning(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = gaussian(),
      data = dat,
      control = list(eval.maxx = 10)
    ),
    class = "drmTMB_unknown_optimizer_control"
  )
})

test_that("valid nlminb control names do not warn", {
  dat <- data.frame(
    y = c(-0.2, 0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )
  expect_no_warning(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = gaussian(),
      data = dat,
      control = list(eval.max = 500, iter.max = 500)
    )
  )
})

test_that("port_cpos names xf.tol and maxiter do not warn", {
  dat <- data.frame(
    y = c(-0.2, 0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )
  expect_no_warning(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = gaussian(),
      data = dat,
      control = list(maxiter = 500, xf.tol = 1e-12)
    )
  )
})

test_that("partial nlminb control names are accepted like stats::nlminb", {
  dat <- data.frame(
    y = c(-0.2, 0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )
  fit <- expect_no_warning(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = gaussian(),
      data = dat,
      control = list(iter = 3, eval.max = 5000)
    )
  )
  expect_true("iter" %in% names(fit$control$optimizer))
  expect_lte(fit$opt$iterations, 3L)
})

test_that("drm_nlminb_control_names matches stats port_cpos", {
  expect_equal(
    drmTMB:::drm_nlminb_control_names(),
    names(stats:::port_cpos)
  )
})

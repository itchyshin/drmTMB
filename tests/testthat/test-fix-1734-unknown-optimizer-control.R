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
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0L)
  expect_match(
    paste(other, collapse = "\n"),
    "Did you mean.*eval\\.max",
    perl = TRUE
  )
  expect_false(any(grepl("unrecognized control element", other, fixed = TRUE)))
})

test_that("drmTMB_unknown_optimizer_control is a distinct warning class", {
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

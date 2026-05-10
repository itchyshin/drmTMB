test_that("drm_control() validates optimizer and storage settings", {
  ctrl <- drm_control(
    optimizer = list(eval.max = 25),
    keep_data = FALSE,
    keep_tmb_object = FALSE
  )

  expect_s3_class(ctrl, "drm_control")
  expect_equal(ctrl$optimizer$eval.max, 25)
  expect_false(ctrl$keep_data)
  expect_true(ctrl$keep_model_frame)
  expect_false(ctrl$keep_tmb_object)
  expect_error(drm_control(optimizer = 1), "optimizer")
  expect_error(drm_control(optimizer = list(25)), "named list")
  expect_error(drm_control(keep_data = NA), "keep_data")
  expect_error(drm_control(keep_model_frame = FALSE), "keep_model_frame")
})

test_that("plain control lists remain optimizer controls", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )

  expect_s3_class(fit$control, "drm_control")
  expect_equal(fit$control$optimizer$eval.max, 100)
  expect_equal(fit$control$optimizer$iter.max, 100)
  expect_equal(fit$data$y, dat$y)
  expect_false(is.null(fit$obj))
})

test_that("memory-light storage keeps core post-fit methods working", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 100, iter.max = 100),
      keep_data = FALSE,
      keep_tmb_object = FALSE
    )
  )

  expect_null(fit$data)
  expect_null(fit$model$data)
  expect_null(fit$obj)
  expect_length(predict(fit, dpar = "mu"), nrow(dat))
  expect_length(fitted(fit), nrow(dat))
  expect_length(residuals(fit), nrow(dat))
  expect_equal(dim(simulate(fit, nsim = 2, seed = 1)), c(nrow(dat), 2L))

  chk <- check_drm(fit)
  fixed_gradient <- chk[chk$check == "fixed_gradient", ]
  expect_true(attr(chk, "ok"))
  expect_equal(fixed_gradient$status, "note")
  expect_match(fixed_gradient$message, "not retained")
})

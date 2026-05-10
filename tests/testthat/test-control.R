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

test_that("core methods tolerate manually removed model frames", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  fit$model$model_frame <- NULL

  expect_length(predict(fit, dpar = "mu"), nrow(dat))
  expect_length(predict(fit, newdata = data.frame(x = c(0, 1))), 2L)
  expect_length(fitted(fit), nrow(dat))
  expect_length(residuals(fit), nrow(dat))
  expect_equal(dim(simulate(fit, nsim = 2, seed = 1)), c(nrow(dat), 2L))
  expect_length(sigma(fit), nrow(dat))
  expect_s3_class(check_drm(fit), "drm_check")
})

test_that("offset prediction tolerates manually removed model frames", {
  dat <- data.frame(
    y = c(0L, 1L, 2L, 3L, 1L, 4L),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5),
    exposure = c(1, 1.5, 2, 2.5, 3, 3.5)
  )
  fit <- drmTMB(
    bf(y ~ x + offset(log(exposure))),
    family = poisson(),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  fit$model$model_frame <- NULL

  pred <- predict(
    fit,
    newdata = data.frame(x = c(0, 1), exposure = c(2, 4)),
    dpar = "mu"
  )
  expect_length(pred, 2L)
  expect_true(all(is.finite(pred)))
  expect_length(residuals(fit), nrow(dat))
  expect_equal(dim(simulate(fit, nsim = 2, seed = 1)), c(nrow(dat), 2L))
})

test_that("representative family methods tolerate manually removed model frames", {
  beta_binomial_dat <- data.frame(
    success = c(2L, 4L, 6L, 8L, 3L, 5L, 7L, 9L, 4L, 6L),
    failure = c(8L, 6L, 4L, 2L, 7L, 5L, 3L, 1L, 6L, 4L),
    x = seq(-1, 1, length.out = 10)
  )
  beta_binomial_fit <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ 1),
    family = beta_binomial(),
    data = beta_binomial_dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  beta_binomial_fit$model$model_frame <- NULL

  expect_length(
    predict(beta_binomial_fit, dpar = "mu"),
    nrow(beta_binomial_dat)
  )
  expect_length(
    predict(beta_binomial_fit, newdata = data.frame(x = c(0, 1)), dpar = "mu"),
    2L
  )
  expect_length(residuals(beta_binomial_fit), nrow(beta_binomial_dat))
  expect_equal(
    dim(simulate(beta_binomial_fit, nsim = 2, seed = 1)),
    c(nrow(beta_binomial_dat), 2L)
  )

  ordinal_dat <- data.frame(
    score = ordered(
      rep(c("low", "medium", "high"), each = 4),
      levels = c("low", "medium", "high")
    ),
    x = rep(c(-1, -0.5, 0.5, 1), times = 3)
  )
  ordinal_fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = ordinal_dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  ordinal_fit$model$model_frame <- NULL

  expect_length(predict(ordinal_fit, dpar = "mu"), nrow(ordinal_dat))
  expect_length(
    predict(ordinal_fit, newdata = data.frame(x = c(0, 1)), dpar = "mu"),
    2L
  )
  expect_length(fitted(ordinal_fit), nrow(ordinal_dat))
  expect_length(residuals(ordinal_fit), nrow(ordinal_dat))
  expect_equal(
    dim(simulate(ordinal_fit, nsim = 2, seed = 1)),
    c(nrow(ordinal_dat), 2L)
  )

  biv_dat <- data.frame(
    y1 = c(-0.4, -0.1, 0.2, 0.4, 0.7, 1.0, 1.2, 1.5),
    y2 = c(0.3, 0.2, 0.4, 0.5, 0.9, 1.1, 1.0, 1.4),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5, 2, 2.5)
  )
  biv_fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = c(gaussian(), gaussian()),
    data = biv_dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  biv_fit$model$model_frame <- NULL

  expect_equal(dim(fitted(biv_fit)), c(nrow(biv_dat), 2L))
  expect_equal(dim(residuals(biv_fit)), c(nrow(biv_dat), 2L))
  expect_length(rho12(biv_fit), nrow(biv_dat))
  expect_equal(dim(simulate(biv_fit, nsim = 2, seed = 1)), c(nrow(biv_dat), 4L))
  pairs <- corpairs(biv_fit)
  expect_equal(pairs$from_response, "y1")
  expect_equal(pairs$to_response, "y2")
})

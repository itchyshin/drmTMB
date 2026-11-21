# Issue #1700: model.frame() on a drmTMB fit must return the rows used to
# fit, not the internal TMB specification stored in fit$model.

test_that("model.frame() returns the location rows used to fit", {
  set.seed(1700)
  n <- 21L
  dat <- data.frame(
    y = rnorm(n),
    x = rnorm(n),
    g = factor(rep(c("a", "b"), length.out = n)),
    z = rnorm(n),
    unused = rnorm(n)
  )
  dat$y[[4L]] <- NA_real_

  fit <- drmTMB(
    bf(y ~ x + g, sigma ~ z),
    family = gaussian(),
    data = dat
  )

  mf <- stats::model.frame(fit)

  expect_s3_class(mf, "data.frame")
  expect_false(identical(mf, fit$model))
  expect_equal(nrow(mf), nobs(fit))
  expect_equal(nrow(mf), sum(!is.na(dat$y)))
  expect_equal(nrow(mf), 20L)
  expect_false(anyNA(mf$y))
  expect_true(all(c("y", "x", "g") %in% names(mf)))
  expect_false("unused" %in% names(mf))
  # The scale covariate is a different distributional formula. The returned
  # frame is the location (mu) frame, so z is not required here.
  expect_false("z" %in% names(mf))

  tt <- attr(mf, "terms")
  expect_s3_class(tt, "terms")
  expect_true(all(c("y", "x", "g") %in% all.vars(tt)))
  expect_false("z" %in% all.vars(tt))

  expect_s3_class(stats::terms(fit), "terms")
  expect_equal(all.vars(stats::terms(fit)), all.vars(tt))

  X <- stats::model.matrix(fit)
  expect_equal(nrow(X), nobs(fit))
  expect_true(all(c("(Intercept)", "x", "gb") %in% colnames(X)))
  expect_equal(unname(X[, "x"]), unname(mf$x))
  expect_equal(as.vector(X), as.vector(fit$model$X$mu))
  expect_equal(colnames(X), colnames(fit$model$X$mu))
  expect_false("4" %in% rownames(mf))
})

test_that("model.frame() refuses a dropped frame and a bivariate fit", {
  set.seed(1701)
  dat <- data.frame(y = rnorm(30), x = rnorm(30), z = rnorm(30))
  dropped <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_model_frame = FALSE)
  )
  expect_error(
    stats::model.frame(dropped),
    "keep_model_frame",
    class = "drmTMB_model_frame_missing"
  )

  dat$y1 <- dat$y
  dat$y2 <- dat$y + 0.2 * dat$z + rnorm(30, sd = 0.3)
  biv <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ z),
    family = biv_gaussian(),
    data = dat
  )
  expect_error(
    stats::model.frame(biv),
    "mu1",
    class = "drmTMB_model_frame_bivariate"
  )
})

test_that("model.frame() does not return Julia bridge metadata", {
  fake <- structure(
    list(
      model = list(
        model_type = "gaussian",
        dpars = "mu",
        data = data.frame(y = 1)
      ),
      data = data.frame(y = 1),
      nobs = 1L
    ),
    class = "drmTMB_julia"
  )
  expect_error(
    stats::model.frame(fake),
    "julia",
    class = "drmTMB_model_frame_julia"
  )
})

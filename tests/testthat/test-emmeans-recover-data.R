emmeans_recover_data_control <- function(keep_model_frame = TRUE) {
  drm_control(
    keep_model_frame = keep_model_frame,
    optimizer = list(eval.max = 120L, iter.max = 120L)
  )
}

emmeans_recover_data_data <- function(n = 36L) {
  habitat <- factor(rep(c("reef", "kelp", "sand"), length.out = n))
  x <- seq(-1, 1, length.out = n)
  data.frame(
    y = 0.1 + 0.4 * x + 0.3 * (habitat == "kelp") + stats::rnorm(n, sd = 0.1),
    x = x,
    habitat = habitat
  )
}

test_that("emmeans recover-data preflight returns retained model metadata", {
  set.seed(20260532)
  dat <- emmeans_recover_data_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_recover_data_control()
  )

  recovered <- drmTMB:::drm_emmeans_recover_data(fit)

  expect_equal(recovered$dpar, "mu")
  expect_s3_class(recovered$model_frame, "data.frame")
  expect_s3_class(recovered$terms, "terms")
  expect_equal(recovered$predictors, c("x", "habitat"))
  expect_equal(recovered$response, "y")
  expect_equal(recovered$xlevels$habitat, levels(dat$habitat))
  expect_equal(recovered$row_names, row.names(fit$model$model_frame$mu))
})

test_that("emmeans recover-data preflight restores offset source variables", {
  set.seed(20260544)
  dat <- emmeans_recover_data_data()
  dat$exposure <- rep(c(1.0, 1.5, 2.0), length.out = nrow(dat))
  dat$count <- stats::rpois(
    nrow(dat),
    lambda = exp(0.2 + 0.4 * dat$x + log(dat$exposure))
  )
  fit <- drmTMB(
    bf(count ~ x + habitat + offset(log(exposure))),
    family = stats::poisson(link = "log"),
    data = dat,
    control = emmeans_recover_data_control()
  )

  recovered <- drmTMB:::drm_emmeans_recover_data(fit)

  expect_equal(recovered$model_frame$exposure, dat$exposure)
  expect_equal(recovered$predictors, c("x", "habitat", "exposure"))
})

test_that("emmeans recover-data preflight requires retained model frames", {
  set.seed(20260533)
  dat <- emmeans_recover_data_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_recover_data_control(keep_model_frame = FALSE)
  )

  expect_error(
    drmTMB:::drm_emmeans_recover_data(fit),
    "keep_model_frame = TRUE"
  )
})

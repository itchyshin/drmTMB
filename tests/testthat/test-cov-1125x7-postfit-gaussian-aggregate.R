# Gaussian aggregation enabled during drmTMB() (R/gaussian-aggregation.R via R/drmTMB.R).

cov_1125x7_agg_dat <- function() {
  base <- expand.grid(
    habitat = factor(c("forest", "reef")),
    effort = factor(c("low", "high")),
    rep = 1:3
  )
  base$y <- stats::rnorm(nrow(base))
  base
}

test_that("aggregate_gaussian fits store aggregation metadata", {
  dat <- cov_1125x7_agg_dat()
  fit <- drmTMB(
    bf(y ~ habitat, sigma ~ effort),
    data = dat,
    control = drm_control(
      aggregate_gaussian = TRUE,
      se = FALSE,
      optimizer = list(eval.max = 80, iter.max = 80)
    )
  )
  expect_equal(fit$opt$convergence, 0L)
  agg <- fit$model$aggregation$gaussian
  expect_true(agg$enabled)
  expect_lt(agg$n_cells, agg$n_original)
  expect_equal(agg$n_original, nrow(dat))
})

test_that("check_drm() summarizes aggregation for aggregated Gaussian fits", {
  dat <- cov_1125x7_agg_dat()
  fit <- drmTMB(
    bf(y ~ habitat, sigma ~ 1),
    data = dat,
    control = drm_control(aggregate_gaussian = TRUE, se = FALSE)
  )
  chk <- check_drm(fit)
  rows <- chk$check
  expect_true(any(grepl("aggregat", rows, ignore.case = TRUE)))
})

test_that("aggregated and dense Gaussian logLik match on tiny replicated designs", {
  dat <- cov_1125x7_agg_dat()
  form <- bf(y ~ habitat, sigma ~ 1)
  dense <- drmTMB(form, data = dat, control = drm_control(se = FALSE))
  agg <- drmTMB(
    form,
    data = dat,
    control = drm_control(aggregate_gaussian = TRUE, se = FALSE)
  )
  expect_equal(as.numeric(logLik(agg)), as.numeric(logLik(dense)), tolerance = 1e-5)
  expect_equal(coef(agg)$mu, coef(dense)$mu, tolerance = 1e-5)
})
# Bootstrap simulation shard from a fit (R/bootstrap-shards.R).

cov_1125x7_boot <- function() {
  set.seed(112581)
  dat <- data.frame(y = stats::rnorm(16), x = stats::rnorm(16))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE, keep_data = TRUE)
  )
}

test_that("drm_bootstrap_replicate_simulation() returns a one-column data frame", {
  fit <- cov_1125x7_boot()
  sim <- drmTMB:::drm_bootstrap_replicate_simulation(fit, seed = 1L, index = 1L, re_form = NULL)
  expect_s3_class(sim, "data.frame")
  expect_equal(nrow(sim), fit$nobs)
  expect_true(all(is.finite(sim[[1L]])))
})

test_that("drm_bootstrap_shard() records targets for a fixef parameter", {
  fit <- cov_1125x7_boot()
  shard <- drmTMB:::drm_bootstrap_shard(
    object = fit,
    parm = "fixef:mu:x",
    indices = c(1L, 2L),
    seed = 11L,
    parallel = "none"
  )
  expect_s3_class(shard, "drm_bootstrap_shard")
  expect_identical(shard$indices, c(1L, 2L))
  expect_equal(shard$header$targets, "fixef:mu:x")
  ledger <- drmTMB:::drm_bootstrap_ledger(shard)
  expect_equal(nrow(ledger), 1L)
  expect_equal(ledger$attempted, 2L)
})

test_that("drm_bootstrap_combine() merges shards that share headers", {
  fit <- cov_1125x7_boot()
  s1 <- drmTMB:::drm_bootstrap_shard(
    fit, parm = "fixef:mu:x", indices = 1L, seed = 3L, parallel = "none"
  )
  s2 <- drmTMB:::drm_bootstrap_shard(
    fit, parm = "fixef:mu:x", indices = 2L, seed = 3L, parallel = "none"
  )
  combined <- drmTMB:::drm_bootstrap_combine(s1, s2)
  expect_s3_class(combined, "drm_bootstrap_shard")
  expect_equal(length(combined$indices), 2L)
})
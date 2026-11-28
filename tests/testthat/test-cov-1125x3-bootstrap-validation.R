# Input validation branches in R/bootstrap-shards.R.

mini_fit <- function(keep_data = TRUE) {
  set.seed(3)
  dat <- data.frame(y = 0.2 + 0.5 * seq_len(12) + rnorm(12), x = seq_len(12))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE, keep_data = keep_data)
  )
}

test_that("drm_bootstrap_shard() validates object, data, indices, and seed", {
  fit <- mini_fit()
  expect_error(drmTMB:::drm_bootstrap_shard(list(), "fixef:mu:x", 1:2, 1), "drmTMB")
  no_data <- mini_fit(keep_data = FALSE)
  expect_error(
    drmTMB:::drm_bootstrap_shard(no_data, "fixef:mu:x", 1:2, 1),
    "keep_data"
  )
  expect_error(
    drmTMB:::drm_bootstrap_shard(fit, "fixef:mu:x", c(1, 1), 1),
    "distinct"
  )
  expect_error(
    drmTMB:::drm_bootstrap_shard(fit, "fixef:mu:x", c(0, 1), 1),
    "distinct"
  )
  expect_error(
    drmTMB:::drm_bootstrap_shard(fit, "fixef:mu:x", 1:2, 1.5),
    "whole number"
  )
})

test_that("drm_bootstrap_ledger() requires a shard object", {
  fit <- mini_fit()
  shard <- drm_bootstrap_shard(fit, parm = "fixef:mu:x", indices = 1:2, seed = 9)
  ledger <- drm_bootstrap_ledger(shard)
  expect_true(all(c("attempted", "usable", "refit_error") %in% names(ledger)))
  expect_error(drm_bootstrap_ledger(list()), "drm_bootstrap_shard")
})

test_that("drm_bootstrap_replicate_simulation() restores RNG state", {
  fit <- mini_fit()
  before <- get(".Random.seed", envir = globalenv())
  sim1 <- drmTMB:::drm_bootstrap_replicate_simulation(fit, seed = 4L, index = 1L, re_form = NULL)
  sim2 <- drmTMB:::drm_bootstrap_replicate_simulation(fit, seed = 5L, index = 1L, re_form = NULL)
  expect_identical(get(".Random.seed", envir = globalenv()), before)
  expect_true(is.data.frame(sim1) || is.matrix(sim1) || is.numeric(unlist(sim1)))
  expect_false(identical(sim1, sim2))
  expect_equal(nrow(sim1), fit$nobs)
})
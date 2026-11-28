# R/bootstrap-shards.R header metadata (drm_bootstrap_combine covered in 1125x5).

test_that("drm_bootstrap_shard_header() records fit fingerprint fields", {
  set.seed(11250902L)
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    family = gaussian(),
    control = drm_control(optimizer_method = "BFGS", se = FALSE)
  )
  hdr <- drmTMB:::drm_bootstrap_shard_header(
    fit,
    target_names = c("mu:x", "sigma:(Intercept)"),
    seed = 99L,
    re_form = NULL,
    refit_control = drm_control(optimizer_method = "BFGS", se = FALSE)
  )
  expect_equal(hdr$schema_version, drmTMB:::drm_bootstrap_shard_schema_version)
  expect_equal(hdr$estimator, "ML")
  expect_identical(hdr$targets, c("mu:x", "sigma:(Intercept)"))
  expect_equal(hdr$seed, 99L)
  expect_true(nzchar(hdr$package_version))
  expect_true(nzchar(hdr$git_sha))
  expect_true(is.finite(hdr$fit_fingerprint$objective))
  expect_equal(hdr$fit_fingerprint$nobs, 20L)
  expect_equal(hdr$refit$se, FALSE)
})

test_that("drm_bootstrap_replicate_simulation() restores caller RNG state", {
  dat <- data.frame(y = stats::rnorm(12), x = 1:12)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, family = gaussian(),
                control = drm_control(se = FALSE))
  saved <- if (exists(".Random.seed", inherits = FALSE)) get(".Random.seed") else NULL
  kind <- RNGkind()
  y1 <- drmTMB:::drm_bootstrap_replicate_simulation(fit, seed = 11L, index = 3L, re_form = NULL)
  y2 <- drmTMB:::drm_bootstrap_replicate_simulation(fit, seed = 11L, index = 3L, re_form = NULL)
  expect_equal(y1, y2)
  expect_length(y1, 1L)
  expect_equal(RNGkind(), kind)
  if (!is.null(saved)) {
    expect_equal(get(".Random.seed", inherits = FALSE), saved)
  }
})
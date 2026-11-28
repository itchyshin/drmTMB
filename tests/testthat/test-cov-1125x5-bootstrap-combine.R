# drm_bootstrap_combine from R/bootstrap-shards.R (beyond x3 shard validation).

mock_shard <- function(indices, seed = 1L, targets = "fixef:mu:(Intercept)") {
  header <- list(
    schema_version = 1L,
    package_version = "0.0.0",
    git_sha = "testsha",
    estimator = NULL,
    fit_fingerprint = list(
      formula = "y ~ x",
      family = "gaussian()",
      nobs = 10L,
      par = 1,
      objective = -1
    ),
    targets = targets,
    seed = seed,
    re_form = "NULL",
    refit = list(
      optimizer_method = "nlminb",
      optimizer_preset = "default",
      se = FALSE,
      multi_start = FALSE
    )
  )
  attempts <- data.frame(
    bootstrap = indices,
  parm = targets,
    refit_ok = TRUE,
    estimate_finite = TRUE,
    refit_status = "ok",
    stringsAsFactors = FALSE
  )
  structure(
    list(header = header, indices = indices, attempts = attempts),
    class = "drm_bootstrap_shard"
  )
}

test_that("drm_bootstrap_combine() rejects incompatible inputs", {
  expect_error(drmTMB:::drm_bootstrap_combine(list()), "drm_bootstrap_shard")
  expect_error(
    drmTMB:::drm_bootstrap_combine(mock_shard(1L), list()),
    "drm_bootstrap_shard"
  )
  s1 <- mock_shard(1L)
  s2 <- mock_shard(2L)
  s2$header$seed <- 2L
  expect_error(drmTMB:::drm_bootstrap_combine(s1, s2), "compatible")
  s3 <- mock_shard(1L)
  s4 <- mock_shard(1L)
  expect_error(drmTMB:::drm_bootstrap_combine(s3, s4), "overlap")
})

test_that("drm_bootstrap_combine() joins disjoint compatible shards", {
  s1 <- mock_shard(1:2)
  s2 <- mock_shard(3:4)
  joined <- drmTMB:::drm_bootstrap_combine(s1, s2)
  expect_s3_class(joined, "drm_bootstrap_shard")
  expect_equal(joined$indices, 1:4)
  expect_equal(nrow(joined$attempts), 4L)
})

test_that("drm_bootstrap_combine() accepts a bare list of shards", {
  shards <- list(mock_shard(1L), mock_shard(2L))
  joined <- drmTMB:::drm_bootstrap_combine(shards)
  expect_equal(joined$indices, 1:2)
})
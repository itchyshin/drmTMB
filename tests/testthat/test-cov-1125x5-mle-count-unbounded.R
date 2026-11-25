# Untested branches in R/mle-existence.R (separate from cov-1125x3 sep internals).

test_that("drm_count_family_success_failure() builds success/failure lists", {
  sf <- drmTMB:::drm_count_family_success_failure(c(0, 2, -1, 5))
  expect_equal(sf$successes, c(0, 1, 0, 1))
  expect_equal(sf$failures, rep(1, 4L))
  expect_length(sf$successes, 4L)
})

test_that("drm_unbounded_scale_families() lists allowed model types", {
  fams <- drmTMB:::drm_unbounded_scale_families()
  expect_true("gaussian" %in% fams)
  expect_true("gamma" %in% fams)
  expect_false("binomial" %in% fams)
})

test_that("drm_sep tolerances are small positive scalars", {
  expect_gt(drmTMB:::drm_sep_obj_tol(), 0)
  expect_gt(drmTMB:::drm_sep_coef_tol(), 0)
  expect_gt(drmTMB:::drm_sep_rank_tol(), 0)
  expect_gt(drmTMB:::drm_sep_resid_tol(), 0)
  expect_true(drmTMB:::drm_sep_max_iter(5L) >= 200L)
})

test_that("drm_glm_ray_screen() returns NULL for non-GLM types", {
  fake <- list(model = list(model_type = "gaussian", X = list(mu = matrix(1))))
  expect_null(drmTMB:::drm_glm_ray_screen(fake))
  bin <- list(
    model = list(
      model_type = "binomial",
      X = list(mu = NULL),
      has_known_v = FALSE
    )
  )
  expect_null(drmTMB:::drm_glm_ray_screen(bin))
})
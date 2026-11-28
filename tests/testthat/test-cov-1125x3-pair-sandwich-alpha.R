# Coverage for alpha-inference helpers in R/associate-pairs-sandwich.R.

mock_association <- function(alpha = 0.1, status = "interior", n = 500L,
                             pair_class = "gaussian_bernoulli") {
  design <- matrix(1, n, 1)
  colnames(design) <- "(Intercept)"
  structure(
    list(
      status = status,
      association_coefficients = setNames(alpha, "(Intercept)"),
      association_design = list(matrix = design),
      alpha_inference = list(
        status = "available",
        covariance = matrix(0.01, 1, 1),
        se = 0.1,
        capability_tier = "interval_feasible",
        reason = NA_character_
      ),
      components = list(pair_class = pair_class),
      diagnostics = list()
    ),
    class = "drm_pair_association"
  )
}

test_that("drm_pair_alpha_coefficient_names() labels intercept and slopes", {
  f <- drmTMB:::drm_pair_alpha_coefficient_names
  one <- mock_association()
  expect_identical(f(one), "alpha")
  two <- mock_association(alpha = c(0.1, 0.2))
  two$association_design$matrix <- matrix(
    rep(c(1, 2), each = 500L),
    ncol = 2L
  )
  colnames(two$association_design$matrix) <- c("x1", "x2")
  two$association_coefficients <- c(0.1, 0.2)
  names(two$association_coefficients) <- c("x1", "x2")
  expect_identical(f(two), c("alpha:x1", "alpha:x2"))
})

test_that("drm_pair_sandwich_unavailable() builds status objects", {
  u <- drmTMB:::drm_pair_sandwich_unavailable("rank deficient")
  expect_identical(u$status, "unavailable")
  expect_match(u$reason, "rank deficient")
})

test_that("drm_pair_public_alpha_inference() errors on bad association objects", {
  obj <- mock_association()
  expect_error(drmTMB:::drm_pair_public_alpha_inference(list()), "drm_pair_association")
  edge <- mock_association(status = "failed")
  expect_error(drmTMB:::drm_pair_public_alpha_inference(edge), "not interior")
  old <- mock_association()
  old$alpha_inference <- NULL
  expect_error(drmTMB:::drm_pair_public_alpha_inference(old), "predates")
  bad <- mock_association()
  bad$alpha_inference$status <- "unavailable"
  bad$alpha_inference$reason <- "singular"
  expect_error(drmTMB:::drm_pair_public_alpha_inference(bad), "unavailable")
  invalid <- mock_association()
  invalid$alpha_inference$covariance <- matrix(1, 1, 1)
  invalid$alpha_inference$se <- -1
  expect_error(drmTMB:::drm_pair_public_alpha_inference(invalid), "invalid")
})

test_that("drm_pair_warn_alpha_inference() emits expected warnings", {
  interior <- mock_association(n = 400L, pair_class = "bernoulli_nbinom2")
  expect_warning(
    drmTMB:::drm_pair_warn_alpha_inference(interior),
    class = "drmTMB_association_inference_warning"
  )
  boundary <- mock_association(status = "near_boundary")
  expect_warning(
    drmTMB:::drm_pair_warn_alpha_inference(boundary),
    class = "drmTMB_association_inference_warning"
  )
})
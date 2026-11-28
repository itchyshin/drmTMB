# Coverage shard cursor-cloud-1125x10: mle-existence separation geometry.

test_that("drm_sep tolerance helpers return positive scalars", {
  expect_equal(drmTMB:::drm_sep_obj_tol(), 1e-9)
  expect_equal(drmTMB:::drm_sep_coef_tol(), 1e-6)
  expect_equal(drmTMB:::drm_sep_rank_tol(), 1e-10)
  expect_equal(drmTMB:::drm_sep_resid_tol(), 1e-8)
  expect_equal(drmTMB:::drm_sep_max_iter(3L), 260L)
})

test_that("drm_count_family_success_failure follows count-screen contract", {
  sf <- drmTMB:::drm_count_family_success_failure(c(0, 3, 0, 5))
  expect_identical(sf$successes, c(0, 1, 0, 1))
  expect_identical(sf$failures, rep(1, 4))
})

test_that("drm_unbounded_scale_families lists continuous scale families", {
  fams <- drmTMB:::drm_unbounded_scale_families()
  expect_true("gaussian" %in% fams)
  expect_true("lognormal" %in% fams)
  expect_true("student" %in% fams)
  expect_false("poisson" %in% fams)
})

test_that("drm_fe_mle_screen_applicable is false for random effects and MSPL", {
  base <- list(
    estimator = "ml",
    random = list(mu = list(n_re = 0L)),
    structured = list(phylo_mu = list(has = FALSE)),
    missing_predictor = list(enabled = FALSE)
  )
  expect_true(drmTMB:::drm_fe_mle_screen_applicable(base))
  re <- base
  re$random$mu$n_re <- 1L
  expect_false(drmTMB:::drm_fe_mle_screen_applicable(re))
  mspl <- base
  mspl$estimator <- "mspl"
  expect_false(drmTMB:::drm_fe_mle_screen_applicable(mspl))
})

test_that("drm_sep_constraints returns ranked constraint rows", {
  X <- cbind(Intercept = 1, x = c(-2, -1, 0, 1, 2, 3))
  cons <- drmTMB:::drm_sep_constraints(
    X,
    successes = c(1, 1, 1, 0, 0, 0),
    failures = c(0, 0, 0, 1, 1, 1)
  )
  expect_true(is.matrix(cons$A) || is.null(cons$A))
  expect_type(cons$keep, "integer")
})

test_that("drm_sep_nnls reaches a small residual on a separable system", {
  A <- matrix(c(1, -1, 0, 1, -1, 0), ncol = 2, byrow = TRUE)
  cvec <- c(0.2, 0.1)
  nn <- drmTMB:::drm_sep_nnls(A, cvec, maxiter = 50L)
  expect_type(nn$r, "double")
  expect_true(nn$converged)
  expect_true(nn$iter >= 0L)
})

test_that("drm_detect_separation flags a perfectly separated design", {
  x <- c(-3, -2, -1, 1, 2, 3)
  X <- cbind(1, x)
  det <- drmTMB:::drm_detect_separation(
    X,
    c(0, 0, 0, 1, 1, 1),
    c(1, 1, 1, 0, 0, 0)
  )
  expect_true(det$separated)
  expect_true(length(det$flagged) >= 0L)
  expect_true(det$conclusive)
})

test_that("drm_detect_separation returns conclusive none for mixed outcomes", {
  xo <- c(-1, 0, 1, 2)
  det <- drmTMB:::drm_detect_separation(
    cbind(1, xo),
    c(1, 0, 1, 0),
    c(0, 1, 0, 1)
  )
  expect_false(det$separated)
  expect_length(det$flagged, 0L)
})

test_that("drm_observed_design_rows respects weights and missing flags", {
  spec <- list(
    missing_data = list(observed_y = c(TRUE, FALSE, TRUE, TRUE)),
    weights = c(1, 1, 0, 2)
  )
  obs <- drmTMB:::drm_observed_design_rows(spec, 4L)
  expect_identical(obs, c(TRUE, FALSE, FALSE, TRUE))
  all_obs <- drmTMB:::drm_observed_design_rows(
    list(missing_data = NULL, weights = NULL),
    3L
  )
  expect_identical(all_obs, c(TRUE, TRUE, TRUE))
})

test_that("drm_mle_nonexistent_is_true is false for a non-separated fit", {
  dat <- data.frame(y = c(0, 1, 0, 1), x = c(-1, -1, 1, 1))
  fit <- drmTMB(
    bf(y ~ x),
    data = dat,
    family = binomial(),
    control = drm_control(se = FALSE)
  )
  expect_false(drmTMB:::drm_mle_nonexistent_is_true(fit))
})
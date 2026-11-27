# refs coverage — mle-existence.R fixed-effect separation screen (27 Nov).

test_that("drm_fe_mle_screen_applicable() is false outside plain fixed-effect GLMs", {
  ok_spec <- list(
    estimator = "ml",
    random = list(mu = list(n_re = 0L)),
    structured = list(phylo_mu = list(has = FALSE)),
    missing_predictor = list(enabled = FALSE)
  )
  expect_true(drmTMB:::drm_fe_mle_screen_applicable(ok_spec))
  expect_false(drmTMB:::drm_fe_mle_screen_applicable(NULL))
  mspl <- ok_spec
  mspl$estimator <- "mspl"
  expect_false(drmTMB:::drm_fe_mle_screen_applicable(mspl))
  with_re <- ok_spec
  with_re$random$mu$n_re <- 3L
  expect_false(drmTMB:::drm_fe_mle_screen_applicable(with_re))
  with_phylo <- ok_spec
  with_phylo$structured$phylo_mu$has <- TRUE
  expect_false(drmTMB:::drm_fe_mle_screen_applicable(with_phylo))
  with_mi <- ok_spec
  with_mi$missing_predictor$enabled <- TRUE
  expect_false(drmTMB:::drm_fe_mle_screen_applicable(with_mi))
})

test_that("drm_sep_constraints() returns an empty constraint set with no informative rows", {
  out <- drmTMB:::drm_sep_constraints(
    matrix(0, 0L, 2L),
    numeric(0),
    numeric(0)
  )
  expect_equal(nrow(out$A), 0L)
  expect_length(out$keep, 0L)
})

test_that("drm_sep_nnls() converges on a one-row feasible cone", {
  A <- matrix(1, nrow = 1, ncol = 1)
  cvec <- c(1)
  sol <- drmTMB:::drm_sep_nnls(A, cvec, maxiter = 20L)
  expect_true(sol$converged)
  expect_lt(sqrt(sum(sol$r^2)), drmTMB:::drm_sep_resid_tol())
})

test_that("separation tolerances are fixed positive scalars", {
  expect_gt(drmTMB:::drm_sep_obj_tol(), 0)
  expect_gt(drmTMB:::drm_sep_rank_tol(), 0)
  expect_gt(drmTMB:::drm_sep_max_iter(4L), 200L)
})
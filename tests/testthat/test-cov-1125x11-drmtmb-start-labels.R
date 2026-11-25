# Coverage: public start-label parsing and phylo dense-index helpers in R/drmTMB.R.

test_that("drm_parse_public_start_label recognises fixef and RE families", {
  p <- drmTMB:::drm_parse_public_start_label("fixef:mu:(Intercept)")
  expect_equal(p$family, "fixef")
  expect_equal(p$dpar, "mu")
  expect_equal(p$target, "(Intercept)")
  sd <- drmTMB:::drm_parse_public_start_label("sd:sigma:(1 | id)")
  expect_equal(sd$family, "sd")
  expect_equal(sd$dpar, "sigma")
  expect_equal(sd$target, "(1 | id)")
  cor <- drmTMB:::drm_parse_public_start_label("cor:mu:x")
  expect_equal(cor$family, "cor")
  expect_null(drmTMB:::drm_parse_public_start_label("not_a_label"))
  expect_null(drmTMB:::drm_parse_public_start_label(c("a", "b")))
  expect_null(drmTMB:::drm_parse_public_start_label(NA_character_))
})

test_that("drm_parse_public_start_label parses phylo_sd and phylo_cor", {
  ps <- drmTMB:::drm_parse_public_start_label("phylo_sd:mu1")
  expect_equal(ps$family, "phylo_sd")
  expect_true(is.na(ps$dpar))
  expect_equal(ps$target, "mu1")
  pc <- drmTMB:::drm_parse_public_start_label("phylo_cor:mu1:mu2")
  expect_equal(pc$family, "phylo_cor")
  expect_equal(pc$dpar, "mu1")
  expect_equal(pc$target, "mu2")
  pt <- drmTMB:::drm_parse_public_start_label("phylo_theta:sigma1:sigma2")
  expect_equal(pt$family, "phylo_theta")
  expect_equal(pt$dpar, "sigma1")
  expect_equal(pt$target, "sigma2")
})

test_that("drm_check_phylo_cor_start_value enforces the correlation bound", {
  expect_equal(
    drmTMB:::drm_check_phylo_cor_start_value(0.2, "phylo_cor:mu1:mu2", "test"),
    0.2
  )
  expect_error(
    drmTMB:::drm_check_phylo_cor_start_value(1, "phylo_cor:mu1:mu2", "test"),
    "correlation"
  )
  expect_error(
    drmTMB:::drm_check_phylo_cor_start_value(NA_real_, "label", "test"),
    "correlation"
  )
  expect_equal(drmTMB:::drm_phylo_cor_bound, 0.999999)
})

test_that("drm_phylo_mu_dense_theta_index orders q4 Cholesky cells", {
  phylo_mu <- list(has = TRUE, q = 4L, dpars = c("mu1", "mu2", "sigma1", "sigma2"))
  expect_equal(drmTMB:::drm_phylo_mu_dense_theta_index(phylo_mu, "mu1", "mu2"), 1L)
  expect_equal(drmTMB:::drm_phylo_mu_dense_theta_index(phylo_mu, "mu2", "sigma1"), 3L)
  expect_equal(drmTMB:::drm_phylo_mu_dense_theta_index(phylo_mu, "sigma2", "sigma1"), 6L)
  expect_true(is.na(drmTMB:::drm_phylo_mu_dense_theta_index(phylo_mu, "mu1", "mu1")))
  expect_true(is.na(drmTMB:::drm_phylo_mu_dense_theta_index(phylo_mu, "mu1", "absent")))
})

test_that("drm_phylo_mu_axis_labels disambiguates duplicated dpars", {
  phylo_mu <- list(
    has = TRUE,
    q = 2L,
    dpars = c("mu", "mu"),
    coef_names = c("(Intercept)", "x")
  )
  labs <- drmTMB:::drm_phylo_mu_axis_labels(phylo_mu)
  expect_equal(labs, c("mu:(Intercept)", "mu:x"))
  simple <- list(has = TRUE, q = 2L, dpars = c("mu1", "mu2"))
  expect_equal(drmTMB:::drm_phylo_mu_axis_labels(simple), c("mu1", "mu2"))
})

test_that("phylo_mu_dpar_codes and response_codes classify endpoints", {
  phylo <- list(has = TRUE, q = 2L, dpars = c("mu1", "sigma2"))
  expect_equal(drmTMB:::phylo_mu_dpar_codes(phylo), c(0L, 1L))
  expect_equal(drmTMB:::phylo_mu_response_codes(phylo), c(1L, 2L))
  inactive <- list(has = FALSE)
  expect_equal(drmTMB:::phylo_mu_dpar_codes(inactive), 0L)
  expect_equal(drmTMB:::phylo_mu_response_codes(inactive), 0L)
})

test_that("phylo_mu_dpars defaults for bivariate phylo blocks", {
  expect_equal(drmTMB:::phylo_mu_dpars(list(q = 2L)), c("mu1", "mu2"))
  expect_equal(drmTMB:::phylo_mu_dpars(list(dpars = "sigma")), "sigma")
  expect_equal(drmTMB:::phylo_mu_dpars(list()), "mu")
  expect_equal(
    drmTMB:::phylo_mu_endpoint_dpars(list(q = 3L, dpars = "mu")),
    rep("mu", 3L)
  )
})

test_that("drm_parse_public_start_label rejects incomplete phylo tokens", {
  expect_null(drmTMB:::drm_parse_public_start_label("phylo_cor:onlyone"))
  expect_null(drmTMB:::drm_parse_public_start_label("fixef:onlytwo"))
  expect_null(drmTMB:::drm_parse_public_start_label(""))
  m <- drmTMB:::drm_parse_public_start_label("fixef:sigma:log(x)")
  expect_equal(m$target, "log(x)")
})

test_that("drm_estimator_exact classifies Gaussian REML eligibility", {
  expect_true(is.na(drmTMB:::drm_estimator_exact(list(estimator = "ML"))))
  expect_false(
    drmTMB:::drm_estimator_exact(list(estimator = "REML", model_type = "poisson"))
  )
  ok <- list(
    estimator = "REML",
    model_type = "gaussian",
    tmb_random_names = character()
  )
  expect_true(drmTMB:::drm_estimator_exact(ok))
  bad <- list(
    estimator = "REML",
    model_type = "gaussian",
    tmb_random_names = "beta_sigma"
  )
  expect_false(drmTMB:::drm_estimator_exact(bad))
})
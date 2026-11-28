# R/sparse-fixed.R design-matrix parity and TMB payload helpers.

test_that("drm_fixed_effect_matrix() returns dense or sparse designs", {
  dat <- data.frame(y = 1:3, x = c(0, 1, 2), g = factor(c("a", "b", "a")))
  terms <- stats::terms(y ~ x + g, data = dat)
  dense <- drmTMB:::drm_fixed_effect_matrix(terms, dat, sparse = FALSE)
  sparse <- drmTMB:::drm_fixed_effect_matrix(terms, dat, sparse = TRUE)
  expect_false(inherits(dense, "dgCMatrix"))
  expect_s4_class(sparse, "dgCMatrix")
  expect_equal(dim(dense), dim(sparse))
})

test_that("drm_fixed_effect_is_sparse() reads the model flag", {
  fit <- list(model = list(sparse_fixed = list(mu = TRUE, sigma = FALSE)))
  expect_true(drmTMB:::drm_fixed_effect_is_sparse(fit, "mu"))
  expect_false(drmTMB:::drm_fixed_effect_is_sparse(fit, "sigma"))
  expect_false(drmTMB:::drm_fixed_effect_is_sparse(list(model = list()), "mu"))
})

test_that("drm_sparse_fixed_tmb_data() marks sparse mu and supplies matrix", {
  spec <- list(
    sparse_fixed = list(mu = TRUE),
    X = list(mu = Matrix::sparseMatrix(i = 1, j = 1, x = 1, dims = c(2L, 1L)))
  )
  td <- drmTMB:::drm_sparse_fixed_tmb_data(spec)
  expect_identical(td$use_sparse_X_mu, 1L)
  expect_s4_class(td$X_mu_sparse, "dgCMatrix")
  spec2 <- list(sparse_fixed = list(mu = FALSE), X = list(mu = matrix(1, 1, 1)))
  td2 <- drmTMB:::drm_sparse_fixed_tmb_data(spec2)
  expect_identical(td2$use_sparse_X_mu, 0L)
})

test_that("drm_sparse_fixed_parity() reports numeric agreement", {
  dat <- data.frame(y = rnorm(6), x = rnorm(6))
  terms <- stats::terms(y ~ x, data = dat)
  chk <- drmTMB:::drm_sparse_fixed_parity(terms, dat)
  expect_true(chk$same_shape)
  expect_true(chk$same_names)
  expect_lt(chk$max_abs_matrix_diff, 1e-12)
  expect_lt(chk$max_abs_eta_diff, 1e-12)
})

test_that("drm_sparse_fixed_parity() validates beta length", {
  dat <- data.frame(y = 1:2, x = 1:2)
  terms <- stats::terms(y ~ x, data = dat)
  expect_error(
    drmTMB:::drm_sparse_fixed_parity(terms, dat, beta = 1),
    "beta"
  )
})
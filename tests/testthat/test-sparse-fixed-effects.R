test_that("internal sparse fixed-effect matrices match dense model matrices", {
  dat <- data.frame(
    y = rnorm(18),
    habitat = factor(
      rep(c("forest", "reef", "grass"), each = 6),
      levels = c("forest", "reef", "grass", "unused")
    ),
    season = factor(rep(c("dry", "wet", "dry"), each = 6)),
    x = rep(seq(-1, 1, length.out = 6), times = 3)
  )
  terms <- stats::terms(y ~ habitat + season + habitat:x)
  parity <- drmTMB:::drm_sparse_fixed_parity(terms, dat)

  expect_s4_class(parity$sparse, "sparseMatrix")
  expect_true(parity$same_shape)
  expect_true(parity$same_names)
  expect_equal(parity$max_abs_matrix_diff, 0)
  expect_equal(parity$max_abs_eta_diff, 0, tolerance = 1e-12)
  expect_equal(colnames(parity$dense), colnames(parity$sparse))
})

test_that("fixed-effect design summary records sparse matrix density", {
  dat <- data.frame(
    y = rnorm(12),
    group = factor(rep(paste0("g", seq_len(6)), each = 2))
  )
  terms <- stats::terms(y ~ group)
  sparse <- drmTMB:::drm_fixed_effect_matrix(terms, dat, sparse = TRUE)
  summary <- drmTMB:::fixed_effect_design_summary(list(mu = sparse))

  expect_equal(summary$dpar, "mu")
  expect_s4_class(sparse, "sparseMatrix")
  expect_equal(summary$matrix_class, class(sparse)[[1L]])
  expect_equal(summary$n_rows, nrow(sparse))
  expect_equal(summary$n_cols, ncol(sparse))
  expect_equal(summary$n_nonzero, Matrix::nnzero(sparse))
  expect_equal(summary$density, Matrix::nnzero(sparse) / prod(dim(sparse)))
})

test_that("sparse fixed-effect parity helper checks beta length", {
  dat <- data.frame(y = rnorm(4), x = c(-1, 0, 1, 2))
  terms <- stats::terms(y ~ x)

  expect_snapshot(
    error = TRUE,
    drmTMB:::drm_sparse_fixed_parity(terms, dat, beta = 1)
  )
})

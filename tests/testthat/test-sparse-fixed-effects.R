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

test_that("sparse Gaussian mu fixed effects match dense fits", {
  set.seed(20260514)
  n <- 80
  dat <- data.frame(
    y = stats::rnorm(n),
    x = stats::rnorm(n),
    habitat = factor(
      sample(c("forest", "reef", "grass"), n, replace = TRUE),
      levels = c("forest", "reef", "grass", "unused")
    ),
    season = factor(sample(c("dry", "wet"), n, replace = TRUE))
  )
  dat$y <- 0.4 +
    0.2 * dat$x +
    c(forest = 0.1, reef = -0.2, grass = 0.3, unused = 0)[dat$habitat] +
    stats::rnorm(n, sd = 0.5)
  form <- bf(y ~ x + habitat + habitat:season, sigma ~ 1)

  dense <- drmTMB(
    form,
    data = dat,
    control = drm_control(optimizer = list(eval.max = 200, iter.max = 200))
  )
  sparse <- drmTMB(
    form,
    data = dat,
    control = drm_control(
      sparse_fixed = TRUE,
      optimizer = list(eval.max = 200, iter.max = 200)
    )
  )
  newdata <- dat[1:4, , drop = FALSE]

  expect_s4_class(sparse$model$X$mu, "sparseMatrix")
  expect_equal(sparse$model$tmb_data$use_sparse_X_mu, 1L)
  expect_equal(dense$opt$convergence, 0L)
  expect_equal(sparse$opt$convergence, 0L)
  expect_equal(coef(sparse, "mu"), coef(dense, "mu"), tolerance = 1e-4)
  expect_equal(coef(sparse, "sigma"), coef(dense, "sigma"), tolerance = 1e-4)
  expect_equal(
    as.numeric(logLik(sparse)),
    as.numeric(logLik(dense)),
    tolerance = 1e-5
  )
  expect_equal(fitted(sparse), fitted(dense), tolerance = 1e-5)
  expect_equal(
    predict(sparse, type = "link"),
    predict(dense, type = "link"),
    tolerance = 1e-5
  )
  expect_equal(
    predict(sparse, newdata = newdata, type = "link"),
    predict(dense, newdata = newdata, type = "link"),
    tolerance = 1e-5
  )
  expect_equal(residuals(sparse), residuals(dense), tolerance = 1e-5)
  expect_equal(
    simulate(sparse, seed = 20260514),
    simulate(dense, seed = 20260514),
    tolerance = 1e-5
  )

  chk <- check_drm(sparse)
  design <- chk[chk$check == "fixed_effect_design_size", ]
  expect_equal(design$status, "ok")
  expect_match(design$value, "largest_class=dgCMatrix")
  expect_match(design$message, "Sparse fixed-effect design matrices")
})

test_that("sparse Gaussian mu fixed effects work with memory-light storage", {
  set.seed(20260515)
  dat <- data.frame(
    y = stats::rnorm(30),
    x = stats::rnorm(30),
    group = factor(rep(letters[1:10], each = 3))
  )
  fit <- drmTMB(
    bf(y ~ x + group, sigma ~ 1),
    data = dat,
    control = drm_control(
      sparse_fixed = TRUE,
      keep_data = FALSE,
      keep_model_frame = FALSE,
      keep_tmb_object = FALSE,
      optimizer = list(eval.max = 160, iter.max = 160)
    )
  )

  expect_null(fit$data)
  expect_null(fit$model$model_frame)
  expect_null(fit$obj)
  expect_s4_class(fit$model$X$mu, "sparseMatrix")
  expect_type(predict(fit, dpar = "mu"), "double")
  expect_type(residuals(fit), "double")
})

test_that("sparse fixed-effect parity reports same_names from column names only", {
  # Row names and other dimname attributes may differ between the dense and
  # sparse builders; same_names should track the load-bearing column names, not
  # full dimnames, so numerically identical designs are not flagged as failures.
  dat <- data.frame(
    y = rnorm(12),
    f = factor(rep(c("a", "b", "c"), 4)),
    x = rnorm(12)
  )
  terms <- stats::terms(y ~ f + x)
  parity <- drmTMB:::drm_sparse_fixed_parity(terms, dat)

  expect_identical(
    parity$same_names,
    identical(colnames(parity$dense), colnames(parity$sparse))
  )
  expect_true(parity$same_names)
  expect_equal(parity$max_abs_matrix_diff, 0)

  # Even if row names diverge between builders, parity should still hold because
  # same_names ignores row names.
  expect_true(
    parity$same_names ||
      !identical(rownames(parity$dense), rownames(parity$sparse))
  )
})

test_that("sparse fixed-effect parity helper checks beta length", {
  dat <- data.frame(y = rnorm(4), x = c(-1, 0, 1, 2))
  terms <- stats::terms(y ~ x)

  expect_snapshot(
    error = TRUE,
    drmTMB:::drm_sparse_fixed_parity(terms, dat, beta = 1)
  )
})

test_that("sparse fixed-effect fitting rejects unsupported first-slice models", {
  dat <- data.frame(
    y = rnorm(12),
    x = rnorm(12),
    id = factor(rep(letters[1:4], each = 3))
  )

  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1),
      data = dat,
      control = drm_control(sparse_fixed = TRUE)
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ x, sigma ~ x),
      data = dat,
      control = drm_control(sparse_fixed = TRUE)
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ x),
      family = poisson(),
      data = transform(dat, y = rpois(12, 2)),
      control = drm_control(sparse_fixed = TRUE)
    )
  )
})

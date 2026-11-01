# Direct tests of the internal helpers in R/gaussian-aggregation.R. The
# companion file test-gaussian-aggregation.R exercises them through drmTMB().

gaussian_helper_design <- function(n = 40L, seed = 1586L) {
  set.seed(seed)
  cell <- rep(1:4, length.out = n)
  x1 <- c(-1, -0.2, 0.5, 1.3)[cell]
  x2 <- c(0, 1, 0, 1)[cell]
  list(
    y = stats::rnorm(n, mean = 0.5 * x1, sd = 0.8),
    X_mu = cbind(`(Intercept)` = 1, x1 = x1, x2 = x2),
    X_sigma = cbind(`(Intercept)` = 1, x2 = x2),
    weights = sample(1:3, n, replace = TRUE),
    offset_mu = c(0.3, -0.2, 0.1, 0.4)[cell],
    offset_sigma = c(0.05, -0.1, 0.2, 0)[cell],
    cell = cell
  )
}

test_that("aggregated and full-row Gaussian log-likelihoods agree", {
  d <- gaussian_helper_design()
  agg <- drmTMB:::drm_gaussian_aggregation(
    d$y, d$X_mu, d$X_sigma,
    offset_mu = d$offset_mu, offset_sigma = d$offset_sigma
  )
  grid <- list(
    list(c(0, 0, 0), c(0, 0)),
    list(c(0.3, -0.1, 0.2), c(-0.5, 0.2)),
    list(c(-1.2, 0.7, 1.1), c(0.4, -0.6)),
    list(c(2, 0, -2), c(-1, 1))
  )
  for (p in grid) {
    full <- drmTMB:::drm_gaussian_full_loglik(
      d$y, d$X_mu, d$X_sigma, p[[1]], p[[2]],
      offset_mu = d$offset_mu, offset_sigma = d$offset_sigma
    )
    aggregated <- drmTMB:::drm_gaussian_aggregated_loglik(agg, p[[1]], p[[2]])
    expect_equal(aggregated, full, tolerance = 1e-8)
  }
})

test_that("aggregation statistics match base-R per-cell summaries", {
  d <- gaussian_helper_design()
  agg <- drmTMB:::drm_gaussian_aggregation(
    d$y, d$X_mu, d$X_sigma,
    offset_mu = d$offset_mu, offset_sigma = d$offset_sigma
  )
  expect_true(agg$enabled)
  expect_equal(agg$n_original, 40L)
  expect_equal(agg$n_cells, 4L)
  expect_equal(agg$row_to_cell, d$cell)
  expect_equal(agg$cell_first_row, 1:4)

  f <- factor(d$cell)
  expect_equal(agg$n, as.numeric(tapply(d$y, f, length)))
  expect_equal(agg$sum_y, as.numeric(tapply(d$y, f, sum)))
  expect_equal(agg$mean_y, as.numeric(tapply(d$y, f, mean)))
  expect_equal(
    agg$css,
    as.numeric(tapply(d$y, f, function(v) sum((v - mean(v))^2)))
  )
  ag <- stats::aggregate(y ~ cell, data = data.frame(y = d$y, cell = d$cell), mean)
  expect_equal(agg$mean_y, ag$y)

  expect_equal(agg$X_mu, d$X_mu[1:4, , drop = FALSE])
  expect_equal(agg$X_sigma, d$X_sigma[1:4, , drop = FALSE])
  expect_equal(agg$offset_mu, d$offset_mu[1:4])
  expect_equal(agg$offset_sigma, d$offset_sigma[1:4])
})

test_that("cells are numbered in order of first appearance", {
  d <- gaussian_helper_design()
  ord <- c(3L, 3L, 1L, 4L, 2L, 1L, 2L, 4L)
  idx <- c(ord, rep(1:4, length.out = 32L))
  agg <- drmTMB:::drm_gaussian_aggregation(
    d$y[seq_along(idx)], d$X_mu[idx, ], d$X_sigma[idx, ],
    offset_mu = d$offset_mu[idx], offset_sigma = d$offset_sigma[idx]
  )
  expect_equal(agg$cell_first_row, c(1L, 3L, 4L, 5L))
  expect_equal(agg$row_to_cell[1:8], c(1L, 1L, 2L, 3L, 4L, 2L, 4L, 3L))
  expect_equal(agg$X_mu, d$X_mu[c(3, 1, 4, 2), , drop = FALSE])
})

test_that("unit weights are accepted and other weights are refused", {
  d <- gaussian_helper_design()
  expect_true(any(d$weights != 1))
  unit <- drmTMB:::drm_gaussian_aggregation(
    d$y, d$X_mu, d$X_sigma, weights = rep(1, length(d$y)),
    offset_mu = d$offset_mu, offset_sigma = d$offset_sigma
  )
  expect_equal(unit$n_cells, 4L)
  expect_error(
    drmTMB:::drm_gaussian_aggregation(
      d$y, d$X_mu, d$X_sigma, weights = d$weights,
      offset_mu = d$offset_mu, offset_sigma = d$offset_sigma
    ),
    "unit likelihood weights"
  )
})

test_that("different offsets split cells that share the same X", {
  n <- 12L
  y <- seq(-1, 1, length.out = n)
  X <- matrix(1, nrow = n, ncol = 1L)
  base <- drmTMB:::drm_gaussian_aggregation(y, X, X)
  expect_equal(base$n_cells, 1L)

  off_mu <- rep(c(0, 0.5, 0), each = 4L)
  by_mu <- drmTMB:::drm_gaussian_aggregation(y, X, X, offset_mu = off_mu)
  expect_equal(by_mu$n_cells, 2L)
  expect_equal(by_mu$n, as.numeric(table(factor(off_mu, unique(off_mu)))))

  off_sigma <- rep(c(0, 0.1), length.out = n)
  by_sigma <- drmTMB:::drm_gaussian_aggregation(y, X, X, offset_sigma = off_sigma)
  expect_equal(by_sigma$n_cells, 2L)

  both <- drmTMB:::drm_gaussian_aggregation(
    y, X, X, offset_mu = off_mu, offset_sigma = off_sigma
  )
  expect_equal(
    both$n_cells,
    nrow(unique(cbind(off_mu, off_sigma)))
  )
  full <- drmTMB:::drm_gaussian_full_loglik(
    y, X, X, 0.1, -0.2, offset_mu = off_mu, offset_sigma = off_sigma
  )
  expect_equal(
    drmTMB:::drm_gaussian_aggregated_loglik(both, 0.1, -0.2),
    full,
    tolerance = 1e-8
  )
})

test_that("input validation hits each abort branch", {
  v <- drmTMB:::drm_validate_gaussian_aggregation_input
  X <- matrix(1, nrow = 3L, ncol = 1L)
  y <- c(0.1, 0.2, 0.3)
  z <- rep(0, 3L)

  expect_true(v(y, X, X, rep(1, 3L), z, z))
  expect_error(
    v(numeric(), matrix(0, 0L, 1L), matrix(0, 0L, 1L), numeric(), numeric(), numeric()),
    "at least one response row"
  )
  expect_error(
    v(y, X[1:2, , drop = FALSE], X, rep(1, 3L), z, z),
    "matching row counts"
  )
  expect_error(
    v(y, X, X[1:2, , drop = FALSE], rep(1, 3L), z, z),
    "matching row counts"
  )
  expect_error(v(y, X, X, rep(1, 2L), z, z), "one value per response row")
  expect_error(v(y, X, X, rep(1, 3L), z[1:2], z), "one value per response row")
  expect_error(v(y, X, X, rep(1, 3L), z, z[1:2]), "one value per response row")

  bad <- c(NA_real_, Inf, -Inf, NaN)
  for (b in bad) {
    yb <- y
    yb[2L] <- b
    expect_error(v(yb, X, X, rep(1, 3L), z, z), "finite response")
  }
  Xb <- X
  Xb[1L, 1L] <- Inf
  expect_error(v(y, Xb, X, rep(1, 3L), z, z), "finite response")
  expect_error(v(y, X, Xb, rep(1, 3L), z, z), "finite response")
  expect_error(v(y, X, X, c(1, NA, 1), z, z), "finite response")
  expect_error(v(y, X, X, rep(1, 3L), c(0, NA, 0), z), "finite response")
  expect_error(v(y, X, X, rep(1, 3L), z, c(0, Inf, 0)), "finite response")
  # Non-numeric design matrices are never finite.
  Xc <- matrix(c("a", "b", "c"), nrow = 3L)
  expect_error(v(y, Xc, X, rep(1, 3L), z, z), "finite response")
  expect_error(
    drmTMB:::drm_gaussian_aggregation(y, Xc, X),
    "finite response"
  )
})

test_that("weight validation refuses zero, negative, and non-unit weights", {
  w <- drmTMB:::drm_validate_gaussian_aggregation_weights
  expect_true(w(rep(1, 5L)))
  expect_error(w(c(1, 0, 1)), "unit likelihood weights")
  expect_error(w(c(1, -1, 1)), "unit likelihood weights")
  expect_error(w(c(1, 2, 1)), "unit likelihood weights")
  expect_error(w(rep(0.5, 3L)), "unit likelihood weights")
})

test_that("parity helper checks coefficient lengths", {
  d <- gaussian_helper_design()
  expect_error(
    drmTMB:::drm_gaussian_aggregation_parity(
      d$y, d$X_mu, d$X_sigma, beta_mu = c(0, 1), beta_sigma = c(0, 0)
    ),
    "beta_mu"
  )
  expect_error(
    drmTMB:::drm_gaussian_aggregation_parity(
      d$y, d$X_mu, d$X_sigma, beta_mu = c(0, 1, 2), beta_sigma = 0
    ),
    "beta_sigma"
  )
})

test_that("empty_gaussian_aggregation() is disabled with zero-length slots", {
  e <- drmTMB:::empty_gaussian_aggregation()
  expect_false(e$enabled)
  expect_identical(e$n_original, 0L)
  expect_identical(e$n_cells, 0L)
  for (nm in c(
    "row_to_cell", "cell_first_row", "n", "sum_y", "mean_y", "css",
    "offset_mu", "offset_sigma"
  )) {
    expect_length(e[[nm]], 0L)
  }
  expect_equal(dim(e$X_mu), c(0L, 0L))
  expect_equal(dim(e$X_sigma), c(0L, 0L))
  expect_null(drmTMB:::drm_gaussian_aggregation_summary(e))
  expect_null(drmTMB:::drm_gaussian_aggregation_summary(NULL))
})

test_that("aggregation summary returns the documented fields", {
  d <- gaussian_helper_design()
  agg <- drmTMB:::drm_gaussian_aggregation(
    d$y, d$X_mu, d$X_sigma,
    offset_mu = d$offset_mu, offset_sigma = d$offset_sigma
  )
  s <- drmTMB:::drm_gaussian_aggregation_summary(agg)
  expect_s3_class(s, "data.frame")
  expect_named(
    s,
    c("original_rows", "aggregation_cells", "compression_ratio", "largest_cell_n")
  )
  expect_equal(nrow(s), 1L)
  expect_equal(s$original_rows, 40L)
  expect_equal(s$aggregation_cells, 4L)
  expect_equal(s$compression_ratio, 10)
  expect_equal(s$largest_cell_n, 10)
})

test_that("TMB data builder reflects enabled and disabled aggregation", {
  d <- gaussian_helper_design()
  agg <- drmTMB:::drm_gaussian_aggregation(
    d$y, d$X_mu, d$X_sigma,
    offset_mu = d$offset_mu, offset_sigma = d$offset_sigma
  )
  on <- drmTMB:::drm_gaussian_aggregation_tmb_data(
    list(aggregation = list(gaussian = agg))
  )
  expect_identical(on$use_gaussian_aggregation, 1L)
  expect_identical(on$n_agg, 4L)
  expect_equal(on$agg_n, agg$n)
  expect_equal(on$agg_mean_y, agg$mean_y)
  expect_equal(on$agg_css, agg$css)
  expect_equal(on$X_mu_agg, agg$X_mu)
  expect_equal(on$offset_sigma_agg, agg$offset_sigma)

  for (spec in list(
    list(),
    list(aggregation = NULL),
    list(aggregation = list(gaussian = drmTMB:::empty_gaussian_aggregation()))
  )) {
    off <- drmTMB:::drm_gaussian_aggregation_tmb_data(spec)
    expect_identical(off$use_gaussian_aggregation, 0L)
    expect_identical(off$n_agg, 0L)
    expect_equal(dim(off$X_mu_agg), c(1L, 1L))
    expect_length(off$agg_n, 1L)
  }
})

# The end-to-end drmTMB() agreement on logLik and coefficients (1e-6 / 1e-5)
# is already asserted in test-gaussian-aggregation.R ("fitting matches
# full-row Gaussian fits"), so it is not duplicated here.

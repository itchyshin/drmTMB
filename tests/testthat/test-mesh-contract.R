test_that("spatial parser records a mesh object but fitting remains a bounded route", {
  parsed <- drmTMB:::parse_structured_marker_call(
    quote(spatial(1 | site, mesh = mesh)), "spatial", "mu"
  )
  expect_identical(parsed$type, "spatial")
  expect_identical(parsed$structure, "mesh")
  expect_identical(parsed$object, "mesh")

  expect_error(
    drmTMB:::parse_structured_marker_call(
      quote(spatial(1 | site, coords = coords, mesh = mesh)), "spatial", "mu"
    ),
    "exactly one"
  )
})

test_that("mesh syntax remains rejected outside the Gaussian mu intercept slice", {
  dat <- data.frame(y = c(0, 1, 2), site = c("a", "b", "c"))
  mesh <- structure(list(), class = "drmTMBmesh")
  expect_error(
    drmTMB(bf(y ~ spatial(1 + y | site, mesh = mesh)), gaussian(), dat),
    "intercept"
  )
  expect_error(
    drmTMB(bf(y ~ 1, sigma ~ spatial(1 | site, mesh = mesh)), gaussian(), dat),
    "mesh"
  )
})

test_that("fixed-kappa mesh Gaussian fits use the projection field and public extractors", {
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")
  dat <- data.frame(
    y = c(1.1, 1.7, 2.4, 2.0),
    lon = c(-123.10, -123.05, -123.00, -123.07),
    lat = c(49.20, 49.23, 49.21, 49.25),
    site = letters[1:4]
  )
  xy <- spatial_coords(dat, lon, lat, crs_out = 32610)
  mesh <- make_mesh(xy, kappa = 1 / 10000)
  fit <- drmTMB(
    bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1),
    family = gaussian(), data = dat
  )

  expect_true(isTRUE(fit$model$structured$mesh_spatial_mu$has))
  expect_equal(nrow(fit$model$structured$mesh_spatial_mu$projection), nrow(dat))
  expect_true("spatial(1 | site)" %in% names(fit$sdpars$mu))
  expect_named(fit$random_effects, "spatial_mu")
  expect_length(fit$random_effects$spatial_mu$projected, nrow(dat))
  expect_identical(fit$random_effects$spatial_mu$kappa_fixed, 1 / 10000)
  expect_length(ranef(fit, "spatial_mu")$projected, nrow(dat))
  mesh_check <- check_drm(fit)
  mesh_check <- mesh_check[mesh_check$check == "mesh_spatial_mu_diagnostics", , drop = FALSE]
  expect_equal(nrow(mesh_check), 1L)
  expect_match(mesh_check$value, "kappa_fixed=")
  expect_match(mesh_check$message, "field-scale fit only")
  target <- profile_targets(fit)
  target <- target[target$parm == "sd:mu:spatial(1 | site)", , drop = FALSE]
  expect_identical(target$tmb_parameter, "log_sd_phylo2")
  expect_false(target$profile_ready)
  expect_identical(target$profile_note, "mesh_field_scale_intervals_unvalidated")

  latent <- fit$random_effects$spatial_mu$latent
  Q <- fit$model$structured$mesh_spatial_mu$precision$precision
  A <- fit$model$structured$mesh_spatial_mu$projection
  report <- fit$obj$report()
  expect_equal(
    as.numeric(A %*% latent), as.numeric(report$mesh_effect), tolerance = 1e-10
  )
  expect_equal(
    sum(latent * as.numeric(Q %*% latent)), as.numeric(report$quadratic_mesh),
    tolerance = 1e-10
  )
  # Gaussian integration gives an independent dense marginal likelihood:
  # y ~ N(X beta, sigma^2 I + s^2 A Q^-1 A').  This does not reuse TMB's
  # random-effect objective or its sparse factorization.
  field_scale <- fit$sdpars$mu[["spatial(1 | site)"]]
  residual_sd <- exp(unname(fit$coefficients$sigma[["(Intercept)"]]))
  marginal_cov <- residual_sd^2 * diag(nrow(A)) +
    field_scale^2 * as.matrix(A) %*% solve(as.matrix(Q), t(as.matrix(A)))
  residual <- dat$y - unname(fit$coefficients$mu[["(Intercept)"]])
  dense_nll <- 0.5 * (
    length(residual) * log(2 * pi) +
      as.numeric(determinant(marginal_cov, logarithm = TRUE)$modulus) +
      drop(crossprod(residual, solve(marginal_cov, residual)))
  )
  expect_equal(fit$opt$objective, dense_nll, tolerance = 1e-7)
  expect_error(
    drmTMB(
      bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1),
      family = gaussian(), data = dat, REML = TRUE
    ),
    "REML = FALSE"
  )
  expect_error(
    drmTMB(
      bf(y ~ spatial(1 | site, mesh = mesh)),
      family = poisson(), data = dat
    ),
    "Gaussian"
  )
  expect_error(
    drmTMB(
      bf(y ~ spatial(1 | p | site, mesh = mesh), sigma ~ 1),
      family = gaussian(), data = dat
    ),
    "unlabelled"
  )
  expect_error(
    drmTMB(
      bf(y ~ spatial(1 | site, mesh = mesh, coords = xy), sigma ~ 1),
      family = gaussian(), data = dat
    ),
    "exactly one"
  )
  missing_dat <- dat
  missing_dat$y[1] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1),
      family = gaussian(), data = missing_dat,
      missing = miss_control(response = "include")
    ),
    "missing-data"
  )
})

test_that("mesh projection follows retained model-row identifiers after permutation", {
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")
  dat <- data.frame(
    y = c(1.1, 1.7, 2.4, 2.0, 1.5, 2.2, 1.9, 2.7),
    lon = c(-123.10, -123.05, -123.00, -123.07,
            -123.12, -123.02, -123.09, -122.98),
    lat = c(49.20, 49.23, 49.21, 49.25,
            49.27, 49.18, 49.16, 49.26),
    site = letters[1:8]
  )
  mesh <- make_mesh(spatial_coords(dat, lon, lat, crs_out = 32610), kappa = 1 / 10000)
  shuffled <- dat[c(8, 2, 5, 1, 7, 3, 6, 4), ]
  fit <- drmTMB(
    bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1),
    family = gaussian(), data = shuffled
  )

  expect_identical(
    fit$model$structured$mesh_spatial_mu$observation_ids,
    rownames(shuffled)
  )
  expect_identical(names(fit$random_effects$spatial_mu$projected), rownames(shuffled))
})

test_that("fixed-kappa mesh smoke recovers an interior GMRF field scale", {
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")
  set.seed(20260802)
  n_site <- 64L
  coords <- cbind(runif(n_site, 0, 100000), runif(n_site, 0, 100000))
  rownames(coords) <- as.character(seq_len(n_site))
  attr(coords, "crs") <- sf::st_crs(3857)
  class(coords) <- c("drmTMB_coords", class(coords))
  mesh <- make_mesh(
    coords, kappa = 1 / 20000,
    max.edge = c(12000, 25000), offset = c(10000, 20000),
    cutoff = 100, max.n = 160L
  )
  Q <- as.matrix(
    (1 / 20000)^4 * mesh$spde$c0 +
      2 * (1 / 20000)^2 * mesh$spde$g1 + mesh$spde$g2
  )
  field_scale <- 1e-4
  omega <- field_scale * as.vector(backsolve(chol(Q), rnorm(ncol(Q))))
  dat <- data.frame(
    y = 1.2 + as.vector(mesh$A_st %*% omega) + rnorm(n_site, sd = 0.25),
    site = paste0("obs", seq_len(n_site))
  )
  fit <- drmTMB(
    bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1),
    family = gaussian(), data = dat
  )
  estimate <- fit$sdpars$mu[["spatial(1 | site)"]]

  expect_true(isTRUE(fit$sdr$pdHess))
  expect_gt(estimate, 1e-6)
  expect_lt(estimate, 4e-4)
})

test_that("mesh field-scale start calibration bounds projection solves", {
  Q <- Matrix::Diagonal(4L)
  A <- Matrix::sparseMatrix(
    i = seq_len(80L), j = rep(seq_len(4L), length.out = 80L), x = 1,
    dims = c(80L, 4L)
  )
  mesh <- list(projection = A, precision = list(precision = Q))
  expect_equal(
    drmTMB:::mesh_spatial_field_scale_start(mesh, rep(c(0, 1), 40L)),
    0.25 * stats::sd(rep(c(0, 1), 40L)), tolerance = 1e-12
  )
})

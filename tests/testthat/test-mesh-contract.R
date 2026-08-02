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

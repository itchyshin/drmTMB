# Coverage shard cursor-cloud-1125x10: mesh.R validation (extends 1124d without editing it).

test_that(".drm_coordinate_name resolves quoted and symbol column names", {
  dat <- data.frame(lon = 1:3, lat = 4:6)
  expect_identical(
    drmTMB:::.drm_coordinate_name(dat, quote(lon), "longitude"),
    "lon"
  )
  expect_identical(
    drmTMB:::.drm_coordinate_name(dat, "lat", "latitude"),
    "lat"
  )
  expect_error(
    drmTMB:::.drm_coordinate_name(dat, quote(missing), "longitude"),
    "must name one column"
  )
})

test_that(".drm_mesh_coordinates adds default column names", {
  m <- cbind(c(0, 1, 0), c(0, 0, 1))
  loc <- drmTMB:::.drm_mesh_coordinates(m)
  expect_identical(colnames(loc), c("x", "y"))
  expect_equal(nrow(loc), 3L)
})

test_that(".drm_mesh_coordinates rejects collinear layouts", {
  collin <- cbind(x = c(0, 1, 2), y = c(0, 2, 4))
  expect_error(
    drmTMB:::.drm_mesh_coordinates(collin),
    "span two dimensions"
  )
})

test_that(".drm_validate_positive_scalar accepts finite positive kappa", {
  expect_equal(drmTMB:::.drm_validate_positive_scalar(0.5, "kappa"), 0.5)
  expect_error(
    drmTMB:::.drm_validate_positive_scalar(0, "kappa"),
    "greater than zero"
  )
  expect_error(
    drmTMB:::.drm_validate_positive_scalar(NA_real_, "kappa"),
    "greater than zero"
  )
})

test_that(".drm_require_mesh_package errors when a suggested package is absent", {
  skip_if(
    requireNamespace("sf", quietly = TRUE),
    "sf is installed; cannot test missing-package path"
  )
  expect_error(
    drmTMB:::.drm_require_mesh_package("sf", "test action"),
    "Install the suggested package"
  )
})

test_that("spatial_coords rejects non-finite coordinates when sf is available", {
  skip_if_not(requireNamespace("sf", quietly = TRUE))
  places <- data.frame(lon = c(-123.2, -123.1), lat = c(49.2, NA_real_))
  expect_error(
    spatial_coords(places, lon, lat, crs_out = 32610),
    "finite numeric"
  )
  expect_error(
    spatial_coords(
      data.frame(lon = c(-123.2, -123.1), lat = c(49.2, 49.3)),
      lon,
      lat,
      crs_out = 4326
    ),
    "must be projected"
  )
})

test_that("make_mesh rejects geographic crs on plain coordinates", {
  skip_if_not(
    requireNamespace("fmesher", quietly = TRUE) &&
      requireNamespace("sf", quietly = TRUE)
  )
  coords <- cbind(
    x = c(0, 1000, 500),
    y = c(0, 0, 1000)
  )
  attr(coords, "crs") <- 4326
  expect_error(
    make_mesh(coords, kappa = 1),
    "projected CRS"
  )
})

test_that("make_mesh returns a drmTMBmesh object for valid planar input", {
  skip_if_not(
    requireNamespace("fmesher", quietly = TRUE) &&
      requireNamespace("sf", quietly = TRUE)
  )
  coords <- cbind(
    x = c(0, 1000, 500, 200),
    y = c(0, 0, 1000, 400)
  )
  rownames(coords) <- letters[1:4]
  attr(coords, "crs") <- sf::st_crs(32610)
  mesh <- make_mesh(coords, kappa = 1 / 5000)
  expect_s3_class(mesh, "drmTMBmesh")
  expect_equal(nrow(mesh$loc_xy), 4L)
  expect_true(mesh$kappa > 0)
  expect_true(inherits(mesh$A_st, "sparseMatrix"))
  expect_identical(length(mesh$alignment_ids), 4L)
})
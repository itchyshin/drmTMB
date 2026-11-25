# Mesh input guards. Construction of an fmesher triangulation is not required.

test_that("spatial coordinate names and ranges are rejected before projection", {
  empty <- data.frame(lon = numeric(), lat = numeric())
  expect_error(
    spatial_coords(empty, lon, lat, crs_out = 32610),
    if (requireNamespace("sf", quietly = TRUE)) {
      "non-empty data frame"
    } else {
      "Install the suggested package"
    }
  )

  if (requireNamespace("sf", quietly = TRUE)) {
    places <- data.frame(lon = c(-123.2, -200), lat = c(49.2, 49.3))
    expect_error(
      spatial_coords(places, lon, lat, crs_out = 32610),
      "\\[-180, 180\\]"
    )
    expect_error(
      spatial_coords(
        data.frame(lon = c(-123.2, -123.1), lat = c(49.2, 49.3)),
        longitude,
        latitude,
        crs_out = 32610
      ),
      "must name one column"
    )
    expect_error(
      drmTMB:::.drm_validate_projected_crs(4326),
      "projected CRS"
    )
  }
})

test_that("mesh coordinate and alignment checks fail closed", {
  expect_error(
    drmTMB:::.drm_mesh_coordinates(matrix(1:4, nrow = 2)),
    "at least three rows"
  )
  expect_error(
    drmTMB:::.drm_mesh_coordinates(cbind(x = c(0, 1, 2), y = c(NA, 0, 1))),
    "finite numeric planar coordinates"
  )

  duplicated_names <- cbind(x = c(0, 1, 0), y = c(0, 0, 1))
  rownames(duplicated_names) <- c("a", "a", "b")
  expect_error(
    drmTMB:::.drm_mesh_alignment_ids(duplicated_names),
    "unique, non-missing"
  )

  expect_error(
    drmTMB:::.drm_validate_mesh(list(loc_xy = cbind(0, 0))),
    "complete"
  )
  expect_error(
    drmTMB:::.drm_validate_positive_scalar(-1, "kappa"),
    "greater than zero"
  )
})

test_that("make_mesh names the missing suggested package or a foreign mesh", {
  coords <- cbind(x = c(0, 1, 0), y = c(0, 0, 1))
  attr(coords, "crs") <- 32610
  if (!requireNamespace("fmesher", quietly = TRUE)) {
    expect_error(
      make_mesh(coords, kappa = 1),
      "Install the suggested package"
    )
  } else {
    expect_error(
      make_mesh(coords, kappa = 1, mesh = structure(list(), class = "not_a_mesh")),
      "fm_mesh_2d"
    )
  }
})

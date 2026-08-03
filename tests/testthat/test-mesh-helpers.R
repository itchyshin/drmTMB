test_that("spatial_coords requires and records an explicit projected CRS", {
  skip_if_not_installed("sf")
  dat <- data.frame(lon = c(-123.20, -123.10, -123.15), lat = c(49.20, 49.30, 49.25))

  xy <- drmTMB:::spatial_coords(dat, lon, lat, crs_out = 32610)
  expect_s3_class(xy, "drmTMB_coords")
  expect_equal(dim(xy), c(3L, 2L))
  expect_false(sf::st_is_longlat(attr(xy, "crs")))
  expect_true(all(is.finite(xy)))
  expect_error(drmTMB:::spatial_coords(dat, lon, lat, crs_out = 4326), "projected")
  expect_error(drmTMB:::spatial_coords(transform(dat, lon = Inf), lon, lat, 32610), "finite")
})

test_that("make_mesh creates a conformable fixed-kappa SPDE contract", {
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")
  dat <- data.frame(lon = c(-123.20, -123.10, -123.15, -123.12),
                    lat = c(49.20, 49.30, 49.25, 49.22))
  xy <- drmTMB:::spatial_coords(dat, lon, lat, crs_out = 32610)
  mesh <- drmTMB:::make_mesh(xy, kappa = 1 / 10000)

  expect_s3_class(mesh, "drmTMBmesh")
  expect_identical(mesh$kappa, 1 / 10000)
  expect_equal(nrow(mesh$A_st), nrow(xy))
  expect_equal(as.numeric(Matrix::rowSums(mesh$A_st)), rep(1, nrow(xy)), tolerance = 1e-8)
  expect_true(all(vapply(mesh$spde[c("c0", "g1", "g2")], inherits, logical(1), "sparseMatrix")))
  expect_identical(mesh$alignment_ids, as.character(seq_len(nrow(xy))))
  expect_identical(mesh$source_rows, seq_len(nrow(xy)))
})

test_that("make_mesh rejects non-metric or malformed coordinates", {
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")
  xy <- matrix(c(0, 0, 1, 0, 0, 1), ncol = 2, byrow = TRUE)
  expect_error(drmTMB:::make_mesh(xy, kappa = 1), "projected")
  expect_error(drmTMB:::make_mesh(xy, kappa = 0, crs = 32610), "greater than zero")
  expect_error(drmTMB:::make_mesh(xy[, 1, drop = FALSE], kappa = 1, crs = 32610), "two-column")
  expect_error(drmTMB:::make_mesh(cbind(1:3, 1:3), kappa = 1, crs = 32610), "two dimensions")
})

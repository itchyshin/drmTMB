# The coords= route of spatial() fixes the exponential range at the median
# positive pairwise distance (#968). The documentation says so, so pin it.
test_that("drm_spatial_coords_precision() fixes the range at the median positive distance", {
  # Skewed layout so median, mean and max pairwise distances all differ.
  coords <- data.frame(
    x = c(0, 1, 2, 3, 10, 11, 25),
    y = c(0, 0.5, 0, 1, 0, 2, 0)
  )
  sites <- paste0("s", seq_len(nrow(coords)))
  rownames(coords) <- sites

  distance <- as.matrix(stats::dist(coords))
  positive <- distance[upper.tri(distance)]
  positive <- positive[positive > 0]
  expect_gt(abs(stats::median(positive) - mean(positive)), 0.5)

  jitter <- 1e-6
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = sites,
    group = "site",
    jitter = jitter
  )

  expect_equal(precision$range, stats::median(positive))

  expected_cov <- exp(-distance / stats::median(positive))
  diag(expected_cov) <- diag(expected_cov) + jitter
  implied_cov <- solve(as.matrix(precision$precision))
  expect_equal(
    unname(implied_cov),
    unname(expected_cov),
    tolerance = 1e-6
  )
})

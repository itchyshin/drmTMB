# Coverage for R/formula-markers.R exported compatibility markers.

test_that("gr() warns that the marker is deprecated", {
  expect_warning(
    gr(group = 1, cov = 2),
    "deprecated"
  )
})

test_that("meta_known_V() warns and meta_V() stays silent", {
  expect_warning(
    meta_known_V(V = 1),
    "meta_known_V"
  )
  expect_invisible(meta_V(V = 1))
})

test_that("mi() returns its argument for model-frame construction", {
  x <- c(1, NA, 3)
  expect_identical(mi(x), x)
})
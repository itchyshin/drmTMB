test_that("individual prediction uses the fitted quadrature order ladder", {
  orders <- c(25L, 41L, 65L, 97L, 129L, 161L, 193L)
  eta <- 1.3
  sigma <- 4
  power <- 2

  observed <- drmTMB:::.cmr_individual_mean(
    eta, sigma, target = "integrated", power = power,
    terminal = FALSE, constraint = NULL, orders = orders
  )
  direct <- vapply(c(129L, 161L, 193L), function(order) {
    gh <- drmTMB:::.cmr_gauss_hermite(order)
    sum(gh$weights * stats::plogis(eta + sigma * gh$nodes)^power)
  }, numeric(1))
  expect_gt(abs(direct[[2L]] - direct[[1L]]), 1e-8)
  expect_lte(abs(direct[[3L]] - direct[[2L]]), 1e-8)
  expected <- direct[[3L]]

  expect_equal(observed, expected, tolerance = 1e-12)
})

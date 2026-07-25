test_that("ten admitted family-and-data combinations have finite association objectives", {
  gaussian_bernoulli <- function(y_g, p, y_b) list(
    pair_class = "gaussian_bernoulli",
    descriptor = drmTMB:::drm_pair_descriptor("gaussian_bernoulli"),
    gaussian_y = y_g, gaussian_mu = rep(0, length(y_g)),
    gaussian_sigma = rep(1, length(y_g)), binary_y = y_b, binary_p = p
  )
  gaussian_nbinom2 <- function(y_g, y_c, mu, sigma) list(
    pair_class = "gaussian_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("gaussian_nbinom2"),
    gaussian_y = y_g, gaussian_mu = rep(0, length(y_g)),
    gaussian_sigma = rep(1, length(y_g)), nbinom2_y = y_c,
    nbinom2_mu = mu, nbinom2_sigma = sigma
  )
  bernoulli_bernoulli <- function(y_1, p_1, y_2, p_2) list(
    pair_class = "bernoulli_bernoulli", binary_1_y = y_1, binary_1_p = p_1,
    binary_2_y = y_2, binary_2_p = p_2
  )
  bernoulli_nbinom2 <- function(y_b, p, y_c, mu, sigma) list(
    pair_class = "bernoulli_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("bernoulli_nbinom2"),
    binary_y = y_b, binary_p = p, nbinom2_y = y_c,
    nbinom2_mu = mu, nbinom2_sigma = sigma
  )
  nbinom2_nbinom2 <- function(y_1, mu_1, sigma_1, y_2, mu_2, sigma_2) list(
    pair_class = "nbinom2_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("nbinom2_nbinom2"),
    nbinom2_y_1 = y_1, nbinom2_mu_1 = mu_1, nbinom2_sigma_1 = sigma_1,
    nbinom2_y_2 = y_2, nbinom2_mu_2 = mu_2, nbinom2_sigma_2 = sigma_2
  )

  scenarios <- list(
    gaussian_bernoulli(c(-1, 0.2, 1), c(.2, .5, .8), c(0L, 1L, 1L)),
    gaussian_bernoulli(c(-2, 0, 2), c(.05, .5, .95), c(0L, 1L, 1L)),
    gaussian_nbinom2(c(-1, 0, 1), c(0L, 2L, 7L), c(1, 2, 5), rep(.7, 3)),
    gaussian_nbinom2(c(-2, .5, 2), c(0L, 8L, 22L), c(.4, 7, 18), rep(.3, 3)),
    bernoulli_nbinom2(c(0L, 1L, 1L), c(.2, .5, .8), c(0L, 2L, 7L), c(1, 2, 5), rep(.7, 3)),
    bernoulli_nbinom2(c(0L, 1L, 1L), c(.05, .5, .95), c(0L, 8L, 22L), c(.4, 7, 18), rep(.3, 3)),
    bernoulli_bernoulli(c(0L, 1L, 1L), c(.2, .5, .8), c(1L, 0L, 1L), c(.7, .4, .6)),
    bernoulli_bernoulli(c(0L, 0L, 1L), c(.05, .1, .9), c(0L, 1L, 1L), c(.1, .8, .95)),
    nbinom2_nbinom2(c(0L, 2L, 7L), c(1, 2, 5), rep(.7, 3), c(1L, 3L, 8L), c(1.2, 2.5, 6), rep(.6, 3)),
    nbinom2_nbinom2(c(0L, 8L, 22L), c(.4, 7, 18), rep(.3, 3), c(0L, 5L, 30L), c(.6, 5, 22), rep(.25, 3))
  )
  for (components in scenarios) {
    objective <- drmTMB:::drm_pair_loglikelihood_function(components)
    expect_true(is.finite(objective(0, components)))
    expect_true(is.finite(objective(0.35, components)))
  }
})

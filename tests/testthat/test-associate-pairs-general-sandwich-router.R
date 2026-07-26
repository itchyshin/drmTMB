test_that("private general sandwich router selects every admitted adapter", {
  adapters <- c(
    gaussian_bernoulli = "gaussian_bernoulli",
    gaussian_nbinom2 = "gaussian_nbinom2",
    bernoulli_bernoulli = "bernoulli_bernoulli",
    bernoulli_nbinom2 = "bernoulli_nbinom2",
    nbinom2_nbinom2 = "nbinom2_nbinom2"
  )
  testthat::local_mocked_bindings(
    drm_pair_gaussian_bernoulli_eta_sandwich = function(...) "gaussian_bernoulli",
    drm_pair_gaussian_nbinom2_eta_sandwich = function(...) "gaussian_nbinom2",
    drm_pair_bernoulli_bernoulli_sandwich = function(...) "bernoulli_bernoulli",
    drm_pair_staged_eta_sandwich = function(...) "bernoulli_nbinom2",
    drm_pair_nbinom2_nbinom2_sandwich = function(...) "nbinom2_nbinom2",
    .package = "drmTMB"
  )
  for (pair_class in names(adapters)) {
    association_fit <- structure(
      list(components = list(pair_class = pair_class)),
      class = "drm_pair_association"
    )
    expect_identical(
      drmTMB:::drm_pair_general_eta_sandwich(
        NULL, NULL, association_fit,
        control = list(private = TRUE)
      ),
      unname(adapters[[pair_class]])
    )
  }
})

test_that("private general sandwich router fails closed outside admitted classes", {
  unsupported <- structure(
    list(components = list(pair_class = "not_reviewed")),
    class = "drm_pair_association"
  )
  expect_error(
    drmTMB:::drm_pair_general_eta_sandwich(NULL, NULL, unsupported),
    "No private staged-sandwich adapter"
  )
  expect_error(
    drmTMB:::drm_pair_general_eta_sandwich(NULL, NULL, list()),
    "drm_pair_association"
  )
})

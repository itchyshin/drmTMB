# The Julia cross-family route fits each Gaussian axis with an identity mean
# link. A Gaussian family with any other link must not be tagged "gaussian",
# matching the link guards on the Poisson and binomial axes (#1750).

test_that("#1750: only an identity-link gaussian() gets the gaussian tag", {
  expect_identical(
    drmTMB:::drm_julia_xfam_family_tag(gaussian()),
    "gaussian"
  )
  expect_null(drmTMB:::drm_julia_xfam_family_tag(gaussian(link = "log")))
  expect_null(drmTMB:::drm_julia_xfam_family_tag(gaussian(link = "inverse")))
})

test_that("#1750: a non-identity gaussian() axis is not a cross-family pair", {
  expect_false(drmTMB:::drm_julia_is_cross_family(
    c(gaussian(link = "log"), poisson())
  ))
  expect_false(drmTMB:::drm_julia_is_cross_family(
    list(binomial(), gaussian(link = "inverse"))
  ))
  expect_true(drmTMB:::drm_julia_is_cross_family(c(gaussian(), poisson())))
})

drm_fix_1750_data <- function() {
  set.seed(1750)
  n <- 60
  x <- stats::rnorm(n)
  data.frame(
    y1 = exp(1 + 0.2 * x + stats::rnorm(n, sd = 0.1)),
    y2 = stats::rpois(n, exp(0.4 + 0.3 * x)),
    x = x
  )
}

test_that("#1750: engine = 'julia' refuses a log-link Gaussian axis in R", {
  expect_error(
    suppressMessages(drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = c(gaussian(link = "log"), poisson()),
      data = drm_fix_1750_data(),
      engine = "julia"
    )),
    "Mixed-response bivariate families",
    class = "rlang_error"
  )
})

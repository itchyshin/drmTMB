glmmtmb_style_family <- function(name, link = "log") {
  structure(
    list(family = name, link = link),
    class = "family"
  )
}

test_that("glm-style family objects suggest drmTMB:: constructor", {
  nbinom <- glmmtmb_style_family("nbinom2")
  logn <- glmmtmb_style_family("lognormal")
  expect_error(
    drmTMB:::drm_family_type(nbinom),
    "drmTMB::nbinom2"
  )
  expect_error(
    drmTMB:::drm_family_type(nbinom),
    "masked"
  )
  expect_error(
    drmTMB:::drm_family_type(logn),
    "drmTMB::lognormal"
  )
  expect_error(
    drmTMB:::drm_family_type(logn),
    "glmmTMB"
  )
})
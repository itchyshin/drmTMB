# Regression for drmTMB#1706: stats-family objects that share a name with a
# drmTMB constructor (often glmmTMB::nbinom2() after library(glmmTMB)) must
# not fall through to the generic "currently supported families" message.

test_that("hand-built stats family objects name drmTMB::constructor", {
  foreign <- stats::binomial()
  foreign$family <- "nbinom2"
  foreign$link <- "log"
  err <- tryCatch(
    drmTMB:::drm_family_type(foreign),
    error = function(cnd) conditionMessage(cnd)
  )
  expect_match(err, "not a.*drmTMB.*family")
  expect_match(err, "drmTMB::nbinom2\\(\\)")
  expect_false(grepl("Currently supported families", err, fixed = TRUE))
})

test_that("glmmTMB family constructors are rejected with a drmTMB:: hint", {
  skip_if_not_installed("glmmTMB")
  clashes <- list(
    nbinom2 = "nbinom2",
    truncated_nbinom2 = "truncated_nbinom2",
    tweedie = "tweedie",
    beta_family = "beta_family"
  )
  for (fn in names(clashes)) {
    drm_fun <- clashes[[fn]]
    family <- getFromNamespace(fn, "glmmTMB")()
    err <- tryCatch(
      drmTMB:::drm_family_type(family),
      error = function(cnd) conditionMessage(cnd)
    )
    expect_match(err, "not a.*drmTMB.*family")
    expect_match(err, paste0("drmTMB::", drm_fun, "\\(\\)"))
    expect_match(err, "glmmTMB")
    expect_false(grepl("Currently supported families", err, fixed = TRUE))
  }
})

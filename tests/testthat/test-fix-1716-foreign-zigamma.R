# Regression for drmTMB#1716: foreign zero-inflated / hurdle stats families
# (notably glmmTMB::ziGamma()) must be refused, not silently routed to plain
# Gamma(log) or another non-inflation family.

test_that("hand-built ziGamma stats family is refused with a clear error (#1716)", {
  foreign <- stats::Gamma(link = "log")
  foreign$family <- "ziGamma"
  err <- tryCatch(
    drmTMB:::drm_family_type(foreign),
    error = function(cnd) conditionMessage(cnd)
  )
  expect_match(err, "ziGamma")
  expect_match(err, "zero-inflat|not supported")
  expect_match(err, "Gamma\\(link = \"log\"\\)")
  expect_false(grepl("Currently supported families", err, fixed = TRUE))
})

test_that("glmmTMB::ziGamma(link = 'log') is refused, not fitted as plain Gamma (#1716)", {
  skip_if_not_installed("glmmTMB")
  suppressPackageStartupMessages(library(glmmTMB))
  set.seed(1716)
  d <- data.frame(y = stats::rgamma(40, shape = 2, scale = 1), x = stats::rnorm(40))
  expect_error(
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = glmmTMB::ziGamma(link = "log"),
    data = d
  ),
  regexp = "ziGamma|zero-inflat",
  class = "rlang_error"
  )
  err <- tryCatch(
    drmTMB:::drm_family_type(glmmTMB::ziGamma(link = "log")),
    error = function(cnd) conditionMessage(cnd)
  )
  expect_match(err, "ziGamma|zero-inflation hooks")
  expect_match(err, "Gamma\\(link = \"log\"\\)")
})

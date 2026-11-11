# Regression for drmTMB#1716: foreign zero-inflated / hurdle stats families
# (notably glmmTMB::ziGamma()) must be refused, not silently routed to plain
# Gamma(log) or another non-inflation family.

test_that("hand-built ziGamma stats family is refused with a clear error (#1716)", {
  foreign <- stats::Gamma(link = "log")
  foreign$family <- "ziGamma"
  expect_error(
    drmTMB:::drm_family_type(foreign),
    class = "drmTMB_foreign_inflation_family"
  )
})

test_that("hand-built Gamma family with ziformula initialize is refused (#1716)", {
  foreign <- stats::Gamma(link = "log")
  foreign$initialize <- expression({
    if (exists("ziformula") && !identical(ziformula, ~0)) NULL
  })
  expect_error(
    drmTMB:::drm_family_type(foreign),
    class = "drmTMB_foreign_inflation_family"
  )
})

test_that("plain Gamma(link = 'log') and drmTMB constructors are unchanged (#1716)", {
  expect_identical(drmTMB:::drm_family_type(stats::Gamma(link = "log")), "gamma")
  expect_identical(drmTMB:::drm_family_type(beta_family()), "beta")
  expect_identical(drmTMB:::drm_family_type(lognormal()), "lognormal")
})

test_that("glmmTMB::ziGamma(link = 'log') is refused, not fitted as plain Gamma (#1716)", {
  skip_if_not_installed("glmmTMB")
  set.seed(1716)
  d <- data.frame(y = stats::rgamma(40, shape = 2, scale = 1), x = stats::rnorm(40))
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = glmmTMB::ziGamma(link = "log"),
      data = d
    ),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_error(
    drmTMB:::drm_family_type(glmmTMB::ziGamma(link = "log")),
    class = "drmTMB_foreign_inflation_family"
  )
})

test_that("zipf is not treated as a zero-inflated family name (#1716)", {
  expect_null(drmTMB:::drm_foreign_inflation_family_kind("zipf"))
  expect_identical(drmTMB:::drm_foreign_inflation_family_kind("ziGamma"), "zero-inflated")
})

test_that("glmmTMB beta_family and lognormal are refused without a zero-inflated label (#1716)", {
  skip_if_not_installed("glmmTMB")
  err <- expect_error(
    drmTMB:::drm_family_type(glmmTMB::beta_family()),
    class = "drmTMB_foreign_inflation_family"
  )
  msg <- conditionMessage(err)
  expect_false(grepl("zero-inflat", msg, ignore.case = TRUE))
  expect_match(msg, "beta_family")
  expect_false(grepl("glmmTMB::beta\\(\\)", msg))
  expect_match(msg, "drmTMB::beta_family")

  err2 <- expect_error(
    drmTMB:::drm_family_type(glmmTMB::lognormal()),
    class = "drmTMB_foreign_inflation_family"
  )
  msg2 <- conditionMessage(err2)
  expect_false(grepl("zero-inflat", msg2, ignore.case = TRUE))
  expect_match(msg2, "lognormal")
  expect_match(msg2, "drmTMB::lognormal")
})

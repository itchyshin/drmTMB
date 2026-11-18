# A foreign stats family whose name is a near miss for a drmTMB constructor
# must say which constructor to use. It must not be fitted, and an unrelated
# name must keep the generic unsupported-family abort (#1718).

foreign_stats_family <- function(name) {
  family <- stats::binomial()
  family$family <- name
  family
}

expect_near_name_hint <- function(name, constructor) {
  dat <- data.frame(y = stats::rnorm(8), x = stats::rnorm(8))
  err <- expect_error(
    drmTMB(
      bf(y ~ x),
      family = foreign_stats_family(name),
      data = dat,
      control = drm_control(se = FALSE)
    ),
    class = "drmTMB_foreign_near_name_family"
  )
  expect_match(
    conditionMessage(err),
    sprintf("drmTMB::%s()", constructor),
    fixed = TRUE
  )
}

test_that("betabinomial hints at drmTMB::beta_binomial() (#1718)", {
  expect_near_name_hint("betabinomial", "beta_binomial")
})

test_that("skewnormal hints at drmTMB::skew_normal() (#1718)", {
  expect_near_name_hint("skewnormal", "skew_normal")
})

test_that("an unrelated foreign family does not get a near-name hint (#1718)", {
  dat <- data.frame(y = stats::rnorm(8), x = stats::rnorm(8))
  err <- expect_error(
    drmTMB(
      bf(y ~ x),
      family = foreign_stats_family("quack"),
      data = dat
    ),
    class = "rlang_error"
  )
  expect_false(grepl("drmTMB::", conditionMessage(err), fixed = TRUE))
  expect_false(inherits(err, "drmTMB_foreign_near_name_family"))
})

test_that("a real gaussian() family is unchanged (#1718)", {
  expect_identical(drm_family_type(gaussian()), "gaussian")
})

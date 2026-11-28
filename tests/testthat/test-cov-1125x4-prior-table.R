# R/prior-table.R parsing and expansion guards.

valid_row <- data.frame(
  prior = "normal(0, 1)",
  class = "fixef",
  coef = "(Intercept)",
  dpar = "mu",
  stringsAsFactors = FALSE
)

test_that("drm_parse_prior_table() rejects malformed tables", {
  expect_error(drmTMB:::drm_parse_prior_table(data.frame(a = 1)), "prior table")
  expect_error(
    drmTMB:::drm_parse_prior_table(
      data.frame(prior = "normal(0,1)", class = "fixef", extra = "z", stringsAsFactors = FALSE)
    ),
    "invalid prior table columns"
  )
  bad <- data.frame(prior = "weird(0)", class = "fixef", coef = "x", stringsAsFactors = FALSE)
  expect_error(drmTMB:::drm_parse_prior_table(bad), "invalid prior syntax")
})

test_that("drm_parse_prior_table() accepts normal and ridge rows", {
  rows <- drmTMB:::drm_parse_prior_table(valid_row)
  expect_length(rows, 1L)
  expect_identical(rows[[1L]]$kind, "normal")
  ridge <- valid_row
  ridge$prior <- "ridge(0.5)"
  rows2 <- drmTMB:::drm_parse_prior_table(ridge)
  expect_identical(rows2[[1L]]$kind, "ridge")
  gamma <- valid_row
  gamma$class <- "ranef_sd"
  gamma$prior <- "gamma(1, 4)"
  rows3 <- drmTMB:::drm_parse_prior_table(gamma)
  expect_identical(rows3[[1L]]$kind, "gamma")
})

test_that("drm_parse_prior_table() guards normal and gamma arity", {
  wrong <- valid_row
  wrong$prior <- "normal(0)"
  expect_error(drmTMB:::drm_parse_prior_table(wrong), "wrong prior arity")
  g <- valid_row
  g$class <- "ranef_sd"
  g$prior <- "gamma(0, 2)"
  expect_error(drmTMB:::drm_parse_prior_table(g), "invalid Gamma prior")
})

test_that("drm_expand_prior_table() expands SD rows across groups", {
  row <- list(
    kind = "gamma",
    class = "ranef_sd",
    coef = "",
    dpar = "mu",
    group = "",
    args = c(1, 4)
  )
  out <- drmTMB:::drm_expand_prior_table(list(row), groups = c("id", "blk"))
  expect_length(out, 2L)
  expect_setequal(vapply(out, `[[`, "", "group"), c("id", "blk"))
  expect_error(
    drmTMB:::drm_expand_prior_table(list(row), groups = c("id", "id")),
    "ambiguous"
  )
})

test_that("drm_expand_prior_table() rejects non-mu SD priors", {
  row <- list(
    kind = "gamma",
    class = "ranef_sd",
    coef = "(Intercept)",
    dpar = "sigma",
    group = "id",
    args = c(1, 4)
  )
  expect_error(
    drmTMB:::drm_expand_prior_table(list(row), "id"),
    "SD priors require dpar=mu"
  )
})
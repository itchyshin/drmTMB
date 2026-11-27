# Direct prior-table parser guards (R/prior-table.R). No model fit required.

valid_fixef_row <- function(prior = "normal(0,2)", coef = "x") {
  data.frame(
    prior = prior,
    class = "fixef",
    coef = coef,
    stringsAsFactors = FALSE
  )
}

valid_sd_row <- function(prior = "gamma(0.6666666666666666,2)", coef = "site") {
  data.frame(
    prior = prior,
    class = "ranef_sd",
    coef = coef,
    dpar = "mu",
    stringsAsFactors = FALSE
  )
}

test_that("drm_parse_prior_table() rejects ill-formed tables", {
  expect_error(drmTMB:::drm_parse_prior_table(1:3), "prior table")
  dup <- valid_fixef_row()
  names(dup) <- c("prior", "prior", "coef")
  expect_error(drmTMB:::drm_parse_prior_table(dup), "unique columns")
  expect_error(
    drmTMB:::drm_parse_prior_table(data.frame(x = "a")),
    "invalid prior table columns"
  )
  expect_error(
    drmTMB:::drm_parse_prior_table(valid_fixef_row()[0, , drop = FALSE]),
    "nonmissing character"
  )
  bad <- valid_fixef_row()
  bad$prior[1] <- NA_character_
  expect_error(drmTMB:::drm_parse_prior_table(bad), "nonmissing character")
  bad <- valid_fixef_row()
  bad$class[1] <- NA_character_
  expect_error(drmTMB:::drm_parse_prior_table(bad), "nonmissing character")
})

test_that("drm_parse_prior_table() validates prior classes and syntax", {
  bad <- valid_fixef_row()
  bad$class <- "shape"
  expect_error(drmTMB:::drm_parse_prior_table(bad), "unsupported prior class")
  expect_error(
    drmTMB:::drm_parse_prior_table(valid_fixef_row(prior = "beta(0,1)")),
    "invalid prior syntax"
  )
  expect_error(
    drmTMB:::drm_parse_prior_table(valid_fixef_row(prior = "normal(0)")),
    "wrong prior arity"
  )
  expect_error(
    drmTMB:::drm_parse_prior_table(valid_fixef_row(prior = "ridge(0,1)")),
    "wrong prior arity"
  )
  expect_error(
    drmTMB:::drm_parse_prior_table(valid_fixef_row(prior = "normal(0,1e309)")),
    "unrepresentable prior parameter"
  )
  expect_error(
    drmTMB:::drm_parse_prior_table(valid_fixef_row(prior = "normal(0,0)")),
    "invalid normal prior"
  )
  expect_error(
    drmTMB:::drm_parse_prior_table(valid_fixef_row(prior = "ridge(-1)")),
    "invalid ridge prior"
  )
  expect_error(
    drmTMB:::drm_parse_prior_table(
      valid_sd_row(prior = "gamma(1,1)")
    ),
    "invalid Gamma prior"
  )
  fix <- valid_fixef_row()
  fix$group <- "site"
  expect_error(drmTMB:::drm_parse_prior_table(fix), "invalid fixed selector")
  all_coef <- valid_fixef_row(coef = "all")
  expect_error(drmTMB:::drm_parse_prior_table(all_coef), "invalid fixed selector")
})

test_that("drm_parse_prior_table() parses optional dpar and group columns", {
  tab <- data.frame(
    prior = c("normal(0,2)", "gamma(0.5,3)"),
    class = c("fixef", "ranef_sd"),
    coef = c("", "g1"),
    dpar = c("", "sigma"),
    group = c("", "g1"),
    stringsAsFactors = FALSE
  )
  rows <- drmTMB:::drm_parse_prior_table(tab)
  expect_length(rows, 2L)
  expect_equal(rows[[1L]]$dpar, "mu")
  expect_equal(rows[[2L]]$dpar, "sigma")
  expect_equal(rows[[2L]]$group, "g1")
  expect_equal(rows[[2L]]$args, c(0.5, 3))
})

test_that("drm_expand_prior_table() validates SD targets", {
  row <- list(
    class = "ranef_sd",
    kind = "gamma",
    coef = "g1",
    dpar = "sigma",
    group = "",
    args = c(0.5, 3)
  )
  expect_error(
    drmTMB:::drm_expand_prior_table(list(row), "site"),
    "dpar=mu"
  )
  row$dpar <- "mu"
  expect_error(
    drmTMB:::drm_expand_prior_table(list(row), c("site", "site")),
    "ambiguous"
  )
  intercept <- row
  intercept$coef <- "(Intercept)"
  expect_error(
    drmTMB:::drm_expand_prior_table(list(intercept), character()),
    "\\(Intercept\\)"
  )
  clash <- row
  clash$group <- "site"
  clash$coef <- "observer"
  expect_error(
    drmTMB:::drm_expand_prior_table(list(clash), "site"),
    "conflicting"
  )
  broad <- row
  broad$coef <- ""
  expect_error(
    drmTMB:::drm_expand_prior_table(list(broad), character()),
    "matched no random intercept"
  )
  expect_error(
    drmTMB:::drm_expand_prior_table(list(row), "nope"),
    "unknown random-intercept group"
  )
  blank <- list(
    class = "ranef_sd",
    kind = "gamma",
    coef = "",
    dpar = "mu",
    group = "",
    args = c(2 / 3, 2)
  )
  expect_error(
    drmTMB:::drm_expand_prior_table(list(blank, blank), "site"),
    "overlapping"
  )
})

test_that("drm_expand_prior_table() expands broad SD selectors across groups", {
  row <- list(
    class = "ranef_sd",
    kind = "gamma",
    coef = "",
    dpar = "mu",
    group = "",
    args = c(2 / 3, 2)
  )
  out <- drmTMB:::drm_expand_prior_table(list(row), c("site", "observer"))
  expect_length(out, 2L)
  expect_equal(vapply(out, `[[`, "", "group"), c("site", "observer"))
  expect_true(all(vapply(out, function(x) x$coef == "(Intercept)", logical(1))))
})

test_that("drm_prior_table_specs() maps rows to drm_priors entries", {
  tab <- data.frame(
    prior = c("normal(0,2)", "gamma(0.6666666666666666,2)"),
    class = c("fixef", "ranef_sd"),
    coef = c("x", "site"),
    dpar = c("mu", "mu"),
    group = c("", ""),
    stringsAsFactors = FALSE
  )
  rows <- drmTMB:::drm_parse_prior_table(tab)
  specs <- drmTMB:::drm_prior_table_specs(rows, "site")
  expect_s3_class(specs, "drm_priors")
  expect_length(specs, 2L)
})

test_that("drm_freeze_table_prior_specs() requires resolved replay targets", {
  resolved <- data.frame(
    class = "fixed",
    coefficient = "y",
    dpar = "mu",
    stringsAsFactors = FALSE
  )
  priors <- drm_priors(drm_prior_normal("mu", "x", mean = 0, sd = 2))
  expect_error(
    drmTMB:::drm_freeze_table_prior_specs(priors, resolved),
    "Prior replay target was not resolved"
  )
})

test_that("drm_freeze_table_prior_specs() rejects coefficient name all", {
  resolved <- data.frame(
    class = "fixed",
    coefficient = "all",
    dpar = "mu",
    reason = "all; intercept exclude",
    stringsAsFactors = FALSE
  )
  priors <- drm_priors(drm_prior_normal("mu", "x", mean = 0, sd = 2))
  expect_error(
    drmTMB:::drm_freeze_table_prior_specs(priors, resolved),
    "literally named all"
  )
})
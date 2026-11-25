# Coverage shard cursor-cloud-1125x10: parse-formula helpers (not post-fit).

test_that("drm_subset_model_columns keeps only requested variables", {
  dat <- data.frame(y = 1:4, x = 4:1, g = letters[1:4])
  sub <- drmTMB:::drm_subset_model_columns(dat, c("y", "x"))
  expect_s3_class(sub, "data.frame")
  expect_named(sub, c("y", "x"))
  expect_equal(nrow(sub), 4L)
  expect_error(
    drmTMB:::drm_subset_model_columns(dat, c("y", "missing_col")),
    "Missing"
  )
  expect_error(
    drmTMB:::drm_subset_model_columns(dat, c("y", "missing_col")),
    "missing_col"
  )
})

test_that("drm_unsupported_dpar_hint names bf()", {
  hint <- drmTMB:::drm_unsupported_dpar_hint()
  expect_type(hint, "character")
  expect_length(hint, 1L)
  expect_match(hint, "bf")
  expect_match(hint, "sigma")
})

test_that("is_formula_call recognises tilde calls", {
  expect_true(drmTMB:::is_formula_call(quote(y ~ x)))
  expect_true(drmTMB:::is_formula_call(quote(~ x)))
  expect_false(drmTMB:::is_formula_call(quote(y + x)))
  expect_false(drmTMB:::is_formula_call(NULL))
})

test_that("drm_formula_to_call preserves one- and two-sided formulas", {
  one <- drmTMB:::drm_formula_to_call(~ x)
  two <- drmTMB:::drm_formula_to_call(y ~ x + z)
  expect_true(drmTMB:::is_formula_call(one))
  expect_true(drmTMB:::is_formula_call(two))
  expect_null(drmTMB:::formula_lhs(one))
  expect_identical(as.character(drmTMB:::formula_lhs(two)), "y")
  expect_identical(
    as.character(drmTMB:::formula_rhs(two)[[1]]),
    "+"
  )
})

test_that("drm_formula_resolve_input accepts literals and symbols", {
  env <- new.env(parent = emptyenv())
  env$f <- y ~ x
  lit <- drmTMB:::drm_formula_resolve_input(quote(y ~ x), env, 1L)
  sym <- drmTMB:::drm_formula_resolve_input(quote(f), env, 2L)
  expect_true(drmTMB:::is_formula_call(lit))
  expect_true(drmTMB:::is_formula_call(sym))
  expect_error(
    drmTMB:::drm_formula_resolve_input(quote(g), env, 3L),
    "could not evaluate"
  )
  env$g <- 42
  expect_error(
    drmTMB:::drm_formula_resolve_input(quote(g), env, 4L),
    "must be a formula"
  )
  expect_error(
    drmTMB:::drm_formula_resolve_input(quote(1 + 2), env, 5L),
    "must be formulas"
  )
})

test_that("parse_drm_formula_entry maps named, unnamed, and sd entries", {
  e_mu <- drmTMB:::parse_drm_formula_entry(quote(y ~ x), "mu", 1L)
  expect_identical(e_mu$dpar, "mu")
  expect_identical(e_mu$response, "y")
  e_sigma <- drmTMB:::parse_drm_formula_entry(quote(sigma ~ z), "", 2L)
  expect_identical(e_sigma$dpar, "sigma")
  expect_true(is.na(e_sigma$response))
  e_sd <- drmTMB:::parse_drm_formula_entry(quote(sd(id) ~ w), "", 3L)
  expect_identical(e_sd$dpar, "sd(id)")
  expect_true(is.na(e_sd$response))
})

test_that("parse_drm_formula_entry rejects invalid combinations", {
  expect_error(
    drmTMB:::parse_drm_formula_entry(quote(list(y, x)), "mu", 1L),
    "must be formulas"
  )
  e_rhs_only <- drmTMB:::parse_drm_formula_entry(quote(~ x), "mu", 1L)
  expect_identical(e_rhs_only$dpar, "mu")
  expect_error(
    drmTMB:::parse_drm_formula_entry(
      quote(sd(id) ~ x),
      "mu",
      1L
    ),
    "Random-effect scale formulas should be unnamed"
  )
})

test_that("check_unique_plain_dpars rejects duplicated plain dpars", {
  mk <- function(dpar, rhs = quote(1)) {
    list(
      dpar = dpar,
      lhs = NULL,
      corpair = NULL,
      response = NA_character_
    )
  }
  good <- list(mk("mu"), mk("sigma"))
  expect_invisible(drmTMB:::check_unique_plain_dpars(good))
  bad <- list(mk("sigma"), mk("sigma"))
  expect_error(
    drmTMB:::check_unique_plain_dpars(bad),
    "at most one formula"
  )
  expect_error(
    drmTMB:::check_unique_plain_dpars(bad),
    "sigma"
  )
})

test_that("drm_known_dpars lists separate location and scale names", {
  loc <- drmTMB:::drm_location_dpars()
  known <- drmTMB:::drm_known_dpars()
  nonloc <- drmTMB:::drm_nonlocation_dpars()
  expect_true(all(loc %in% known))
  expect_false(any(loc %in% nonloc))
  expect_true("sigma" %in% nonloc)
  expect_true("rho12" %in% known)
  expect_true("mu1" %in% loc)
})

test_that("drm_smooth_marker_names lists mgcv-style markers", {
  markers <- drmTMB:::drm_smooth_marker_names()
  expect_type(markers, "character")
  expect_true("s" %in% markers)
  expect_true("te" %in% markers)
  expect_length(markers, 4L)
})

test_that("drm_reject_smooth_terms aborts when a smooth marker appears", {
  f <- bf(y ~ x + s(z))
  expect_error(
    drmTMB:::drm_reject_smooth_terms(f),
    "Smooth terms are not supported"
  )
  expect_error(
    drmTMB:::drm_reject_smooth_terms(bf(y ~ te(x, z))),
    "Smooth terms"
  )
  expect_invisible(drmTMB:::drm_reject_smooth_terms(bf(y ~ x + poly(z, 2))))
})

test_that("is_double_bar_call recognises || random-effect syntax", {
  expect_true(drmTMB:::is_double_bar_call(quote(1 + x || id)))
  expect_false(drmTMB:::is_double_bar_call(quote(1 | id)))
})

test_that("drm_desugar_double_bars expands || into separate bars", {
  dat <- data.frame(
    y = rnorm(12),
    x = rnorm(12),
    z = rnorm(12),
    id = factor(rep(1:6, 2))
  )
  f <- bf(y ~ x + (1 + z || id))
  g <- drmTMB:::drm_desugar_double_bars(f, dat)
  rhs <- deparse(g$calls[[1L]][[length(g$calls[[1L]])]])
  expect_match(rhs, "\\(1 \\| id\\)")
  expect_match(rhs, "\\(0 \\+ z \\| id\\)")
  same <- drmTMB:::drm_desugar_double_bars(bf(y ~ x + (1 | id)), dat)
  expect_identical(same$calls, bf(y ~ x + (1 | id))$calls)
})

test_that("desugar || rejects non-simple grouping variables", {
  dat <- data.frame(y = 1:3, x = 1:3, id = factor(1:3), extra = 1:3)
  bad <- bf(y ~ (1 || id + extra))
  expect_error(
    drmTMB:::drm_desugar_double_bars(bad, dat),
    "simple variables"
  )
})

test_that("desugar || rejects factor slopes on uncorrelated syntax", {
  dat <- data.frame(
    y = c(0, 1, 0, 1),
    g = factor(c("a", "a", "b", "b")),
    f = factor(c("l", "h", "l", "h"))
  )
  expect_error(
    drmTMB:::drm_desugar_double_bars(bf(y ~ (1 + f || g)), dat),
    "categorical random slopes"
  )
})

test_that("desugar || rejects empty random structure", {
  dat <- data.frame(y = 1:3, id = factor(1:3))
  expect_error(
    drmTMB:::drm_desugar_double_bars(bf(y ~ (0 || id)), dat),
    "at least one random term"
  )
})

test_that("desugar || rejects non-symbol numeric slopes", {
  dat <- data.frame(y = 1:4, x = 1:4, id = factor(rep(1:2, 2)))
  expect_error(
    drmTMB:::drm_desugar_double_bars(bf(y ~ (1 + I(x^2) || id)), dat),
    "simple numeric slopes"
  )
})

test_that("parse_drm_formula_entries batches entries with class", {
  calls <- list(quote(y ~ x), quote(sigma ~ 1))
  names <- c("mu", "sigma")
  entries <- drmTMB:::parse_drm_formula_entries(calls, names)
  expect_s3_class(entries, "drm_formula_entries")
  expect_length(entries, 2L)
  expect_identical(vapply(entries, `[[`, "", "dpar"), c("mu", "sigma"))
})
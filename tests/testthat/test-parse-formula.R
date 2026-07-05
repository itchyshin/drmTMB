# Regression tests for the drmTMB formula-grammar parser (R/parse-formula.R).
# Covers the left-hand-side interpretation and parser invariants documented in
# docs/design/01-formula-grammar.md.

entry_dpars <- function(formula) {
  vapply(formula$entries, `[[`, character(1), "dpar")
}

entry_responses <- function(formula) {
  vapply(
    formula$entries,
    function(entry) as.character(entry$response),
    character(1)
  )
}

# --- #696: bare-symbol location LHS is a response, not a parameterless dpar ----

test_that("a bare location-parameter LHS is parsed as a response for mu", {
  f_mu <- bf(mu ~ x)
  expect_identical(entry_dpars(f_mu), "mu")
  expect_identical(entry_responses(f_mu), "mu")

  f_mu1 <- bf(mu1 ~ x)
  expect_identical(entry_dpars(f_mu1), "mu")
  expect_identical(entry_responses(f_mu1), "mu1")

  f_mu2 <- bf(mu2 ~ x)
  expect_identical(entry_dpars(f_mu2), "mu")
  expect_identical(entry_responses(f_mu2), "mu2")
})

test_that("a bare non-location-parameter LHS still sets a parameterless dpar", {
  f_sigma <- bf(sigma ~ x)
  expect_identical(entry_dpars(f_sigma), "sigma")
  expect_true(is.na(entry_responses(f_sigma)))

  f_nu <- bf(y ~ x, nu ~ z)
  expect_identical(entry_dpars(f_nu), c("mu", "nu"))
  expect_identical(entry_responses(f_nu), c("y", NA_character_))
})

test_that("an ordinary response symbol maps to mu with a response", {
  f <- bf(y ~ x)
  expect_identical(entry_dpars(f), "mu")
  expect_identical(entry_responses(f), "y")
})

# --- #702: one formula per plain distributional parameter --------------------

test_that("a duplicated plain dpar is rejected at parse time, naming it", {
  expect_error(
    bf(y ~ x, sigma ~ a, sigma ~ b),
    "at most one formula"
  )
  expect_error(
    bf(y ~ x, sigma ~ a, sigma ~ b),
    "sigma"
  )
})

test_that("the location parameter is left to family consumers, not parse-time", {
  # A bare-symbol LHS that is not a keyed marker or a known dpar becomes a `mu`
  # response (see #696). The parse-time uniqueness check deliberately excludes
  # `mu` so families can emit their own location-count / unsupported-parameter /
  # latent-skewness messages instead of a generic duplicate-`mu` error. So two
  # location responses, or a mistyped parameter, must parse cleanly here.
  expect_no_error(bf(y1 ~ x, y2 ~ z))
  expect_no_error(bf(y ~ x, phi ~ 1))
})

test_that("keyed sd() and corpair() formulas may repeat", {
  expect_no_error(
    bf(
      y ~ x + (1 | id) + (1 | site),
      sd(id) ~ a,
      sd(site) ~ b
    )
  )
  expect_no_error(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ a,
      corpair(id, level = "group", block = "p", from = "sigma1", to = "sigma2") ~ b
    )
  )
})

test_that("distinct bivariate parameters are not treated as duplicates", {
  expect_no_error(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~ x,
      sigma2 = ~ x,
      rho12 = ~ x
    )
  )
  expect_no_error(bf(mvbind(y1, y2) ~ x, sigma1 = ~ x, sigma2 = ~ x))
})

# --- #703: corpair() endpoints must be bivariate ----------------------------

test_that("corpair() rejects univariate mu/sigma endpoints", {
  expect_error(
    bf(corpair(id, from = "mu", to = "sigma") ~ x),
    "mu1"
  )
  expect_error(
    bf(corpair(id, from = "mu", to = "mu1") ~ x),
    "endpoints"
  )
})

test_that("corpair() accepts bivariate endpoints", {
  f <- bf(corpair(id, from = "mu1", to = "mu2") ~ x)
  expect_true(!is.null(f$entries[[1]]$corpair))
  expect_identical(f$entries[[1]]$corpair$from, "mu1")
  expect_identical(f$entries[[1]]$corpair$to, "mu2")

  expect_no_error(bf(corpair(id, from = "sigma1", to = "sigma2") ~ x))
})

# --- #708.2: meta_known_V deprecation fires on either side -------------------

test_that("meta_known_V() deprecation warns on the RHS", {
  expect_warning(
    bf(y ~ moderator + meta_known_V(V = vi)),
    "meta_known_V"
  )
})

test_that("meta_known_V() deprecation warns on the LHS", {
  expect_warning(
    bf(meta_known_V(V = vi) ~ moderator),
    "meta_known_V"
  )
})

# --- #709.3: unknown structured markers fail loudly -------------------------

test_that("parse_structured_marker_call aborts on an unregistered marker", {
  expect_error(
    drmTMB:::parse_structured_marker_call(
      quote(gp(1 | site, coords = coords)),
      "gp",
      "mu"
    ),
    "unhandled structured marker"
  )
})

test_that("a registered spatial marker still parses", {
  parsed <- drmTMB:::parse_structured_marker_call(
    quote(spatial(1 | site, coords = coords)),
    "spatial",
    "mu"
  )
  expect_identical(parsed$type, "spatial")
})

# Fit-free coverage for R/random-effect-targets.R: drm_scalar_sd_mu_targets(),
# drm_binomial_sd_mu_targets(), and alias conflict handling in drm_resolve_sd_target().

scalar_sd_fixture <- function(expr = quote(1 | id), dpar = "mu") {
  data <- data.frame(
    id = factor(rep(c("a", "b"), each = 2L)),
    x = c(1, 2, 3, 4)
  )
  term <- drmTMB:::parse_random_mu_term(expr, dpar)
  re <- drmTMB:::build_random_mu_structure(list(term), data)
  list(data = data, terms = list(term), re = re)
}

sd_mu_entry <- function(group = "id", fun = "sd", coef = NULL) {
  lhs <- if (is.null(coef)) {
    call(fun, quote(id))
  } else {
    call(fun, quote(id), coef = coef)
  }
  list(lhs = lhs, dpar = "mu")
}

test_that("drm_scalar_sd_mu_targets() returns nothing when no SD entries are present", {
  fix <- scalar_sd_fixture()
  expect_identical(
    drmTMB:::drm_scalar_sd_mu_targets(
      list(), fix$terms, fix$re, family_label = "Test"
    ),
    list()
  )
  expect_identical(drmTMB:::drm_binomial_sd_mu_targets(list(), fix$terms, fix$re), list())
})

test_that("drm_scalar_sd_mu_targets() errors when SD entries lack matching mu RE terms", {
  data <- data.frame(id = factor(c("a", "b")))
  re0 <- drmTMB:::build_random_mu_structure(list(), data)
  entry <- sd_mu_entry()
  msg <- "No random-effect term matches"
  expect_error(
    drmTMB:::drm_scalar_sd_mu_targets(list(entry), list(), re0, family_label = "Poisson"),
    msg
  )
  expect_error(
    drmTMB:::drm_binomial_sd_mu_targets(list(entry), list(), re0),
    "Binomial"
  )
})

test_that("drm_scalar_sd_mu_targets() maps one intercept SD formula to one RE axis", {
  fix <- scalar_sd_fixture()
  targets <- drmTMB:::drm_scalar_sd_mu_targets(
    list(sd_mu_entry()),
    fix$terms,
    fix$re,
    family_label = "Probe"
  )
  expect_length(targets, 1L)
  expect_equal(targets[[1L]]$dpar, "mu")
  expect_equal(targets[[1L]]$group, "id")
  expect_equal(targets[[1L]]$identity$coef, "(Intercept)")
})

test_that("drm_scalar_sd_mu_targets() rejects duplicate mu SD formulas", {
  fix <- scalar_sd_fixture()
  entries <- list(sd_mu_entry(), sd_mu_entry())
  expect_error(
    drmTMB:::drm_scalar_sd_mu_targets(entries, fix$terms, fix$re, family_label = "Probe"),
    "Duplicate random-effect scale formula"
  )
})

test_that("drm_scalar_sd_mu_targets() rejects unsupported slope SD shapes unless allowed", {
  fix <- scalar_sd_fixture(quote(0 + x | id))
  expect_error(
    drmTMB:::drm_scalar_sd_mu_targets(
      list(sd_mu_entry()),
      fix$terms,
      fix$re,
      family_label = "Probe",
      allow_slopes = FALSE
    ),
    "does not support the selected random-effect shape"
  )
})

test_that("drm_scalar_sd_mu_targets() refuses mixed intercept and slope without layout flags", {
  data <- data.frame(
    id = factor(rep(c("a", "b"), each = 2L)),
    x = c(1, 2, 3, 4)
  )
  terms <- list(
    drmTMB:::parse_random_mu_term(quote(1 | id), "mu"),
    drmTMB:::parse_random_mu_term(quote(0 + x | id), "mu")
  )
  re <- drmTMB:::build_random_mu_structure(terms, data)
  entries <- list(sd_mu_entry(coef = "(Intercept)"))
  expect_error(
    drmTMB:::drm_scalar_sd_mu_targets(
      entries, terms, re, family_label = "Gaussian", allow_slopes = FALSE
    ),
    "cannot yet combine another random-effect coefficient"
  )
})

test_that("drm_resolve_sd_target() rejects conflicting sd1 alias and explicit dpar", {
  member <- list(
    provider = "ordinary",
    level = "group",
    group = "id",
    dpar = "mu",
    coef = "(Intercept)",
    block = NA_character_
  )
  target <- drmTMB:::parse_sd_lhs(call("sd1", quote(id)))
  target$target_dpar <- "mu2"
  expect_error(
    drmTMB:::drm_resolve_sd_target(target, list(member)),
    "Conflicting SD target distributional parameter and alias"
  )
})
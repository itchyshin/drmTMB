# Identity resolution in R/random-effect-targets.R (excluding binomial admission).

test_that("drm_ordinary_sd_target_members returns empty list for empty terms", {
  re <- list(
    n_terms = 0L, n_re = 0L, dpars = list(), groups = list()
  )
  expect_identical(
    drmTMB:::drm_ordinary_sd_target_members(list(), re, "mu"),
    list()
  )
  re_bad <- re
  re_bad$n_re <- 1L
  expect_error(
    drmTMB:::drm_ordinary_sd_target_members(list(), re_bad, "mu"),
    "misaligned random-effect metadata"
  )
})

test_that("drm_resolve_sd_target selects a unique ordinary member", {
  members <- list(
    list(
      provider = "ordinary", level = "group", group = "animal",
      dpar = "mu", coef = "(Intercept)", block = NA_character_
    ),
    list(
      provider = "ordinary", level = "group", group = "site",
      dpar = "mu", coef = "(Intercept)", block = NA_character_
    )
  )
  target <- list(group = "animal", fun = "sd", level = NA_character_)
  picked <- drmTMB:::drm_resolve_sd_target(target, members)
  expect_identical(picked$group, "animal")
  expect_identical(picked$dpar, "mu")

  alias_members <- list(
    list(
      provider = "ordinary", level = "group", group = "animal",
      dpar = "mu1", coef = "(Intercept)", block = NA_character_
    )
  )
  alias <- list(group = "animal", fun = "sd1", level = NA_character_)
  picked1 <- drmTMB:::drm_resolve_sd_target(alias, alias_members)
  expect_identical(picked1$dpar, "mu1")

  expect_error(
    drmTMB:::drm_resolve_sd_target(
      list(group = "missing", fun = "sd"),
      members
    ),
    "No ordinary random-effect SD target"
  )

  ambiguous <- list(group = "animal", fun = "sd", level = NA_character_)
  dup <- c(members, list(members[[1]]))
  expect_error(
    drmTMB:::drm_resolve_sd_target(ambiguous, dup),
    "Ambiguous"
  )
})

test_that("drm_resolve_sd_target fences malformed member metadata", {
  target <- list(group = "g", fun = "sd", level = NA_character_)
  bad_member <- list(
    provider = "ordinary", level = "group", group = "g",
    dpar = "mu", coef = character(0), block = NA_character_
  )
  expect_error(
    drmTMB:::drm_resolve_sd_target(target, list(bad_member)),
    "complete identity metadata"
  )
})

test_that("drm_scalar_sd_mu_targets errors when SD formula has no RE match", {
  entries <- list(list(lhs = quote(sd(1 | herd))))
  terms <- list()
  re <- list(n_terms = 0L, n_re = 0L, dpars = list(), groups = list())
  expect_error(
    drmTMB:::drm_scalar_sd_mu_targets(
      entries, terms, re, family_label = "Poisson"
    ),
    "No random-effect term matches"
  )
  expect_identical(
    drmTMB:::drm_scalar_sd_mu_targets(list(), terms, re, family_label = "X"),
    list()
  )
})
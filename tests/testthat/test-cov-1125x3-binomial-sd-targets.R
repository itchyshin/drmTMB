# R/random-effect-targets.R binomial mu SD admission.

local_ordinary_fixture <- function() {
  data <- data.frame(
    id = factor(rep(c("g3", "g1", "g2"), each = 2L)),
    x = c(1, 2, 3, 4, 5, 6)
  )
  terms <- list(parse_random_mu_term(quote(1 | id), dpar = "mu"))
  re <- build_random_mu_structure(terms, data)
  re$dpars <- rep("mu", re$n_terms)
  list(data = data, terms = terms, re = re)
}

test_that("drm_binomial_sd_mu_targets() resolves an intercept ordinary term", {
  fixture <- local_ordinary_fixture()
  members <- drm_ordinary_sd_target_members(fixture$terms, fixture$re, "mu")
  resolved <- drmTMB:::drm_binomial_sd_mu_targets(
    list(list(lhs = quote(sd(id)), dpar = "mu")),
    fixture$terms,
    fixture$re
  )
  expect_length(resolved, 1L)
  expect_identical(resolved[[1L]]$identity$coef, "(Intercept)")
  expect_identical(resolved[[1L]]$group, "id")
  expect_identical(resolved[[1L]]$dpar, "mu")
  expect_identical(resolved[[1L]]$group, "id")
})

test_that("drm_binomial_sd_mu_targets() errors when no ordinary RE matches", {
  fixture <- local_ordinary_fixture()
  expect_error(
    drmTMB:::drm_binomial_sd_mu_targets(
      list(list(lhs = quote(sd(missing)), dpar = "mu")),
      fixture$terms,
      fixture$re
    ),
    "No ordinary random-effect SD target"
  )
})
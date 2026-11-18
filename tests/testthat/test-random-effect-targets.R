ordinary_target_fixture <- function(exprs, dpar = "mu") {
  data <- data.frame(
    id = factor(rep(c("g3", "g1", "g2"), each = 2L)),
    x = c(1, 2, 3, 4, 5, 6),
    z = c(2, 1, 4, 3, 6, 5)
  )
  terms <- lapply(exprs, parse_random_mu_term, dpar = dpar)
  re <- build_random_mu_structure(terms, data)
  re$dpars <- rep(dpar, re$n_terms)
  list(data = data, terms = terms, re = re)
}

ordinary_target <- function(group = "id", dpar = NA_character_,
                            coef = NA_character_, block = NA_character_,
                            level = NA_character_, fun = "sd") {
  target <- parse_sd_lhs(call(fun, as.name(group)))
  target$target_dpar <- dpar
  target$target_coef <- coef
  target$target_block <- block
  target$level <- level
  target$explicit <- any(!is.na(c(dpar, coef, block)))
  target
}

bivariate_target_fixture <- function(label1 = "p", label2 = label1) {
  data <- data.frame(
    id = factor(rep(c("g3", "g1", "g2"), each = 2L)),
    x = c(1, 2, 3, 4, 5, 6)
  )
  make_term <- function(label, dpar) {
    parse_random_mu_term(
      call("|", call("|", call("+", 1, as.name("x")), as.name(label)), as.name("id")),
      dpar
    )
  }
  mu1 <- make_term(label1, "mu1")
  mu2 <- make_term(label2, "mu2")
  re <- build_biv_mu_random_structure(list(mu1), list(mu2), data)
  list(data = data, terms = list(mu1, mu2), re = re)
}

test_that("ordinary target members keep coefficient, latent and group maps separate", {
  fixture <- ordinary_target_fixture(list(quote(1 + x | p | id)))
  members <- drm_ordinary_sd_target_members(fixture$terms, fixture$re, "mu")
  expect_length(members, 2L)
  expect_equal(vapply(members, `[[`, character(1), "coef"), c("(Intercept)", "x"))
  expect_equal(vapply(members, `[[`, integer(1), "target_coef"), 1:2)
  expect_equal(vapply(members, `[[`, integer(1), "axis_pos0"), 0:1)
  expect_equal(members[[2L]]$block, "p")
  expect_equal(members[[2L]]$latent_pos0, 3:5)
  expect_equal(members[[2L]]$obs_group_index0, fixture$re$index0[, 2L] - 3L)
  expect_equal(members[[2L]]$group_levels, levels(fixture$data$id))
  expect_equal(members[[2L]]$design_value, fixture$data$x)
  expect_equal(members[[2L]]$provider, "ordinary")
})

test_that("unique simple targets include a labelled intercept or slope", {
  labelled <- ordinary_target_fixture(list(quote(1 | p | id)))
  slope <- ordinary_target_fixture(list(quote(0 + x | id)))
  for (fixture in list(labelled, slope)) {
    members <- drm_ordinary_sd_target_members(fixture$terms, fixture$re, "mu")
    expect_identical(drm_resolve_sd_target(ordinary_target(), members), members[[1L]])
  }
})

test_that("ambiguous and missing targets list actionable ordinary candidates", {
  fixture <- ordinary_target_fixture(list(quote(1 + x | p | id)))
  members <- drm_ordinary_sd_target_members(fixture$terms, fixture$re, "mu")
  expect_error(drm_resolve_sd_target(ordinary_target(), members), "Ambiguous.*id")
  expect_error(drm_resolve_sd_target(ordinary_target(), members), "coef=x")
  selected <- drm_resolve_sd_target(ordinary_target(dpar = "mu", coef = "x", block = "p"), members)
  expect_identical(selected, members[[2L]])
  expect_error(drm_resolve_sd_target(ordinary_target(coef = "z"), members), "No ordinary random-effect SD target")
  expect_error(drm_resolve_sd_target(ordinary_target(dpar = "sigma"), members), "No ordinary random-effect SD target")
  expect_error(drm_resolve_sd_target(ordinary_target(block = "other"), members), "No ordinary random-effect SD target")
  expect_error(drm_resolve_sd_target(ordinary_target(group = "other"), members), "No ordinary random-effect SD target")
  expect_error(drm_resolve_sd_target(ordinary_target(level = "spatial"), members), "Structured")
})

test_that("dpar filtering and term ordering do not use the printed label as an index", {
  mu <- ordinary_target_fixture(list(quote(0 + x | id), quote(1 | id)), "mu")
  sigma <- ordinary_target_fixture(list(quote(1 | id)), "sigma")
  members <- c(
    drm_ordinary_sd_target_members(mu$terms, mu$re, "mu"),
    drm_ordinary_sd_target_members(sigma$terms, sigma$re, "sigma")
  )
  expect_equal(vapply(members, `[[`, character(1), "dpar"), c("mu", "mu", "sigma"))
  chosen <- drm_resolve_sd_target(ordinary_target(dpar = "sigma"), members)
  expect_equal(chosen$dpar, "sigma")
  expect_equal(chosen$coef, "(Intercept)")
  expect_equal(members[[2L]]$target_term, 2L)
  expect_equal(members[[2L]]$target_coef, 2L)
  expect_equal(members[[2L]]$latent_pos0, 3:5)
})

test_that("ordinary resolver excludes structured metadata and respects response aliases", {
  fixture <- ordinary_target_fixture(list(quote(1 | id)), "mu1")
  members <- drm_ordinary_sd_target_members(fixture$terms, fixture$re, "mu1")
  expect_identical(drm_resolve_sd_target(ordinary_target(fun = "sd1"), members), members[[1L]])
  expect_error(drm_resolve_sd_target(ordinary_target(fun = "sd2"), members), "No ordinary")
  structured <- members[[1L]]
  structured$provider <- "phylo"
  structured$level <- "phylogenetic"
  expect_error(
    drm_resolve_sd_target(ordinary_target(level = "group"), list(structured)),
    "No random-effect SD target"
  )

  terms <- fixture$terms
  terms[[1L]]$type <- "phylo"
  expect_error(drm_ordinary_sd_target_members(terms, fixture$re, "mu1"), "ordinary")
})

test_that("real bivariate registry keeps mixed endpoints and global latent positions", {
  fixture <- bivariate_target_fixture()
  members <- drm_ordinary_sd_target_members(fixture$terms, fixture$re, c("mu1", "mu2"))
  expect_equal(vapply(members, `[[`, character(1), "dpar"), c("mu1", "mu1", "mu2", "mu2"))
  expect_equal(vapply(members, `[[`, integer(1), "axis_pos0"), 0:3)
  expect_equal(members[[4L]]$latent_pos0, 9:11)
  expect_equal(members[[4L]]$obs_group_index0, fixture$re$index0[, 4L] - 9L)
  expect_equal(members[[4L]]$target_term, 2L)
  expect_equal(members[[4L]]$coef, "x")
  expect_identical(drm_resolve_sd_target(ordinary_target(fun = "sd2", coef = "x", block = "p"), members), members[[4L]])
  expect_identical(drm_resolve_sd_target(ordinary_target(fun = "sd1", coef = "x", block = "p"), members), members[[2L]])
})

test_that("distinct labelled same-group blocks need explicit selectors", {
  fixture <- bivariate_target_fixture("p", "q")
  members <- drm_ordinary_sd_target_members(fixture$terms, fixture$re, c("mu1", "mu2"))
  expect_error(drm_resolve_sd_target(ordinary_target(coef = "x"), members), "Ambiguous")
  expect_identical(drm_resolve_sd_target(ordinary_target(coef = "x", block = "q"), members), members[[4L]])
  expect_error(drm_resolve_sd_target(ordinary_target(coef = "x", block = "r"), members), "block")

  same_dpar <- ordinary_target_fixture(list(
    quote(0 + x | p | id), quote(0 + z | q | id)
  ))
  same_members <- drm_ordinary_sd_target_members(same_dpar$terms, same_dpar$re, "mu")
  expect_error(drm_resolve_sd_target(ordinary_target(), same_members), "Ambiguous")
  expect_identical(drm_resolve_sd_target(ordinary_target(block = "q"), same_members), same_members[[2L]])
})

test_that("correlated pair metadata respects member and group order", {
  fixture <- ordinary_target_fixture(list(quote(1 + x | p | id)))
  members <- drm_ordinary_sd_target_members(fixture$terms, fixture$re, "mu")
  expect_equal(fixture$re$re_pair_index0[4:6], 0:2)
  expect_equal(members[[2L]]$latent_pos0, 3:5)
  broken <- fixture$re
  broken$re_pair_index0[4L] <- 1L
  expect_error(drm_ordinary_sd_target_members(fixture$terms, broken, "mu"), "pair")

  mu1 <- parse_random_mu_term(quote(1 | p | id), "mu1")
  mu2 <- parse_random_mu_term(quote(1 | p | id), "mu2")
  paired_re <- build_biv_mu_random_structure(list(mu1), list(mu2), fixture$data)
  expect_equal(paired_re$re_pair_index0[4:6], 0:2)
  expect_equal(length(drm_ordinary_sd_target_members(list(mu1, mu2), paired_re,
                                                     c("mu1", "mu2"))), 2L)
})

test_that("empty term inventory fails closed against nonempty registry", {
  fixture <- ordinary_target_fixture(list(quote(1 | id)))
  expect_error(drm_ordinary_sd_target_members(list(), fixture$re, "mu"), "misaligned")
  empty <- empty_random_mu_structure(nrow(fixture$data))
  expect_identical(drm_ordinary_sd_target_members(list(), empty, "mu"), list())
})

test_that("pair validation rejects equal-level axes with incompatible metadata", {
  data <- ordinary_target_fixture(list(quote(1 | id)))$data
  data$site <- factor(as.character(data$id), levels = levels(data$id))
  terms <- list(
    parse_random_mu_term(quote(0 + z | q | site), "mu"),
    parse_random_mu_term(quote(1 + x | p | id), "mu")
  )
  re <- build_random_mu_structure(terms, data)
  expect_equal(re$groups[[1L]], re$groups[[2L]])
  expect_length(drm_ordinary_sd_target_members(terms, re, "mu"), 3L)

  wrong_group <- re
  wrong_group$re_pair_index0[7:9] <- 0:2
  expect_error(drm_ordinary_sd_target_members(terms, wrong_group, "mu"), "pair")

  same_group_terms <- terms
  same_group_terms[[1L]] <- parse_random_mu_term(quote(0 + z | q | id), "mu")
  same_group <- build_random_mu_structure(same_group_terms, data)
  wrong_block <- same_group
  wrong_block$re_pair_index0[7:9] <- 0:2
  expect_error(drm_ordinary_sd_target_members(same_group_terms, wrong_block, "mu"), "pair")

  wrong_cor <- same_group
  wrong_cor$re_cor_id0[7:9] <- 9L
  expect_error(drm_ordinary_sd_target_members(same_group_terms, wrong_cor, "mu"), "pair")
  wrong_paired_cor <- same_group
  wrong_paired_cor$re_cor_id0[4:6] <- -1L
  expect_error(drm_ordinary_sd_target_members(same_group_terms, wrong_paired_cor, "mu"), "pair")
})

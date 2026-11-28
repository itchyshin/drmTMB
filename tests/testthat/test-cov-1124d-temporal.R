# Temporal validators called on parsed terms. No optimizer run.

temporal_term <- function(structure = c("ar1", "ou", "homtoep")) {
  structure <- match.arg(structure)
  formula <- switch(
    structure,
    ar1 = bf(y ~ temporal(1 | id, time = occasion, structure = "ar1")),
    ou = bf(y ~ temporal(1 | id, time = occasion, structure = "ou")),
    homtoep = bf(y ~ temporal(1 | id, time = occasion, structure = "homtoep"))
  )
  formula$entries[[1L]]$structured[[1L]]
}

test_that("only one temporal effect is extracted from a mu formula", {
  formula <- bf(y ~ temporal(1 | id, time = occasion, structure = "ar1") +
    temporal(1 | id, time = occasion, structure = "ou"))
  expect_error(
    drmTMB:::extract_gaussian_mu_temporal_term(formula$entries[[1L]]),
    "Only one temporal effect"
  )
})

test_that("temporal columns, occasions, and keys are checked before a fit", {
  term <- temporal_term()
  expect_error(
    drmTMB:::validate_temporal_raw_data(term, data.frame(y = 1)),
    "Missing temporal column"
  )

  fractional <- data.frame(id = c("a", "a"), occasion = c(1, 1.5))
  homtoep <- temporal_term("homtoep")
  expect_error(
    drmTMB:::validate_temporal_raw_data(homtoep, fractional),
    "homogeneous Toeplitz is defined by discrete lag"
  )

  duplicated_key <- data.frame(
    id = c("a", "a"),
    occasion = c(1, 1)
  )
  expect_error(
    drmTMB:::validate_temporal_raw_data(term, duplicated_key),
    "series-time keys must be unique"
  )
})

test_that("HOMTOEP rejects an ordinary intercept and fewer than three occasions", {
  homtoep <- temporal_term("homtoep")
  expect_error(
    drmTMB:::validate_temporal_gaussian_terms(
      homtoep,
      mu_re = list(terms = list(list(type = "intercept"))),
      sigma_re = list(terms = list()),
      sigma_rhs = quote(1),
      data = data.frame(id = c("a", "a"), occasion = c(1, 2))
    ),
    "does not allow an ordinary random intercept"
  )

  ar1 <- temporal_term("ar1")
  expect_error(
    drmTMB:::validate_temporal_gaussian_terms(
      ar1,
      mu_re = list(terms = list(list(), list())),
      sigma_re = list(terms = list()),
      sigma_rhs = quote(1),
      data = data.frame(id = c("a", "b"), occasion = c(1, 2))
    ),
    "at most one ordinary random intercept"
  )

  short <- data.frame(id = c("a", "a"), occasion = c(1, 2))
  expect_error(
    drmTMB:::build_temporal_mu_structure(homtoep, short),
    "at least three common occasions"
  )
})

test_that("a phylogenetic term paired with temporal AR1 asks for OU", {
  phylo_term <- list(
    type = "phylo",
    coef_names = "(Intercept)",
    covariance_label = NULL,
    group = "species",
    tree = "tree"
  )
  ar1 <- list(structure = "ar1", group = "species", time = "elapsed")
  expect_error(
    drmTMB:::validate_phylo_temporal_ou_pair(
      ar1,
      phylo_term,
      data.frame(species = c("a", "a"), elapsed = c(0, 1)),
      environment()
    ),
    "structure = \"ou\""
  )

  labelled <- phylo_term
  labelled$covariance_label <- "p"
  ou <- list(structure = "ou", group = "species", time = "elapsed")
  expect_error(
    drmTMB:::validate_phylo_temporal_ou_pair(
      ou,
      labelled,
      data.frame(species = c("a", "a"), elapsed = c(0, 1)),
      environment()
    ),
    "unlabelled"
  )
})

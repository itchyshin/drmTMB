# validate_gaussian_aggregation_gaussian() refusal branches (helpers in
# test-gaussian-aggregation-helpers.R already cover numeric aggregation).

gaussian_agg_guard_args <- function() {
  list(
    meta = list(),
    mu_phylo = list(term = NULL),
    mu_phylo_interaction = list(term = NULL),
    mu_spatial = list(term = NULL),
    mu_animal = list(term = NULL),
    mu_relmat = list(term = NULL),
    mu_re = list(terms = list()),
    sigma_re = list(terms = list()),
    sd_mu_entries = list(),
    sd_phylo_entries = list(),
    sparse_mu = FALSE
  )
}

test_that("validate_gaussian_aggregation_gaussian() accepts a bare fixed-effect layout", {
  args <- gaussian_agg_guard_args()
  expect_invisible(do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args))
})

test_that("validate_gaussian_aggregation_gaussian() refuses meta_V sampling covariance", {
  args <- gaussian_agg_guard_args()
  args$meta$V <- diag(2)
  expect_error(
    do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args),
    "known sampling covariance"
  )
})

test_that("validate_gaussian_aggregation_gaussian() refuses structured random fields", {
  args <- gaussian_agg_guard_args()
  args$mu_phylo$term <- list(type = "phylo")
  expect_error(
    do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args),
    "structured random effects"
  )
  args <- gaussian_agg_guard_args()
  args$mu_spatial$term <- list(type = "spatial")
  expect_error(
    do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args),
    "structured random effects"
  )
})

test_that("validate_gaussian_aggregation_gaussian() refuses ordinary random effects", {
  args <- gaussian_agg_guard_args()
  args$mu_re$terms <- list(list(type = "intercept"))
  expect_error(
    do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args),
    "ordinary random effects"
  )
  args <- gaussian_agg_guard_args()
  args$sigma_re$terms <- list(list(type = "intercept"))
  expect_error(
    do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args),
    "ordinary random effects"
  )
})

test_that("validate_gaussian_aggregation_gaussian() refuses direct SD formulas", {
  args <- gaussian_agg_guard_args()
  args$sd_mu_entries <- list("(Intercept)")
  expect_error(
    do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args),
    "random-effect SD models"
  )
  args <- gaussian_agg_guard_args()
  args$sd_phylo_entries <- list("phylo")
  expect_error(
    do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args),
    "random-effect SD models"
  )
})

test_that("validate_gaussian_aggregation_gaussian() refuses sparse_fixed together with aggregation", {
  args <- gaussian_agg_guard_args()
  args$sparse_mu <- TRUE
  expect_error(
    do.call(drmTMB:::validate_gaussian_aggregation_gaussian, args),
    "sparse fixed-effect"
  )
})

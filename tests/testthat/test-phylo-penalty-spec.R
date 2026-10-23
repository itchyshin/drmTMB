# Fit-free characterisation tests for R/penalty.R: drm_phylo_penalty(),
# drm_parse_phylo_penalty() and drm_apply_phylo_penalty_spec(). The fit-level
# behaviour is covered by test-phylo-penalized-map.R and
# test-phylo-penalty-sweep.R; here every validation branch is hit directly.

# Minimal hand-built spec with the fields drm_apply_phylo_penalty_spec() reads.
phylo_spec <- function(q = 1L, has = TRUE, direct_sd = FALSE) {
  list(
    tmb_data = list(has_sd_phylo_model = if (direct_sd) 1L else 0L),
    structured = list(phylo_mu = list(has = has)),
    start = list(log_sd_phylo = numeric(q))
  )
}

test_that("drm_phylo_penalty() returns the documented class and fields", {
  pen <- drm_phylo_penalty()
  expect_s3_class(pen, "drm_phylo_penalty")
  expect_true(inherits(pen, "list"))
  expect_named(pen, c("sd_u", "sd_alpha", "rate", "cor_sd"), ignore.order = TRUE)
  expect_equal(pen$sd_u, 1)
  expect_equal(pen$sd_alpha, 0.05)
  expect_equal(pen$rate, -log(0.05))
  expect_null(pen$cor_sd)

  pen2 <- drm_phylo_penalty(sd_u = 2, sd_alpha = 0.1, cor_sd = 0.5)
  expect_equal(pen2$sd_u, 2)
  expect_equal(pen2$sd_alpha, 0.1)
  expect_equal(pen2$rate, -log(0.1) / 2)
  expect_equal(pen2$cor_sd, 0.5)
})

test_that("drm_phylo_penalty() validates sd_u", {
  msg <- "sd_u.*single positive number"
  expect_error(drm_phylo_penalty(sd_u = 0), msg)
  expect_error(drm_phylo_penalty(sd_u = -1), msg)
  expect_error(drm_phylo_penalty(sd_u = NA_real_), msg)
  expect_error(drm_phylo_penalty(sd_u = Inf), msg)
  expect_error(drm_phylo_penalty(sd_u = c(1, 2)), msg)
  expect_error(drm_phylo_penalty(sd_u = numeric(0)), msg)
  expect_error(drm_phylo_penalty(sd_u = "1"), msg)
})

test_that("drm_phylo_penalty() validates sd_alpha", {
  msg <- "sd_alpha.*single number in"
  expect_error(drm_phylo_penalty(sd_alpha = 0), msg)
  expect_error(drm_phylo_penalty(sd_alpha = 1), msg)
  expect_error(drm_phylo_penalty(sd_alpha = 1.5), msg)
  expect_error(drm_phylo_penalty(sd_alpha = -0.1), msg)
  expect_error(drm_phylo_penalty(sd_alpha = NA_real_), msg)
  expect_error(drm_phylo_penalty(sd_alpha = c(0.1, 0.2)), msg)
  expect_error(drm_phylo_penalty(sd_alpha = "0.05"), msg)
})

test_that("drm_phylo_penalty() validates cor_sd", {
  msg <- "cor_sd.*single positive number or NULL"
  expect_error(drm_phylo_penalty(cor_sd = 0), msg)
  expect_error(drm_phylo_penalty(cor_sd = -0.5), msg)
  expect_error(drm_phylo_penalty(cor_sd = Inf), msg)
  expect_error(drm_phylo_penalty(cor_sd = NA_real_), msg)
  expect_error(drm_phylo_penalty(cor_sd = c(0.5, 1)), msg)
  expect_error(drm_phylo_penalty(cor_sd = "0.5"), msg)
  expect_error(drm_phylo_penalty(cor_sd = NULL), NA)
})

test_that("drm_parse_phylo_penalty() accepts NULL and penalty objects only", {
  expect_null(drm_parse_phylo_penalty(NULL))
  pen <- drm_phylo_penalty(cor_sd = 0.5)
  expect_identical(drm_parse_phylo_penalty(pen), pen)

  msg <- "must be created with.*drm_phylo_penalty.*or be NULL"
  expect_error(drm_parse_phylo_penalty(1), msg)
  expect_error(drm_parse_phylo_penalty("pen"), msg)
  expect_error(drm_parse_phylo_penalty(TRUE), msg)
  # A bare list with the right fields but no class is rejected.
  expect_error(
    drm_parse_phylo_penalty(
      list(sd_u = 1, sd_alpha = 0.05, rate = -log(0.05), cor_sd = NULL)
    ),
    msg
  )
  expect_error(drm_parse_phylo_penalty(unclass(pen)), msg)
})

test_that("drm_apply_phylo_penalty_spec() leaves a spec alone for NULL penalty", {
  spec <- phylo_spec(q = 2L)
  out <- drm_apply_phylo_penalty_spec(spec, NULL)
  # Only the three always-present DATA fields are added.
  expect_identical(out$tmb_data$penalize_phylo, 0L)
  expect_identical(out$tmb_data$phylo_sd_penalty_rate, numeric(0))
  expect_identical(out$tmb_data$phylo_cor_penalty_sd, numeric(0))
  expect_null(out$estimator)
  expect_null(out$penalty)
  out$tmb_data[c("penalize_phylo", "phylo_sd_penalty_rate", "phylo_cor_penalty_sd")] <- NULL
  expect_identical(out, spec)
})

test_that("drm_apply_phylo_penalty_spec() writes penalty fields into the spec", {
  pen <- drm_phylo_penalty(sd_u = 2, sd_alpha = 0.1)
  out <- drm_apply_phylo_penalty_spec(phylo_spec(q = 1L), pen)
  expect_identical(out$tmb_data$penalize_phylo, 1L)
  expect_equal(out$tmb_data$phylo_sd_penalty_rate, pen$rate)
  expect_identical(out$tmb_data$phylo_cor_penalty_sd, numeric(0))
  expect_identical(out$estimator, "MAP")
  expect_identical(out$penalty, pen)

  pen_cor <- drm_phylo_penalty(cor_sd = 0.5)
  out2 <- drm_apply_phylo_penalty_spec(phylo_spec(q = 3L), pen_cor)
  expect_equal(out2$tmb_data$phylo_sd_penalty_rate, rep(pen_cor$rate, 3L))
  expect_equal(out2$tmb_data$phylo_cor_penalty_sd, 0.5)
  expect_identical(out2$estimator, "MAP")
})

test_that("drm_apply_phylo_penalty_spec() aborts when cor_sd needs two SDs", {
  pen_cor <- drm_phylo_penalty(cor_sd = 0.5)
  expect_error(
    drm_apply_phylo_penalty_spec(phylo_spec(q = 1L), pen_cor),
    class = "drm_phylo_cor_penalty_needs_two_sd"
  )
  expect_error(
    drm_apply_phylo_penalty_spec(phylo_spec(q = 1L), pen_cor),
    "at least two phylogenetic SDs"
  )
  # cor_sd = NULL with a single SD is fine; two SDs with cor_sd is fine.
  expect_error(drm_apply_phylo_penalty_spec(phylo_spec(q = 1L), drm_phylo_penalty()), NA)
  expect_error(drm_apply_phylo_penalty_spec(phylo_spec(q = 2L), pen_cor), NA)
})

test_that("drm_apply_phylo_penalty_spec() aborts without a usable phylo term", {
  pen <- drm_phylo_penalty()
  expect_error(
    drm_apply_phylo_penalty_spec(phylo_spec(has = FALSE), pen),
    "requires a phylogenetic term"
  )
  no_struct <- phylo_spec()
  no_struct$structured <- NULL
  expect_error(
    drm_apply_phylo_penalty_spec(no_struct, pen),
    "requires a phylogenetic term"
  )
  expect_error(
    drm_apply_phylo_penalty_spec(phylo_spec(direct_sd = TRUE), pen),
    "not supported with direct"
  )
  expect_error(
    drm_apply_phylo_penalty_spec(phylo_spec(q = 0L), pen),
    "no phylogenetic SD parameters"
  )
})

test_that("a penalty object prints without error", {
  # There is no dedicated print method; the default list print must work.
  pen <- drm_phylo_penalty(cor_sd = 0.5)
  expect_output(print(pen))
  expect_output(print(drm_phylo_penalty()))
})

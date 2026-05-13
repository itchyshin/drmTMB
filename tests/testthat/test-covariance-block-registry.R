new_covariance_registry_re <- function(dpars, labels) {
  n_obs <- 4L
  group_levels <- c("g1", "g2")
  n_groups <- length(group_levels)
  n_terms <- length(dpars)
  group_index0 <- c(0L, 0L, 1L, 1L)

  groups <- rep(list(group_levels), n_terms)
  names(groups) <- labels

  list(
    n_terms = n_terms,
    n_re = n_terms * n_groups,
    index0 = matrix(rep(group_index0, n_terms), nrow = n_obs),
    value = matrix(1, nrow = n_obs, ncol = n_terms),
    term_id0 = rep(seq_len(n_terms) - 1L, each = n_groups),
    dpar_id0 = rep(seq_len(n_terms) - 1L, each = n_groups),
    re_pos0 = rep(0L, n_terms * n_groups),
    re_cor_id0 = rep(-1L, n_terms * n_groups),
    re_pair_index0 = rep(-1L, n_terms * n_groups),
    labels = labels,
    dpars = dpars,
    coef_names = rep("(Intercept)", n_terms),
    group_names = rep("id", n_terms),
    covariance_labels = rep("p", n_terms),
    groups = groups
  )
}

new_three_member_covariance_registry <- function() {
  re_mu <- new_covariance_registry_re(
    dpars = c("mu1", "mu2"),
    labels = c("mu1:(1 | p | id)", "mu2:(1 | p | id)")
  )
  re_sigma <- new_covariance_registry_re(
    dpars = "sigma1",
    labels = "sigma1:(1 | p | id)"
  )
  registry <- drmTMB:::empty_labelled_covariance_block_registry()
  registry <- drmTMB:::append_covariance_registry_block(
    registry,
    re_list = list(re_mu, re_sigma),
    member_terms = list(seq_len(re_mu$n_terms), seq_len(re_sigma$n_terms)),
    parameter = c("scaffold:12", "scaffold:13", "scaffold:23"),
    tmb_parameter = rep(NA_character_, 3L),
    tmb_index = rep(NA_integer_, 3L),
    implemented = FALSE
  )
  registry$n_blocks <- nrow(registry$blocks)
  registry
}

test_that("internal covariance registry can describe a guarded q=3 block", {
  registry <- new_three_member_covariance_registry()
  block <- registry$blocks[1L, , drop = FALSE]
  members <- registry$members[
    order(registry$members$member_id0),
    ,
    drop = FALSE
  ]
  pairs <- registry$pairs[order(registry$pairs$pair_id0), , drop = FALSE]

  expect_equal(registry$n_blocks, 1L)
  expect_equal(block$n_members, 3L)
  expect_equal(block$n_pairs, 3L)
  expect_false(block$implemented)
  expect_equal(block$group, "id")
  expect_equal(block$block_label, "p")
  expect_equal(block$group_levels[[1L]], c("g1", "g2"))
  expect_equal(members$member_id0, 0:2)
  expect_equal(members$dpar, c("mu1", "mu2", "sigma1"))
  expect_equal(members$component, c("mu", "mu", "sigma"))
  expect_equal(members$response_index, c(1L, 2L, 1L))
  expect_equal(members$coef, rep("(Intercept)", 3L))
  expect_true(all(
    vapply(members$latent_index0, length, integer(1L)) == 4L
  ))
  expect_true(all(
    vapply(members$design_value, function(x) all(is.finite(x)), logical(1L))
  ))

  expect_equal(pairs$pair_id0, 0:2)
  expect_equal(pairs$from_member_id0, c(0L, 0L, 1L))
  expect_equal(pairs$to_member_id0, c(1L, 2L, 2L))
  expect_equal(pairs$from_dpar, c("mu1", "mu1", "mu2"))
  expect_equal(pairs$to_dpar, c("mu2", "sigma1", "sigma1"))
  expect_equal(pairs$class, c("mean-mean", "mean-scale", "mean-scale"))
  expect_equal(pairs$parameter, c("scaffold:12", "scaffold:13", "scaffold:23"))
  expect_true(all(is.na(pairs$tmb_parameter)))
  expect_true(all(is.na(pairs$tmb_index)))
})

test_that("q=3 block TMB data remains guarded until parameterization exists", {
  registry <- new_three_member_covariance_registry()

  expect_error(
    drmTMB:::labelled_covariance_block_tmb_data(registry),
    "two-member|q > 2"
  )
})

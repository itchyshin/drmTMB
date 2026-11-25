mock_registry_fit <- function() {
  list(
    model = list(
      random = list(
        covariance_blocks = list(
          pairs = data.frame(
            class = "mean-mean",
            from_dpar = "mu1",
            to_dpar = "mu2",
            block_id0 = 1L,
            tmb_parameter = "eta_cor_mu",
            parameter = "eta_cor_mu12",
            stringsAsFactors = FALSE
          ),
          blocks = data.frame(block_id0 = 1L, n_groups = 3L),
          members = data.frame(
            block_id0 = 1L,
            dpar = "mu1",
            latent_index0 = I(list(c(0L, 1L, 5L)))
          )
        )
      )
    ),
    corpars = list(mu = c(eta_cor_mu12 = 0.82))
  )
}

test_that("registry_covariance_pair selects a unique mean-mean block", {
  fit <- mock_registry_fit()
  info <- drmTMB:::registry_covariance_pair(
    fit,
    class = "mean-mean",
    from_dpar = "mu1",
    to_dpar = "mu2"
  )
  expect_false(info$complex)
  expect_equal(info$pair$class, "mean-mean")
  expect_equal(info$block$n_groups, 3L)
  expect_equal(nrow(info$members), 1L)

  empty_fit <- list(model = list(random = list(covariance_blocks = list())))
  expect_null(drmTMB:::registry_covariance_pair(empty_fit, "mean-mean"))
  dup <- fit
  dup$model$random$covariance_blocks$pairs <- rbind(
    dup$model$random$covariance_blocks$pairs,
    dup$model$random$covariance_blocks$pairs
  )
  complex <- drmTMB:::registry_covariance_pair(dup, "mean-mean", "mu1", "mu2")
  expect_true(complex$complex)
  expect_equal(complex$n_pairs, 2L)
})

test_that("registry_member helpers slice members and latent indices", {
  fit <- mock_registry_fit()
  info <- drmTMB:::registry_covariance_pair(fit, "mean-mean", "mu1", "mu2")
  member <- drmTMB:::registry_covariance_member(info, "mu1")
  expect_equal(member$dpar, "mu1")
  expect_null(drmTMB:::registry_covariance_member(info, "sigma1"))
  counts <- drmTMB:::registry_member_group_counts(member, 3L)
  expect_equal(length(counts), 3L)
  expect_equal(sum(counts), 3L)
  expect_equal(drmTMB:::registry_member_group_counts(member, NA), integer())
  rho <- drmTMB:::registry_covariance_pair_rho_abs(fit, info)
  expect_equal(rho, 0.82)
})

test_that("mu_sigma and bivariate diagnostic messages cover warning paths", {
  msg <- drmTMB:::mu_sigma_re_diagnostic_message(
    near_rho_boundary = TRUE,
    weak_replication = FALSE,
    weak_sd = FALSE
  )
  expect_match(msg, "close to")
  msg2 <- drmTMB:::mu_sigma_re_diagnostic_message(
    near_rho_boundary = FALSE,
    weak_replication = TRUE,
    weak_sd = TRUE
  )
  expect_match(msg2, "fewer than two")
  expect_match(msg2, "tiny")
  ok <- drmTMB:::mu_sigma_re_diagnostic_message(FALSE, FALSE, FALSE)
  expect_match(ok, "non-negligible")

  q4_warn <- drmTMB:::bivariate_q4_re_diagnostic_message(
    near_rho_boundary = TRUE,
    weak_group_count = FALSE,
    weak_replication = FALSE,
    weak_location_sd = FALSE,
    weak_scale_sd = FALSE
  )
  expect_match(q4_warn, "q4")
  q4_rho <- drmTMB:::bivariate_q4_re_diagnostic_message(
    FALSE, FALSE, FALSE, FALSE, FALSE, rho_unavailable = TRUE
  )
  expect_match(q4_rho, "could not be extracted")
})

test_that("phylo direct-SD and shared-shift messages respond to status flags", {
  expect_match(
    drmTMB:::phylo_direct_sd_message("sigma", TRUE, FALSE),
    "non-finite"
  )
  expect_match(
    drmTMB:::phylo_direct_sd_message("sigma", FALSE, TRUE),
    "fewer than two"
  )
  expect_match(
    drmTMB:::phylo_direct_sd_message("sigma", FALSE, FALSE),
    "replicated species"
  )
  expect_match(
    drmTMB:::phylo_shared_shift_message("sd(species)", "ok"),
    "no large shared shift"
  )
  expect_match(
    drmTMB:::phylo_shared_shift_message("sd(species)", "note"),
    "common shift"
  )
})

test_that("random_effect_correlated_block_ranks reports within-group design rank", {
  re <- list(
    n_cors = 1L,
    n_terms = 2L,
    re_cor_id0 = c(0L, 0L),
    term_id0 = c(0L, 0L),
    index = matrix(c(1L, 1L, 2L, 2L), ncol = 2L),
    value = matrix(c(1, 2, 3, 4, 5, 6), ncol = 2L),
    cor_labels = c("block")
  )
  ranks <- drmTMB:::random_effect_correlated_block_ranks(re)
  expect_length(ranks, 1L)
  expect_equal(unname(ranks), "1/1")
  empty <- drmTMB:::random_effect_correlated_block_ranks(
    modifyList(re, list(n_cors = 0L))
  )
  expect_equal(empty, character())
})
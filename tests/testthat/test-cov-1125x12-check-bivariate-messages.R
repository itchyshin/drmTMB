test_that("bivariate mu RE diagnostic messages enumerate weak-data paths", {
  boundary <- drmTMB:::bivariate_mu_re_diagnostic_message(TRUE, FALSE, FALSE)
  expect_match(boundary, "close to")
  both <- drmTMB:::bivariate_mu_re_diagnostic_message(FALSE, TRUE, TRUE)
  expect_match(both, "tiny relative")
  replicate <- drmTMB:::bivariate_mu_re_diagnostic_message(FALSE, TRUE, FALSE)
  expect_match(replicate, "fewer than two")
  weak_sd <- drmTMB:::bivariate_mu_re_diagnostic_message(FALSE, FALSE, TRUE)
  expect_match(weak_sd, "tiny relative")
  ok <- drmTMB:::bivariate_mu_re_diagnostic_message(FALSE, FALSE, FALSE)
  expect_match(ok, "non-negligible")
  missing <- drmTMB:::bivariate_mu_re_diagnostic_message(
    FALSE, FALSE, FALSE, rho_unavailable = TRUE
  )
  expect_match(missing, "could not be extracted")
})

test_that("bivariate phylogenetic mu messages mention replication and mixing", {
  mix <- drmTMB:::bivariate_phylo_mu_diagnostic_message(
    near_rho_boundary = TRUE,
    weak_replication = FALSE,
    weak_sd = FALSE,
    same_group_covariance = TRUE
  )
  expect_match(mix, "ordinary group-level covariance")
  weak_both <- drmTMB:::bivariate_phylo_mu_diagnostic_message(
    FALSE, TRUE, TRUE, same_group_covariance = FALSE
  )
  expect_match(weak_both, "fewer than two fitted observations")
  same_only <- drmTMB:::bivariate_phylo_mu_diagnostic_message(
    FALSE, FALSE, FALSE, same_group_covariance = TRUE
  )
  expect_match(same_only, "cleanly separated")
  healthy <- drmTMB:::bivariate_phylo_mu_diagnostic_message(
    FALSE, FALSE, FALSE, same_group_covariance = FALSE
  )
  expect_match(healthy, "replicated species")
})

test_that("check_scale_phylo_identifiability returns note when pdHess is false", {
  mock <- list(
    model = list(
      structured = list(
        phylo_mu = list(
          has = TRUE,
          dpar_endpoint = c("mu", "sigma")
        )
      )
    ),
    sdr = list(pdHess = FALSE)
  )
  with_mocked_bindings(
    phylo_mu_endpoint_dpars = function(phylo_mu) c("mu", "sigma"),
    .package = "drmTMB",
    {
      row <- drmTMB:::check_scale_phylo_identifiability(mock)
      expect_equal(row$check, "scale_phylo_identifiability")
      expect_equal(row$status, "note")
      expect_match(row$message, "positive-definite Hessian")
    }
  )
  mock_ok <- modifyList(mock, list(sdr = list(pdHess = TRUE)))
  with_mocked_bindings(
    phylo_mu_endpoint_dpars = function(phylo_mu) c("mu", "sigma"),
    .package = "drmTMB",
    {
      ok_row <- drmTMB:::check_scale_phylo_identifiability(mock_ok)
      expect_equal(ok_row$status, "ok")
    }
  )
  no_phylo <- list(model = list(structured = list(phylo_mu = list(has = FALSE))))
  expect_null(drmTMB:::check_scale_phylo_identifiability(no_phylo))
})

test_that("check_penalized_fit distinguishes fixed priors from phylo penalty", {
  prior_fit <- list(penalty = NULL)
  class(prior_fit) <- "drmTMB"
  with_mocked_bindings(
    drm_has_fixed_priors = function(object) TRUE,
    .package = "drmTMB",
    {
      row <- drmTMB:::check_penalized_fit(prior_fit)
      expect_equal(row$check, "penalized_map")
      expect_match(row$message, "penalized objective")
    }
  )
  penalized <- list(penalty = 0.1)
  with_mocked_bindings(
    drm_has_fixed_priors = function(object) FALSE,
    .package = "drmTMB",
    {
      map_row <- drmTMB:::check_penalized_fit(penalized)
      expect_match(map_row$message, "maximum-a-posteriori")
      expect_null(drmTMB:::check_penalized_fit(list()))
    }
  )
})
reader_journey_audit <- local({
  cached <- NULL

  function() {
    if (is.null(cached)) {
      skip_if_not_installed("ape")
      audit_path <- testthat::test_path("..", "..", "tools", "run-reader-workflow-audit.R")
      skip_if_not(file.exists(audit_path), "The development audit script is not installed with drmTMB")
      audit_env <- new.env(parent = globalenv())
      audit_out <- tempfile(fileext = ".tsv")
      withr::local_envvar(DRMTMB_READER_AUDIT_OUT = audit_out)
      source(audit_path, local = audit_env)
      value <- audit_env$reader_workflow_audit
      value$tsv <- utils::read.delim(audit_out, check.names = FALSE)
      cached <<- value
    }
    cached
  }
})

reader_journey <- function(id) {
  reader_journey_audit()$fixtures[[id]]
}

test_that("the ten native reader journeys complete their generic post-fit smoke", {
  audit <- reader_journey_audit()
  results <- audit$tsv
  workflows <- c(
    "continuous_location_scale", "count_with_effort", "denominator_proportion",
    "ordinal_condition", "boundary_proportion", "phylogenetic_trait",
    "spatial_site_effect", "bivariate_traits", "meta_analysis", "missing_response"
  )

  expect_equal(nrow(results), 10L)
  expect_setequal(results$workflow, workflows)
  expect_setequal(names(audit$fixtures), workflows)
  expect_true(all(vapply(audit$fixtures, function(x) inherits(x$fit, "drmTMB"), logical(1))))
  expect_true(all(results$fit == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(results$diagnostics == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(results$report_output == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(results$unsupported_response == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(grepl("^Unknown confidence-interval target:", results$unsupported_message)))
  expect_setequal(results$unsupported_request, paste0("profile target unsupported:", workflows))
  expect_true(all(grepl("generic post-fit smoke", results$report_artifact, fixed = TRUE)))
})

test_that("each reader journey retains its scientific meaning through exported APIs", {
  continuous <- reader_journey("continuous_location_scale")
  continuous_parameters <- predict_parameters(
    continuous$fit, dpar = c("mu", "sigma"), type = "response"
  )
  expect_true(all(is.finite(continuous_parameters$estimate[continuous_parameters$dpar == "mu"])))
  expect_true(all(
    is.finite(continuous_parameters$estimate[continuous_parameters$dpar == "sigma"]) &
      continuous_parameters$estimate[continuous_parameters$dpar == "sigma"] > 0
  ))

  count <- reader_journey("count_with_effort")
  count_grid <- count$data[rep(1L, 2L), c("habitat", "x", "effort")]
  count_grid$habitat <- factor("degraded", levels = unique(count$data$habitat))
  count_grid$effort <- c(2, 6)
  count_mean <- predict_parameters(
    count$fit, newdata = count_grid, dpar = "mu", type = "response",
    include_newdata = FALSE
  )$estimate
  expect_true(all(is.finite(count_mean) & count_mean > 0))
  expect_gt(count_mean[[2L]], count_mean[[1L]])

  denominator <- reader_journey("denominator_proportion")
  probability <- predict_parameters(denominator$fit, dpar = "mu", type = "response")$estimate
  distribution <- fitted_distribution(denominator$fit)
  expect_true(all(is.finite(probability) & probability >= 0 & probability <= 1))
  expect_equal(
    distribution$params$trials,
    denominator$data$germinated + denominator$data$failed
  )

  ordinal <- reader_journey("ordinal_condition")
  ordinal_distribution <- fitted_distribution(ordinal$fit)
  ordinal_probability <- vapply(seq_along(levels(ordinal$data$score)), function(k) {
    ordinal_distribution$d(rep(k, nrow(ordinal$data)))
  }, numeric(nrow(ordinal$data)))
  ordinal_targets <- profile_targets(ordinal$fit)
  ordinal_raw <- ordinal_targets[grepl("^ordinal:theta_ord:", ordinal_targets$parm), , drop = FALSE]
  ordinal_cutpoints <- ordinal_targets[grepl("^ordinal:cutpoint:", ordinal_targets$parm), , drop = FALSE]
  expect_true(all(is.finite(ordinal_probability) & ordinal_probability >= 0 & ordinal_probability <= 1))
  expect_equal(rowSums(ordinal_probability), rep(1, nrow(ordinal$data)), tolerance = 1e-8)
  expect_true(all(ordinal_cutpoints$profile_ready))
  expect_true(all(!ordinal_raw$profile_ready))
  expect_false(isTRUE(all.equal(ordinal_cutpoints$estimate, ordinal_raw$estimate)))

  boundary <- reader_journey("boundary_proportion")
  boundary_parameters <- predict_parameters(
    boundary$fit, dpar = c("mu", "zoi", "coi"), type = "response"
  )
  expect_true(all(is.finite(stats::fitted(boundary$fit)) & stats::fitted(boundary$fit) >= 0 & stats::fitted(boundary$fit) <= 1))
  expect_setequal(unique(boundary_parameters$dpar), c("mu", "zoi", "coi"))
  expect_true(all(is.finite(boundary_parameters$estimate) & boundary_parameters$estimate >= 0 & boundary_parameters$estimate <= 1))

  phylo <- reader_journey("phylogenetic_trait")
  phylo_deviation <- ranef(phylo$fit, dpar = "phylo_mu")
  phylo_term <- phylo_deviation$terms[["phylo(1 | species)"]]
  phylo_targets <- profile_targets(phylo$fit)
  phylo_sd <- phylo_targets[grepl("^sd:mu:phylo", phylo_targets$parm), , drop = FALSE]
  expect_named(phylo_deviation$terms, "phylo(1 | species)")
  expect_true(length(phylo_term) > 0L)
  expect_true(all(is.finite(phylo_term)))
  expect_gt(nrow(phylo_sd), 0L)
  expect_true(all(is.finite(phylo_sd$estimate) & phylo_sd$estimate > 0))
  expect_true(all(phylo_sd$profile_ready))

  spatial <- reader_journey("spatial_site_effect")
  spatial_deviation <- ranef(spatial$fit, dpar = "spatial_mu")
  spatial_term <- spatial_deviation$terms[["spatial(1 | site)"]]
  spatial_targets <- profile_targets(spatial$fit)
  spatial_sd <- spatial_targets[grepl("^sd:mu:spatial", spatial_targets$parm), , drop = FALSE]
  expect_named(spatial_deviation$terms, "spatial(1 | site)")
  expect_true(length(spatial_term) > 0L)
  expect_true(all(is.finite(spatial_term)))
  expect_gt(nrow(spatial_sd), 0L)
  expect_true(all(is.finite(spatial_sd$estimate) & spatial_sd$estimate > 0))
  expect_true(all(spatial_sd$profile_ready))

  bivariate <- reader_journey("bivariate_traits")
  bivariate_grid <- bivariate$data[seq_len(3L), c("food", "disturbance")]
  bivariate_grid$food <- 0
  bivariate_grid$disturbance <- c(-0.75, 0, 0.75)
  response_rho <- rho12(bivariate$fit, newdata = bivariate_grid)
  link_rho <- rho12(bivariate$fit, newdata = bivariate_grid, type = "link")
  expect_true(all(is.finite(response_rho) & abs(response_rho) < 1))
  expect_equal(response_rho, 0.999999 * tanh(link_rho), tolerance = 1e-12)
  expect_false(isTRUE(all.equal(response_rho, link_rho)))
  expect_true(all(diff(response_rho) > 0))

  meta <- reader_journey("meta_analysis")
  meta_diagnostic <- check_drm(meta$fit)
  known_sampling <- meta_diagnostic[
    meta_diagnostic$check == "known_sampling_covariance", , drop = FALSE
  ]
  expect_identical(known_sampling$status, "ok")
  expect_match(known_sampling$message, "meta_V\\(V = V\\)")
  expect_true(all(is.finite(sigma(meta$fit)) & sigma(meta$fit) > 0))

  missing <- reader_journey("missing_response")
  missing_rows <- is.na(missing$data$growth)
  expect_equal(nobs(missing$fit), sum(!missing_rows))
  expect_length(stats::fitted(missing$fit), nrow(missing$data))
  expect_true(all(is.na(stats::residuals(missing$fit)[missing_rows])))
  expect_true(all(is.finite(stats::fitted(missing$fit)[missing_rows])))
})

test_that("check_drm() makes a boundary warning visible to reader workflows", {
  fit <- reader_journey("bivariate_traits")$fit
  diagnostic <- check_drm(fit, rho_boundary = 1e-6)
  rho_row <- diagnostic[diagnostic$check == "rho12_boundary", , drop = FALSE]

  expect_s3_class(diagnostic, "drm_check")
  expect_identical(rho_row$status, "warning")
  expect_false(isTRUE(attr(diagnostic, "ok")))
  expect_identical(
    isTRUE(attr(diagnostic, "ok")),
    !any(diagnostic$status %in% c("warning", "error"))
  )
})

test_that("reader vignettes do not depend on private missing-data slots", {
  vignette_files <- list.files("vignettes", pattern = "\\.Rmd$", full.names = TRUE)
  vignette_text <- unlist(lapply(vignette_files, readLines, warn = FALSE), use.names = FALSE)
  expect_false(any(grepl("fit$missing_data", vignette_text, fixed = TRUE)))
})

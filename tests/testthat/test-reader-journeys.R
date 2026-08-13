test_that("the ten native reader journeys complete their generic post-fit smoke", {
  skip_if_not_installed("ape")

  audit_env <- new.env(parent = globalenv())
  audit_out <- tempfile(fileext = ".tsv")
  withr::local_envvar(DRMTMB_READER_AUDIT_OUT = audit_out)
  source(testthat::test_path("..", "..", "tools", "run-reader-workflow-audit.R"), local = audit_env)

  results <- utils::read.delim(audit_out, check.names = FALSE)
  expect_equal(nrow(results), 10L)
  expect_setequal(
    results$workflow,
    c(
      "continuous_location_scale", "count_with_effort", "denominator_proportion",
      "ordinal_condition", "boundary_proportion", "phylogenetic_trait",
      "spatial_site_effect", "bivariate_traits", "meta_analysis", "missing_response"
    )
  )
  expect_true(all(results$fit == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(results$diagnostics == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(results$report_output == "pass"), info = paste(results$first_blocker, collapse = "\n"))
  expect_true(all(grepl("generic post-fit smoke", results$report_artifact, fixed = TRUE)))
})

test_that("the reader audit does not call warning diagnostics a pass", {
  source_lines <- readLines(testthat::test_path("..", "..", "tools", "run-reader-workflow-audit.R"))
  expect_true(any(grepl('isTRUE\\(attr\\(diagnostic\\$value, "ok"\\)\\)', source_lines)))
})

test_that("ordinal probabilities are response-scale probabilities, not raw thresholds", {
  set.seed(20260813)
  dat <- data.frame(
    x = seq(-1, 1, length.out = 60),
    score = ordered(sample(c("low", "medium", "high"), 60, replace = TRUE),
      levels = c("low", "medium", "high"))
  )
  fit <- drmTMB(bf(score ~ x), cumulative_logit(), data = dat)
  grid <- prediction_grid(fit, focal = "x", at = list(x = c(-.5, 0, .5)))
  distribution <- fitted_distribution(fit, newdata = grid)
  probability <- vapply(seq_along(levels(dat$score)), function(k) {
    distribution$d(rep(k, nrow(grid)))
  }, numeric(nrow(grid)))

  expect_equal(nrow(probability), nrow(grid))
  expect_true(all(is.finite(probability) & probability >= 0 & probability <= 1))
  expect_equal(rowSums(probability), rep(1, nrow(grid)), tolerance = 1e-8)
  targets <- profile_targets(fit)
  expect_true(all(!targets$profile_ready[grepl("^ordinal:theta_ord:", targets$parm)]))
  expect_true(all(targets$profile_ready[grepl("^ordinal:cutpoint:", targets$parm)]))
})

test_that("missing-response rows retain fitted values but not residuals", {
  set.seed(20260813)
  dat <- data.frame(x = seq(-1, 1, length.out = 40))
  dat$y <- .5 + .7 * dat$x + stats::rnorm(nrow(dat), sd = .2)
  missing <- c(5L, 16L, 29L)
  dat$y[missing] <- NA_real_
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1), gaussian(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )

  expect_equal(nobs(fit), nrow(dat) - length(missing))
  expect_length(fitted(fit), nrow(dat))
  expect_true(all(is.na(residuals(fit)[missing])))
  expect_true(all(is.finite(fitted(fit)[missing])))
})

assessment_path <- testthat::test_path("..", "..", "tools", "assess-phylo-temporal-ou-g11.R")
assessment_environment <- new.env(parent = baseenv())
sys.source(assessment_path, envir = assessment_environment)

make_phylo_temporal_ou_g11_summary <- function() {
  cells <- c(P1 = 1000L, P2 = 1000L, P3 = 1000L, P4 = 500L)
  do.call(rbind, lapply(names(cells), function(cell) {
    data.frame(
      cell = cell,
      parm = paste0("fixef:mu:", c("(Intercept)", "between", "within")),
      n_attempted = unname(cells[[cell]]), n_available = unname(cells[[cell]]),
      availability = 1, coverage_all = 0.95,
      coverage_conditional = 0.95,
      coverage_mcse = sqrt(0.95 * 0.05 / unname(cells[[cell]])),
      lower_tail_all = 0.025, upper_tail_all = 0.025,
      lower_tail_conditional = 0.025, upper_tail_conditional = 0.025,
      bias = 0.02, empirical_sd = 1, mean_interval_width = 2 * stats::qnorm(0.975),
      source_commit = paste(rep("a", 40L), collapse = ""),
      worker_md5 = paste(rep("b", 32L), collapse = ""), stringsAsFactors = FALSE
    )
  }))
}

test_that("phylo OU G11 assessment applies the frozen primary and stress rules", {
  assessed <- assessment_environment$phylo_temporal_ou_g11_assess(make_phylo_temporal_ou_g11_summary())
  expect_true(all(assessed$qualification[assessed$cell %in% c("P1", "P2", "P3")] == "qualified_in_simulated_cell"))
  expect_true(all(assessed$qualification[assessed$cell == "P4"] == "stress_report_only"))
  expect_true(all(assessed$criterion_coverage[assessed$cell %in% c("P1", "P2", "P3")]))
})

test_that("phylo OU G11 target registry retains the shared generating coefficients", {
  targets <- assessment_environment$phylo_temporal_ou_g11_targets()
  expect_equal(
    targets$truth,
    rep(c(0, 0.5, 0.5), times = 4L)
  )
})

test_that("phylo OU G11 assessment rejects incomplete and forged campaign summaries", {
  reference <- make_phylo_temporal_ou_g11_summary()
  expect_error(
    assessment_environment$phylo_temporal_ou_g11_assess(reference[-1L, , drop = FALSE]),
    "denominator"
  )
  forged <- reference
  forged$worker_md5[[1L]] <- "forged"
  expect_error(assessment_environment$phylo_temporal_ou_g11_assess(forged), "provenance")
})

test_that("phylo OU G11 assessment retains a known failing coverage fixture", {
  failing <- make_phylo_temporal_ou_g11_summary()
  failing$coverage_all[[1L]] <- 0.90
  failing$coverage_mcse[[1L]] <- sqrt(0.90 * 0.10 / failing$n_attempted[[1L]])
  assessed <- assessment_environment$phylo_temporal_ou_g11_assess(failing)
  expect_false(assessed$criterion_coverage[[1L]])
  expect_identical(assessed$qualification[[1L]], "unqualified_in_simulated_cell")
})

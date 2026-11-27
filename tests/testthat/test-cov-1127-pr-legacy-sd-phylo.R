# Lifecycle hook in R/random-effect-scale-formulas.R (called from parse-formula.R).

test_that("legacy sd_phylo* formula heads emit the phylogenetic replacement hint", {
  withr::local_options(lifecycle_verbosity = "warning")
  expect_warning(
    drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo"),
    "deprecated in drmTMB 0.3.0"
  )
  expect_warning(
    drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo1"),
    "deprecated in drmTMB 0.3.0"
  )
  expect_warning(
    drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo2"),
    "deprecated in drmTMB 0.3.0"
  )
})
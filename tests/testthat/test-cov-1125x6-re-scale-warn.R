# Legacy SD formula deprecation in R/random-effect-scale-formulas.R.

test_that("warn_sd_phylo_legacy_deprecated() emits lifecycle warnings", {
  expect_warning(
    drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo"),
    "deprecated"
  )
  expect_invisible(
    suppressWarnings(drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo1"))
  )
  expect_invisible(
    suppressWarnings(drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo2"))
  )
})
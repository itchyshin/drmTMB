# R/random-effect-scale-formulas.R deprecation wiring.

test_that("warn_sd_phylo_legacy_deprecated() maps each legacy constructor", {
  expect_warning(
    drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo"),
    "0.3.0"
  )
  suppressWarnings(
    expect_warning(
      drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo1"),
      "sd_phylo1"
    )
  )
  suppressWarnings(
    expect_warning(
      drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo2"),
      "sd_phylo2"
    )
  )
})

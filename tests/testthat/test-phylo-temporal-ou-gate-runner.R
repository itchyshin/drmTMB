# The gate runners live in tools/, which .Rbuildignore keeps out of the built
# package, so this suite runs only from a source checkout.
test_that("temporal gate runners fail closed and pass their self-tests", {
  runner_path <- testthat::test_path("..", "..", "tools", "phylo-temporal-ou-gates.R")
  testthat::skip_if_not(
    file.exists(runner_path),
    "tools/phylo-temporal-ou-gates.R is not in the built package"
  )
  runner <- normalizePath(runner_path)
  source_runner <- normalizePath(file.path("..", "..", "tools", "temporal-source-map-gates.R"))
  expect_match(system2("Rscript", c("--vanilla", runner, "--self-test"), stdout = TRUE),
               "PHYLO_TEMPORAL_OU_RUNNER_SELFTEST_PASS")
  expect_match(system2("Rscript", c("--vanilla", source_runner, "--self-test"), stdout = TRUE),
               "TEMPORAL_SOURCE_MAP_RUNNER_SELFTEST_PASS")
  expect_true(any(grepl("TEMPORAL_SOURCE_MAP_M01_BOOTSTRAP_PASS",
                        system2("Rscript", c("--vanilla", source_runner, "M01-bootstrap"), stdout = TRUE),
                        fixed = TRUE)))
  expect_match(system2("Rscript", c("--vanilla", source_runner, "M02"), stdout = TRUE),
               "TEMPORAL_SOURCE_MAP_M02_PASS")
  # M03 is the Phase-0 provenance receipt: it pins the SHA-256 of
  # src/drmTMB.cpp at a1d01dab3 and the R version of that session, so any
  # later native edit or R upgrade makes it stale by design. It is a
  # historical gate, not a regression test; the self-test above still runs
  # its incomplete-fingerprint negative control.
  expect_match(system2("Rscript", c("--vanilla", runner, "G14"), stdout = TRUE),
               "PHYLO_TEMPORAL_OU_G14_PASS")
  # The retained G9b full-study artifacts now exist, so G9b-full verifies
  # them; the replaced G9 gate and the pending calibration gates fail closed.
  expect_match(system2("Rscript", c("--vanilla", runner, "G9b-full"), stdout = TRUE),
               "PHYLO_TEMPORAL_OU_G9B_FULL_PASS")
  bad <- suppressWarnings(system2("Rscript", c("--vanilla", runner, "G9"), stdout = TRUE, stderr = TRUE))
  expect_false(is.null(attr(bad, "status")))
  pending <- suppressWarnings(system2("Rscript", c("--vanilla", runner, "G10"), stdout = TRUE, stderr = TRUE))
  expect_false(is.null(attr(pending, "status")))
})

test_that("the phylo-OU reader workflow renders (G15)", {
  runner_path <- testthat::test_path("..", "..", "tools", "phylo-temporal-ou-gates.R")
  testthat::skip_if_not(
    file.exists(runner_path),
    "tools/phylo-temporal-ou-gates.R is not in the built package"
  )
  testthat::skip_if_not_installed("rmarkdown")
  testthat::skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  expect_match(system2("Rscript", c("--vanilla", normalizePath(runner_path), "G15"), stdout = TRUE),
               "PHYLO_TEMPORAL_OU_G15_PASS")
})

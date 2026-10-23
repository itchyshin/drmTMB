# The A9f REML-by-route table (docs/design/261-reml-by-route.md) is GENERATED
# by tools/write-reml-route-table.R. Regeneration must be byte-identical (G3)
# and the generator's own G1 sanity check (every TSV-sourced capability_id is
# a real row in inst/extdata/julia-capabilities.tsv) must actually fire on a
# planted defect -- these two tests call the generator's functions IN-PROCESS
# (source()-ing the script has no file-write side effect; see the
# `sys.nframe() == 0L` guard at the bottom of that file), mirroring how
# test-julia-gate-vs-engine.R checks the capability TSV against its registry
# function rather than shelling out.

pkg_root <- normalizePath(testthat::test_path("..", ".."), mustWork = FALSE)
gen_path <- file.path(pkg_root, "tools", "write-reml-route-table.R")
# Under R CMD check the tests run from the INSTALLED package, where tools/ and
# docs/design/ are not shipped: the generator cannot be sourced there, so the
# regeneration checks run in the source tree only (devtools::test()) and skip
# under check rather than erroring at file level.
gen_env <- NULL
if (file.exists(gen_path)) {
  gen_env <- new.env()
  source(gen_path, local = gen_env)
}

test_that("the REML-by-route table regenerates byte-identically", {
  skip_if(is.null(gen_env), "tools/write-reml-route-table.R is not shipped in the package (source tree only)")
  doc_path <- file.path(pkg_root, "docs", "design", "261-reml-by-route.md")
  skip_if_not(file.exists(doc_path), "docs/design/261-reml-by-route.md not committed yet")

  committed <- readLines(doc_path)
  regenerated <- gen_env$drm_reml_route_table_lines(pkg_root)

  expect_identical(
    regenerated, committed,
    info = "regenerating docs/design/261-reml-by-route.md changed its content -- either the generator drifted from the committed .md, or the .md was hand-edited"
  )
})

test_that("every TSV-sourced route in the generator exists in the committed capabilities TSV", {
  skip_if(is.null(gen_env), "tools/write-reml-route-table.R is not shipped in the package (source tree only)")
  # Positive check: the real, unmodified generator must build without error
  # against the real TSV (the RED CONTROL for this gate -- planting a bogus
  # capability_id and confirming this same call `stop()`s -- is run manually
  # and recorded verbatim in docs/dev-log/after-task/2026-09-05-a9f-reml-table.md,
  # since it requires temporarily editing committed source, not something a
  # permanent test should do to itself).
  expect_no_error(gen_env$drm_reml_route_table_rows(pkg_root))

  reml_table <- gen_env$drm_reml_route_table_rows(pkg_root)
  tsv <- utils::read.delim(
    file.path(pkg_root, "inst", "extdata", "julia-capabilities.tsv"),
    sep = "\t", stringsAsFactors = FALSE, quote = ""
  )
  tsv_sourced <- reml_table$capability_id[grepl("^TSV", reml_table$source)]
  expect_true(all(unique(tsv_sourced) %in% tsv$capability_id))

  # Every row must land on a real verdict, and every "NO" must carry a gap
  # note naming an issue/decision (G5: no silent disagreement).
  expect_true(all(reml_table$agree %in% c("YES", "NO", "N/A")))
  no_rows <- reml_table[reml_table$agree == "NO", ]
  expect_true(all(nzchar(no_rows$gap)))
})

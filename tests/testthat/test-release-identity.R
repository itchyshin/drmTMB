test_that("public release identity matches DESCRIPTION", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  public_paths <- file.path(
    root,
    c(
      "DESCRIPTION", "README.md", "NEWS.md", "_pkgdown.yml",
      "vignettes/drmTMB.Rmd", "vignettes/formula-grammar.Rmd"
    )
  )
  skip_if(
    !all(file.exists(public_paths)),
    "source-only public release surfaces are unavailable"
  )

  version <- unname(read.dcf(public_paths[[1L]], fields = "Version")[[1L]])
  read_text <- function(path) paste(readLines(path, warn = FALSE), collapse = "\n")
  surfaces <- lapply(public_paths[-1L], read_text)
  names(surfaces) <- basename(public_paths[-1L])

  expect_match(surfaces[["README.md"]], paste0("`drmTMB` ", version), fixed = TRUE)
  expect_match(
    surfaces[["NEWS.md"]],
    paste0("# drmTMB ", version),
    fixed = TRUE
  )
  expect_match(surfaces[["_pkgdown.yml"]], paste0(version, " pre-CRAN"), fixed = TRUE)
  expect_match(surfaces[["drmTMB.Rmd"]], paste0("`drmTMB` ", version), fixed = TRUE)

  current_reader_text <- paste(
    surfaces[["README.md"]],
    surfaces[["_pkgdown.yml"]],
    surfaces[["drmTMB.Rmd"]],
    sep = "\n"
  )
  expect_false(grepl("0\\.6\\.0 development|v0\\.5\\.0", current_reader_text))
  expect_false(grepl("not in the frozen 0\\.7\\.0", surfaces[["NEWS.md"]]))
  expect_false(grepl("Non-logit links", surfaces[["formula-grammar.Rmd"]], fixed = TRUE))
  expect_match(
    surfaces[["formula-grammar.Rmd"]],
    "Logit, probit, and complementary log-log links are available.",
    fixed = TRUE
  )
})

test_that("plot-heavy reader articles remain development articles", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  articles_path <- file.path(root, "vignettes", "articles")
  skip_if(
    !dir.exists(articles_path),
    "source-only development article layout is unavailable"
  )

  expect_true(all(file.exists(file.path(
    articles_path,
    c(
      "distributional-outputs-and-adequacy.Rmd",
      "figure-gallery.Rmd",
      "function-map-cheatsheet.Rmd",
      "model-workflow.Rmd",
      "phylogenetic-spatial.Rmd",
      "simulation-plot-grammar.Rmd"
    )
  ))))
  expect_false(file.exists(file.path(articles_path, "function-map-cheatsheet.png")))
})

test_that("public release identity matches DESCRIPTION", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  public_paths <- setNames(
    file.path(
      root,
      c(
        "DESCRIPTION", "README.md", "NEWS.md", "_pkgdown.yml",
        "vignettes/drmTMB.Rmd", "vignettes/formula-grammar.Rmd",
        "inst/trust-dossier/README.md", "inst/trust-dossier/run.R"
      )
    ),
    c(
      "description", "readme", "news", "pkgdown", "vignette", "formula",
      "trust_readme", "trust_run"
    )
  )
  skip_if(
    !all(file.exists(public_paths)),
    "source-only public release surfaces are unavailable"
  )

  version <- unname(read.dcf(public_paths[["description"]], fields = "Version")[[1L]])
  read_text <- function(path) paste(readLines(path, warn = FALSE), collapse = "\n")
  surfaces <- lapply(public_paths[names(public_paths) != "description"], read_text)

  expect_match(surfaces[["readme"]], paste0("`drmTMB` ", version), fixed = TRUE)
  expect_match(
    surfaces[["news"]],
    paste0("# drmTMB ", version),
    fixed = TRUE
  )
  expect_match(surfaces[["pkgdown"]], paste0(version, " pre-CRAN"), fixed = TRUE)
  expect_match(surfaces[["vignette"]], paste0("`drmTMB` ", version), fixed = TRUE)

  current_reader_text <- paste(
    surfaces[["readme"]],
    surfaces[["pkgdown"]],
    surfaces[["vignette"]],
    sep = "\n"
  )
  expect_false(grepl("0\\.6\\.0 development|v0\\.5\\.0", current_reader_text))
  expect_false(grepl("not in the frozen 0\\.7\\.0", surfaces[["news"]]))
  expect_false(grepl("Non-logit links", surfaces[["formula"]], fixed = TRUE))
  expect_match(
    surfaces[["formula"]],
    "Logit, probit, and complementary log-log links are available.",
    fixed = TRUE
  )
  expect_false(grepl(
    "MSPL\\) entry point remains\\s+\\*\\*logit-only",
    surfaces[["news"]],
    perl = TRUE
  ))

  trust_text <- paste(
    surfaces[["trust_readme"]],
    surfaces[["trust_run"]],
    sep = "\n"
  )
  expect_false(grepl("all on CRAN.*drmTMB", trust_text, ignore.case = TRUE))
  expect_match(
    trust_text,
    "drmTMB installed from the source or release candidate under review",
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

  pkgdown_path <- file.path(root, "pkgdown")
  if (dir.exists(pkgdown_path)) {
    expect_true(all(file.exists(file.path(
      pkgdown_path,
      "assets",
      "cheatsheets",
      c("drmTMB-function-map.pdf", "drmTMB-function-cheatsheet.pdf")
    ))))
  }
})

test_that("original function-map sources cover the current public API", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  namespace_path <- file.path(root, "NAMESPACE")
  source_path <- file.path(root, "tools", "function-cheatsheet-source.Rmd")
  generator_path <- file.path(root, "tools", "build-function-pdfs.py")
  skip_if(
    !all(file.exists(c(namespace_path, source_path, generator_path))),
    "source-only function-map inputs are unavailable"
  )

  namespace_lines <- readLines(namespace_path, warn = FALSE)
  exports <- sub(
    "^export\\(([^)]+)\\)$", "\\1",
    grep("^export\\(", namespace_lines, value = TRUE)
  )
  current_exports <- setdiff(exports, c("gr", "meta_known_V"))
  source <- paste(readLines(source_path, warn = FALSE), collapse = "\n")

  for (name in current_exports) {
    expect_match(source, paste0(name, "()"), fixed = TRUE, info = name)
  }
  expect_match(
    source,
    "These functions create or inspect a separate `drm_pair_association` object.",
    fixed = TRUE
  )
  expect_match(source, "eta` is distinct from residual `rho12", fixed = TRUE)

  reference_links <- regmatches(
    source,
    gregexpr("\\.\\./reference/([^)]+)\\.html", source, perl = TRUE)
  )[[1L]]
  reference_topics <- unique(sub(
    "[.]html$", "",
    sub("^\\.\\./reference/", "", reference_links)
  ))
  reference_topics <- setdiff(reference_topics, "index")
  expect_true(all(file.exists(file.path(
    root, "man", paste0(reference_topics, ".Rd")
  ))))
})

test_that("article restores the audited map and original printable downloads", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  article_path <- file.path(
    root, "vignettes", "articles", "function-map-cheatsheet.Rmd"
  )
  image_path <- file.path(
    root, "vignettes", "articles", "function-map-cheatsheet.png"
  )
  assets <- file.path(
    root,
    "pkgdown",
    "assets",
    "cheatsheets",
    c("drmTMB-function-map.pdf", "drmTMB-function-cheatsheet.pdf")
  )
  skip_if(
    !file.exists(article_path) || !dir.exists(file.path(root, "pkgdown")),
    "source-only function-map article and assets are unavailable"
  )

  article <- paste(readLines(article_path, warn = FALSE), collapse = "\n")
  expect_match(
    article,
    'knitr::include_graphics("function-map-cheatsheet.png")',
    fixed = TRUE
  )
  expect_match(article, "Open the full-size function map", fixed = TRUE)
  expect_match(article, "../cheatsheets/drmTMB-function-map.pdf", fixed = TRUE)
  expect_match(
    article,
    "../cheatsheets/drmTMB-function-cheatsheet.pdf",
    fixed = TRUE
  )
  expect_false(grepl("function_map_html()", article, fixed = TRUE))

  expect_true(file.exists(image_path))
  expect_identical(
    unname(tools::md5sum(image_path)),
    "6c907feba6f95e84594d15ab8dba95d3"
  )
  expect_true(all(file.exists(assets)))
  expect_true(all(file.info(assets)$size > 50000))
  expect_false(file.exists(file.path(
    root, "vignettes", "function-map-cheatsheet.png"
  )))
})

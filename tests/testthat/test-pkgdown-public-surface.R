test_that("rendered pkgdown prose rejects internal process language", {
  site <- tempfile("pkgdown-site-")
  dir.create(file.path(site, "articles"), recursive = TRUE)
  writeLines("<html><body>Home</body></html>", file.path(site, "index.html"))
  writeLines("<html><body>Guide</body></html>", file.path(site, "articles", "drmTMB.html"))
  writeLines(
    "<html><body>This implementation lane closes issue #123.</body></html>",
    file.path(site, "articles", "capability-and-limits.html")
  )
  writeLines("{}", file.path(site, "search.json"))
  writeLines("<urlset/>", file.path(site, "sitemap.xml"))
  writeLines("Reader documentation", file.path(site, "llms.txt"))

  checker <- testthat::test_path("..", "..", "tools", "check-pkgdown-public-surface.R")
  testthat::skip_if_not(file.exists(checker), "pkgdown source checker is not in this build")
  rscript <- file.path(R.home("bin"), "Rscript")
  testthat::skip_if_not(file.exists(rscript), "Rscript is not available")
  result <- suppressWarnings(system2(rscript, c(checker, site), stdout = TRUE, stderr = TRUE))

  expect_true(is.numeric(attr(result, "status")))
  expect_match(paste(result, collapse = "\n"), "internal process language")
})

test_that("rendered pkgdown prose keeps ordinary scientific language", {
  site <- tempfile("pkgdown-site-")
  dir.create(file.path(site, "articles"), recursive = TRUE)
  writeLines("<html><body>Home</body></html>", file.path(site, "index.html"))
  writeLines("<html><body>Guide</body></html>", file.path(site, "articles", "drmTMB.html"))
  writeLines(
    "<html><body>An agent-based simulation follows a biological movement process.</body></html>",
    file.path(site, "articles", "capability-and-limits.html")
  )
  writeLines("{}", file.path(site, "search.json"))
  writeLines("<urlset/>", file.path(site, "sitemap.xml"))
  writeLines("Reader documentation", file.path(site, "llms.txt"))

  checker <- testthat::test_path("..", "..", "tools", "check-pkgdown-public-surface.R")
  testthat::skip_if_not(file.exists(checker), "pkgdown source checker is not in this build")
  rscript <- file.path(R.home("bin"), "Rscript")
  testthat::skip_if_not(file.exists(rscript), "Rscript is not available")
  result <- system2(rscript, c(checker, site), stdout = TRUE, stderr = TRUE)

  expect_null(attr(result, "status"))
  expect_match(paste(result, collapse = "\n"), "PKGDOWN PUBLIC SURFACE PASS")
})

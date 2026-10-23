# Guard for a break that reached main on 2026-09-05: PRs #1116 and #1118 exported five
# functions (chibar_pvalue, lrt_boundary, coevolution_cor, coevolution_vc,
# coevolution_summary) and documented them, but neither added its topic to
# `_pkgdown.yml`. `pkgdown::build_site()` then ABORTS in build_reference_index() --
# a fatal error, not a warning -- so the whole site stops building, and nothing in
# `R CMD check` or the test suite notices. This test is the missing notice.
#
# It reimplements the covered/uncovered half of pkgdown's index check rather than
# calling pkgdown, because pkgdown is not a dependency of this package and a
# skip_if_not_installed() guard would simply never run in CI. `starts_with()` is the
# only selector `_pkgdown.yml` uses; an unrecognised selector leaves its topics
# looking uncovered, so the test fails loudly rather than passing silently.
test_that("every exported topic appears in the pkgdown reference index", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = FALSE)
  yml <- file.path(root, "_pkgdown.yml")
  man <- file.path(root, "man")
  skip_if(!file.exists(yml) || !dir.exists(man), "source tree unavailable")

  lines <- readLines(yml, warn = FALSE)
  start <- grep("^reference:", lines)
  skip_if(length(start) != 1L, "no single reference: block")
  after <- grep("^[a-zA-Z]", lines)
  after <- after[after > start]
  block <- lines[seq(start + 1L, if (length(after)) after[1L] - 1L else length(lines))]

  entries <- trimws(sub("^\\s*-\\s*", "", grep("^\\s+-\\s", block, value = TRUE)))
  prefixes <- sub('^starts_with\\("(.*)"\\)$', "\\1",
                  grep('^starts_with\\("', entries, value = TRUE))
  literal <- entries[!grepl("^[a-z_]+\\(", entries)]

  # A topic is covered when ANY of its aliases is indexed, not only its \\name{}:
  # `model-fit-extractors` is listed in _pkgdown.yml but that file's \\name{} is
  # `vcov.drmTMB`. Keying on \\name{} alone reports it as a false positive.
  rd <- list.files(man, pattern = "[.]Rd$", full.names = TRUE)
  uncovered <- character()
  n_topics <- 0L
  for (f in rd) {
    txt <- readLines(f, warn = FALSE)
    if (any(grepl("^\\\\keyword\\{internal\\}", txt))) next
    n_topics <- n_topics + 1L
    aliases <- sub("^\\\\alias\\{(.*)\\}$", "\\1", grep("^\\\\alias\\{", txt, value = TRUE))
    aliases <- c(aliases, sub("[.]Rd$", "", basename(f)))
    hit <- any(aliases %in% literal) ||
      any(vapply(aliases, function(a) any(startsWith(a, prefixes)), logical(1L)))
    if (!hit) uncovered <- c(uncovered, basename(f))
  }
  expect_gt(n_topics, 50L)
  expect_equal(sort(uncovered), character(0))
})

#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
site_dir <- if (length(args)) args[[1L]] else "pkgdown-site"
site_dir <- normalizePath(site_dir, mustWork = TRUE)

private_stems <- c("AGENTS", "CLAUDE", "CONTRIBUTING", "ROADMAP")
private_pages <- paste0(private_stems, ".html")
leaked_pages <- private_pages[file.exists(file.path(site_dir, private_pages))]
if (length(leaked_pages)) {
  stop("Private root pages were generated: ", paste(leaked_pages, collapse = ", "), call. = FALSE)
}

required_pages <- c(
  "index.html",
  file.path("articles", "drmTMB.html"),
  file.path("articles", "capability-and-limits.html")
)
missing_pages <- required_pages[!file.exists(file.path(site_dir, required_pages))]
if (length(missing_pages)) {
  stop("Expected reader pages are missing: ", paste(missing_pages, collapse = ", "), call. = FALSE)
}

required_indexes <- c("search.json", "sitemap.xml", "llms.txt")
missing_indexes <- required_indexes[!file.exists(file.path(site_dir, required_indexes))]
if (length(missing_indexes)) {
  stop("Expected site indexes are missing: ", paste(missing_indexes, collapse = ", "), call. = FALSE)
}

html_files <- list.files(site_dir, pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
files_to_scan <- c(html_files, file.path(site_dir, required_indexes))
private_target <- paste0("(?i)(?:^|[/\"'])", paste(private_pages, collapse = "|"))
leaks <- vapply(files_to_scan, function(path) {
  any(grepl(private_target, readLines(path, warn = FALSE), perl = TRUE))
}, logical(1))
if (any(leaks)) {
  stop(
    "Private page links leaked into generated site files: ",
    paste(sub(paste0("^", site_dir, "/"), "", files_to_scan[leaks]), collapse = ", "),
    call. = FALSE
  )
}

# Reader-facing pages must explain a model and its limits, not expose the
# package's issue tracker, internal decision records, or implementation lanes.
# Scan visible HTML text because pkgdown also renders public roxygen help.
process_patterns <- c(
  "PR/issue identifier" = "\\b(?:PR|pull[[:space:]-]+request|issue)[[:space:]]*#[0-9]+\\b",
  "internal decision identifier" = "\\bD-[0-9]+\\b",
  "development evidence path" = "docs/dev-log(?:/|\\b)",
  "capability ledger" = "\\bcapability[[:space:]-]+ledger\\b",
  "implementation/development lane or arc" = "\\b(?:(?:implementation|development)[[:space:]-]+(?:lane|arc)s?|(?:lane|arc)s?[[:space:]-]+(?:for|of)[[:space:]-]+(?:implementation|development))\\b"
)
visible_text <- function(path) {
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
  text <- gsub("<script[^>]*>.*?</script>|<style[^>]*>.*?</style>", " ", text, perl = TRUE)
  text <- gsub("<[^>]+>", " ", text, perl = TRUE)
  gsub("&[[:alnum:]#]+;", " ", text, perl = TRUE)
}
rendered_slop <- unlist(lapply(html_files, function(path) {
  text <- visible_text(path)
  hits <- names(process_patterns)[vapply(process_patterns, grepl, logical(1), x = text, perl = TRUE)]
  if (!length(hits)) return(character())
  paste0(sub(paste0("^", site_dir, "/"), "", path), " (", paste(hits, collapse = ", "), ")")
}), use.names = FALSE)
if (length(rendered_slop)) {
  stop(
    "Rendered public documentation contains internal process language: ",
    paste(rendered_slop, collapse = "; "),
    call. = FALSE
  )
}

cat("PKGDOWN PUBLIC SURFACE PASS\n")

#!/usr/bin/env Rscript

# Source-checkout guard for the 0.7.0 CRAN resubmission.  `R CMD check` runs
# examples but does not retain README.md or the source Rd/R files, so these
# reviewer-specific static assertions must run before the package check.
root <- normalizePath(".", mustWork = TRUE)
source_files <- c(
  list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE),
  list.files(file.path(root, "man"), pattern = "[.]Rd$", full.names = TRUE)
)

wrapped <- unlist(lapply(source_files, function(path) {
  lines <- readLines(path, warn = FALSE)
  hits <- grep("\\\\(donttest|dontrun)\\{", lines)
  if (!length(hits)) return(character())
  sprintf("%s:%d", path, hits)
}), use.names = FALSE)
if (length(wrapped)) {
  stop(
    "CRAN 0.7.0 examples must be ordinary executable examples; wrappers remain at: ",
    paste(wrapped, collapse = ", "),
    call. = FALSE
  )
}

status_phrase <- "first submitted to CRAN on 24 August 2026"
for (path in file.path(root, c("README.md", "NEWS.md"))) {
  text <- gsub(
    "[[:space:]]+",
    " ",
    paste(readLines(path, warn = FALSE), collapse = "\n")
  )
  if (!grepl(status_phrase, text, fixed = TRUE)) {
    stop(
      sprintf("%s must state the 24 August 2026 first submission history", path),
      call. = FALSE
    )
  }
}

message("CRAN resubmission source assertions passed")

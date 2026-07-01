#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
runner <- file.path(
  repo_root,
  "tools",
  "run-structured-re-gaussian-lowq-mu-intercept-dry-run.R"
)

if (!any(grepl("^--run-kind=", args))) {
  args <- c("--run-kind=pregrid", args)
}
if (!any(grepl("^--n-rep=", args))) {
  args <- c("--n-rep=150", args)
}
if (!any(grepl("^--write-dashboard=", args))) {
  args <- c(args, "--write-dashboard=false")
}

status <- system2(
  "Rscript",
  shQuote(c("--no-init-file", runner, args))
)
quit(status = status)

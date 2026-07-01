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
runner <- file.path(
  dirname(script_file),
  "run-structured-re-gaussian-lowq-mu-intercept-dry-run.R"
)

if (!any(grepl("^--run-kind=", args))) {
  args <- c("--run-kind=smoke", args)
}
if (!any(grepl("^--write-dashboard=", args))) {
  args <- c(args, "--write-dashboard=false")
}

status <- system2(
  file.path(R.home("bin"), "Rscript"),
  shQuote(c("--no-init-file", runner, args))
)
quit(status = status)

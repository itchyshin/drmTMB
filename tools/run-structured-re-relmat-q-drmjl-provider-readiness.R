#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

fixture_file <- file.path(
  repo_root,
  "inst",
  "sim",
  "R",
  "sim_structured_re_bridge_fixtures.R"
)
source(fixture_file)

output_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-relmat-q-drmjl-provider-readiness.tsv"
)

out <- phase18_structured_re_relmat_q_drmjl_provider_readiness()
utils::write.table(
  out,
  output_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("wrote ", output_path, " with ", nrow(out), " rows")

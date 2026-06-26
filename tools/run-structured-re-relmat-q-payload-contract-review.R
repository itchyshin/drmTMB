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

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
contract_path <- file.path(
  dashboard_dir,
  "structured-re-relmat-q-payload-contract-review.tsv"
)
gate_path <- file.path(
  dashboard_dir,
  "structured-re-relmat-q-payload-marshalling-gate.tsv"
)

contract <- phase18_structured_re_relmat_q_payload_contract_review()
gate <- phase18_structured_re_relmat_q_payload_marshalling_gate()

utils::write.table(
  contract,
  contract_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  gate,
  gate_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("wrote ", contract_path, " with ", nrow(contract), " rows")
message("wrote ", gate_path, " with ", nrow(gate), " rows")

#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-gaussian-lowq-sigma-intercept-pregrid.R [options]",
      "",
      "Runs only the reviewed Gaussian low-q q1 sigma-intercept SR150 pregrid.",
      "",
      "Required/guarded options:",
      "  --n-rep=150",
      "  --providers=animal,relmat",
      "  --host-class=<nibi-or-rorqual label>",
      "  --write-dashboard=false",
      "",
      sep = "\n"
    )
  )
  quit(status = 0)
}

arg_value <- function(name, default = NULL) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (length(hit) == 0L) {
    return(default)
  }
  sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
}

has_arg <- function(name) {
  any(grepl(paste0("^--", name, "="), args))
}

split_csv <- function(x) {
  out <- trimws(strsplit(x, ",", fixed = TRUE)[[1L]])
  out[nzchar(out)]
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

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
contract_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-sigma-intercept-denominator-contract.tsv"
)
contract <- utils::read.delim(
  contract_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

expected_cells <- c(
  "qseries_animal_q1_sigma_intercept",
  "qseries_relmat_q1_sigma_intercept"
)
if (!setequal(contract$cell_id, expected_cells) || nrow(contract) != 2L) {
  stop(
    "Sigma pregrid contract must contain exactly animal and relmat q1 sigma-intercept rows.",
    call. = FALSE
  )
}
if (!all(contract$contract_status == "fisher_gauss_rose_reviewed_sr150_pregrid_ready")) {
  stop(
    "Sigma pregrid contract is not Fisher/Gauss/Rose reviewed for SR150 pregrid.",
    call. = FALSE
  )
}
if (!all(contract$promotion_decision == "do_not_promote")) {
  stop("Sigma pregrid contract must remain do_not_promote.", call. = FALSE)
}
if (!all(contract$pregrid_n_rep == 150L)) {
  stop("Sigma pregrid contract must keep pregrid_n_rep = 150.", call. = FALSE)
}

n_rep <- as.integer(arg_value("n-rep", "150"))
if (!is.finite(n_rep) || n_rep != 150L) {
  stop("Sigma pregrid requires exactly --n-rep=150.", call. = FALSE)
}

providers <- split_csv(arg_value("providers", "animal,relmat"))
if (length(providers) != 2L || !setequal(providers, c("animal", "relmat"))) {
  stop(
    "Sigma pregrid requires exactly --providers=animal,relmat.",
    call. = FALSE
  )
}

write_dashboard <- tolower(arg_value("write-dashboard", "false"))
if (!write_dashboard %in% c("0", "false", "no", "n")) {
  stop("Sigma pregrid must run with --write-dashboard=false.", call. = FALSE)
}

host_class <- arg_value("host-class", NULL)
if (is.null(host_class) || !grepl("nibi|rorqual", tolower(host_class))) {
  stop(
    "Sigma pregrid requires a Nibi/Rorqual host class; use local smoke tools for rehearsal.",
    call. = FALSE
  )
}

if (!has_arg("n-rep")) {
  args <- c("--n-rep=150", args)
}
if (!has_arg("providers")) {
  args <- c("--providers=animal,relmat", args)
}
if (!has_arg("write-dashboard")) {
  args <- c(args, "--write-dashboard=false")
}
if (!has_arg("profile")) {
  args <- c(args, "--profile=true")
}

runner <- file.path(
  repo_root,
  "tools",
  "run-structured-re-gaussian-lowq-sigma-intercept-smoke.R"
)

status <- system2(
  "Rscript",
  shQuote(c("--no-init-file", runner, args))
)
quit(status = status)

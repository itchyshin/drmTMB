#!/usr/bin/env Rscript

# Derived profile-interval truth manifest.
#
# WHY THIS FILE EXISTS
# ---------------------
# The profile-feasibility receipts (tools/run-arc2-profile-feasibility.R and
# the five frozen tools/run-arc1-*-profile-feasibility.R runners) record the
# true parameter value only as PROSE, in a `true_parameter_scale` field (e.g.
# "0.55 phylogenetic random-intercept SD on log(sigma) (NB2 dispersion),
# independent of a 0.20 phylogenetic random-slope SD ... 30 observations per
# tip"). Several numbers appear in that sentence; only one is the truth.
# Nothing can mechanically check `lower <= truth <= upper` against prose.
#
# This script derives a NUMERIC truth for every cell from the SAME source the
# receipts themselves were produced from -- it never hand-types a second,
# independent copy of a truth value:
#   - the 25 Arc 2 cells: each `cell_registry` entry in
#     tools/run-arc2-profile-feasibility.R now carries a
#     `true_value = function(fx) fx$<element>` accessor (added alongside this
#     script); this script calls that SAME accessor on the SAME fixture
#     result the runner itself would fit against, at that cell's own first
#     pinned seed.
#   - the 5 Arc 1 cells: each frozen tools/run-arc1-*-profile-feasibility.R
#     runner has its own literal top-level `truth_*` constant (e.g.
#     `truth_mu_x <- .55`); this script reads that binding directly rather
#     than retyping the number.
#
# mc-0282 is intentionally ABSENT from the output: it has no entry in the
# current `cell_registry` (an earlier registry state did have one -- see this
# task's after-task report for the historical receipts that predate its
# removal -- but there is no live contract in the current source to derive a
# truth from), so it is skipped rather than guessed.
#
# Output: tools/profile-truth-manifest.tsv, one row per cell, columns
# cell_id / target_id / profile_parameter / true_value / source_kind /
# source_file / truth_element, sorted by cell_id (radix order, so the sort is
# byte-exact and locale-independent).
#
# `--check` regenerates the manifest in memory and diffs it against the
# committed TSV byte-for-byte (mirroring `tools/capability_ledger.py
# --check`), so CI can detect drift between the fixture builders/arc1
# constants and the committed manifest.
#
# FAIL CLOSED: any cell whose derived truth is missing, NULL, NA, or
# non-finite aborts the entire run -- never a silently-skipped or
# silently-NA row.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) && !identical(args, "--check")) {
  stop("Only --check is accepted.", call. = FALSE)
}
check_mode <- identical(args, "--check")

script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]]))
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)

# --- Parse-and-eval ONE top-level `<-` binding out of a source file --------
#
# Copied from tools/run-arc2-profile-feasibility.R's `source_fixture_builder()`
# (there specialised to fixture-builder functions) and generalised: the same
# idiom reads a fixture-builder function, the `cell_registry` list itself, or
# a bare numeric truth constant in a frozen arc1 runner -- so nothing this
# script reports is ever re-typed, only re-evaluated from its one
# authoritative source file. Only the ONE matching top-level assignment is
# ever eval()'d (never the whole file), so this never re-runs a runner's CLI
# argument parsing, fitting, or side effects.
source_top_level_binding <- function(path, name) {
  if (!file.exists(path)) stop("Source file not found: ", path, call. = FALSE)
  exprs <- parse(path, keep.source = FALSE)
  env <- new.env(parent = globalenv())
  found <- FALSE
  for (e in exprs) {
    if (
      is.call(e) && identical(e[[1L]], as.name("<-")) &&
        is.name(e[[2L]]) && identical(as.character(e[[2L]]), name)
    ) {
      eval(e, envir = env)
      found <- TRUE
    }
  }
  if (!found) {
    stop("Top-level binding ", name, " not found in ", path, call. = FALSE)
  }
  get(name, envir = env)
}

# --- First pinned seed per cell, from retained receipts ---------------------
#
# "First" = the lexicographically-first (`method = "radix"`, byte-exact and
# locale-independent) receipt path under
# docs/dev-log/interval-feasibility/results/ whose `cell_id` column names
# this cell. The true-parameter DEFAULTS in every fixture builder here are
# seed-independent literals (verified by reading each builder), so this
# choice only affects provenance/reproducibility of the exact call, not the
# derived numeric truth.
receipt_seed_table <- local({
  receipt_dir <- file.path(root, "docs/dev-log/interval-feasibility/results")
  files <- sort(
    list.files(receipt_dir, pattern = "-receipt\\.tsv$", recursive = TRUE, full.names = TRUE),
    method = "radix"
  )
  rows <- lapply(files, function(f) {
    d <- tryCatch(utils::read.delim(f, stringsAsFactors = FALSE), error = function(e) NULL)
    if (is.null(d) || !all(c("cell_id", "seed") %in% names(d))) return(NULL)
    data.frame(cell_id = d$cell_id, seed = d$seed, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
})

first_pinned_seed <- function(cell_id) {
  hit <- receipt_seed_table[receipt_seed_table$cell_id == cell_id, , drop = FALSE]
  if (!nrow(hit)) {
    stop(
      "No retained receipts under docs/dev-log/interval-feasibility/results/ ",
      "name cell_id=", cell_id, "; cannot derive a pinned seed.", call. = FALSE
    )
  }
  as.integer(hit$seed[[1L]])
}

# --- Fail-closed truth validation -------------------------------------------
validate_truth <- function(cell_id, value) {
  ok <- !is.null(value) && length(value) == 1L && !is.na(value) && is.finite(value)
  if (!ok) {
    stop(
      "Cell ", cell_id, " derived a missing/NULL/NA/non-finite true_value (",
      if (is.null(value)) "NULL" else paste(format(value), collapse = ", "),
      "). Aborting -- fail closed.", call. = FALSE
    )
  }
  as.numeric(value)
}

rows <- list()

# --- 25 Arc 2 cells: derive from tools/run-arc2-profile-feasibility.R's own
# `cell_registry` -- the SAME contracts the runner itself fits against -------
arc2_runner <- file.path(root, "tools/run-arc2-profile-feasibility.R")
cell_registry <- source_top_level_binding(arc2_runner, "cell_registry")

for (cell_id in names(cell_registry)) {
  contract <- cell_registry[[cell_id]]
  seed <- first_pinned_seed(cell_id)
  fixture_fn <- source_top_level_binding(
    file.path(root, contract$fixture_file), contract$fixture_name
  )
  fixture_result <- contract$fixture_call(fixture_fn, seed)
  true_value <- validate_truth(cell_id, contract$true_value(fixture_result))
  truth_element <- paste(deparse(body(contract$true_value)), collapse = " ")
  rows[[length(rows) + 1L]] <- data.frame(
    cell_id = cell_id,
    target_id = paste0(cell_id, "::", contract$target),
    profile_parameter = contract$target,
    true_value = format(true_value, digits = 15),
    source_kind = "fixture_builder",
    source_file = contract$fixture_file,
    truth_element = truth_element,
    stringsAsFactors = FALSE
  )
}

# --- 5 Arc 1 cells: derive from each frozen arc1 runner's own top-level
# truth constants -------------------------------------------------------------
arc1_cells <- list(
  list(
    cell_id = "mc-0260", runner = "tools/run-arc1-gaussian-fixed-profile-feasibility.R",
    constant = "truth_mu_x", target = "fixef:mu:x"
  ),
  list(
    cell_id = "mc-0262", runner = "tools/run-arc1-gaussian-fixed-profile-feasibility.R",
    constant = "truth_sigma_x", target = "fixef:sigma:x"
  ),
  list(
    cell_id = "mc-0266", runner = "tools/run-arc1-gaussian-sigma-re-profile-feasibility.R",
    constant = "truth_sd", target = "sd:sigma:(1 | id)"
  ),
  list(
    cell_id = "mc-0269", runner = "tools/run-arc1-gaussian-reml-slope-profile-feasibility.R",
    constant = "truth_sd", target = "sd:mu:(0 + x | id)"
  ),
  list(
    cell_id = "mc-0260m", runner = "tools/run-arc1-meta-v-profile-feasibility.R",
    constant = "truth_mu", target = "fixef:mu:(Intercept)"
  )
)

for (entry in arc1_cells) {
  value <- source_top_level_binding(file.path(root, entry$runner), entry$constant)
  true_value <- validate_truth(entry$cell_id, value)
  rows[[length(rows) + 1L]] <- data.frame(
    cell_id = entry$cell_id,
    target_id = paste0(entry$cell_id, "::", entry$target),
    profile_parameter = entry$target,
    true_value = format(true_value, digits = 15),
    source_kind = "arc1_runner_constant",
    source_file = entry$runner,
    truth_element = entry$constant,
    stringsAsFactors = FALSE
  )
}

manifest <- do.call(rbind, rows)
manifest <- manifest[order(manifest$cell_id, method = "radix"), , drop = FALSE]
row.names(manifest) <- NULL

# --- Write or check, mirroring tools/capability_ledger.py's --write/--check
# in-memory-vs-disk byte comparison ------------------------------------------
out_path <- file.path(root, "tools/profile-truth-manifest.tsv")
generated_lines <- local({
  con <- textConnection("captured", "w", local = TRUE)
  on.exit(close(con))
  utils::write.table(manifest, con, sep = "\t", quote = FALSE, row.names = FALSE)
  captured
})

if (check_mode) {
  if (!file.exists(out_path)) {
    message("profile-truth-manifest: MISSING -- run `Rscript tools/emit-profile-truth-manifest.R` to generate ", out_path)
    quit(status = 2L, save = "no")
  }
  committed_lines <- readLines(out_path, warn = FALSE)
  if (!identical(committed_lines, generated_lines)) {
    message(
      "profile-truth-manifest: STALE -- ", out_path,
      " does not match the manifest derived from current sources.\n",
      "Run: Rscript tools/emit-profile-truth-manifest.R"
    )
    quit(status = 2L, save = "no")
  }
  message("profile-truth-manifest: OK (", nrow(manifest), " rows)")
} else {
  writeLines(generated_lines, out_path)
  message("Wrote ", out_path, " (", nrow(manifest), " rows)")
  # Only echo the table when regenerating, so the CI --check step stays quiet
  # on success. A 30-row dump on every green run is noise that trains readers
  # to skim past the one line that matters.
  print(manifest, row.names = FALSE)
}

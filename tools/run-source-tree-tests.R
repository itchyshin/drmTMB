#!/usr/bin/env Rscript

# Source-tree test lane: run the tests that `R CMD check` structurally CANNOT.
#
# WHY THIS EXISTS. CI checks the built TARBALL, and .Rbuildignore removes
# tools/, docs/, pkgdown/, bench/, _pkgdown.yml and inst/sim/results from it.
# A test whose premise is one of those paths therefore hits its own
# `skip_if(!file.exists(...))` under check and SKIPS -- and testthat reports a
# skip in the same green summary line as a pass. The premise being absent is
# not a fact about the code under test; it is a fact about the build, so the
# skip is unconditional and permanent, not environmental.
#
# Measured on this repository at origin/main eccb10299 (macOS, R 4.6.0) by
# running the affected files twice -- once with the working directory in the
# source tree, once inside the extracted `R CMD build` tarball:
#
#   35 test files change behaviour between the two trees
#   24,348 passing assertions in the source tree -> 855 in the tarball
#   23,493 assertions (96.5%) are structurally unreachable under R CMD check
#   24 of the 35 files contribute ZERO assertions to the tarball run
#
# Two user-facing defects reached main inside that blind spot and were found
# only by a full source-tree run: the reader-contract linter had stopped
# policing six vignettes (PR #1207) and nine exported functions were missing
# from the printable cheatsheets (PR #1208).
#
# WHAT THIS SCRIPT DOES. It derives the affected set from .Rbuildignore rather
# than trusting a hand-kept list, cross-checks that derivation against the
# committed manifest tools/source-tree-tests.txt so the set cannot grow OR
# shrink unnoticed, then runs exactly those files with pkgload::load_all()
# against the source checkout.
#
# Usage:
#   Rscript --no-init-file tools/run-source-tree-tests.R           # check + run
#   Rscript --no-init-file tools/run-source-tree-tests.R --check   # manifest only
#   Rscript --no-init-file tools/run-source-tree-tests.R --update  # rewrite manifest

MANIFEST <- file.path("tools", "source-tree-tests.txt")

# .Rbuildignore patterns, minus blank lines and comments.
drm_build_ignore_patterns <- function(root) {
  path <- file.path(root, ".Rbuildignore")
  if (!file.exists(path)) {
    stop(".Rbuildignore not found at ", path, call. = FALSE)
  }
  lines <- trimws(readLines(path, warn = FALSE))
  lines[nzchar(lines) & !startsWith(lines, "#")]
}

# TRUE when `path` (relative to the package root) is removed by R CMD build.
# Every ANCESTOR prefix is tested, not just the whole string: "^tools$" excludes
# tools/build-function-pdfs.py by excluding the directory above it, and
# "^inst/sim/results($|/)" shows the pattern need not be top-level.
drm_is_build_excluded <- function(path, patterns) {
  parts <- strsplit(path, "/", fixed = TRUE)[[1L]]
  if (length(parts) == 0L) return(FALSE)
  prefixes <- vapply(
    seq_along(parts),
    function(i) paste(parts[seq_len(i)], collapse = "/"),
    character(1L)
  )
  for (p in patterns) {
    if (any(grepl(p, prefixes, perl = TRUE))) return(TRUE)
  }
  FALSE
}

# Double-quoted string literals on non-comment lines. A path named only inside a
# comment is prose, not a premise: tests/testthat/test-gradient-conformance.R
# cites CLAUDE.md in a comment and is verifiably unaffected by the build.
drm_path_literals <- function(file) {
  lines <- readLines(file, warn = FALSE)
  lines <- lines[!grepl("^\\s*#", lines)]
  m <- regmatches(lines, gregexpr('"[^"]*"', lines))
  lit <- unlist(m, use.names = FALSE)
  if (length(lit) == 0L) return(character(0))
  unique(substr(lit, 2L, nchar(lit) - 1L))
}

# The test files whose premise is a path R CMD build removes.
drm_scan_source_tree_tests <- function(root) {
  patterns <- drm_build_ignore_patterns(root)
  dir <- file.path(root, "tests", "testthat")
  files <- sort(list.files(dir, pattern = "^test-.*\\.[Rr]$"), method = "radix")
  keep <- vapply(files, function(f) {
    lits <- drm_path_literals(file.path(dir, f))
    any(vapply(lits, drm_is_build_excluded, logical(1L), patterns = patterns))
  }, logical(1L))
  files[keep]
}

# The same anchored, fully escaped filter testthat sharding uses
# (tests/testthat/helper-shard-util.R): testthat matches `filter` against the
# file name with the "test-" prefix and ".R" extension stripped.
drm_source_tree_filter <- function(files) {
  nm <- sub("\\.[Rr]$", "", sub("^test-", "", files))
  paste0("^(", paste(gsub("([^A-Za-z0-9_])", "\\\\\\1", nm), collapse = "|"), ")$")
}

drm_read_manifest <- function(path) {
  lines <- trimws(readLines(path, warn = FALSE))
  lines[nzchar(lines) & !startsWith(lines, "#")]
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  root <- normalizePath(".", mustWork = TRUE)
  if (!file.exists(file.path(root, "DESCRIPTION"))) {
    stop("run this from the package root", call. = FALSE)
  }

  derived <- drm_scan_source_tree_tests(root)

  if ("--update" %in% args) {
    writeLines(
      c(
        "# Test files whose premise is a path .Rbuildignore removes from the",
        "# tarball, so R CMD check can only ever SKIP them. Derived by",
        "# tools/run-source-tree-tests.R --update; do not hand-edit.",
        derived
      ),
      file.path(root, MANIFEST)
    )
    cat("wrote", MANIFEST, "with", length(derived), "files\n")
    return(invisible(NULL))
  }

  manifest <- drm_read_manifest(file.path(root, MANIFEST))
  added <- setdiff(derived, manifest)
  removed <- setdiff(manifest, derived)
  if (length(added) || length(removed)) {
    msg <- c(
      "source-tree test manifest is out of date.",
      if (length(added)) {
        c("  NOT IN MANIFEST (new build-excluded premise, never run under check):",
          paste0("    ", added))
      },
      if (length(removed)) {
        c("  IN MANIFEST BUT NO LONGER DETECTED (premise dropped, or hidden from",
          "  the scanner behind a variable -- the second case is the same disease):",
          paste0("    ", removed))
      },
      "  Re-derive with: Rscript --no-init-file tools/run-source-tree-tests.R --update"
    )
    stop(paste(msg, collapse = "\n"), call. = FALSE)
  }
  cat(sprintf(
    "source-tree test manifest agrees with .Rbuildignore: %d files\n",
    length(derived)
  ))

  if ("--check" %in% args) return(invisible(NULL))

  if (length(derived) == 0L) {
    stop(
      "no source-tree tests detected; the scanner is broken, or the blind spot ",
      "closed and this lane should be retired deliberately",
      call. = FALSE
    )
  }

  Sys.setenv(NOT_CRAN = "true")
  # This lane is never sharded: it is already a bounded, derived subset.
  Sys.unsetenv("DRMTMB_TEST_SHARD")
  # Report every failure. The default stops at ten, which in a lane whose whole
  # point is finding work CI never did would hide most of the answer.
  options(testthat.progress.max_fails = Inf)

  cat(sprintf("running %d source-tree test files\n", length(derived)))

  suppressMessages(pkgload::load_all(root, quiet = TRUE, helpers = FALSE))
  testthat::test_dir(
    file.path(root, "tests", "testthat"),
    package = "drmTMB",
    load_package = "none",
    filter = drm_source_tree_filter(derived),
    stop_on_failure = TRUE,
    stop_on_warning = FALSE
  )
  invisible(NULL)
}

if (identical(environment(), globalenv()) && !interactive()) {
  main()
}

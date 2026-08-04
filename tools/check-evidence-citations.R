#!/usr/bin/env Rscript
# Evidence-citation guard: every cited rejection message must still exist.
#
# WHY THIS IS A SEPARATE TOOL AND NOT ONLY A TEST
# -----------------------------------------------
# The equivalent assertion already lives in
# `tests/testthat/test-estimator-surface-conformance.R`, but it CANNOT FAIL IN
# CI: `.Rbuildignore` excludes `^docs$`, so the conformance TSV is absent from
# the built tarball and the test's `skip_if_not(file.exists(path))` skips the
# whole block under `R CMD check`. That is why four citations rotted on `main`
# while CI stayed green. This script runs from the SOURCE CHECKOUT, where
# `docs/` exists, and is wired into `.github/workflows/R-CMD-check.yaml`
# alongside the other `tools/` guards.
#
# It reads files only -- no package load, no fits -- so it costs milliseconds
# and cannot be defeated by a stale install.
#
# THE CITATION CONTRACT (file-anchored, not line-anchored)
# --------------------------------------------------------
# A citation names a FILE. For a declared rejection (`expected == "error"` with
# a non-empty `detail`), that `detail` string must appear somewhere in the file.
# A trailing `:line` is an optional reading hint, range-checked but never
# authoritative. A line shift therefore cannot fail this check; deleting or
# rewording the cited message still does.
#
# This form exists because the line-anchored form drifted twice and was
# hand-refreshed twice -- see
# `docs/dev-log/after-task/2026-07-25-estimator-surface-anchor-hygiene.md:79-80`,
# whose recommendation this implements.
#
# Usage: Rscript --no-init-file tools/check-evidence-citations.R
# Exit 0 = all citations resolve. Exit 1 = at least one is broken.

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1L]] else "."

tsv <- file.path(
  root, "docs", "dev-log", "dashboard", "estimator-surface-conformance.tsv"
)
if (!file.exists(tsv)) {
  cat("FAIL: conformance TSV not found at", tsv, "\n")
  cat("  This script must run from a source checkout, not a built tarball.\n")
  quit(status = 1L)
}

tab <- utils::read.delim(
  tsv, stringsAsFactors = FALSE, na.strings = character(),
  colClasses = "character"
)

violations <- character(0)
checked <- 0L

for (i in seq_len(nrow(tab))) {
  row <- tab[i, ]
  parts <- strsplit(row$evidence, ":", fixed = TRUE)[[1L]]
  file <- parts[[1L]]
  path <- file.path(root, file)

  if (!file.exists(path)) {
    violations <- c(violations, sprintf(
      "%s: evidence file does not exist: %s", row$cell_id, file
    ))
    next
  }
  lines <- readLines(path, warn = FALSE)

  # Optional hint: reported, never fatal on its own.
  if (length(parts) >= 2L) {
    span <- suppressWarnings(
      as.integer(strsplit(parts[[2L]], "-", fixed = TRUE)[[1L]])
    )
    if (any(is.na(span)) || any(span < 1L) || any(span > length(lines))) {
      violations <- c(violations, sprintf(
        "%s: line hint out of range for %s (file has %d lines)",
        row$cell_id, row$evidence, length(lines)
      ))
    }
  }

  if (!identical(row$expected, "error") || !nzchar(row$detail)) next
  checked <- checked + 1L

  hits <- which(vapply(
    lines, function(l) grepl(row$detail, l, fixed = TRUE), logical(1L),
    USE.NAMES = FALSE
  ))
  if (!length(hits)) {
    violations <- c(violations, sprintf(
      paste0(
        "%s: %s no longer contains \"%s\". The cited rejection was deleted or ",
        "reworded. This is NOT line drift -- the citation is file-anchored."
      ),
      row$cell_id, file, row$detail
    ))
  }
}

cat(sprintf(
  "[citations] %d rows, %d cited rejections checked, %d violation(s)\n",
  nrow(tab), checked, length(violations)
))
if (length(violations)) {
  cat("VIOLATIONS:\n")
  cat(paste0(" - ", violations, collapse = "\n"), "\n", sep = "")
  quit(status = 1L)
}
cat("VIOLATIONS: none\n")

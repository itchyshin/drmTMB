#!/usr/bin/env Rscript
## Generate inst/extdata/env-skip-census.tsv: one row per skip CALL SITE in
## tests/testthat, classified by WHAT WOULD HAVE TO CHANGE for the guarded code
## to run, and by what the drmTMB CI runner actually does with that mechanism.
##
## WHY THIS EXISTS
##
## PR #1222 measured one family of permanent CI skips: tests whose premise is a
## path `.Rbuildignore` keeps out of the tarball. In its own "not covered" it
## named a second family and declined to guess at it -- environment-permanent
## skips, where the premise is something the RUNNER does not have. Both print
## inside the same green summary line as a pass. Nobody had counted the second
## family. This generator counts it.
##
## THE SCANNER IS NOT HERE. It is `tests/testthat/helper-env-skip-census.R`,
## which this file sources. That is deliberate: `^tools$` is in `.Rbuildignore`,
## so a scanner living under tools/ could not run under `R CMD check` -- it
## would sit inside blind spot #1 while measuring blind spot #2. From
## tests/testthat/ the same code runs in the tarball, so
## `tests/testthat/test-env-skip-census.R` can re-derive this artefact and fail
## when it goes stale, on every runner, in the ordinary suite.
##
## Usage:
##   Rscript tools/write-env-skip-census.R           # regenerate in place
##   Rscript tools/write-env-skip-census.R --check   # fail if stale

args <- commandArgs(trailingOnly = TRUE)
check_only <- "--check" %in% args

root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("run from the package root", call. = FALSE)
}
scanner <- file.path(root, "tests", "testthat", "helper-env-skip-census.R")
if (!file.exists(scanner)) {
  stop("scanner not found: ", scanner, call. = FALSE)
}
source(scanner)

out_path <- file.path(root, "inst", "extdata", "env-skip-census.tsv")

census <- drm_skip_census(file.path(root, "tests", "testthat"))
if (!nrow(census)) stop("no skip call sites found -- scanner is broken", call. = FALSE)

lines <- drm_env_skip_census_tsv(census)

if (check_only) {
  if (!file.exists(out_path)) {
    stop("inst/extdata/env-skip-census.tsv is missing; regenerate with ",
         "Rscript tools/write-env-skip-census.R", call. = FALSE)
  }
  have <- readLines(out_path, warn = FALSE)
  if (!identical(have, lines)) {
    stop("inst/extdata/env-skip-census.tsv is out of date; regenerate with ",
         "Rscript tools/write-env-skip-census.R", call. = FALSE)
  }
  cat(sprintf("env-skip census up to date: %d skip call sites\n", nrow(census)))
} else {
  writeLines(lines, out_path)
  cat(sprintf("wrote %s (%d skip call sites)\n", out_path, nrow(census)))
}

## Human-readable tally, printed either way. This is the NUMBER.
tab <- table(census$gate_class, census$ci_status)
cat("\n")
print(tab)
env <- census[census$axis == "environment", , drop = FALSE]
perm <- env[env$ci_status == "skips", , drop = FALSE]
cat(sprintf(
  paste0(
    "\n%d skip call sites total\n",
    "  %d environment-axis (the runner could satisfy them)\n",
    "  %d build-axis (only the build can satisfy them -- PR #1222)\n",
    "  %d runtime-axis (the run's own data decides)\n",
    "\n%d ENVIRONMENT-PERMANENT sites: the drmTMB CI runner never satisfies\n",
    "these, in %d test files. They are as permanent as a build skip.\n"
  ),
  nrow(census),
  sum(census$axis == "environment"),
  sum(census$axis == "build"),
  sum(census$axis == "runtime"),
  nrow(perm),
  length(unique(perm$file))
))
for (g in sort(unique(perm$gate_class))) {
  s <- perm[perm$gate_class == g, , drop = FALSE]
  cat(sprintf("  %-16s %3d sites in %2d files\n", g, nrow(s), length(unique(s$file))))
}

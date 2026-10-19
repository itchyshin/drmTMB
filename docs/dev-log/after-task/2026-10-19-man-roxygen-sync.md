# man/*.Rd synchronised with roxygen sources

## 1. Goal

Make `devtools::document()` a no-op on main (issue #1571): #1400 edited
`man/*.Rd` directly, so the next `document()` run would rewrite 39 help files
and discard those edits.

## 2. Implemented

The #1400 help-text edits were moved into the matching roxygen blocks in 20
files under `R/`. Regenerating with the pinned roxygen2 8.0.0 now leaves
`man/`, `NAMESPACE` and `DESCRIPTION` unchanged. Two source details were made
deterministic: the `makePSOCKcluster` link in `R/parallel-docs.R` pins its
`parallel:makeCluster` target explicitly (the auto-resolved topic differs by R
version), and the `0.09%` in `R/profile.R` is unescaped as markdown roxygen requires.

## 3a. Decisions and Rejected Alternatives

The committed `man/` text is treated as the intended wording, so the roxygen
sources were changed to match it, not the reverse. Rewording was not
attempted. A source-loading roxygen run (`load_code = "source"`) was rejected
for the guard test because it resolves S3 and link targets differently.

## 4. Files Touched

`R/*.R` roxygen text (20 files), the new `tests/testthat/test-man-roxygen-sync.R`,
this report and a check-log row. No `man/`, `NAMESPACE`, C++ or behaviour change.

## 5. Checks Run

Before the fix, `document()` rewrote 39 `man/*.Rd` files. After it, no diff.
The new test fails on the pre-fix tree (39 stale files) and passes after.
Full testthat suite: see the PR description.

## 6. Tests of the Tests

`test-man-roxygen-sync.R` copies `R/`, `man/`, `DESCRIPTION` and `NAMESPACE` to
a temporary directory, runs the Rd roclet against the loaded namespace, and
compares every file. It skips on CRAN, in an installed-package check, and when
the installed roxygen2 differs from `Config/roxygen2/version`.

## 7a. Issue Ledger

Closes #1571.

# After-task: define `%||%` for R < 4.4 (#1550)

## What changed

- `R/utils.R` defines an internal `%||%` (identical to base R 4.4). Base R
  exports it only from 4.4.0, while `DESCRIPTION` declares R >= 4.1.0, so
  `engine = "julia"` aborted before reaching Julia on R 4.1-4.3.
- `tests/testthat/test-null-default-operator.R` asserts the operator exists in
  the package namespace (`inherits = FALSE`), keeps empty vectors and `NA`, and
  that `drm_mspl_link_name(NULL)` works.

## Evidence

- Red: with no definition, `exists("%||%", envir = asNamespace("drmTMB"),
  inherits = FALSE)` is FALSE on every R version.
- Green: after `R/utils.R`, the definition resolves (checked by sourcing the
  file into a base-parented environment).
- The package suite, `document()` and `R CMD check` were NOT run in this
  sandbox: testthat, TMB and Matrix could not be installed (network policy).
  CI is the authority. No exports or roxygen changed, so no Rd/NAMESPACE edits.

## Overlap

Drafts #1502 (Cursor-owned) also defines `%||%`. Whichever lands second will
need to drop the duplicate definition.

# 2026-11-10 — 071 SHA-256 locator accepts sys.source `file`

## Goal

The source-tree blind-spot job on `8ff206feb` still failed
`tests/testthat/test-071-four-fixture-summary.R` with
`cannot locate 071 ordinary-Laplace evidence directory`. Every real caller
uses `sys.source()`, which stores the script path in `file` and never sets
`source()`'s `ofile`.

## Change

- `prepare-s7-campaign-bundle.R`, `s7-write-coverage-summary.R`, and
  `r071-file-sha256.R` accept a character `ofile` or `file`, then
  `DRMTMB_ROOT`, and use a cwd-relative path only last.
- The bundle script binds `r071_s7_sha256` in the sourcing environment
  (`exists(..., inherits = FALSE)` and `sys.source(..., envir = environment())`).
- `s7-run-task.R` is unchanged: it still exports `DRMTMB_ROOT` and the
  coverage writer still uses `sys.source(..., envir = environment())`.
- New test in `tests/testthat/test-071-four-fixture-summary.R`. It sources
  the bundle from a non-repo working directory with `DRMTMB_ROOT` unset,
  and requires `env$r071_s7_sha256` plus no new `globalenv()` names.

No receipt, golden file, fixture, tolerance, capability ledger, or recorded
checksum was edited.

## Verify

R 4.3.3. The new test, copied unchanged onto the old trees:

```
a2846c7c  [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]
          Error: missing 071 SHA-256 helper: docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/r071-file-sha256.R
8ff206fe  [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]
          Error: cannot locate 071 ordinary-Laplace evidence directory
this tree [ FAIL 0 | WARN 0 | SKIP 0 | PASS 4 ]
```

`testthat::test_file("tests/testthat/test-071-four-fixture-summary.R")` on
this tree: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 186 ]`.

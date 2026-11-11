# After Task: 071 SHA-256 locator under sys.source

## Goal

Make the 071 ordinary-Laplace SHA-256 helper resolvable when callers use
`sys.source()`, including the source-tree blind-spot job, and bind
`r071_s7_sha256` in the caller environment.

## Implemented

`r071_ordinary_laplace_dir()` and `r071_helper_dir()` now read a character
`ofile` (`source()`) or `file` (`sys.source()`). If neither frame has the
script, they use `DRMTMB_ROOT`, then a cwd-relative path. The campaign
bundle loads the helper with `sys.source(..., envir = environment())` only
when the sourcing environment itself lacks `r071_s7_sha256`.
`s7-run-task.R` still sets `DRMTMB_ROOT` from `--root` before it sources
helpers. `s7-write-coverage-summary.R` keeps
`sys.source(..., envir = environment())`.

## Mathematical Contract

No likelihood, formula, or checksum contract changed. Empty-file SHA-256
from the bound helper is
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.

## Files Changed

- `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/prepare-s7-campaign-bundle.R`
- `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/r071-file-sha256.R`
- `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-write-coverage-summary.R`
- `tests/testthat/test-071-four-fixture-summary.R`
- `docs/dev-log/check-log.d/2026-11-10-fix-1702-sys-source-locator.md`

## Checks Run

R 4.3.3, installed drmTMB 0.8.1. The new test fails on `a2846c7c5` and
`8ff206feb` and passes on this tree. The full
`test-071-four-fixture-summary.R` file passes 186 assertions. Details are
in the check-log shard.

## Tests Of The Tests

The new test was run on `a2846c7c5` and `8ff206feb` with only that test
added. Both failed before any assertion. It passes after the locator fix.

## Consistency Audit

Receipts, fixtures, tolerances, and recorded checksums were not edited.
`rg` for `cannot locate 071 ordinary-Laplace` still finds the same stop
text, now after the `file` / `DRMTMB_ROOT` / cwd search. No formula or
likelihood wording changed, so the status-inventory files were not edited.

## GitHub Issue Maintenance

Issue #1702 stays open. This slice is on draft PR #1704. The PR body was
not edited.

## What Did Not Go Smoothly

`8ff206feb` looked up only `ofile`, so `sys.source()` never found the
evidence directory, even from the repository root. A parent-environment
`exists()` check also left `env$r071_s7_sha256` empty when an earlier test
had already leaked the helper into `globalenv()`.

## Team Learning

Evidence scripts that are loaded with `sys.source()` cannot use the
`source()` `ofile` idiom. Record the path variable the loader actually sets.

## Known Limitations

The locator still depends on a path that contains
`071-ordinary-laplace/<file>`. A copied script outside that directory needs
`DRMTMB_ROOT` or a repository-root working directory.

## Next Actions

Confirm the source-tree blind-spot job is green and that
`test-fix-1702-sha256-portable.R` on R-CMD-check shard 4/4 has at least 13
passes and 0 skips.

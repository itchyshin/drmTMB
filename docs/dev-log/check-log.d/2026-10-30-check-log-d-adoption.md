# 2026-10-30: adopt check-log.d as the live log (#1113)

Goal: implement the 25 Oct Decision on #1113 (process only).

Commands:

- Added `docs/dev-log/check-log.d/README.md` from the HSquared.jl
  wording, adapted to drmTMB (no builder script, no CI lint yet).
- Prepended a freeze notice to `docs/dev-log/check-log.md`. Did not
  rewrite historical entries.
- Pointed `AGENTS.md` rule 7 at `check-log.d`.
- Added `tests/testthat/test-check-log-d-adoption.R`.

Results: local file-existence test is the pin (PASS 5). CI source-tree
`--check` failed because the new test names `docs/` (build-excluded),
so `tools/source-tree-tests.txt` now lists `test-check-log-d-adoption.R`.
No receipt-tracked file changed.

Claim boundary: process docs and one test only. No package default,
likelihood, or CRAN-byte change.

# Parity generator reconciliation

## Goal and implementation

Allow the parity matrix and scoreboard to describe the 22 named R capability
rows missing from the pinned Julia status document. The explicit pending list
keeps these routes unreconciled and prevents a GREEN verdict. A previously
unlisted R row, or a missing Julia row outside this list, still stops generation.
Absence from a status document does not establish absence from the code.

The matrix now reports the actual row-name intersection. The scoreboard
identifies its R inputs as working-tree files and reports unmatched names as
UNCITED. Both generated documents remain anchored to the historical Julia pin
`da8b3f8711beb5ef3186b890544c2e7850c7f194`. The separate capability-join
script's explanation was updated to match this behavior. No model, estimator,
formula syntax, pkgdown navigation, or package API changed.

## Checks and tests of the tests

On macOS, with the R package loaded from this worktree and a separate Julia
checkout at the recorded pin, the targeted test files reported:

| Test file | Passed | Failed | Errors | Warnings | Skips |
| --- | ---: | ---: | ---: | ---: | ---: |
| parity matrix | 197 | 0 | 0 | 1 | 0 |
| parity scoreboard | 47 | 0 | 0 | 0 | 0 |
| parity pin | 8 | 0 | 0 | 0 | 0 |
| parity honesty | 18 | 0 | 0 | 0 | 0 |

The honesty gate exits 1 as intended: 22 rows remain `UNCITED`, with zero
defects. This preserves the open evidence gate. The warning concerns the
existing deprecated `beta()` alias. The Julia engine
was not started. Before the repair, the new pending-row test failed at the
existing entry-table mismatch, and the previously failing regeneration test
failed at the same guard. The new test checks that pending rows cannot become
GREEN and that an unreviewed extra R row or unexpected missing Julia name still
raises an error. It also checks the displayed join counts.

The first test invocation passed an unsupported `filter` argument to
`test_file()` and did not run the test. The subsequent recorded run executed the
whole test file. After regeneration, the tests above passed. Both generated
files matched a second regeneration byte for byte, and `git diff --check`
passed. `pkgdown::check_pkgdown()` reported no problems, with repeated Pandoc
`--mathjax` deprecation warnings. An initial query for `test-capability-status-join.R` found no such file;
the separate parity honesty test was run instead.

## Consistency and limitations

The matrix has 67 R rows, 45 exact Julia-name matches, 22 R-only names and
three Julia-only names at the historical pin. Those counts describe documents,
not model parity or coverage. The pending list is a visible work queue requiring
route-level validation. Current source-pair checks and independent receipts are
still required before any of its rows can be promoted. Other branches were
reviewed and preserved; their additional fence checks were not incorporated.

No GitHub issue or PR was modified as part of this local repair. The historical
at-pin generator failure and source-pair evidence are documented in the
separate cleanup handoff. Before integration, review the explicit pending list,
regenerate from the final exact source, run the required package checks, and
refresh the broader crosswalk against current package sources.

## Package-check follow-up

The Totoro package check for commit `da46bf821` reported two failures because
the generated skip census did not include the new parity test's skip sites.
The check reported 41,883 passes, 117 warnings and 697 skips; it did not run
the live Julia bridge. The log also reported a parallel-worker shutdown error.
The census was regenerated with `Rscript tools/write-env-skip-census.R`; only
the two expected parity-matrix rows changed. The focused source test passed
five assertions using `devtools::test(filter = "^env-skip-census$")`.
The corrected candidate still needs a fresh package check.

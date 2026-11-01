## 1. Goal

Bring PR #1627 (`make_tmb_data_core()` onto one shared defaults list, issue #1329) up to date with `origin/main` and clear the red check, without changing any default or API.

## 2. Implemented

- Merged `origin/main` with a normal merge commit. One conflict, in the C17 receipt manifest `2026-08-08-c17c2-c14-final-source-compatibility.tsv`; resolved by taking main's rows.
- Regenerated `inst/extdata/env-skip-census.tsv` with `tools/write-env-skip-census.R`. The only change is the two rows for the PR's own `test-tmb-data-pin.R` (one env-var opt-in skip, two `skip_if_not_installed("ape")` runs).
- Made `test-tmb-data-pin.R` compare double fields at tolerance 1e-12 (type, dimension and names still exact; integer, logical and character fields still `expect_identical`).
- No change to `R/`, `src/`, defaults or the public API.

## 3a. Decisions and Rejected Alternatives

- Did not raise the `tools/recertify-c17.py` tolerance. See section 9.
- Kept the pin test strict for every non-double field, so the #1048 shape (`has_phylo_mu` 0L against 1L) is still caught. Checked by mutation: forcing `has_phylo_mu = 0L` in `phylo_block` gives 2 failures; the mutation was reverted.

## 4. Files Touched

- `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv` (merge resolution)
- `inst/extdata/env-skip-census.tsv`
- `tests/testthat/test-tmb-data-pin.R`
- `docs/dev-log/after-task/2026-10-31-pr1627-tmb-data-defaults-merge-ci.md`

## 5. Checks Run

Local, arm64 macOS, one core per shard, `NOT_CRAN=true`, on the merged tree before the two test-side fixes:

| shard | files | passed | failed | skipped |
|---|---|---|---|---|
| 1/4 | 131 | 32653 | 81 | 36 |
| 2/4 | 130 | 7619 | 1 | 21 |
| 3/4 | 130 | 9009 | 0 | 19 |
| 4/4 | 129 | 7566 | 2 | 23 |

Failing files: `test-tmb-data-pin.R` (81), `test-associate-pairs-bernoulli-bernoulli.R` (1), `test-env-skip-census.R` (2). After the fixes, `test-tmb-data-pin.R` (2629 expectations) and `test-env-skip-census.R` pass when run directly. The full shards were not re-run after the fixes.

## 6. Tests of the Tests

The #1048-shaped mutation (section 3a) turns the relaxed pin test red.

## 7a. Issue Ledger

- #1329: refs only. The closing marker lives in the PR body.

## 8. Consistency Audit

- `test-tmb-data-pin.R` failed identically on the PR's pre-merge head (`7051068ef`) on this machine, so the merge did not cause it.
- `test-env-skip-census.R` fails on the PR head and passes on `origin/main` (`b535bfbcc`): the census never listed the PR's new test file.
- `test-associate-pairs-bernoulli-bernoulli.R` fails identically on `origin/main`. It is not in this PR's scope and was left alone.

## 9. What Did Not Go Smoothly

- The CI log for the red shard 3/4 run (run 40279955662, head `7051068ef`) had expired (HTTP 410), so the original failure could not be read. Shard 3/4 has 0 failures locally on the merged tree. The next CI run on the pushed head is the check.
- `tools/recertify-c17.py` refused to rewire the receipt: the measured `mean_tau_relative_error` moved by up to 3.2e-11 against main's recorded value, with and without `OPENBLAS_NUM_THREADS=1`. A dry run on an untouched `origin/main` worktree gave the same three differences, so this is host-level numerical noise, not the PR. The tool is deliberately exact and says not to raise the tolerance, so the receipt was left as main has it.
- I first wrote that the staleness guard runs only on main (true of the `receipt-staleness` workflow) and so does not gate this PR. That was wrong: each R-CMD-check shard also runs a receipt guard step before the tests. After the push, all four shards failed at that step with `mc-0568: current source blob differs for R/drmTMB.R` (receipt 8b715877f, current b887d0d00). The tests did not run in CI on this head.

## 10. Known Residuals

- The PR is red on every shard until the C17 receipt is recertified for the merged `R/drmTMB.R`. That needs a host whose numbers match the recorded ones, or an owner decision on a tolerance (NEEDS-DECISION, see the lane NOTES.md).
- `test-associate-pairs-bernoulli-bernoulli.R` is red on main on this host.
- No `engine = "julia"` live tests, no `R CMD check`, no pkgdown.

## 11. Team Learning

A snapshot test that compares simulated doubles with `expect_identical` is host-dependent. Pin names, types and dimensions exactly and values to a stated tolerance.

# After-Task: SR132 q4 Phylogenetic Covariance Target Map

## Goal

Bank a q4 phylogenetic covariance target map that separates direct among-axis
standard-deviation targets from derived among-axis correlation targets.

## Changes

- Added `phase18_structured_re_q4_phylocov_target_map()` with 10 rows:
  four direct SD targets and six derived correlation targets.
- Added `structured-re-q4-phylocov-target-map.tsv`.
- Added validator checks for q4 SD targets, derived correlation targets,
  log-Cholesky source labels, extractor boundaries, and no interval-coverage
  claim.
- Updated dashboard rendering, dashboard README, fixture tests, and
  dashboard-contract tests.

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 258 assertions, 0 failures, 0 warnings, and 0 skips.
- `python3 tools/validate-mission-control.py` passed with 10 q4 phylocov
  target-map rows.

## Boundary

This banks a target-map contract only. It does not promote q4 all-four parity,
q4 REML, HSquared AI-REML, interval coverage, public bridge support, a commit,
a PR, or an Ayumi-facing reply.

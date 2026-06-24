# After Task: SR160-SR170 Scope Gate Status

Date: 2026-06-22

## Goal

Record the REML acceptance blocker and bank structured-type gap rows as scoped
status evidence without promoting missing features.

## Changes

- Added `structured-re-scope-gate-status.tsv` for SR160-SR170.
- SR160 records the blocked REML acceptance gate.
- SR161-SR170 record type-specific scope rows for mesh/SPDE, sparse animal
  pedigree, `relmat()` precision `Q`, q1-only `phylo_interaction()`, direct-SD
  grammar, structured slopes, structured `rho12`, non-Gaussian q2/q4
  structured covariance, and the type-gap acceptance gate.

## Evidence

Checks run:

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/structured-re-scope-gate-status.tsv >/dev/null
```

Results:

- `structured-re-conversion-contracts` passed with 280 assertions, 0 failures,
  0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 11 scope-gate rows, 29
  closeout-package rows, and 45 executable-evidence rows.
- `status.json` and `sweep.json` parsed as JSON, `tools/start-mission-control.sh`
  passed shell syntax validation, and `git diff --check` was clean.
- The live widget served build `r16`; direct fetches passed for
  `structured-re-scope-gate-status.tsv`,
  `structured-re-finish-100-slices.tsv`, `structured-re-closeout-package.tsv`,
  and `structured-re-executable-evidence.tsv`.

## Boundary

This banks scope and negative evidence only. It does not implement mesh/SPDE,
large sparse pedigree helpers, precision-Q bridge marshalling, generic
direct-SD grammar, correlated structured slopes, structured `rho12`,
non-Gaussian q2/q4 structured covariance, REML support, bridge support,
interval coverage, public optimizer controls, or an Ayumi-facing reply.

## Next Gate

SR171-SR180 should synchronize formula grammar, known limitations, README,
pkgdown, examples, error messages, and forbidden-claim scans with these scope
rows.

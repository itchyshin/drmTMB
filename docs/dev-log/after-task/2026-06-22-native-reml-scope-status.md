# After Task: SR151-SR159 Native REML Scope Status

Date: 2026-06-22

## Goal

Bank the native REML scope rows as source-map, rejection, wording,
diagnostics-schema, optimizer-gate, and non-Gaussian wording evidence without
promoting unsupported REML capability.

## Changes

- Added `structured-re-native-reml-scope-status.tsv` for SR151-SR159.
- The rows separate requested and effective estimators and name exact target,
  route, support status, negative evidence, and next gate.
- The q1 mean-side phylo cell remains the only native exact-Gaussian supported
  REML row in this status surface. Sigma-side, q2, q4, public optimizer, and
  non-Gaussian rows are banked as rejection, planned, or wording evidence.

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
curl -fsS http://127.0.0.1:8765/structured-re-native-reml-scope-status.tsv >/dev/null
```

Results:

- `structured-re-conversion-contracts` passed with 269 assertions, 0 failures,
  0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 9 native-REML scope rows, 28
  closeout-package rows, and 44 executable-evidence rows.
- `status.json` and `sweep.json` parsed as JSON, `tools/start-mission-control.sh`
  passed shell syntax validation, and `git diff --check` was clean.
- The live widget served build `r15`; direct fetches passed for
  `structured-re-native-reml-scope-status.tsv`,
  `structured-re-finish-100-slices.tsv`, `structured-re-closeout-package.tsv`,
  and `structured-re-executable-evidence.tsv`.
- One parallel fetch of the new TSV raced the `/tmp/drm-dashboard` copy and
  returned 404 before the refresh completed; the serial retry after the start
  script finished passed.

## Boundary

This banks status and negative evidence only. It does not promote q1 sigma-side
native REML, q2 REML, q4 REML, q4 Patterson-Thompson as HSquared AI-REML,
non-Gaussian REML, public optimizer controls, interval coverage, bridge
support, or an Ayumi-facing reply.

## Next Gate

SR160 remains the acceptance gate: a REML row can move only with an exact
derivation, route-specific tests, diagnostics rows with requested/effective
estimator fields, docs, and claim-scan evidence.

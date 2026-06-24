# After Task: R Docs/API Sync Status

## Goal

Bank SR171-SR180 by making the R documentation and user-facing status surfaces
auditable without promoting any unsupported structured random-effect route.

## Implemented

- Added `structured-re-r-docs-sync-status.tsv` with one row each for SR171
  through SR180.
- Softened one formula-grammar sentence so the coordinate-spatial one-slope row
  no longer reads as an automatic profile-interval or coverage promotion.
- Wired the new TSV into the mission-control validator, dashboard renderer,
  focused row-contract tests, closeout package, executable evidence ledger, and
  finish ledger.

## Mathematical Contract

No mathematical estimator changed. This tranche only synchronizes claim
boundaries: fitted ML grammar, exact-Gaussian REML boundaries, planned
structured neighbours, bridge-negative evidence, and interval/coverage
non-claims remain separate.

## Files Changed

- `docs/design/01-formula-grammar.md`
- `docs/dev-log/dashboard/structured-re-r-docs-sync-status.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-closeout-package.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/structured-re-r-docs-sync-status.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-closeout-package.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv >/dev/null
```

Results:

- `structured-re-conversion-contracts` passed with 291 assertions, 0 failures,
  0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 10 R docs sync-status rows,
  30 closeout-package rows, and 46 executable-evidence rows.
- `status.json` and `sweep.json` parsed cleanly with `python3 -m json.tool`.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed.
- The live widget served build `r17` and direct fetches passed for
  `structured-re-r-docs-sync-status.tsv`,
  `structured-re-finish-100-slices.tsv`,
  `structured-re-closeout-package.tsv`, and
  `structured-re-executable-evidence.tsv`.

## Tests Of The Tests

The focused row-contract test now requires exactly SR171-SR180, requires each
row to carry an `rg -n` scan command, and checks the formula-grammar fix, error
message audit row, forbidden-claim scan row, and acceptance gate row.

## Consistency Audit

The scan commands recorded in the TSV cover formula grammar, known
limitations, README/ROADMAP/NEWS/pkgdown/vignette surfaces, and R-side
rejection-message files. Expected hits are negative boundaries, planned-route
language, or historical simulation rows; the tranche does not add public
bridge, q4 REML, HSquared AI-REML, non-Gaussian REML, optimizer, or coverage
support wording.

## GitHub Issue Maintenance

No issue comment, staging, commit, PR, or Ayumi reply was requested or made.

## What Did Not Go Smoothly

The stale wording was small but real: the spatial one-slope formula-grammar row
used profile-interval coverage wording that was too strong for this structured
RE finish arc. The fix keeps interval and coverage language attached to
row-specific diagnostic evidence.

## Team Learning

Rose should keep forbidden-claim scans row-specific, and Grace should require
new dashboard TSVs to be both validated and served before rows are banked.

## Known Limitations

SR171-SR180 bank documentation synchronization only. They do not implement q2
bridge support, q4 parity, native q4 REML, non-Gaussian REML, interval coverage,
public optimizer controls, mesh/SPDE, direct-SD grammar, or an Ayumi reply.

## Next Actions

Move to SR181-SR190: synchronize direct DRM.jl evidence names, active branch/SHA
state, and gate-vs-engine checks before the final SR191-SR200 Ayumi and
handoff gates.

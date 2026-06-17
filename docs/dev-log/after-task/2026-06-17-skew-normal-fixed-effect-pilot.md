# After Task: fixed-effect skew-normal diagnostic pilot

## Goal

Bank the first modest operating-characteristic pilot for the implemented
fixed-effect `skew_normal()` first slice without promoting interval calibration,
random effects, structured effects, bivariate skew-normal models, or release
readiness.

## Changed

- Added the reproducible artifact
  `docs/dev-log/simulation-artifacts/2026-06-17-skew-normal-fixed-effect-pilot/`.
- The artifact runs six fixed-effect cells: `nu` intercepts `-1.20`, `0`, and
  `1.20`, crossed with `nu` slopes `0` and `0.35`; all use `n = 720`,
  `sigma ~ z` slope `0.15`, and `rho(x, w) = 0.20`.
- The runner writes condition, manifest, aggregate, replicate, Wald interval,
  Wald coverage, and failure-ledger tables plus a diagnostic PNG.
- Updated docs 46/157/159 and mission-control status so the pilot is visible
  as diagnostic evidence only.

## Results

- 150/150 fits returned `ok`.
- No skipped fits, no errors, and no captured warnings.
- Each cell had convergence rate 1.000 and `pdHess` rate 1.000.
- Maximum absolute slant-term bias was 0.3067476 on the formula scale.
- Slant-term 70% Wald coverage ranged from 0.64 to 0.96, with MCSE up to
  0.096 at 25 replicates per cell.

Interpretation: the fitted fixed-effect skew-normal route is stable enough in
these cells to justify a larger formal grid. This pilot does not support
calibrated slant interval language, speed claims, external comparator parity,
or release promotion.

## Checks Run

```sh
Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-17-skew-normal-fixed-effect-pilot/run-pilot.R
python3 -m json.tool docs/dev-log/dashboard/status.json
python3 tools/validate-mission-control.py
Rscript --vanilla -e 'devtools::test(filter = "phase18-skew-normal-fixed-effect|skew-normal-location-scale|skew-normal-density-contract", reporter = "summary")'
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/design/159-drmtmb-0-2-0-release-readiness.md docs/dev-log/dashboard/status.json docs/dev-log/after-task/2026-06-17-skew-normal-fixed-effect-pilot.md docs/dev-log/check-log.md docs/dev-log/simulation-artifacts/2026-06-17-skew-normal-fixed-effect-pilot
```

## Boundary

No package code, no TMB likelihood code, no Julia bridge change, no new family
surface, no random/structured/bivariate skew-normal support, no profile or
bootstrap interval calibration, no speed claim, and no release-promotion claim.

# Q4 Stabilized Preflight

## Goal

Run a compact stabilized q4 preflight after the boundary-separated and Hessian
diagnostics showed that smaller toy fixtures were collapsing onto `pdHess =
false` and near-boundary correlations.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-preflight.tsv`.
- Added reproducibility artifact
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/`
  with `run.R`, `README.md`, and
  `q4-stabilized-preflight-results.tsv`.
- The preflight used a balanced 32-tip tree, eight observations per species,
  mild among-axis target correlations (`0.05` off-diagonal), two scale-axis
  signal levels (`0.35`, `0.50`), and two seeds (`202606901`, `202606902`).
- Two seed-902 rows reached optimizer convergence with `pdHess = TRUE`,
  interior fitted derived correlations (`max_abs` about `0.39` and `0.30`),
  and 4/4 finite Wald direct-SD interval rows.
- The two seed-901 companion rows still ended with singular convergence and
  `pdHess = false`, so the denominator and failed-fit accounting requirement
  remains active.
- Updated the mission-control widget so the stabilized preflight renders beside
  the q4 fixture design, Hessian diagnostic, and boundary-separated probe.
- Added validator and test coverage for the row count, seeds, scale levels,
  gradient threshold, interior correlation threshold, the two positive
  `pdHess` rows, the two negative rows, finite-Wald status, and claim
  boundaries.

## Boundary

This is q4 stabilized preflight evidence only. It does not promote q4 interval
reliability, interval coverage, q4 REML, HSquared AI-REML, profile/bootstrap
intervals, broad bridge support, a public optimizer control, a commit, a PR, or
an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 539 assertions.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run.R`
  reproduced the two positive `pdHess = TRUE` finite-Wald rows and the two
  singular-convergence `pdHess = false` rows.
- `python3 tools/validate-mission-control.py` passed with 4 q4 stabilized
  preflight rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r38`, `status.json`,
  `sweep.json`, `structured-re-q4-stabilized-preflight.tsv`, and
  `structured-re-q4-stabilized-fixture-design.tsv` from
  `http://127.0.0.1:8765/`.
- The live dashboard also served
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/README.md`
  and `q4-stabilized-preflight-results.tsv`.

## Next Gate

Replicate the stabilized fixture with explicit denominator accounting and then
test profile/bootstrap availability before any calibrated q4 coverage grid or
user-facing interval wording.

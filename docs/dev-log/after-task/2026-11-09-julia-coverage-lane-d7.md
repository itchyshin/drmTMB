# After task: Julia bridge coverage CI lane (D7)

## Goal

Add a separate GitHub Actions covr job that installs Julia and DRModels.jl,
runs live `test-julia-*.R` files, and uploads cobertura under Codecov flag
`julia-bridge` without lengthening the four existing R coverage shards.

## Implemented

- `julia-bridge-coverage` job in `test-coverage.yaml` (parallel to shards 1–4).
- `tools/ci-install-drmodels-julia.sh`, `tools/covr-julia-bridge-testthat.R`,
  `tools/covr-plant-julia-bridge-testthat.sh` (CI-only test driver; committed
  `tests/testthat.R` unchanged).
- Second OIDC upload step in `codecov-upload.yaml` with `flags: julia-bridge`.
- `codecov.yml` flag carryforward for `julia-bridge`.
- Extended `tools/tests/test_codecov_workflow.py` guardrails.

## Claim boundary

CI and tooling only. No test file edits, no coverage exclusions, no parity
assertions. Job fails on test failure via standard covr / testthat behaviour.

## Checks

- `python3 -m unittest tools/tests/test_codecov_workflow.py -v` (local).
- Hosted `test-coverage` workflow: pending PR CI.

## Next

- After merge, confirm merged project % on Codecov rises on `R/julia-bridge.R`
  and related Julia joint sources when the julia-bridge flag uploads on main.

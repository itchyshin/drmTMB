# After Task: AI-REML Guarded Update Experiment Gate

## Goal

Continue the HSquared transfer lane by adding a guarded average-information
update experiment for the exact-Gaussian location-only REML pilot, while keeping
q4, non-Gaussian, R bridge, Ayumi-facing, and 10k interval claims unchanged.

## Implemented

The clean DRM.jl worktree now has `_loconly_reml_ai_update_optimizer_diagnostic()`.
It uses sparse-Woodbury score and average-information diagnostics, applies a
guarded two-parameter update with objective-decrease step-halving, records
per-iteration traces, and compares the endpoint against the finite-difference,
dense-score, and sparse-score optimizer diagnostics.

The drmTMB mission-control layer records that evidence in the HSquared transfer
ledger, finish capability matrix, dashboard JSON, check log, and this
after-task report.

## Mathematical Contract

The experiment targets the exact Gaussian restricted likelihood for
`V = sigma^2 I + sigma_phy^2 S Q_cond^{-1} S'`. It is a diagnostic optimizer
experiment for that Gaussian cell only. It is not a q4 derivation, not a
non-Gaussian method, and not a user-facing R bridge estimator.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-guarded-update-experiment.md`

The paired DRM.jl worktree changes are in
`/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
tools/start-mission-control.sh --background
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply|public estimator claim|AI-REML optimizer" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-guarded-update-experiment.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 229/229 assertions.

## Tests Of The Tests

The guarded-update endpoint must agree with the finite-difference, dense-score,
and sparse-score optimizer diagnostics to `1e-5`, expose accepted-step trace
records, report a small final score norm, carry comparator and boundary
diagnostics, and fail explicitly for singular fixed-effect information.

## Consistency Audit

The dashboard row remains `partial`; the R bridge remains `unsupported`; q4 and
non-Gaussian routes keep observed-information, profile, bootstrap, ML/Laplace,
or Patterson-Thompson wording as appropriate. No Ayumi reply draft was touched.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation correction was needed; the focused DRM.jl test passed on the
first run after adding the guarded update helper and tests.

## Team Learning

The exact-Gaussian update loop now has enough guardrails to be useful as a
diagnostic optimizer, but the next claim gate is simulation recovery rather than
wording promotion.

## Known Limitations

There is still no simulation grid, bridge provenance field, external comparator
package, large-tree stress test, q4 derivation, or full-tree interval claim.

## Next Actions

Add a small Monte Carlo recovery grid for this exact-Gaussian location-only cell
and keep the result separate from bridge and interval claims.

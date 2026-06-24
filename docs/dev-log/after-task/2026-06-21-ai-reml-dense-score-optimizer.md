# After Task: AI-REML Dense-Score Optimizer Diagnostic

## Goal

Add a dense analytic restricted-score diagnostic and dense-score optimizer
experiment for the exact-Gaussian location-only REML pilot.

## Implemented

The clean DRM.jl worktree now evaluates the dense Gaussian REML score for the two
log-SD parameters and tests it against finite differences. It also has a
developer-only LBFGS experiment using that dense score, compared against the
finite-difference optimizer diagnostic.

## Mathematical Contract

The dense score is `0.5 * (tr(P dV) - y' P dV P y)` for the Gaussian restricted
negative log likelihood. It is dense developer evidence, not a sparse score and
not an average-information update.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-dense-score-optimizer.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
tools/start-mission-control.sh --background
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-dense-score-optimizer.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 161/161 assertions in 7.9 seconds.

## Tests Of The Tests

The dense score is checked against finite differences of the sparse restricted
objective. The dense-score optimizer must agree with the finite-difference
optimizer to 1e-6 on the objective and keep an interior boundary label.

## Consistency Audit

The dashboard row remains `partial`. No bridge row, public optimizer, q4,
Laplace, non-Gaussian, Ayumi-facing, or 10k interval claim is promoted.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No new issue in this slice.

## Team Learning

The dense restricted score is the right stepping stone before attempting a
sparse Takahashi score.

## Known Limitations

The score is dense and unsuitable for large trees. No sparse analytic score,
true average-information update, or full package test suite is included.

## Next Actions

Port the score identity to sparse Woodbury/Takahashi quantities.

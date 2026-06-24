# After Task: AI-REML Sparse Information Diagnostic Gate

## Goal

Continue the HSquared transfer lane by adding the sparse average-information
diagnostic for the exact-Gaussian location-only REML pilot, while keeping q4,
non-Gaussian, R bridge, Ayumi-facing, and 10k interval claims unchanged.

## Implemented

The clean DRM.jl worktree now has `_loconly_reml_sparse_ai_information_diagnostic()`.
It applies the residual and phylogenetic derivative matrices through sparse
Woodbury projection, compares the 2 by 2 matrix against the dense AI diagnostic,
and reports relative error against the finite-difference observed Hessian. The
combined developer payload now includes `sparse_information`.

The drmTMB mission-control layer records that evidence in the HSquared transfer
ledger, finish capability matrix, dashboard JSON, check log, and this
after-task report.

## Mathematical Contract

The diagnostic evaluates the Gaussian REML average-information expression for
`V = sigma^2 I + sigma_phy^2 S Q_cond^{-1} S'`. It is a matrix diagnostic for
the exact-Gaussian pilot, not a production update step, not a q4 derivation, and
not a non-Gaussian method.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-sparse-information-diagnostic.md`

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
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply|public estimator claim|AI-REML optimizer" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-sparse-information-diagnostic.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 205/205 assertions.

## Tests Of The Tests

The sparse information matrix must match the dense AI diagnostic to `1e-8`,
remain symmetric, keep the observed-Hessian relative error below `0.1`, appear
in the combined payload, and fail explicitly for singular fixed-effect
information.

## Consistency Audit

The dashboard row remains `partial`; the R bridge remains `unsupported`; q4 and
non-Gaussian routes keep observed-information, profile, bootstrap, ML/Laplace,
or Patterson-Thompson wording as appropriate. No Ayumi reply draft was touched.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation correction was needed; the focused DRM.jl test passed on the
first run after adding the sparse information diagnostic.

## Team Learning

The sparse projection and derivative-action helpers are now enough to evaluate
both score and average-information diagnostics without building dense `P`.

## Known Limitations

There is still no validated update step, step-halving, simulation evidence,
R bridge provenance field, q4 derivation, or full-tree interval claim.

## Next Actions

Build a guarded two-parameter average-information update experiment and compare
its endpoint with the finite-difference, dense-score, and sparse-score optimizer
diagnostics before using stronger estimator language.

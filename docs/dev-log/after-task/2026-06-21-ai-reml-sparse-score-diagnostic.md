# After Task: AI-REML Sparse-Score Diagnostic Gate

## Goal

Continue the HSquared transfer lane by moving the exact-Gaussian restricted
score from dense developer matrices to sparse Woodbury quantities, while keeping
q4, non-Gaussian, R bridge, Ayumi-facing, and 10k interval claims unchanged.

## Implemented

The clean DRM.jl worktree now has a sparse-Woodbury restricted-score diagnostic
for the location-only Gaussian phylogenetic mean cell. It reports residual and
phylogenetic trace terms, quadratic terms, fixed-effect correction terms, dense
score parity, finite-difference parity, and a developer-only sparse-score LBFGS
optimizer experiment with `ai_reml_ready = false`.

The drmTMB mission-control layer now records that evidence in the HSquared
transfer ledger, the finish capability matrix, dashboard JSON, check log, and
this after-task report.

## Mathematical Contract

The diagnostic remains the Gaussian REML derivative
`0.5 * (tr(P dV) - y' P dV P y)` for
`V = sigma^2 I + sigma_phy^2 S Q_cond^{-1} S'`. The sparse implementation
uses Woodbury `V^{-1}` solves and sparse `Q_cond` solves, then compares back to
the dense same-estimand oracle. It is not a q4 derivation and not a validated
average-information update.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-sparse-score-diagnostic.md`

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
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply|public estimator claim|AI-REML optimizer" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-sparse-score-diagnostic.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 194/194 assertions.

## Tests Of The Tests

The sparse score must match the dense score to `1e-8` and finite differences to
`1e-6`. The optimizer experiment is compared with the dense-score optimizer,
and the boundary tests exercise a near-zero phylogenetic SD and singular
fixed-effect information.

## Consistency Audit

The dashboard row remains `partial`; the R bridge remains `unsupported`; q4 and
non-Gaussian routes keep observed-information, profile, bootstrap, ML/Laplace,
or Patterson-Thompson wording as appropriate. No Ayumi reply draft was touched.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation correction was needed after the sparse-score patch; the
focused DRM.jl test passed on the first run.

## Team Learning

Dense same-estimand score tests are a useful guardrail before replacing dense
algebra with Woodbury quantities. The next update step should keep the same
oracle pattern.

## Known Limitations

The sparse score still materializes a dense selection matrix in the tiny
developer diagnostic, and there is no validated average-information matrix,
simulation evidence, R bridge field, q4 derivation, or full-tree interval
claim.

## Next Actions

Derive and test the exact-Gaussian sparse average-information matrix for this
same location-only cell, then compare it with the finite-difference observed
Hessian before any bridge-provenance change is considered.

# After Task: AI-REML Recovery-Grid Diagnostics

## Goal

Add tiny deterministic point-recovery diagnostics for the exact-Gaussian
location-only REML guarded update experiment, while keeping q4, non-Gaussian,
R bridge, Ayumi-facing, interval, and 10k claims unchanged.

## Implemented

The clean DRM.jl worktree now has `_loconly_reml_recovery_grid_diagnostic()` and
`_loconly_reml_recovery_condition_grid_diagnostic()`. The first simulates a
truth-known exact-Gaussian location-only cell and reports convergence, mean
estimates, bias, RMSE, MCSE for bias, boundary counts, and replicate records.
The second keeps multiple simulation cells row-separated and preserves the full
nested diagnostic for each row.

The drmTMB mission-control layer records that evidence in the HSquared transfer
ledger, finish capability matrix, dashboard JSON, check log, and this
after-task report.

## Mathematical Contract

The diagnostics use
`y = X beta + u_species + epsilon`,
`u ~ N(0, sigma_phy^2 Sigma_phy)`, and
`epsilon ~ N(0, sigma^2 I)` for the exact Gaussian location-only phylogenetic
mean cell. They evaluate point-estimate recovery for `sigma` and `sigma_phy`.
They do not evaluate interval coverage and do not apply to q4 or non-Gaussian
routes.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-recovery-grid-diagnostics.md`

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
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply|public estimator claim|AI-REML optimizer" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-recovery-grid-diagnostics.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 267/267 assertions.

## Tests Of The Tests

The single-cell grid uses a fixed seed, known `sigma`/`sigma_phy`, 10 species,
3 observations per species, and 3 replicates. It requires accepted fits,
interior boundary counts, finite bias/RMSE/MCSE fields, and broad bias sanity
thresholds. The condition grid uses two named interior cells and requires
row-level accepted fits and finite summaries.

## Consistency Audit

The dashboard row remains `partial`; the R bridge remains `unsupported`; q4 and
non-Gaussian routes keep observed-information, profile, bootstrap, ML/Laplace,
or Patterson-Thompson wording as appropriate. No Ayumi reply draft was touched.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

The first single-cell draft used a sparser design and correctly exposed
weak-signal boundary behavior. The routine test was resized to a stable
interior cell, and weak-boundary recovery was deferred to a separately labelled
diagnostic.

## Team Learning

Recovery evidence should stay row-separated by condition. A tiny stable
interior row is useful for optimizer regression tests; weak-signal rows should
be allowed to report boundary behavior without failing the routine suite.

## Known Limitations

The grids are intentionally tiny and do not support interval coverage,
large-tree performance, bridge, q4, or non-Gaussian claims.

## Next Actions

Add an explicitly labelled weak-signal/boundary condition diagnostic that
reports low convergence or boundary states as evidence rather than as a routine
test failure.

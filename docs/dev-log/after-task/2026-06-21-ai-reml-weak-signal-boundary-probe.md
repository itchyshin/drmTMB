# After Task: AI-REML Weak-Signal Boundary Recovery Probe

## Goal

Add an explicitly labelled weak-signal point-recovery probe for the
exact-Gaussian location-only REML guarded update experiment, while keeping q4,
non-Gaussian, R bridge, Ayumi-facing, interval, and 10k claims unchanged.

## Implemented

The clean DRM.jl worktree now has `_loconly_reml_weak_signal_recovery_probe()`.
It runs a low-phylogenetic-signal recovery cell and reports boundary count,
boundary rate, convergence rate, the nested recovery-grid diagnostic, and
`expected_behavior = :boundary_states_allowed`.

The drmTMB mission-control layer records that evidence in the HSquared transfer
ledger, finish capability matrix, dashboard JSON, check log, and this
after-task report.

## Mathematical Contract

The probe uses the exact Gaussian location-only phylogenetic mean cell. It is
intentionally boundary-prone and is tested for honest reporting, not for
universal convergence. It does not evaluate interval coverage and does not apply
to q4 or non-Gaussian routes.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-weak-signal-boundary-probe.md`

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
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply|public estimator claim|AI-REML optimizer" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-weak-signal-boundary-probe.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 277/277 assertions.

## Tests Of The Tests

The probe uses a fixed weak-signal cell and requires at least one boundary
replicate, a boundary rate of at least 0.5, explicit
`boundary_states_allowed` semantics, and no convergence-success requirement.

## Consistency Audit

The dashboard row remains `partial`; the R bridge remains `unsupported`; q4 and
non-Gaussian routes keep observed-information, profile, bootstrap, ML/Laplace,
or Patterson-Thompson wording as appropriate. No Ayumi reply draft was touched.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation correction was needed. The weak-signal probe formalizes the
boundary behavior observed in the first too-sparse recovery draft.

## Team Learning

Boundary-prone simulation cells need a different pass condition from stable
interior recovery cells: honest reporting beats forced convergence.

## Known Limitations

The probe is tiny and intentionally boundary-prone. It does not support
coverage, bridge, q4, non-Gaussian, or 10k-scale claims.

## Next Actions

Add a compact simulation-status table that separates stable recovery,
condition-grid, and weak-signal boundary diagnostics in one machine-readable
row set.

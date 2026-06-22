# After Task: AI-REML Simulation-Status Rows

## Goal

Carry the exact-Gaussian location-only REML diagnostics through slices 1 to 20:
add and harden a compact machine-readable simulation-status surface in the
clean DRM.jl worktree, then sync the drmTMB mission-control evidence while
preserving the Gaussian-only AI-REML boundary.

## Implemented

The clean DRM.jl worktree now has `_loconly_reml_simulation_status()`. It
returns four row-separated diagnostics for the guarded average-information
update experiment:

- `stable_recovery`
- `condition_grid`
- `weak_signal_boundary_probe`
- `larger_interior_stress`

Each row reports target, estimator, design, claim status, coverage status,
replicate counts, convergence rate, boundary rate, bias, RMSE, MCSE, runtime,
seed, evidence, and next gate.

The full 20-slice pass also adds a schema helper, row-contract validator, TSV
writer, optional `medium_interior_stress` row, broader recovery-grid helper,
weak-signal condition-grid helper, failure-reason counts, diagnostic-only MCSE
status, runtime-budget fields, and deterministic seed registries. The DRM.jl
tool script `tools/loconly-reml-simulation-status.jl` regenerates the default
four-row TSV and can write a five-row optional stress TSV with
`--with-medium-stress`.

The drmTMB mission-control layer records that evidence in the HSquared transfer
ledger, finish capability matrix, dashboard JSON, check log, and this
after-task report. The AI-REML-inspired matrix row now marks simulation evidence
as `partial`, not `covered`, because this is diagnostic simulation evidence and
interval coverage is not evaluated.

## Mathematical Contract

The row surface uses the exact Gaussian location-only phylogenetic mean cell
only. It reports point-recovery and boundary diagnostics for an internal
guarded update experiment. It does not evaluate coverage and does not apply to
q4, Laplace, non-Gaussian, or bivariate location-scale routes.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-simulation-status-rows.md`

The paired DRM.jl worktree changes are in
`/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. tools/loconly-reml-simulation-status.jl --output docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv
tmp=$(mktemp -d)/loconly-status-medium.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-medium-stress --output "$tmp" && wc -l "$tmp"
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
tools/start-mission-control.sh --background
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply|public estimator claim|AI-REML optimizer" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-simulation-status-rows.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 348/348 assertions. The default TSV writer
produced four rows. The optional medium-stress script path produced five rows
in a temporary TSV.

## Tests Of The Tests

The DRM.jl schema test requires all four expected row IDs, exact
`gaussian_loconly_phylo_reml` target labels, exact
`guarded_ai_update_reml_optimizer_experiment` estimator labels,
`coverage_status = :not_evaluated`, nonnegative runtime fields, populated seed
and evidence fields, bounded boundary rates, and row-specific next gates. It
also requires the weak-signal row to retain boundary behavior and the larger
interior stress row to accept both replicates.

The expanded test also verifies the schema fields, stable row order, validator,
TSV writer header, optional medium stress row, broader recovery-grid helper,
weak-signal condition-grid helper, failure-reason count field, seed registry,
runtime budget field, and `mcse_status = :diagnostic_only`.

## Consistency Audit

The dashboard row remains partial; the R bridge remains unsupported. q4 and
non-Gaussian routes keep observed-information, profile, bootstrap, ML/Laplace,
or Patterson-Thompson wording as appropriate. No Ayumi reply draft was touched.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

The first focused rerun failed because the TSV header assertion compared a
vector read from file with a tuple schema. The assertion now compares vectors.
The first tool-script run failed because a string separator was over-escaped;
the script now uses the correct Julia string. A broad `jq` probe of
`sweep.json` used the wrong shape during inspection; the file was then read
directly before editing.

## Team Learning

Once a diagnostic has stable, boundary-prone, and stress-smoke conditions, the
evidence should become row-shaped and writer-backed. A single prose status is
too easy to overread as a broad simulation claim.

## Known Limitations

The simulation-status rows and optional stress path are tiny and
diagnostic-only. They do not support coverage, bridge, q4, non-Gaussian,
Ayumi-facing, or 10k-scale claims.

## Next Actions

Use the TSV writer as the stable interface for future broadening. Larger
exact-Gaussian stress rows should stay optional until a separate runtime budget
and CI strategy are chosen.

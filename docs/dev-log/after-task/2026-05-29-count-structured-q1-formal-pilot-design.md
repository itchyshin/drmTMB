# After Task: Count Structured q1 Formal-Pilot Design

## Goal

Write the first formal-pilot design for the stable count structured q1 lane
after GitHub Actions run `26638116979` passed the boundary gate.

## Implemented

Added
`docs/design/139-phase-18-count-structured-q1-formal-pilot-design-slices-1763-1770.md`.
The design keeps the next run on
`phase18_count_structured_q1_followup_conditions("stable")`, requests the
direct `log_sd_phylo` profile target at `profile_level = 0.70`, uses
`n_reps = 100`, leaves bootstrap disabled, and sets boundary, profile-status,
watch-cell, MCSE, and runtime rules before any later recovery-grid design.

Updated `ROADMAP.md`, `docs/design/41-phase-18-simulation-programme.md`, and
`docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`
so the slice map points to the new design note.

## Mathematical Contract

No likelihood, formula grammar, DGP code, or runner code changed. The design
uses the existing direct structured-SD profile target exposed by
`profile_targets()` and mapped through
`phase18_count_structured_q1_profile_parameter_map()`. The pilot target is 70%
profile interval coverage for the public structured-SD scale, not a final 95%
coverage claim and not a bootstrap claim.

## Files Changed

- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`
- `docs/design/139-phase-18-count-structured-q1-formal-pilot-design-slices-1763-1770.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-count-structured-q1-formal-pilot-design.md`

## Checks Run

```sh
air format docs/design/139-phase-18-count-structured-q1-formal-pilot-design-slices-1763-1770.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md
Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); source(system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE)); source(system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE)); source(system.file("sim/dgp/sim_dgp_count_structured_q1.R", package = "drmTMB", mustWork = TRUE)); source(system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE)); source(system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE)); source(system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE)); source(system.file("sim/fit/sim_summarise_count_structured_q1.R", package = "drmTMB", mustWork = TRUE)); source(system.file("sim/run/sim_run_count_structured_q1_smoke.R", package = "drmTMB", mustWork = TRUE)); source(system.file("sim/run/sim_summary_count_structured_q1_smoke.R", package = "drmTMB", mustWork = TRUE)); cond <- phase18_count_structured_q1_followup_conditions("stable")[1, , drop = FALSE]; result_dir <- tempfile("drmTMB-count-structured-profile-"); dir.create(result_dir); timing <- system.time(out <- phase18_summarise_count_structured_q1_smoke(conditions = cond, n_rep = 1L, master_seed = 20260530L, result_dir = result_dir, profile_parameters = "log_sd_phylo", profile_level = 0.70)); print(timing); print(out$profile_intervals); unlink(result_dir, recursive = TRUE)'
rg -n "significant|various|leverages|important to note|in order to|formal recovery|coverage claim|coverage claims|recovery claim|all clean|promote|promoted|bootstrap" docs/design/139-phase-18-count-structured-q1-formal-pilot-design-slices-1763-1770.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md
gh issue list --repo itchyshin/drmTMB --state open --search 'count structured q1 formal pilot stable profile log_sd_phylo MCSE' --limit 20 --json number,title,state,url,labels
```

## Tests Of The Tests

This was a design-only slice, so no package test changed. The local one-replicate
smoke checked that the proposed `profile_parameters = "log_sd_phylo"` path is
executable on one stable cell and returns an `ok` profile interval. That smoke
supports the runtime paragraph only; it does not validate coverage.

## Consistency Audit

The prose scan found expected guardrails about formal recovery, coverage claims,
and bootstrap being out of scope. I updated the Phase 18 programme count row so
it names the new design note instead of implying the formal-pilot design remains
future work. The design note, ROADMAP row, programme row, and count structured
artifact note now agree that the next action is dispatch and audit, not a
recovery claim.

## GitHub Issue Maintenance

The issue search returned no exact open issue for the count structured q1
formal-pilot design. The broader Phase 18 simulation issue remains the umbrella
for this work; no duplicate issue was opened.

## What Did Not Go Smoothly

My first local runtime command selected interval-table columns that did not
exist and exited after the model/profile run. I reran it to print the actual
schema and the full `profile_intervals` row, then used that successful rerun as
the evidence.

## Team Learning

- Ada should keep design slices tied to a dispatch-and-audit next action.
- Fisher should name the interval level and MCSE scale before any formal run is
  dispatched.
- Curie should include both overall and condition-level stop rules.
- Pat should make the dispatch command copy-ready for the next runner.
- Grace should avoid turning a local timing smoke into a runtime guarantee.
- Rose should update high-level programme rows when a future design note becomes
  a current artifact.

No spawned subagents were running.

## Known Limitations

This slice does not dispatch the formal pilot, download artifacts, audit
profile coverage, change the DGP or runner, add bootstrap intervals, or make
recovery claims.

## Next Actions

After this PR lands, dispatch the manual `count_structured_q1` stable-set pilot
from `main`, download the artifact, run
`phase18_audit_count_structured_q1_boundary_gate()`, and write a separate
after-task audit before updating the ROADMAP from design to run evidence.

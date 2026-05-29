# After Task: Phase 18 Count Structured q1 Stable Diagnostic Audit

## Goal

Dispatch and audit the `condition_set = "stable"` diagnostic run for ordinary
Poisson and NB2 count models with one q=1 structured `mu` intercept.

## Implemented

GitHub Actions run `26638116979` dispatched `task=count_structured_q1` from
`main` at commit `c4919dd3ece07e9fe2ff15b616a530e680658f73`, with
`condition_set = "stable"`, `n_reps = 20`, `cores = 2`,
`backend = multicore`, `profile_parameters = ''`, one condition shard, and
`render_report = false`. The selected job succeeded in 3m48s, while the
unselected matrix jobs skipped.

The downloaded artifact had 10 condition directories, 200 replicate RDS files,
200 `ok` manifest rows, 760 replicate parameter rows, 38 aggregate rows, 200
profile-target rows, 200 not-requested profile-interval rows, 760 Wald
interval rows, 28 Wald coverage rows, and no warning-ledger rows.

The boundary-gate helper collapsed the replicate table to 200 fitted
replicates and returned `propose_next_pilot`. The overall SD-boundary warning
rate was 3/200 = 0.015, below the pre-declared 15% gate. No cell crossed the
condition-level 40% SD-boundary trigger. The two cells with SD-boundary
warnings were stable-set `count_structured_q1_003`, mapped to original pilot
cell `count_structured_q1_016`, and stable-set `count_structured_q1_005`,
mapped to original pilot cell `count_structured_q1_018`.

## Mathematical Contract

No likelihood, formula grammar, parameterization, fitted model surface, or
user-facing model syntax changed. The audited model remains an ordinary
non-zero-inflated Poisson or NB2 count model with one q=1 structured `mu`
intercept on the log-mean scale.

## Files Changed

- `docs/design/138-phase-18-count-structured-q1-stable-diagnostic-audit-slices-1761-1762.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-stable-diagnostic-audit.md`

## Checks Run

```sh
gh workflow run phase18-simulation-grid.yaml --repo itchyshin/drmTMB --ref main -f task=count_structured_q1 -f condition_set=stable -f n_reps=20 -f cores=2 -f backend=multicore -f bootstrap_nsim=0 -f bootstrap_cores=2 -f bootstrap_backend=none -f profile_parameters='' -f condition_shard=1 -f condition_shards=1 -f render_report=false -f retention_days=14
gh run watch 26638116979 --repo itchyshin/drmTMB --interval 30 --exit-status
gh run download 26638116979 --repo itchyshin/drmTMB --dir /tmp/drmTMB-phase18-count-structured-q1-stable-26638116979
Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); source("inst/sim/R/sim_registry.R"); source("inst/sim/R/sim_utils.R"); source("inst/sim/R/sim_runner.R"); source("inst/sim/R/sim_uncertainty.R"); source("inst/sim/fit/sim_summarise_count_structured_q1.R"); source("inst/sim/run/sim_write_count_structured_q1_grid.R"); root <- "/tmp/drmTMB-phase18-count-structured-q1-stable-26638116979/phase18-count_structured_q1-shard-1-of-1-26638116979"; audit <- phase18_audit_count_structured_q1_boundary_gate(root, require_complete = TRUE); print(audit$boundary_gate$overall); print(audit$boundary_gate$conditions[audit$boundary_gate$conditions$fit_diagnostic_warning > 0 | audit$boundary_gate$conditions$sd_boundary_warning > 0 | audit$boundary_gate$conditions$hessian_warning > 0, c("cell_id", "family", "structured_type", "n_level", "sd_structured", "mean_count", "sigma_baseline", "n_fit", "fit_diagnostic_warning", "sd_boundary_warning", "hessian_warning")]); print(audit$boundary_gate$checks); print(audit$boundary_gate$decision)'
Rscript --vanilla -e 'root <- "/tmp/drmTMB-phase18-count-structured-q1-stable-26638116979/phase18-count_structured_q1-shard-1-of-1-26638116979"; result <- readRDS(file.path(root, "phase18-actions-result.rds")); cells <- result$summary$run$registry$cells; print(cells[, c("cell_id", "pilot_cell_id", "family", "structured_type", "n_level", "sd_structured", "pilot_condition_role", "pilot_sd_boundary_status")], row.names = FALSE)'
gh issue list --repo itchyshin/drmTMB --state open --search 'count_structured_q1 stable diagnostic OR count structured q1 stable OR count structured q1 formal pilot' --limit 20 --json number,title,state,url,labels
air format docs/design/138-phase-18-count-structured-q1-stable-diagnostic-audit-slices-1761-1762.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-stable-diagnostic-audit.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|condition_set=stable.*coverage|condition_set=stable.*recovery claim|stable.*formal recovery claim|stable.*all clean|stable.*promot.*recovery|stable diagnostic.*coverage' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
```

The Actions run succeeded, the boundary-gate helper returned
`propose_next_pilot`, the issue search returned `[]`,
`pkgdown::check_pkgdown()` reported no problems, the stale-claim scan returned
only intended guardrails, and `git diff --check` was clean.

## Tests Of The Tests

No package tests changed. The executable gate was tested against the real
stable-set Actions artifact and produced the positive diagnostic path:
`propose_next_pilot`, with low SD-boundary warning rates and no Hessian or
warning-ledger failures.

## Consistency Audit

The roadmap, Phase 18 simulation programme, simulation README, check log,
design note, and this after-task report now state the same decision: the
stable-set diagnostic passes the boundary gate and supports a separate
formal-pilot design note, but it does not make recovery or coverage claims.

## GitHub Issue Maintenance

`gh issue list` found no overlapping open issue for the stable count structured
q1 diagnostic or formal-pilot transition. I did not open a new issue because
the design note, roadmap row, check log, and after-task report record the
diagnostic result and next design action.

## What Did Not Go Smoothly

The run itself was smooth. The only audit wrinkle is that the artifact's
replicate table uses stable-set cell IDs, while the saved result registry
stores the mapping to original pilot cells. The stable-set audit report records
both IDs for the warning cells so future readers do not confuse new stable-set
IDs with the 24-cell pilot IDs.

## Team Learning

Ada kept the lane at diagnostic evidence and pointed to a separate formal
design. Curie checked fitted-replicate counts, row counts, and cell-ID mapping.
Fisher kept direct-interval, MCSE, recovery, and coverage claims out. Grace
watched Actions, downloaded the artifact, ran pkgdown, and checked diff
hygiene. Rose checked stale wording and issue overlap. No spawned subagents
were running.

## Known Limitations

This run did not request profile or bootstrap intervals, so structured-SD
coverage remains unestimated. The low-SD `boundary_stress` cells and the
high-SD `stable_watch` cells remain diagnostic lanes, not promotion evidence.
The next step must be a formal-pilot design note with interval policy, MCSE
targets, runtime budget, and stop rules.

## Next Actions

Write the formal-pilot design note for the stable count structured q1 condition
set. It should specify direct interval targets, MCSE thresholds, replicate
count, whether and how to profile `log_sd_phylo`, runtime limits, and stop
rules for the two NB2 high-SD cells that still produced low-rate SD-boundary
warnings.

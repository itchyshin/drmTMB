# Phase 18 Count Structured q1 Follow-Up Condition Sets, Slices 1753-1760

This note specifies the follow-up after the 24-cell diagnostic pilot for
ordinary Poisson and NB2 count models with one q=1 structured `mu` intercept.
The reader is an R package contributor deciding how to keep stable operating
conditions separate from deliberate boundary stress after GitHub Actions run
`26631771105`.

## Aim

The previous pilot returned `hold_diagnostic` because 40/240 fitted replicates
had non-ok SD-boundary diagnostics, just above the 15% gate. The follow-up
does not revise the likelihood or formula grammar. It makes the next condition
sets executable so that a stable candidate run cannot hide low-`sd_structured`
boundary behavior inside an averaged 24-cell result.

## Condition Sets

`phase18_count_structured_q1_followup_conditions()` starts from the same
24-cell table used by the manual `count_structured_q1` task. It annotates each
cell with `pilot_source_run = "26631771105"`, the original `pilot_cell_id`,
the pilot SD-boundary status, and a condition role:

| Condition set | Cells | Purpose |
| --- | ---: | --- |
| `stable` | 10 | High-`sd_structured` cells with no SD-boundary warning in run `26631771105`; this is the only set eligible to propose a later recovery design. |
| `stable_watch` | 2 | High-`sd_structured` NB2 spatial cells with lower-rate SD-boundary warnings; these remain diagnostic watchlist cells. |
| `boundary_stress` | 12 | All low-`sd_structured = 0.25` cells; six crossed the condition-level SD-boundary trigger and the rest had lower-rate warnings. |
| `all` | 24 | The historical default table, retained for reproducing the original diagnostic surface. |

The split treats low `sd_structured` as a boundary-stress factor, not as a
failed implementation. A boundary-stress run can teach the team where weak
structured SDs are hard to estimate, but it cannot promote the count structured
q1 lane to formal recovery evidence.

## Manual Actions Contract

The manual workflow now accepts `condition_set`. The next stable-set diagnostic
run should use:

```sh
gh workflow run phase18-simulation-grid.yaml \
  --repo itchyshin/drmTMB \
  --ref main \
  -f task=count_structured_q1 \
  -f condition_set=stable \
  -f n_reps=20 \
  -f cores=2 \
  -f backend=multicore \
  -f bootstrap_nsim=0 \
  -f bootstrap_cores=2 \
  -f bootstrap_backend=none \
  -f profile_parameters='' \
  -f condition_shard=1 \
  -f condition_shards=1 \
  -f render_report=false \
  -f retention_days=14
```

This is 10 cells x 20 replicates, for 200 fitted replicates and 800 parameter
rows if all fits complete. The previous 24-cell x 10-replicate run finished
the selected job in 3m51s, so the stable-set run should be treated as a
short diagnostic job until Actions evidence says otherwise.

The watchlist and boundary-stress sets are separate dispatches. They should
not be combined with the stable-set artifact when deciding whether a later
formal recovery design is allowed.

## Gate Audit

Use the same helper as the previous pilot:

```r
devtools::load_all(quiet = TRUE)
source("inst/sim/R/sim_registry.R")
source("inst/sim/R/sim_utils.R")
source("inst/sim/R/sim_runner.R")
source("inst/sim/R/sim_uncertainty.R")
source("inst/sim/fit/sim_summarise_count_structured_q1.R")
source("inst/sim/run/sim_write_count_structured_q1_grid.R")

audit <- phase18_audit_count_structured_q1_boundary_gate(
  output_dir = "path/to/phase18-count_structured_q1-<run-id>",
  require_complete = TRUE
)
audit$boundary_gate$overall
audit$boundary_gate$conditions
audit$boundary_gate$checks
audit$boundary_gate$decision
```

For the `stable` set, all Slice 1737-1738 checks must pass before the next
step can be a formal-pilot design note. Passing this diagnostic still does not
create a recovery or coverage claim, because direct structured-SD intervals
and MCSE targets are not part of this run.

For `stable_watch` or `boundary_stress`, record the same fitted-replicate
rates but keep the decision at diagnostic evidence. These runs answer where
the weak-SD behavior lives, not whether the stable lane is recovered.

## Reporting Requirements

The after-task report for the next Actions run must name the `condition_set`,
cell count, fitted-replicate count, selected-job runtime, boundary-gate output,
and whether any warning-ledger row is explained by SD-boundary diagnostics. It
must state that `condition_set=stable` excludes the two high-SD watchlist cells
and all low-SD boundary-stress cells.

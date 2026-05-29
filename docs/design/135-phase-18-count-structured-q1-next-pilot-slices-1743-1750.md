# Phase 18 Count Structured q1 Next Diagnostic Pilot, Slices 1743-1750

This note specifies the next bounded diagnostic pilot for ordinary Poisson and
NB2 count models with one q=1 structured `mu` intercept. It follows the
boundary-gate helper audit in `docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`,
which returned `propose_next_pilot` for GitHub Actions run `26626333581`.

## Aim

Estimate whether the boundary-sensitive fits from the 2-replicate smoke audit
are rare one-off cases or concentrated condition-level behavior. The target is
diagnostic stability before any recovery or coverage grid, not model-surface
promotion.

## Condition Table

Use the existing `phase18_count_structured_q1_conditions()` defaults from the
manual Actions task:

| Factor | Levels |
| --- | --- |
| Family | `poisson`, `nbinom2` |
| Structured type | `spatial`, `animal`, `relmat` |
| Group or site count | `n_level = 10`, `16` |
| Observations per group | `n_per_level = 8` |
| Structured SD | `sd_structured = 0.25`, `0.60` |
| Mean count | `mean_count = 3.0` |
| NB2 baseline `sigma` | `sigma_baseline = 0.45` |
| Spatial geometry | `geometry = "ring"` |
| Matrix decay | `matrix_decay = 0.4` |

This is 24 condition cells. Run 10 replicates per cell, for 240 fitted
replicates and 960 parameter rows if all fits complete.

## Dispatch Contract

Use one manual workflow dispatch from `main`:

```sh
gh workflow run phase18-simulation-grid.yaml \
  --repo itchyshin/drmTMB \
  --ref main \
  -f task=count_structured_q1 \
  -f n_reps=10 \
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

The 48-fit post-diagnostic smoke job took 3m33s for the selected job. A
240-fit diagnostic pilot should be treated as a roughly 20-30 minute selected
job until Actions evidence says otherwise. If runtime exceeds that range or
the job approaches platform limits, stop and redesign as condition shards
rather than raising replicate counts.

## Interval Policy

Leave `profile_parameters` empty for this pilot. The artifact should still
write direct profile-target rows, but it should not spend runtime profiling SD
targets. Wald intervals remain fixed-effect diagnostics only. Structured-SD
coverage is not interpretable without direct profile or bootstrap intervals,
so this pilot cannot make structured-SD coverage claims.

## Gate Audit

After downloading the artifact, run:

```r
devtools::load_all(quiet = TRUE)
source("inst/sim/R/sim_registry.R")
source("inst/sim/R/sim_utils.R")
source("inst/sim/R/sim_runner.R")
source("inst/sim/R/sim_uncertainty.R")
source("inst/sim/fit/sim_summarise_count_structured_q1.R")
source("inst/sim/run/sim_write_count_structured_q1_grid.R")

audit <- phase18_audit_count_structured_q1_boundary_gate(
  output_dir = "path/to/phase18-count_structured_q1-shard-1-of-1-<run-id>",
  require_complete = TRUE
)
audit$boundary_gate$overall
audit$boundary_gate$conditions
audit$boundary_gate$checks
audit$boundary_gate$decision
```

The next report must record fitted-replicate counts, not parameter-row counts.
It must also list condition cells with non-ok fit-diagnostic, SD-boundary, or
Hessian status.

## Decision Rules

The Slice 1737-1738 gate still applies:

- more than 5% Hessian-warning fitted replicates stops the lane at diagnostic
  evidence;
- any condition cell with at least two Hessian-warning fits stops the lane at
  diagnostic evidence;
- 15% or more SD-boundary warning fitted replicates stops the lane at
  diagnostic evidence;
- any condition cell with at least five attempted replicates and at least 40%
  SD-boundary warnings stops the lane at diagnostic evidence;
- any condition cell with fewer than five attempted replicates and at least two
  SD-boundary warnings stops the lane at diagnostic evidence; and
- optimizer, `NaNs produced`, or non-finite warning-ledger rows that are not
  explained by SD-boundary diagnostics stop the lane at diagnostic evidence.

If all checks pass, the next step is a separate formal-pilot design note with a
larger replicate count and MCSE target. It is not an immediate recovery or
coverage claim.

## Reporting Requirements

The after-task report for the run must include:

- GitHub Actions run ID, selected-job runtime, and matrix skip behavior;
- artifact row counts for aggregate, replicate, manifest, failure-ledger,
  Wald, profile-target, interval-evidence, interval-diagnostic, and
  interval-failure tables;
- boundary-gate helper overall, condition, checks, and decision output;
- whether any warning-ledger row is explained by SD-boundary diagnostics; and
- a clear statement that the run is diagnostic evidence only.

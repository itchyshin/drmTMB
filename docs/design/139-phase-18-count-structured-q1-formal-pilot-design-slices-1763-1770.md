# Phase 18 Count Structured q1 Formal-Pilot Design, Slices 1763-1770

This note specifies the first formal-pilot design for ordinary Poisson and NB2
count models with one q=1 structured `mu` intercept. The reader is an R package
contributor preparing a manual GitHub Actions run after the stable diagnostic
audit passed. This is a pilot design, not a recovery or coverage claim.

## Aim

The stable diagnostic run `26638116979` showed that the 10 high-`sd_structured`
cells from `phase18_count_structured_q1_followup_conditions("stable")` can fit
reliably at 20 replicates per cell. The next useful question is narrower:
whether direct profile intervals for the structured-SD target can be collected
reliably enough to support a larger recovery grid later.

The pilot should therefore estimate operating behavior for the direct
`log_sd_phylo` profile target only. It must keep the low-SD boundary-stress
cells, the two high-SD watchlist cells, bootstrap intervals, zero-inflated
structure, structured slopes, labelled count covariance, and structured NB2
`sigma` out of scope.

## Condition Set

Use exactly the stable set:

```r
phase18_count_structured_q1_followup_conditions("stable")
```

This gives 10 high-`sd_structured = 0.60` cells across Poisson/NB2, spatial,
animal, and `relmat()` routes at `n_level = 10` and `n_level = 16`. It excludes
all low-`sd_structured = 0.25` boundary-stress cells and the two high-SD NB2
spatial watchlist cells. The two stable cells that still showed low-rate
SD-boundary warnings in run `26638116979` must remain named in the audit:

| Stable cell | Pilot cell | Family | Structure | `n_level` | Stable diagnostic warning rate |
| --- | --- | --- | --- | ---: | ---: |
| `count_structured_q1_003` | `count_structured_q1_016` | NB2 | `animal()` | 10 | 2/20 |
| `count_structured_q1_005` | `count_structured_q1_018` | NB2 | `relmat()` | 10 | 1/20 |

## Interval Policy

Request one direct profile target:

```sh
-f profile_parameters='log_sd_phylo'
-f profile_level=0.70
```

The `log_sd_phylo` alias maps to the fitted structured-SD row, such as
`sd:mu:spatial(1 | site)`, through
`phase18_count_structured_q1_profile_parameter_map()`. The reported interval is
on the public SD scale (`interval_scale = "public_sd"`).

Use `profile_level = 0.70` for this first pilot because the goal is interval
plumbing and failure-rate evidence, not a final 95% recovery claim. If this
pilot passes the gates below, a later formal recovery grid can raise the level
or add a 95% companion run.

Leave bootstrap off:

```sh
-f bootstrap_nsim=0
-f bootstrap_backend=none
```

Direct bootstrap coverage for this surface is a separate design problem. Mixing
profile and bootstrap in the first formal pilot would make failures harder to
diagnose.

## Replicate Count And MCSE

Use 100 replicates per stable cell, for 1,000 fitted replicates if all fits
complete:

```sh
-f n_reps=100
```

At the target 70% profile interval level, the binomial Monte Carlo standard
error is about 0.046 for each 100-replicate condition cell and about 0.014 for
the pooled 1,000-replicate stable set. This is enough to decide whether the
direct profile interval machinery is operational on the stable set, but it is
not enough to claim family-by-structure coverage for individual cells.

## Dispatch Contract

Run one manual Actions job:

```sh
gh workflow run phase18-simulation-grid.yaml \
  --repo itchyshin/drmTMB \
  --ref main \
  -f task=count_structured_q1 \
  -f condition_set=stable \
  -f n_reps=100 \
  -f cores=2 \
  -f backend=multicore \
  -f bootstrap_nsim=0 \
  -f bootstrap_cores=2 \
  -f bootstrap_backend=none \
  -f profile_parameters='log_sd_phylo' \
  -f profile_level=0.70 \
  -f condition_shard=1 \
  -f condition_shards=1 \
  -f render_report=false \
  -f require_complete=true \
  -f retention_days=21
```

The stable diagnostic without requested profiles used 10 cells x 20 replicates
and finished the selected job in 3m48s. A local one-replicate smoke with
`profile_parameters = "log_sd_phylo"` on stable cell 001 finished in 0.69
seconds and returned an `ok` 70% profile interval, but that is local timing
evidence only. Treat the Actions runtime budget as 60 minutes for the selected
job. If the selected job exceeds 60 minutes or times out, stop and redesign
before increasing replicates.

## Stop Rules

First apply the existing boundary gate with fitted replicates as the counting
unit:

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

Add profile-specific stop rules:

- every fitted replicate must have a ready `log_sd_phylo` profile target row;
- more than 5% non-`ok` profile intervals overall stops the lane at interval
  diagnostic evidence;
- any condition cell with 10% or more non-`ok` profile intervals stops the lane
  at interval diagnostic evidence;
- either named NB2 watch cell above stops the lane if its SD-boundary warning
  rate reaches 10% or its non-`ok` profile interval rate reaches 10%; and
- profile coverage should be summarized only when at least 90 successful
  profile intervals are available for a condition cell.

If all gates pass, the report may say that the stable condition set is ready for
a larger formal recovery grid design. It must not claim broad recovery for
count structured q1 models, low-SD boundary-stress recovery, bootstrap
coverage, or interval support for unsupported model layers.

## Audit Requirements

The after-run audit must record:

- GitHub Actions run ID, selected-job runtime, and matrix skip behavior;
- artifact row counts for manifest, replicates, failures, Wald intervals,
  profile targets, profile intervals, profile coverage, interval evidence,
  interval diagnostics, and interval failures;
- boundary-gate overall, condition, checks, and decision output from
  `phase18_audit_count_structured_q1_boundary_gate()`;
- profile interval status counts overall and by condition cell;
- profile coverage rows, including MCSE columns, when available;
- the two named NB2 high-SD cells and whether either crossed its watch stop
  rule; and
- a clear statement that this pilot remains stable-set evidence only.

## Next Actions

After this design note lands, dispatch the manual Actions run above from
`main`, download the artifact, run the boundary helper, and write a separate
after-task report before changing any ROADMAP status from pilot design to
pilot audit.

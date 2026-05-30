# Phase 18 Count Structured q1 Formal-Pilot Audit, Slices 1774-1782

This note audits the first stable-set formal pilot for ordinary Poisson and
NB2 count models with one q=1 structured `mu` intercept. The reader is an R
package contributor deciding whether the stable condition set is ready for a
larger recovery-grid design. It is not ready yet.

## Run

The successful manual GitHub Actions run was `26669005577` on `main` at commit
`f7e090f26729057cf3f4597dc903e8ec384324a0`. The selected
`count_structured_q1` job was `78608250703` and finished in 8m35s. All
unselected matrix jobs skipped successfully.

The dispatch matched the Slice 1763-1770 contract:

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
  -f profile_parameters=log_sd_phylo \
  -f profile_level=0.70 \
  -f condition_shard=1 \
  -f condition_shards=1 \
  -f render_report=false \
  -f require_complete=true \
  -f retention_days=21
```

Run `26667502560` used the same dispatch after Slice 1771-1772, but failed
after the task body because the post-run print-plan call omitted
`require_complete`. Slice 1773 fixed that runner plumbing before this audit run.

## Artifact

The downloaded artifact was
`phase18-count_structured_q1-shard-1-of-1-26669005577`. The table row counts
were computed with `read.csv()` so embedded line breaks in messages did not
inflate counts.

| Table | Rows |
| --- | ---: |
| `count-structured-q1-manifest.csv` | 1000 |
| `count-structured-q1-replicates.csv` | 3800 |
| `count-structured-q1-failures.csv` | 8 |
| `count-structured-q1-wald-intervals.csv` | 3800 |
| `count-structured-q1-wald-coverage.csv` | 28 |
| `count-structured-q1-profile-targets.csv` | 1000 |
| `count-structured-q1-profile-intervals.csv` | 1000 |
| `count-structured-q1-profile-coverage.csv` | 10 |
| `count-structured-q1-interval-evidence.csv` | 4800 |
| `count-structured-q1-interval-diagnostics.csv` | 48 |
| `count-structured-q1-interval-failures.csv` | 1027 |
| `count-structured-q1-aggregate.csv` | 38 |

All 1000 manifest rows had `status = "ok"`.

## Boundary Gate

`phase18_audit_count_structured_q1_boundary_gate()` returned
`propose_next_pilot` for the fit-level boundary gate:

| Quantity | Value |
| --- | ---: |
| Fitted replicates | 1000 |
| Fit-diagnostic warning replicates | 10 |
| Fit-diagnostic warning rate | 0.010 |
| SD-boundary warning replicates | 10 |
| SD-boundary warning rate | 0.010 |
| Hessian-warning replicates | 0 |
| Hessian-warning rate | 0.000 |
| Warning-ledger replicates | 0 |

The warning ledger had eight warning rows, all with message
`collapsing to unique 'x' values`. The boundary helper did not classify these
as unexplained optimizer or non-finite warnings.

## Profile Intervals

The direct `log_sd_phylo` target produced 973 `ok` profile intervals and 27
failed intervals. The overall failure rate was 0.027, below the 0.05 overall
stop rule. The condition-level rule still stopped the lane because
`count_structured_q1_001` had 11 failed profile intervals out of 100.

| Cell | Family | Structure | `n_level` | Failed profile intervals | Failure rate |
| --- | --- | --- | ---: | ---: | ---: |
| `count_structured_q1_001` | Poisson | `spatial()` | 10 | 11 | 0.11 |
| `count_structured_q1_002` | Poisson | `animal()` | 10 | 0 | 0.00 |
| `count_structured_q1_003` | NB2 | `animal()` | 10 | 6 | 0.06 |
| `count_structured_q1_004` | Poisson | `relmat()` | 10 | 0 | 0.00 |
| `count_structured_q1_005` | NB2 | `relmat()` | 10 | 2 | 0.02 |
| `count_structured_q1_006` | Poisson | `spatial()` | 16 | 4 | 0.04 |
| `count_structured_q1_007` | Poisson | `animal()` | 16 | 1 | 0.01 |
| `count_structured_q1_008` | NB2 | `animal()` | 16 | 2 | 0.02 |
| `count_structured_q1_009` | Poisson | `relmat()` | 16 | 0 | 0.00 |
| `count_structured_q1_010` | NB2 | `relmat()` | 16 | 1 | 0.01 |

The interval failures split into 22 non-finite interval endpoints and five
profiles that did not provide two finite crossing values for interpolation.

## Watch Cells

The two named NB2 watch cells from the Slice 1763-1770 design did not cross
their 10% watch stop rules:

| Cell | Family | Structure | Failed profile intervals | SD-boundary warnings | Hessian warnings |
| --- | --- | --- | ---: | ---: | ---: |
| `count_structured_q1_003` | NB2 | `animal()` | 6/100 | 2/100 | 0/100 |
| `count_structured_q1_005` | NB2 | `relmat()` | 2/100 | 1/100 | 0/100 |

## Coverage

Coverage summaries are descriptive, not promotion evidence. The design note
allowed coverage interpretation only when at least 90 successful profile
intervals were available for a condition cell. Cell `count_structured_q1_001`
had 89 successful intervals and should not be interpreted. The other cells had
94 to 100 successful intervals, with 70% profile-interval coverage estimates
from 0.56 to 0.70 and MCSE near 0.046 to 0.050.

The low coverage estimates and the `count_structured_q1_001` interval-failure
trigger keep this lane at interval diagnostic evidence.

## Decision

The formal pilot stops at `hold_interval_diagnostic`. The stable set fits
reliably enough for boundary diagnostics, but direct profile intervals for
`log_sd_phylo` are not yet reliable enough to design a larger recovery grid.

Slice 1783-1784 codified this manual profile-interval decision in
`phase18_count_structured_q1_profile_gate_summary()`, so future artifact audits
can apply the same overall, condition-level, and watch-cell profile-failure stop
rules.

The next slice should diagnose profile interval geometry for the failed
spatial and NB2 cells. It should not dispatch a larger formal recovery grid,
add bootstrap intervals, or make broad recovery or coverage claims for count
structured q1 models.

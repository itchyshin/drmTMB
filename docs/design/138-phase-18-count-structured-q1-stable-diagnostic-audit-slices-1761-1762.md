# Phase 18 Count Structured q1 Stable Diagnostic Audit, Slices 1761-1762

This note audits the first `condition_set = "stable"` diagnostic run for
ordinary Poisson and NB2 count models with one q=1 structured `mu` intercept.
The reader is an R package contributor deciding whether the stable count
structured q1 lane can move from diagnostic filtering to a formal-pilot design.

## Aim

The stable-set run tests the 10 high-`sd_structured` cells that had no
SD-boundary warnings in the 24-cell pilot from run `26631771105`. The goal is
to check whether these cells remain stable at 20 replicates per cell. This is
still diagnostic evidence only: it does not estimate structured-SD coverage,
and it does not make a recovery claim.

## Dispatch

GitHub Actions run `26638116979` used `main` commit
`c4919dd3ece07e9fe2ff15b616a530e680658f73`:

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

The selected `count_structured_q1` job succeeded in 3m48s. The unselected
matrix jobs skipped successfully.

## Stable-Set Cells

The run used 10 stable cells and 20 replicates per cell, for 200 fitted
replicates. The saved `phase18-actions-result.rds` registry preserves the
mapping from stable-set cell IDs to original pilot cell IDs:

| Stable cell | Pilot cell | Family | Structure | `n_level` | `sd_structured` |
| --- | --- | --- | --- | ---: | ---: |
| `count_structured_q1_001` | `count_structured_q1_013` | Poisson | `spatial()` | 10 | 0.60 |
| `count_structured_q1_002` | `count_structured_q1_015` | Poisson | `animal()` | 10 | 0.60 |
| `count_structured_q1_003` | `count_structured_q1_016` | NB2 | `animal()` | 10 | 0.60 |
| `count_structured_q1_004` | `count_structured_q1_017` | Poisson | `relmat()` | 10 | 0.60 |
| `count_structured_q1_005` | `count_structured_q1_018` | NB2 | `relmat()` | 10 | 0.60 |
| `count_structured_q1_006` | `count_structured_q1_019` | Poisson | `spatial()` | 16 | 0.60 |
| `count_structured_q1_007` | `count_structured_q1_021` | Poisson | `animal()` | 16 | 0.60 |
| `count_structured_q1_008` | `count_structured_q1_022` | NB2 | `animal()` | 16 | 0.60 |
| `count_structured_q1_009` | `count_structured_q1_023` | Poisson | `relmat()` | 16 | 0.60 |
| `count_structured_q1_010` | `count_structured_q1_024` | NB2 | `relmat()` | 16 | 0.60 |

## Artifact Contents

The downloaded artifact was
`phase18-count_structured_q1-shard-1-of-1-26638116979`.

| Artifact table | Rows |
| --- | ---: |
| `count-structured-q1-aggregate.csv` | 38 |
| `count-structured-q1-failures.csv` | 0 |
| `count-structured-q1-interval-diagnostics.csv` | 48 |
| `count-structured-q1-interval-evidence.csv` | 960 |
| `count-structured-q1-interval-failures.csv` | 400 |
| `count-structured-q1-manifest.csv` | 200 |
| `count-structured-q1-profile-intervals.csv` | 200 |
| `count-structured-q1-profile-targets.csv` | 200 |
| `count-structured-q1-replicates.csv` | 760 |
| `count-structured-q1-wald-coverage.csv` | 28 |
| `count-structured-q1-wald-intervals.csv` | 760 |

The manifest had 200 `ok` rows. The replicate table had 760 parameter rows,
760 converged rows, 760 positive-Hessian rows, and no warning-ledger rows.
Profile targets were ready for all 200 fitted replicates, but profile
intervals were `not_requested` because the dispatch left `profile_parameters`
empty.

## Boundary-Gate Result

The executable gate collapsed the 760 parameter rows to 200 fitted replicates.
It returned:

| Quantity | Count | Rate |
| --- | ---: | ---: |
| Fitted replicates | 200 | 1.000 |
| Fit-diagnostic warning replicates | 3 | 0.015 |
| SD-boundary warning replicates | 3 | 0.015 |
| Hessian warning replicates | 0 | 0.000 |
| Warning-ledger replicates | 0 | 0.000 |

Two stable-set condition cells had SD-boundary warnings:
`count_structured_q1_003`, which maps to pilot cell
`count_structured_q1_016`, had 2 warnings among 20 fitted replicates; and
`count_structured_q1_005`, which maps to pilot cell
`count_structured_q1_018`, had 1 warning among 20 fitted replicates. Both
cells remained below the 40% condition-level trigger.

The helper decision was:

```text
surface = count_structured_q1
decision = propose_next_pilot
reason = boundary gate checks passed; a separate design note is still required
```

## Decision

The stable diagnostic passes the pre-declared boundary gate and supports
writing a separate formal-pilot design note for the stable count structured q1
condition set. It does not support a recovery or structured-SD coverage claim
yet, because the run used no direct profile or bootstrap intervals and had no
MCSE target. The two NB2 high-SD cells with SD-boundary warnings should remain
visible in the formal-pilot stop rules.

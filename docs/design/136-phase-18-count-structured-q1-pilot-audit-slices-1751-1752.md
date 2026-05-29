# Phase 18 Count Structured q1 Pilot Audit, Slices 1751-1752

This note audits the 24-cell x 10-replicate diagnostic pilot for ordinary
Poisson and NB2 count models with one q=1 structured `mu` intercept. The reader
is an R package contributor deciding whether the `spatial()`, `animal()`, and
`relmat()` count route is ready for a formal recovery design.

## Aim

The pilot tests whether the boundary-sensitive fits seen in the 2-replicate
smoke artifact are rare one-off cases or condition-level behavior. The
pre-run contract is in
`docs/design/135-phase-18-count-structured-q1-next-pilot-slices-1743-1750.md`.
This run remains diagnostic evidence only.

## Dispatch

GitHub Actions run `26631771105` used commit
`12e0c789e9f74afb0fd8d104561571332d42e3c6` on `main`:

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

The selected `count_structured_q1` job succeeded in 3m51s. The unselected
matrix jobs skipped successfully.

## Artifact Contents

The downloaded artifact was
`phase18-count_structured_q1-shard-1-of-1-26631771105`.

| Artifact table | Rows |
| --- | ---: |
| `count-structured-q1-aggregate.csv` | 96 |
| `count-structured-q1-failures.csv` | 1 |
| `count-structured-q1-interval-diagnostics.csv` | 120 |
| `count-structured-q1-interval-evidence.csv` | 1200 |
| `count-structured-q1-interval-failures.csv` | 480 |
| `count-structured-q1-manifest.csv` | 240 |
| `count-structured-q1-profile-coverage.csv` | empty placeholder |
| `count-structured-q1-profile-intervals.csv` | 240 |
| `count-structured-q1-profile-targets.csv` | 240 |
| `count-structured-q1-replicates.csv` | 960 |
| `count-structured-q1-wald-coverage.csv` | 72 |
| `count-structured-q1-wald-intervals.csv` | 960 |

The artifact also contained 24 condition directories and 240 replicate RDS
files. The manifest had 240 `ok` rows. The replicate table had 960 parameter
rows, 955 positive-Hessian rows, and 5 rows with a warning-ledger message. The
single warning-ledger replicate was `count_structured_q1_004` replicate 3,
with message `NaNs produced`.

Profile targets were ready for all 240 fitted replicates, but profile
intervals were `not_requested` because the workflow dispatch left
`profile_parameters` empty. Wald intervals remained fixed-effect diagnostics:
720 fixed-effect interval rows were usable and 240 structured-SD rows were
marked failed because they do not have Wald standard errors.

## Boundary-Gate Result

The executable gate collapsed the 960 parameter rows to 240 fitted replicates.
It returned:

| Quantity | Count | Rate |
| --- | ---: | ---: |
| Fitted replicates | 240 | 1.000 |
| Fit-diagnostic warning replicates | 40 | 0.167 |
| SD-boundary warning replicates | 40 | 0.167 |
| Hessian warning replicates | 1 | 0.004 |
| Warning-ledger replicates | 1 | 0.004 |

The Hessian rate and warning-ledger checks passed. The SD-boundary rate failed
the pre-declared 15% threshold, and the condition-level SD-boundary check
failed in six cells:

| Cell | Family | Structure | `n_level` | `sd_structured` | SD-boundary warnings |
| --- | --- | --- | ---: | ---: | ---: |
| `count_structured_q1_002` | NB2 | `spatial()` | 10 | 0.25 | 5 |
| `count_structured_q1_005` | Poisson | `relmat()` | 10 | 0.25 | 5 |
| `count_structured_q1_006` | NB2 | `relmat()` | 10 | 0.25 | 5 |
| `count_structured_q1_008` | NB2 | `spatial()` | 16 | 0.25 | 5 |
| `count_structured_q1_010` | NB2 | `animal()` | 16 | 0.25 | 4 |
| `count_structured_q1_012` | NB2 | `relmat()` | 16 | 0.25 | 4 |

The full warning-cell set also included lower-rate warnings in
`count_structured_q1_001`, `count_structured_q1_003`,
`count_structured_q1_004`, `count_structured_q1_007`,
`count_structured_q1_014`, and `count_structured_q1_020`. Only
`count_structured_q1_004` had a Hessian warning and warning-ledger row, and
the gate classified the warning-ledger message as explained by the
SD-boundary diagnostic.

The helper decision was:

```text
surface = count_structured_q1
decision = hold_diagnostic
reason = sd_boundary_rate, sd_boundary_condition_rate
```

## Decision

This pilot does not support a formal recovery grid or a structured-SD coverage
claim. The next design step should split the low-`sd_structured` boundary cells
from stable condition cells, or revise the condition table before another
recovery-oriented pilot is dispatched. A formal pilot still needs its own MCSE
target, interval policy, runtime budget, and stop rules.

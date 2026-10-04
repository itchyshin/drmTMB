# 0.7.1 ordinary-Laplace — S6 cost probe

Source pins: drmTMB `9939ace07967af9a9b6e23a4d021080d5d7d76a7`; DRM.jl
`b877f5136dbd13b6ff1cb3a1de02ee826b0fdf1c`. The machine-readable
four-fixture reconciliation is
[`reconciled-summary.tsv`](reconciled-summary.tsv). This is a local, one-core
pre-run measurement (`OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`), not the
coverage campaign.

## Measured receipt-time bounds

Each engine-target task writes its durable profile sidecar only when profiling
returns. The table uses the earliest and latest final-pin sidecar modification
times within an engine/fixture sequence, so it excludes the first task's setup
and is a conservative *lower bound* on the corresponding wall time. The paired
route itself was serial.

| frozen fixture | targets × engines | TMB bound | Julia bound | operational paired budget |
| --- | ---: | ---: | ---: | ---: |
| Binomial RI | 3 × 2 | 18 s | 155 s | 3 min |
| Poisson RI | 3 × 2 | 15 s | 95 s | 2 min |
| NB2 RI | 4 × 2 | 32 s | 147 s | 3 min |
| coupled NB2 location–scale RI | 7 × 2 | 1,453 s | 1,449 s | 25 min |

The coupled L22 pair was the cost driver: TMB and Julia both classified it as
`nonfinite_endpoint`; Julia ran from the L22 task start to its durable terminal
sidecar for about 17 minutes. It is retained in the denominator, not retried or
dropped. All 34 engine-target attempts returned a terminal profile
classification: 32 finite profiles and the two matched L22 non-finite
endpoints. There were no `fit_failed`, `profile_failed`, or `truth_outside`
outcomes in this frozen probe.

## DRAC sizing and approval gate

For 500 paired seeds per fixture, the observed serial budget is approximately
`500 × (3 + 2 + 3 + 25) = 16,500` core-minutes (275 core-hours), before queue
and scheduler overhead. The coupled NB2 array alone is about 208 core-hours.
At a live allocation of 250 one-core array tasks, the arithmetic floor is about
66 minutes; request a two-hour walltime initially, retain one fixture×seed per
array task, and let the scheduler's actual availability set concurrency. The
launch must use `/project` keepers, `--account`, `--time`,
`OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`, and verify process cleanup.

The estimate exceeds 30 minutes. Do **not** submit the 2,000-task, 500-seed
campaign until Shinichi explicitly approves this measured sizing and the live
DRAC queue/account/keeper preflight.

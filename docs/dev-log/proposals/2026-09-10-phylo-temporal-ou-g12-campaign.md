# G12 decision packet — phylogenetic-stable plus independent-OU profile campaign

## Decision requested

Authorize the retained 95% profile-calibration campaign defined by G11, subject to a live Rorqual capacity check immediately before submission.

## Frozen scientific target

The campaign evaluates only the additive Gaussian model with a phylogenetically correlated stable intercept plus independent within-species OU deviations. It profiles the fixed `mu` intercept, between-species effect, and within-species effect. It does not test a separable phylogeny-by-OU field, temporal scale effects, forecasts, `newdata`, Wald covariance, or any other temporal covariance structure.

P1--P3 each have 1,000 generated datasets; P4 has 500 stress datasets. All 3,500 data sets, all two-start fit records, and all three profile attempts are retained. Missing endpoints count as unavailable and uncovered in the all-attempt denominator. P4 is reported but cannot qualify a nominal-coverage claim.

## Measured cost

G10's 20 local fits measured these per-dataset means:

| Cell | Fit + profile seconds | Campaign tasks | Projected CPU hours |
| --- | ---: | ---: | ---: |
| P1 | 15.219 | 1,000 | 4.23 |
| P2 | 28.513 | 1,000 | 7.92 |
| P3 | 19.550 | 1,000 | 5.43 |
| P4 | 3.735 | 500 | 0.52 |
| Total | — | 3,500 | 18.10 |

The G10 maximum peak R allocation was 371.1 MB. Reserve 2 GiB and 30 minutes per task to cover fresh-node package load, numerical tails, artifact writing, and ordinary cluster variation. The projected campaign ceiling is 22.7 single-core hours after a 25% contingency; this is a ceiling for planning, not a claim of measured cluster time.

## Proposed compute and storage route

- **Target:** DRAC Rorqual, selected only if the live capacity and account check succeed. If it is unavailable, stop and return for a recorded target revision; do not silently fall back to Fir.
- **Array:** 3,500 one-core tasks, at most 60 concurrent tasks; `OPENBLAS_NUM_THREADS=1` and `OMP_NUM_THREADS=1`.
- **Resources:** one CPU, 2 GiB RAM, 30-minute wall limit per task.
- **Storage:** node-local temporary work, sealed task artifacts or 50-task immutable shards, then checksum-verified transfer to Totoro durable storage before any DRAC cleanup. `/scratch` is staging only and is not evidence storage.
- **Evidence:** retain source and worker fingerprints, every start, endpoint, warning/error, diagnostic, task status, and the complete denominator. G13 will only recompute summaries; it must never launch another fit.

## Approval boundary

Approval permits a one-task scheduled smoke after a successful live Rorqual check, followed by the 3,500-task array if the smoke stays within the stated resource limits. It does not authorize a target substitution, a higher concurrency cap, a larger denominator, source changes, public calibration claims, push/merge, or any different temporal model.

If the smoke exceeds 30 minutes, 2 GiB, or fails its retained-artifact check, stop and report the result instead of submitting the array.

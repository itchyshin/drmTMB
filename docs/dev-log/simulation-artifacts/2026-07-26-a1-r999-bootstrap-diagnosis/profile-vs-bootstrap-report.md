# Scalar A1 profile versus marginal-bootstrap report

## Question and frozen scope

This completed Totoro study compares intervals for the scalar Gaussian iid
random-intercept SD (`truth = 0.5`) only. Each of the three cells has 1,000
outer attempts (`g = 10, 25, 50`; 10 observations/group). Every attempt runs
a marginal percentile bootstrap with `R = 999`, a profile interval, and a Wald
comparator. The primary estimand is coverage on **all** outer attempts:
unavailable intervals count as noncoverage and are reported separately.

This is not an Arc D endpoint-contract change, a new bootstrap construction,
a public API change, a capability promotion, or association-lane work.

## Authentication

Totoro completed all 300 deterministic ten-attempt shards at
`2026-07-26T14:17:21Z`. The completed manifest, 3,000-row all-attempt table,
unique `(cell_id, seed)` keys, and row-level runner/helper/package-commit
labels passed the fail-closed analysis. No matching error log was found. The
recorded package-commit label was `37091153b4bdd55a48a6de758d893d75eb9888dc`;
the launcher, runner, and helper hashes are recorded in `campaign-manifest.txt` under
`~/drm_work/results_a1_profile_full_20260726`.

An earlier duplicate launcher was stopped before this completion. The final
analysis requires the surviving launcher's completed manifest and exact row
contract. However, it cannot prove that every overlapping shard was written
only by that launcher. The two concurrent 100-worker launchers briefly
violated the approved cap; Shinichi must ratify that exception or authorise a
clean rerun before strict protocol compliance can be claimed.

## All-attempt calibration

| Groups | Method | Coverage (95% exact CI) | Valid intervals | Lower / upper misses | Median width |
| ---: | --- | --- | ---: | --- | ---: |
| 10 | Marginal bootstrap | 0.829 (0.804, 0.852) | 1000/1000 | 0 / 171 | 0.535 |
| 10 | Profile | 0.937 (0.920, 0.951) | 1000/1000 | 10 / 53 | 0.555 |
| 10 | Wald | 0.988 (0.979, 0.994) | 997/1000 | 7 / 2 | 0.524 |
| 25 | Marginal bootstrap | 0.890 (0.869, 0.909) | 1000/1000 | 1 / 109 | 0.330 |
| 25 | Profile | 0.942 (0.926, 0.956) | 1000/1000 | 15 / 43 | 0.340 |
| 25 | Wald | 0.952 (0.937, 0.964) | 1000/1000 | 8 / 40 | 0.331 |
| 50 | Marginal bootstrap | 0.916 (0.897, 0.932) | 1000/1000 | 3 / 81 | 0.232 |
| 50 | Profile | 0.941 (0.925, 0.955) | 1000/1000 | 13 / 46 | 0.236 |
| 50 | Wald | 0.943 (0.927, 0.957) | 1000/1000 | 10 / 47 | 0.233 |

Profile coverage is closer to 0.95 than R=999 bootstrap coverage in all three
cells. The paired profile-minus-bootstrap coverage differences are +0.108
(95% paired CI 0.087, 0.129), +0.052 (0.035, 0.069), and +0.025 (0.012,
0.038), respectively. Thus increasing the bootstrap resamples to 999 did not
resolve the bootstrap undercoverage in this design.

The earlier matched R=199/R=999 diagnostic independently found changes of only
+0.001 at 10 groups and +0.003 at 50 groups, with paired confidence intervals
crossing zero and neither reaching the preregistered +0.020 materiality
threshold. Finite bootstrap-quantile resolution is therefore not the dominant
explanation for the original 0.871 shortfall.

## Interpretation and limits

Profile is a promising, markedly better scalar-A1 diagnostic than the marginal
percentile bootstrap: it is closer to nominal in all three cells and has no
unavailable intervals. Wald is a useful cheap interior comparator, but it
overcovers at 10 groups and has three unavailable intervals there.

The predeclared profile-first recommendation gate **fails**. Profile's
remaining misses are consistently upper-tail heavy: 53 upper versus 10 lower
at 10 groups, 43 versus 15 at 25, and 46 versus 13 at 50. Fisher's independent
review found these directional differences material (approximate 95% intervals
2.8–5.8, 1.3–4.3, and 1.8–4.8 percentage points). At 10 groups, 63/1,000
profiles reach the genuine parameter-space zero boundary and 47 of those cases
miss above. These are profile boundary endpoints, not clamp-created finite
endpoints; nevertheless they remain important low-group evidence. This study
does not decide the blocked Arc D question of when a clamped endpoint can be
reported as real inference.

The study is one well-specified Gaussian iid random-intercept design. It does
not establish calibration for other families, random-effect structures,
replication layouts, or structured covariance. In particular, the profile
comparison has 10 observations/group, whereas the R=199/R=999 resolution study
used its original 4-observation/group cells; it cannot explain or fix that
original design. Its remaining plausible explanations for bootstrap
undercoverage are boundary-sensitive percentile behavior and low-group Laplace
refit bias, not `R = 199` resolution in the two matched original cells.

## Reproducible outputs

The final Totoro directory holds raw all-attempt rows and:

- `profile_vs_bootstrap_summary.csv` — all-attempt coverage, exact CIs,
  availability, tails, widths, and profile boundaries;
- `profile_vs_bootstrap_paired.csv` — paired profile-minus-bootstrap contrasts;
- `profile_endpoint_summary.csv` — profile engine and boundary counts.

The analysis is idempotent: it selects only deterministic shard filenames and
therefore does not re-ingest its own summary CSVs.

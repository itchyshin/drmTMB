# Clean scalar-A1 `g = 10` provenance-rerun receipt

## Authority and purpose

On 2026-07-26, Shinichi ratified the earlier overlapping-launch result as
diagnostic-only and separately authorised this clean rerun of the affected
`g = 10` cell. Its purpose was provenance repair, not a new method search or a
second chance at a different result.

## Cap and provenance checks

The clean run used `~/drm_work/results_a1_profile_clean_g10_20260726` and
finished at `2026-07-26T14:49:56Z`. Its atomic lock was present while 100 R
workers ran and was released at completion. It produced exactly 100 shards and
1,000 unique seeds, with no matching error logs.

Its manifest records:

- `R_boot = 999`, 1,000 outer attempts, and 100 workers;
- package commit label `37091153b4bdd55a48a6de758d893d75eb9888dc`;
- reinstalled package tarball SHA-256
  `36ff4c79d9693fdf07b0fe9945424bf12c118345e59f1e22b0ca4bc07517acd9`;
- runner, helper, and launcher SHA-256 values.

The separate analysis verified every manifest field, all 1,000 rows, unique
keys, and row-level runner/helper/package labels before calculating coverage.

## Result and agreement check

| Method | Coverage (95% exact CI) | Valid intervals | Lower / upper misses |
| --- | --- | ---: | --- |
| Marginal bootstrap | 0.829 (0.804, 0.852) | 1000/1000 | 0 / 171 |
| Profile | 0.937 (0.920, 0.951) | 1000/1000 | 10 / 53 |
| Wald | 0.988 (0.979, 0.994) | 997/1000 | 7 / 2 |

All non-runtime inference and status fields are exactly identical across the
1,000 matched seeds in the clean and earlier retained `g = 10` outputs.
Expected differences are restricted to elapsed-time, host/timestamp, and helper
provenance metadata. The clean rerun therefore repairs the worker-cap and
package-tarball provenance for this affected cell without changing its evidence.

## Scope retained

This receipt does not change Fisher's conclusion: profile's upper-tail miss
asymmetry and 63 zero-boundary profile endpoints at `g = 10` still fail the
predeclared profile-first recommendation fence. It does not implement Arc D,
change public documentation or defaults, or widen the scalar Gaussian claim.

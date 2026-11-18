# Bernoulli stage-two current-source review

The post-v8 adapter source snapshot is retained at
`docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-current-source-audit-20261019/`.
Its 17-file manifest digest is
`d9c1d9e7a071ab666c304d6aa46ac494d2ba710e7ab841f824b0f8d44d394e23`; independent
readback matched all files and the current checkout HEAD. The source-review gate
passes for this snapshot only.

No-fit checks passed: Python adapter suite 29/29; stage-two R rules; prior-seed
stream negatives; copied-manifest registry/tamper guard; and the synthetic
combiner subprocess, which retained its receipt and emitted the required
nonqualifying marker for injected `integrity_failure`. No model fits or remote
jobs ran. The synthetic combiner test emitted its expected subprocess warning
while returning `STAGE_TWO_COMBINE_SUBPROCESS_PASS`.

This does not qualify the current adapter, estimate runtime, or establish
Bernoulli interval calibration. The v8 partial run remains incomplete and
contradicts the earlier 7,956-second projection. Obtain fresh source-relevant
runtime evidence before proposing another campaign; any projection above three
hours needs a specific pre-run result and approval.

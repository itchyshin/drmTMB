# Plan versus actual — A1 ML–REML attribution

| Axis | Planned | Actual | Assessment |
| --- | --- | --- | --- |
| Scope | oracle, harness, smoke, prepare-only packet | all delivered | aligned |
| Evidence | oracle must pass before campaign path | six-row oracle passes after a matched direct REML reference | aligned |
| Compute | no campaign | no campaign | aligned |
| Claims | no public/default claim | none made | aligned |
| Safety | <=100 worker future packet | packet requires <=100 and approval | aligned |
| Lane | scalar intervals only | no Arc D/association edits | aligned |

**Result:** local diagnostic infrastructure complete.  The lme4 REML profile
was shown unsuitable as a REML endpoint comparator and replaced by an exact
direct restricted-likelihood profile; no tolerance was reduced.  The next
substantive question—whether REML materially changes directional misses—still
requires separately approved Totoro compute.

## Campaign addendum

| Axis | Planned | Actual | Assessment |
| --- | --- | --- | --- |
| Compute | Totoro, 3 x 1,000 paired attempts, <=100 workers | 300 shards, 3,000 paired datasets, single lock and `xargs -P 100` | aligned; direct peak was not sampled before completion |
| Provenance | tarball plus runner/helper/oracle hashes | isolated tarball, full parent manifest, raw-shard checksum list, and paired-decision sidecar | strengthened adaptively |
| Result | apply frozen directional-miss rule | REML material at g=10/25, not g=50 | answered narrow attribution question |
| Claims | no public/default promotion | diagnostic-only report and reviews | aligned |

The initial remote launcher failed before output because Totoro's default R
library shadowed the isolated package.  Replacing `R_LIBS_USER` with `R_LIBS`
and running R with `--vanilla`, then repeating the three-cell smoke, was an
adaptive provenance repair.  It did not change estimators, seeds, cells,
thresholds, or the successful campaign data.

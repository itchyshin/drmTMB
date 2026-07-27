# Arc 6 F4 completion-review template

## Status

Template only.  It records how retained F4 evidence will be reviewed after all
24 fixed shards finish.  It does not summarize partial output, alter the
campaign, approve F5, or make a public inference claim.

## Campaign authentication

| Check | Required evidence | Verdict |
| --- | --- | --- |
| source | every shard records `a97aa0930cbfe635886f483cb32baf4e75f74227` | pending |
| private blobs | receipts match the frozen sandwich and fixture blobs | pending |
| schedule | 24 cells x 1,000 seeds; no duplication or omission | pending |
| retention | all-attempt tables and terminal statuses retained | pending |
| quarantine | no source, fixture, DGP, seed, or status-schema mismatch | pending |

Any failure in this table quarantines the campaign and ends the review without
a public exposure decision.

## Cell-wise calibration panel

For each cell, report all-attempt, valid-protocol, point-available,
alpha-Godambe-available, and interval-available denominators; the corresponding
availability proportions and binomial MCSEs; alpha bias; empirical alpha SD;
mean alpha Godambe SE; their ratio; 95% alpha-Wald coverage; and coverage MCSE.
Unavailable intervals remain retained in all-attempt records and count as
non-coverage in the primary valid-protocol coverage denominator.

Every cell must satisfy the frozen screen:

| Quantity | Requirement |
| --- | --- |
| absolute alpha bias | <= 0.10 |
| alpha-Godambe availability | >= 0.95 |
| interval availability | >= 0.95 |
| mean SE / empirical SD | [0.90, 1.10] |
| 95% alpha-Wald coverage | [0.925, 0.975] |

The nominal 0.95 coverage MCSE at 1,000 valid-protocol datasets is
approximately 0.0069, but the report must use each cell's actual denominator.

## Independent verdicts

Fisher reviews calibration, coverage, and MCSE; Noether verifies the alpha
estimand and denominators against the source/runner; Rose verifies provenance,
retention, scope, and reader-facing claim boundaries.  The consolidated verdict
is one of:

- **PASS — F5 may be considered:** all source and calibration checks pass;
- **FAIL — public uncertainty remains unavailable:** one or more frozen cells
  fail a calibration screen; or
- **QUARANTINED:** provenance or protocol evidence is malformed/mismatched.

PASS is not F5 approval.  It only supplies the evidence needed for Shinichi to
decide whether the separately designed alpha-only S3 surface should be
implemented.

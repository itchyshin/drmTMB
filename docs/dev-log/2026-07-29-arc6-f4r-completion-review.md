# Arc 6 F4R completion review: high-information alpha interval screen

## Decision

**PASS — private, high-information screen only.** Arc 6 F4R establishes that
the predeclared alpha-scale Godambe-Wald interval can be computed and is well
calibrated on its exact fixed-effect, complete-pair Bernoulli x ordinary-NB2
intercept grid. It does not enable a public `vcov()` or `confint()` method, and
it does not establish a general association-inference claim.

## Frozen contract and provenance

The completed replacement array was Rorqual job array `17603598`. Its durable
results root is
`/home/snakagaw/arc6-f4r-replacement-18c37bbc8/results`. The campaign retains
all 16,000 outer attempts: 16 completed shards, each with an
`all-attempts.tsv` and `RUN-COMPLETE.txt` receipt. The receipts agree on the
runner source commit `18c37bbc8e472e79272056ce90e12a18f2379ff4`, engine blob
`d090f67b74bf5dfee6baa4396a8f45a3c977d6fd`, and fixture blob
`d36b02b2ad470e641843d4f751ee1c998e6922bf`.

F4R is the prospective high-information remediation described in
`docs/dev-log/2026-07-27-arc6-f4r-high-information-design.md`: 16 cells, 1,000
attempts per cell, and `n = 480` or `960`. The original lower-information F4
campaign remains a retained failure; F4R is not a deletion, retry, or revision
of those records.

## Results

Of 16,000 protocol-valid retained attempts, 15,978 (99.86%) have an available
alpha point estimate, Godambe standard error, and alpha interval. The remaining
22 are retained `boundary_unresolved` records and count as unavailable
intervals; none is silently dropped. Across the 16 cells:

| Frozen check | Observed range | Gate | Verdict |
| --- | ---: | ---: | --- |
| Absolute alpha bias | 0.00003–0.00443 | at most 0.10 | PASS |
| Alpha point/Godambe/interval availability | at least 0.991 per cell | at least 0.95 | PASS |
| Mean Godambe SE / empirical SD | 0.9705–1.0378 | 0.90–1.10 | PASS |
| Provisional 95% alpha-interval coverage | 0.935–0.957 | 0.925–0.975 | PASS |
| Coverage MCSE | 0.0064–0.0078 | report | reported |

The completed receipt review found no provenance disagreement, quarantine, or
unretained attempted fit. A separate inference review and a method review both
returned PASS for the bounded F4R contract.

## Claim boundary

This result is **interval feasible** only for the named alpha target and the
frozen F4R high-information grid. In particular, it does not establish:

- a public association standard-error or confidence-interval API;
- a sample-size rule for arbitrary data, margins, dispersion, or association
  values;
- eta-scale inference (the available alpha records retain
  `eta_delta_unavailable` as ancillary metadata);
- calibration for slopes, random effects, missingness, weights, offsets,
  REML, other family pairs, or `rho12` generally.

F5 remains a separate product-and-validation decision. It must specify the
exact public eligibility boundary, test and document any alpha-only S3 surface,
and keep informative failures outside that boundary. No capability-ledger
status changes are made by this review.

## Evidence-retention improvement

The receipts are sufficient for this frozen decision, but the next campaign
packet should retain a compact post-processing summary plus its bootstrap seed
for uncertainty around SE/SD and coverage summaries, and an explicit source
manifest/library-build hash. Those are reproducibility improvements, not
reasons to reverse this F4R verdict.


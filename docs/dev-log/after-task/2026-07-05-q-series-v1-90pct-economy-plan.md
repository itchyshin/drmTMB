# After Task: Q-Series v1 90 Percent Economy Plan

## 1. Goal

Make the remaining path from 91/104 to the 90% practical-surface target more
actionable without inflating support status. The slice should answer which
current rows block 90%, what the least-compute next action is for each row, and
why parallel local, Totoro, or DRAC compute should wait.

## 2. Implemented

`tools/qseries_v1_release_check.py` now generates
`docs/dev-log/release-audits/q-series-v1-90pct-economy-plan.tsv` whenever
`--write-candidates` is used. `--check-candidates` verifies that checked-in
sidecar, and `--summary` reports `ninety_economy_rows`.

The generated preflight report now includes a "Next Rows To 90% Economy Plan"
section. The dashboard README points readers to the sidecar alongside the
existing 90% review packet.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Keep the sidecar generated, not hand-maintained.
- Scope it to the exact rows needed by the current `rows_to_90` counter.
- Record implementation cost, least-compute next action, compute blocker,
  blocking reviewers, coverage decision, promotion decision, and claim
  boundary.
- Leave all support-cell statuses unchanged.

Rejected alternatives:

- Do not move any row into the practical surface from this planning artifact.
- Do not run local, Totoro, or DRAC compute for the three rows. The current
  blockers are route/design blockers, not missing compute.
- Do not implement simultaneous non-Gaussian structured providers or animal
  q2-plus sigma in this slice.

## 3b. Mathematical Contract

This slice has no new likelihood, covariance, or parameter-transform contract.
It records that the current rows to 90% need one of these prior contracts before
runtime work:

```text
qseries_count_mu_simultaneous_structured_types_rejected:
  additive multi-provider count-mu design and extractor policy

qseries_nongaussian_structured_slope_neighbors_planned:
  row-specific family/provider DGP and extractor/recovery contract

qseries_animal_q2_plus_q2_sigma_rejected:
  scale-side q2-plus-q2 covariance route and failure taxonomy
```

The sidecar is therefore a planning constraint, not evidence of model support.

## 4. Files Touched

- `tools/qseries_v1_release_check.py`
- `docs/dev-log/release-audits/q-series-v1-90pct-economy-plan.tsv`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 -m py_compile tools/qseries_v1_release_check.py
  tools/validate-mission-control.py tools/qseries_v1_claim_guard.py`: passed.
- `python3 tools/qseries_v1_release_check.py --summary --check-report
  --check-candidates`: passed with practical v1.0 surface 91/104 (87.5%),
  `rows_to_90=3`, and `ninety_economy_rows=3`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file -e
  "Sys.setenv(NOT_CRAN='true', OMP_NUM_THREADS='1',
  OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1');
  devtools::test(filter = 'structured-re-conversion-contracts', reporter =
  'summary')"`: passed.

## 6. Tests of the Tests

The conversion-contract test now reads
`q-series-v1-90pct-economy-plan.tsv` and checks the schema, row count, row
identity, implementation-cost labels, least-compute wording, compute-blocker
wording, Rose/Fisher/Grace blockers, coverage-not-authorized decisions,
do-not-promote decisions, and planning-only claim boundary.

## 7a. Issue Ledger

No GitHub issue was opened, commented on, or closed in this slice. This is a
generated release-preflight aid for the local branch.

## 8. Consistency Audit

Rose audit: the sidecar is explicitly planning-only and does not move support
cells. It preserves the claim boundary against `inference_ready`, `supported`,
coverage, q4/q8, REML, AI-REML, bridge, and public support.

Fisher audit: coverage remains unauthorized for every row in the sidecar.

Gauss audit: no TMB likelihood, covariance route, optimizer setting, or
parameter transform changed.

Noether audit: the sidecar distinguishes the three route classes instead of
pretending one generic compute strategy applies to all rows.

Grace audit: the sidecar is generated and checked by the release preflight, and
the focused conversion-contract test validates the checked-in file.

## 9. What Did Not Go Smoothly

The first plan was to inspect whether the next candidate row could be a cheap
implementation. The simultaneous count-`mu` row is not cheap: the current count
engine has one structured field slot, and the contract requires an additive
multi-provider design and extractor policy before parser or TMB edits.

## 10. Known Residuals

- Practical surface remains 91/104, not 90%.
- The next three rows still need row-specific design or route work before
  movement.
- No new local debug fit, denominator row, coverage run, or host job was
  authorized by this slice.

## 11. Team Learning

Kim's economy rule is now visible in the generated artifacts: when the blocker
is design, extra compute is waste. Ada kept the work in the release tooling,
Rose and Fisher kept promotion/coverage closed, and Grace made the sidecar part
of the checked generator path.

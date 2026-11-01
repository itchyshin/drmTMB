# Parser and time layout

OWNS: R/temporal.R, R/parse-formula.R, tests/testthat/test-temporal-g1.R, tests/testthat/test-temporal-g2.R, tests/testthat/helper-temporal-reference.R

- [ ] G1: Parsed fields and every admitted/rejected formula cell match the temporal contract
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G1
  EXPECT: TEMPORAL_G1_PASS
  EVIDENCE: pending

- [ ] G2: Ordering, integer gaps, malformed/duplicate time, missingness and lag-design rules are exercised
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G2
  EXPECT: TEMPORAL_G2_PASS
  EVIDENCE: pending

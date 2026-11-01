# Native likelihood and independent identities

OWNS: R/temporal.R, R/drmTMB.R, src/drmTMB.cpp, src/temporal-ar1.hpp, tests/testthat/test-temporal-g3.R, tests/testthat/test-temporal-g4.R, tests/testthat/test-temporal-g5.R, tests/testthat/test-temporal-g6.R, tests/testthat/test-temporal-g7.R, tests/testthat/helper-temporal-reference.R

- [ ] G3: Dynamic phi, normalized prior, all-model defaults, exclusive field and both-start selection are correct
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G3
  EXPECT: TEMPORAL_G3_PASS
  EVIDENCE: pending

- [ ] G4: Independent dense marginal likelihood and two-step finite-difference gradients meet frozen tolerances
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G4
  EXPECT: TEMPORAL_G4_PASS
  EVIDENCE: pending

- [ ] G5: Zero-persistence total variance, singleton prior and nonidentifiable split have the specified behaviour
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G5
  EXPECT: TEMPORAL_G5_PASS
  EVIDENCE: pending

- [ ] G6: Positive AR1 agrees with regular/gapped OU reference and OU fitting remains unavailable
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G6
  EXPECT: TEMPORAL_G6_PASS
  EVIDENCE: pending

- [ ] G7: Independent blocks, row permutations, elapsed gaps and splitting a connected series pass behavioural checks
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G7
  EXPECT: TEMPORAL_G7_PASS
  EVIDENCE: pending

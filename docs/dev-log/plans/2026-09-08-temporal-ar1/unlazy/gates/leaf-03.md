# Public methods and neighbour regressions

OWNS: R/temporal.R, R/drmTMB.R, R/methods.R, R/check.R, R/profile.R, tests/testthat/test-temporal-g8.R, tests/testthat/test-temporal-g9.R, tests/testthat/test-temporal-g10.R

- [ ] G8: Process SD, residual sigma, phi, states/nodes and conditional modes agree with their independent references
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G8
  EXPECT: TEMPORAL_G8_PASS
  EVIDENCE: pending

- [ ] G9: In-sample points and both simulation modes work; every deferred entry point refuses explicitly
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G9
  EXPECT: TEMPORAL_G9_PASS
  EVIDENCE: pending

- [ ] G10: All four deliberate oracle mutations fail and ordinary/phylo/spatial/relmat neighbours retain verified behaviour
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G10
  EXPECT: TEMPORAL_G10_PASS
  EVIDENCE: pending

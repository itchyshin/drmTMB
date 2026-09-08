# Bounded recovery, after native identity and methods

OWNS: inst/validation/temporal-ar1-recovery.R, tests/testthat/test-temporal-g11.R, tests/testthat/test-temporal-g12.R, .unlazy/temporal-ar1/recovery/**

- [ ] G11: Timed full-fixture pre-run has complete valid outputs and proves a bounded runtime estimate
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R --ready G11 && Rscript --vanilla inst/validation/temporal-ar1-recovery.R --mode pre-run --output .unlazy/temporal-ar1/recovery/pre-run && Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G11
  EXPECT: TEMPORAL_G11_PASS
  EVIDENCE: pending

- [ ] G12: Six frozen datasets retain all twelve attempts, correct winners, diagnostics and recovery-to-truth thresholds
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R --ready G12 && Rscript --vanilla inst/validation/temporal-ar1-recovery.R --mode bounded --output .unlazy/temporal-ar1/recovery/bounded && Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G12
  EXPECT: TEMPORAL_G12_PASS
  EVIDENCE: pending

Run G11 before G12 and inspect its estimate. The bounded runner must refuse a
projected total beyond the plan's 15-minute runtime estimate; stop and re-estimate.
Before any bounded draw it must also require a current, passing G11 receipt and
its matching pre-run output/source/DGP hashes. A missing or failed G11 must prevent
the G12 model run, even if a caller mistakenly approves both CHECK lines together.
Any >30-minute campaign needs separate user approval after pre-run results. Do not
relax this CHECK or its tests automatically when it fails. No seed selection or
lost optimisation attempts; a failure row stays in the twelve-row attempt table.

# P3 heterogeneous AR1 — Unlazy gates

Every runnable gate has a reviewed command, a success-only receipt and initially pending evidence. Runnable checks must not start a campaign. `--reverify` reads frozen outputs and must not create new fits.

- [ ] T4-0: User approves this child plan and source fingerprint before code changes.
  EVIDENCE: pending

- [ ] T4-1: Canonical `hetar1` grammar, common schedule admission, 12-level boundary, labels and early errors pass.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-1
  EXPECT: TEMPORAL_HETAR1_T4_1_PASS
  EVIDENCE: pending

- [ ] T4-2: Native D-R-D provider uses both persistence starts and preserves independent IDs, residual sigma and all Gaussian normalizers.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-2
  EXPECT: TEMPORAL_HETAR1_T4_2_PASS
  EVIDENCE: pending

- [ ] T4-3: Dense covariance, native likelihood, gradient and two finite-difference Hessian step sizes agree.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-3
  EXPECT: TEMPORAL_HETAR1_T4_3_PASS
  EVIDENCE: pending

- [ ] T4-4: Extraction, fixed-mean covariance/Wald diagnostics, residuals and seeded simulation expose labelled process SDs and constant residual sigma.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-4
  EXPECT: TEMPORAL_HETAR1_T4_4_PASS
  EVIDENCE: pending

- [ ] T4-5: Homogeneous-AR1 and diagonal reductions plus all predeclared D-R-D mutations pass.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-5
  EXPECT: TEMPORAL_HETAR1_T4_5_PASS
  EVIDENCE: pending

- [ ] T4-6: Frozen interval-feasibility fixtures retain both starts, all failures and full denominators; public fixed-mean Wald intervals are assessed without a coverage claim.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-6
  EXPECT: TEMPORAL_HETAR1_T4_6_PASS
  EVIDENCE: pending

- [ ] T4-7: Five-seed timing pilot records time, memory, interval availability and output completeness before any longer run.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-7
  EXPECT: TEMPORAL_HETAR1_T4_7_PASS
  EVIDENCE: pending

- [ ] T4-11: Immutable interval-feasibility outputs reverify without launching fits.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-11 --reverify
  EXPECT: TEMPORAL_HETAR1_T4_11_PASS
  EVIDENCE: pending

- [ ] T4-12: Formula grammar, likelihood documentation and reader workflow render; the article makes no coverage or scale-side claim.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-12
  EXPECT: TEMPORAL_HETAR1_T4_12_PASS
  EVIDENCE: pending

- [ ] T4-14: Package check, independent Noether and Pat reviews, after-task report and final reverify close P3.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-14 --reverify
  EXPECT: TEMPORAL_HETAR1_T4_14_PASS
  EVIDENCE: pending

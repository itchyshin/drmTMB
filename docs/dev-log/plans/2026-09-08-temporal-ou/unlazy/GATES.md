# Gaussian temporal OU — Unlazy acceptance ledger

Scope: Gaussian ML models with `sigma ~ 1`, one `temporal(1 | id, time = elapsed, structure = "ou")` term, and an optional same-ID `(1 | id)` random intercept. This ledger is new work; the AR1 ledger and its retained evidence remain historical evidence.

- [x] G0: User approved this exact OU-after-AR1-calibration scope in a fresh isolated worktree
  EVIDENCE: user approval 2026-09-08; branch `codex/temporal-ou-v1-20260908`; base `57c368109d583bd15e6d75694b2835909ad68d0e`; lease `codex-temporal-ou-v1-20260908`

- [x] G1: The inherited AR1 source and C1 interval blocker are reconciled before public OU interval claims
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G1
  EXPECT: TEMPORAL_OU_G1_PASS
  EVIDENCE: Retained C1 diagnosis and OU Wald guard inspected 2026-09-08. Exact C1 replay found active-boundary behavior: production-control starts at residual SD 0.4, 0.1, 0.01, 1e-4, and 1e-6 produced objectives 618.883549324, 618.883549221, 618.883548969, 618.883548215, and 618.880626547 respectively; the two lowest-scale attempts did not converge. See `c1-variance-start-profile-2026-09-08.md`. This rules out treating the higher pdHess candidate as the ML inference repair; G7 remains closed.

- [x] G2: OU grammar admits numeric elapsed time and rejects duplicate, missing, unordered, or nonpositive-gap keys
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G2
  EXPECT: TEMPORAL_OU_G2_PASS
  EVIDENCE: `devtools::test(filter = "temporal-ou", reporter = "location")` passed grammar, irregular-gap, label, and start assertions 2026-09-08.

- [x] G3: Fixed-parameter OU likelihood, score, and Hessian agree with an independent dense marginal Gaussian oracle
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G3
  EXPECT: TEMPORAL_OU_G3_PASS
  EVIDENCE: focused location-reporter suite passed independent dense likelihood, score, two finite-difference Hessians, and coefficient covariance checks 2026-09-08.

- [x] G4: Native OU likelihood retains stationary initial densities, gap-specific normalization, and independent series
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G4
  EXPECT: TEMPORAL_OU_G4_PASS
  EVIDENCE: native stationary first-state, elapsed-gap transition, and series-start source checks plus dense oracle passed in focused suite 2026-09-08.

- [x] G5: Mutation checks detect compressed gaps, unsorted time, omitted normalization, shared series states, and illegal negative persistence
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G5
  EXPECT: TEMPORAL_OU_G5_PASS
  EVIDENCE: focused temporal suite passed OU compressed-gap, shared-series, and omitted-normalizer mutation checks 2026-09-08.

- [x] G6: Extraction, fitted values, residuals, conditional modes, and fresh/conditional simulation agree with dense references
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G6
  EXPECT: TEMPORAL_OU_G6_PASS
  EVIDENCE: focused location-reporter suite passed fitted values, residuals, conditional modes, and fresh/conditional simulation assertions 2026-09-08.

- [ ] G7: Mean-coefficient covariance and Wald intervals are available only after the AR1 prerequisite and match independent references
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G7
  EXPECT: TEMPORAL_OU_G7_PASS
  EVIDENCE: pending

- [ ] G8: Retained OU recovery preserves every start, failure, source fingerprint, and predeclared threshold
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G8
  EXPECT: TEMPORAL_OU_G8_PASS
  EVIDENCE: pending

- [ ] G9: A bounded timed pilot records runtime, memory, interval availability, and output completeness
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G9
  EXPECT: TEMPORAL_OU_G9_PASS
  EVIDENCE: pending

- [x] G10: The reader vignette explains irregular time, positive-only persistence, aggregation of duplicate keys, and simulation conditioning
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G10
  EXPECT: TEMPORAL_OU_G10_PASS
  EVIDENCE: `Rscript --vanilla tools/temporal-ou-gates.R G10` emitted `TEMPORAL_OU_G10_PASS` 2026-09-08.

- [ ] G11: Documentation and package integration are synchronized and a source-built temporal vignette renders
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G11
  EXPECT: TEMPORAL_OU_G11_PASS
  EVIDENCE: pending

- [ ] G12: R CMD build and R CMD check pass at the final exact source
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G12
  EXPECT: TEMPORAL_OU_G12_PASS
  EVIDENCE: pending

- [ ] G13: Independent mathematical and reader-workflow reviews find no unresolved blocking defect
  EVIDENCE: pending

- [ ] G14: The measured campaign design, target, cost, and denominator are explicitly authorized
  EVIDENCE: pending

- [ ] G15: Retained campaign outputs are recomputed without launching another campaign
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G15 --reverify
  EXPECT: TEMPORAL_OU_G15_PASS
  EVIDENCE: pending

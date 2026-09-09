# Gaussian temporal OU — Unlazy acceptance ledger

Scope: Gaussian ML models with `sigma ~ 1`, one `temporal(1 | id, time = elapsed, structure = "ou")` term, and an optional same-ID `(1 | id)` random intercept. This ledger is new work; the AR1 ledger and its retained evidence remain historical evidence.

- [x] G0: User approved this exact OU-after-AR1-calibration scope in a fresh isolated worktree
  EVIDENCE: user approval 2026-09-08; branch `codex/temporal-ou-v1-20260908`; base `57c368109d583bd15e6d75694b2835909ad68d0e`; lease `codex-temporal-ou-v1-20260908`

- [x] G1: The inherited AR1 source and C1 interval blocker are reconciled before public OU interval claims
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G1
  EXPECT: TEMPORAL_OU_G1_PASS
  EVIDENCE: Retained C1 diagnosis and OU Wald guard inspected 2026-09-08. Exact C1 replay found active-boundary behavior: production-control starts at residual SD 0.4, 0.1, 0.01, 1e-4, and 1e-6 produced objectives 618.883549324, 618.883549221, 618.883548969, 618.883548215, and 618.880626547 respectively; the two lowest-scale attempts did not converge. The independent dense marginal profile subsequently converged at every declared fixed SD and confirmed that the objective declines to its smallest declared SD (`618.883549144532` at `1e-7`; `618.913025096580` at `0.1`), while free-SD fits stop at `0.000131`--`0.000155` only about `5e-8` above that grid minimum. See `c1-dense-marginal-profile-2026-09-09.md`. This rules out treating a higher pdHess candidate as the ML inference repair; G7 remains closed.

- [x] G2: OU grammar admits finite numeric elapsed time, preserves shuffled input order, and rejects duplicate or missing metadata
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G2
  EXPECT: TEMPORAL_OU_G2_PASS
  EVIDENCE: `Rscript --vanilla tools/temporal-ou-gates.R G2` emitted `TEMPORAL_OU_G2_PASS` after shuffled-row, duplicate, missing, non-numeric, decay-extraction, and small-decay regressions 2026-09-08.

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
  EVIDENCE: The retained original C1 pilot had 4/5 available intervals. A disjoint five-seed current-source C1 replication (`2026091101`--`2026091105`) had 4/5 available intervals; seed `2026091101` had residual SD `0.000338`, a non-positive-definite full Hessian, and unavailable covariance. The combined 8/10 bounded result is diagnostic only, but it rules out treating the original failure as an isolated optimizer accident and is incompatible with the predeclared C1 availability criterion of at least 0.99. See `c1-wald-availability-replication-2026-09-09.md`. The current free-sigma full-Hessian Wald route remains unqualified.

- [x] G8: Retained OU recovery preserves every start, failure, source fingerprint, and predeclared threshold
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G8
  EXPECT: TEMPORAL_OU_G8_PASS
  EVIDENCE: `Rscript --vanilla tools/run-temporal-ou-recovery.R` emitted `TEMPORAL_OU_RECOVERY_PASS` and G8 emitted `TEMPORAL_OU_G8_PASS` at source `5eada6c03a41ecaed0f96b98224c9511f9ae6a4e`. The retained 12-fixture, 24-start point-recovery run met all predeclared criteria: mean absolute fixed-effect error `0.0758`, median absolute SD error `0.0374`, and median absolute decay error `0.0400`. Ordinary-plus-OU O05 selected a false-convergence start because it had the lower finite objective; its warning and both starts remain in `raw-attempts.csv` and it is not treated as interval evidence.

- [x] G9: A bounded timed pilot records runtime, memory, interval availability, and output completeness
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G9
  EXPECT: TEMPORAL_OU_G9_PASS
  EVIDENCE: At source `565cd663c`, five seeds each for three predeclared irregular-time cells produced 15 finite selected fits and 30 retained starts. The resource replay took `30.33` seconds wall time with `569,245,696` bytes maximum resident size; summed fit time was `27.441` seconds. All 15 fits had positive-definite Hessians. Public Wald availability was `0/15`, with all 15 explicitly guarded as unqualified rather than numerically unavailable. `Rscript --vanilla tools/temporal-ou-gates.R G9` emitted `TEMPORAL_OU_G9_PASS`.

- [x] G10: The reader vignette explains irregular time, positive-only persistence, aggregation of duplicate keys, and simulation conditioning
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G10
  EXPECT: TEMPORAL_OU_G10_PASS
  EVIDENCE: `Rscript --vanilla tools/temporal-ou-gates.R G10` emitted `TEMPORAL_OU_G10_PASS` after the runnable irregular-time OU workflow and decay-unit interpretation were added 2026-09-08.

- [x] G11: Documentation and package integration are synchronized and a source-built temporal vignette renders
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G11
  EXPECT: TEMPORAL_OU_G11_PASS
  EVIDENCE: `Rscript --vanilla tools/temporal-ou-gates.R G11` emitted `TEMPORAL_OU_G11_PASS` 2026-09-08.

- [x] G12: R CMD build and R CMD check pass at the final exact source
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G12
  EXPECT: TEMPORAL_OU_G12_PASS
  EVIDENCE: `R --vanilla CMD build .` built `drmTMB_0.7.1.tar.gz`; `R CMD check --no-manual drmTMB_0.7.1.tar.gz` returned `Status: OK` 2026-09-08.

- [x] G13: Independent mathematical and reader-workflow reviews find no unresolved blocking defect
  EVIDENCE: Independent mathematical review approved the AD-safe small-decay transition, decay target registry, and explicit unavailable-inference summary diagnostic; independent reader review approved `decaypars`, structure-aware errors, the corrected G2 contract, and the runnable irregular-time vignette, 2026-09-08.

- [ ] G14: The measured campaign design, target, cost, and denominator are explicitly authorized
  EVIDENCE: pending

- [ ] G15: Retained campaign outputs are recomputed without launching another campaign
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G15 --reverify
  EXPECT: TEMPORAL_OU_G15_PASS
  EVIDENCE: pending

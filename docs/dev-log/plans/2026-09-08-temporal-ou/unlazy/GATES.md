# Gaussian temporal OU — Unlazy acceptance ledger

Scope: Gaussian ML models with `sigma ~ 1`, one `temporal(1 | id, time = elapsed, structure = "ou")` term, and an optional same-ID `(1 | id)` random intercept. This ledger is new work; the AR1 ledger and its retained evidence remain historical evidence.

- [x] G0: User approved this exact OU-after-AR1-calibration scope in a fresh isolated worktree
  EVIDENCE: user approval 2026-09-08; branch `codex/temporal-ou-v1-20260908`; base `57c368109d583bd15e6d75694b2835909ad68d0e`; lease `codex-temporal-ou-v1-20260908`

- [x] G1: The inherited AR1 source and C1 interval blocker are reconciled before public OU interval claims
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G1
  EXPECT: TEMPORAL_OU_G1_PASS
  EVIDENCE: The historical C1 seed `2026091002` non-PD result came from the pre-repair AR1 transition calculation: current source selects a positive-definite fit at residual SD `0.000224` whose objective agrees with the independent dense marginal oracle to about `6e-8`. A current-source recheck of all five historical C1 seeds has 5/5 finite covariance and interval sets. This resolves that historical numerical artifact, but does not qualify the method: disjoint current-source seed `2026091101` has residual SD `0.000338`, non-PD covariance, persistence `0.189`, and a separate dense marginal profile that is flat through `sigma = 1e-4` and rises at `0.1`. The two current-source five-seed batches have 9/10 available intervals, which is a bounded diagnostic rather than a coverage estimate. See `c1-current-source-reconciliation-2026-09-09.md`; G7 remains unfulfilled.

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

- [x] G7: Temporal mean-coefficient profile intervals agree with independent dense profiles, reject deferred targets, and warn about an irregular fitted Hessian
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G7
  EXPECT: TEMPORAL_OU_G7_PASS
  EVIDENCE: Reverified 2026-09-09. The public route profiles only `mu` fixed-effect targets, supports coefficient aliases such as `mu:x`, rejects decay, every non-mean target (including the stable intercept SD in a combined fit), bootstrap, `newdata`, and scalar-endpoint requests, and warns when the base fitted Hessian is not positive definite. `profile_targets(fit, ready_only = TRUE)` reports the same boundary. `test-temporal-ou-dense-oracle.R` independently re-optimizes the dense marginal covariance likelihood at three fixed-effect profile locations. This establishes deterministic agreement and an honest per-fit diagnostic; it is not a coverage calibration claim. The free-sigma full-Hessian Wald route remains unqualified.

- [x] G8: Retained OU recovery preserves every start, failure, source fingerprint, and predeclared threshold
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G8
  EXPECT: TEMPORAL_OU_G8_PASS
  EVIDENCE: `Rscript --vanilla tools/run-temporal-ou-recovery.R` emitted `TEMPORAL_OU_RECOVERY_PASS` and G8 emitted `TEMPORAL_OU_G8_PASS` at source `5eada6c03a41ecaed0f96b98224c9511f9ae6a4e`. The retained 12-fixture, 24-start point-recovery run met all predeclared criteria: mean absolute fixed-effect error `0.0758`, median absolute SD error `0.0374`, and median absolute decay error `0.0400`. Ordinary-plus-OU O05 selected a false-convergence start because it had the lower finite objective; its warning and both starts remain in `raw-attempts.csv` and it is not treated as interval evidence.

- [x] G9: A bounded timed pilot records runtime, memory, interval availability, and output completeness
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G9
  EXPECT: TEMPORAL_OU_G9_PASS
  EVIDENCE: At source `565cd663c`, five seeds each for three predeclared irregular-time cells produced 15 finite selected fits and 30 retained starts. The resource replay took `30.33` seconds wall time with `569,245,696` bytes maximum resident size; summed fit time was `27.441` seconds. All 15 fits had positive-definite Hessians. Public Wald availability was `0/15`, with all 15 explicitly guarded as unqualified rather than numerically unavailable. This is point-estimation evidence only; G16 measures the new profile route. `Rscript --vanilla tools/temporal-ou-gates.R G9` emitted `TEMPORAL_OU_G9_PASS`.

- [x] G10: The reader vignette explains irregular time, positive-only persistence, aggregation of duplicate keys, and simulation conditioning
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G10
  EXPECT: TEMPORAL_OU_G10_PASS
  EVIDENCE: `Rscript --vanilla tools/temporal-ou-gates.R G10` emitted `TEMPORAL_OU_G10_PASS` after the runnable irregular-time OU workflow and decay-unit interpretation were added 2026-09-08.

- [x] G11: Documentation and package integration are synchronized and a source-built temporal vignette renders
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G11
  EXPECT: TEMPORAL_OU_G11_PASS
  EVIDENCE: Reverified after the profile-target clarification on 2026-09-09: the source-built temporal vignette rendered and includes the irregular-time OU profile workflow and `check_drm()` condition.

- [x] G12: R CMD build and R CMD check pass at the final exact source
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G12
  EXPECT: TEMPORAL_OU_G12_PASS
  EVIDENCE: Reverified at clean source `4d1fcc10055ea3f619afc36169e4d91dd28fac32` on 2026-09-09: `R CMD check --no-manual drmTMB_0.7.1.tar.gz` returned `Status: OK` on macOS after build.

- [x] G13: Independent mathematical and reader-workflow reviews find no unresolved blocking defect
  EVIDENCE: The independent mathematical review found two public-profile boundary defects: generic `profile()` bypassed the mean-only target restriction, and it did not report an irregular fitted Hessian. Both are now covered by the public target validator, `profile_targets()` metadata, the Hessian warning, and focused tests. The independent reader review requested neutral irregular-likelihood wording and a nearby reporting condition; both are in the vignette and diagnostic. Reviewers found no unresolved blocker after these repairs, 2026-09-09.

- [x] G16: A bounded fixed-effect profile pilot records runtime, output completeness, regular and irregular-Hessian diagnostics, and interval availability
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G16
  EXPECT: TEMPORAL_OU_G16_PASS
  EVIDENCE: At source `01e16f23d33e3b7c1bc0c9ebea3ff54dcb8c6433`, five deterministic seeds in each of U1, U2, and U3 produced 15 finite selected fits and 30 retained starts. All 15 fixed-effect profile requests produced three finite intervals and all fitted Hessians were positive definite. The local resource replay took `759.24` seconds wall time with `663,764,992` bytes maximum resident size. Median profile times were 34.764 seconds (U1), 47.133 seconds (U2), and 64.638 seconds (U3). `Rscript --vanilla tools/temporal-ou-gates.R G16` emitted `TEMPORAL_OU_G16_PASS`. This is timing and output-completeness evidence, not coverage calibration or campaign authority.

- [x] G14: The measured fixed-effect profile campaign design, target, cost, and all-attempt denominator are explicitly authorized
  EVIDENCE: Shinichi approved the revised storage-consolidating route on 2026-09-09: U1--U3, 1,000 deterministic replicates per cell, 3,000 all-attempt denominators, 60 Fir array shards of 50 with concurrency 10, sealed archives, and Totoro as the durable keeper after checksum verification. Fir project storage is inode-full and nearline is absent on compute nodes, so Fir home is temporary staging only. Smoke job `58907593`, source `e46bf2e702c08383e1883de34b07163a5d9ba896`, completed one data set in 2:30 with 4,183,676 KiB peak RSS, installed the package once node-locally, retained `shard-001.tar.gz` SHA-256 `20a6bf2fa205fb3815cf4746850cba3c26cfd6684266e37b5a3bfcd58ff8b49d`, and recorded task status 0 with all two starts and three finite intervals. Production ceiling: one CPU, 6 GiB, 2.5 hours; estimated demand is about 43 CPU-hours and 5 array wall-hours before queue delay. The initial 2 GiB, 10-minute, one-data-set design is superseded.

- [ ] G15: Retained fixed-effect profile campaign outputs are recomputed without launching another campaign
  CHECK: Rscript --vanilla tools/temporal-ou-gates.R G15 --reverify
  EXPECT: TEMPORAL_OU_G15_PASS
  EVIDENCE: pending

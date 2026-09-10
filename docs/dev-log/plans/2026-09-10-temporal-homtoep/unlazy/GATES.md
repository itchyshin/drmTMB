# P2 homogeneous Toeplitz — Unlazy gates

Scope: identified **marginal** Gaussian homogeneous Toeplitz covariance after the direct OU parent. On 2026-09-10, the approved ordinary one-row-per-series--occasion panel scope selected M from `T3-8-REDESIGN-DECISION.md`: `sigma` is the total within-series SD of `sigma^2 R`; there is no temporal conditional mode or separate iid residual component. The preceding latent Toeplitz provider, recovery, and pilot remain retained historical diagnosis only. They never qualify this replacement model. Every runnable gate has an exact success-only receipt and source/provenance evidence.

- [x] T3-0: User approves this child plan and its source fingerprint before P2 implementation.
  EVIDENCE: 2026-09-10 explicit user approval after review of `PLAN.md`, `source-fingerprint.md`, and this ledger. S0 begins with the map decision only; no grammar or TMB provider code is authorized until T3-2 passes.

- [x] T3-1: Homtoep grammar validates common integer schedules, raw keys before omission, complete retained schedules and all early errors.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-1
  EXPECT: TEMPORAL_HOMTOEP_T3_1_PASS
  EVIDENCE: 2026-09-10 S1: canonical parser, raw-key validation, common complete equally spaced K=3..12 layout, output-row mapping, aliases and pre-provider fitting boundary pass in `tests/testthat/test-temporal-homtoep-parser.R`.

- [x] T3-2: One differentiable valid-Toeplitz map passes random-draw positive-definiteness, reconstruction, derivative and dense-reference tests.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-2
  EXPECT: TEMPORAL_HOMTOEP_T3_2_PASS
  EVIDENCE: 2026-09-10 S0: inverse-Levinson reflection map selected; 480 deterministic K=1..12 draws, reconstruction, finite-difference and dense-reference tests retained in `S0-PARAMETERISATION.md`, `tools/temporal-homtoep-map-study.R`, and `tests/testthat/test-temporal-homtoep-map.R`.

- [x] T3-3: M native likelihood, independent dense covariance, score, and Hessian agree at two finite-difference step sizes.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-3
  EXPECT: TEMPORAL_HOMTOEP_T3_3_PASS
  EVIDENCE: 2026-09-10 redesign reverify: `test-temporal-homtoep-native.R` independently constructs the marginal block covariance and inverse-Levinson correlations, then matches native likelihood, score, and 1e-4/1e-5 finite-difference Hessians. The exact gate command emitted its stated success receipt on 2026-09-10.

- [x] T3-4: M preserves original order, labels total scale and lag correlations, whitens Pearson residuals, and simulates the marginal covariance.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-4
  EXPECT: TEMPORAL_HOMTOEP_T3_4_PASS
  EVIDENCE: 2026-09-10 redesign reverify: the native method test checks fixed marginal fitted values, response and Pearson residuals, no temporal random-effect extractor, deferred interval surfaces, explicit temporal-correlation labels, and seeded per-series marginal simulation. The exact gate command emitted its stated success receipt on 2026-09-10.

- [x] T3-5: M AR1 and diagonal reductions plus invalid-map, compressed-schedule, cross-ID, and omitted-normalizer mutations fail as designed.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-5
  EXPECT: TEMPORAL_HOMTOEP_T3_5_PASS
  EVIDENCE: 2026-09-10 redesign reverify: `test-temporal-homtoep-reductions.R` matches marginal AR1 and diagonal reductions against the independent dense likelihood and detects indefinite direct lags, irregular schedules, cross-series covariance, and a missing MVN normalizer. The exact gate command emitted its stated success receipt on 2026-09-10.

- [ ] T3-6: RETIRED latent-provider recovery record; it does NOT qualify marginal Toeplitz recovery.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-6
  EXPECT: TEMPORAL_HOMTOEP_T3_6_PASS
  EVIDENCE: 2026-09-10 final-source recovery at `b9dacf42d`: 12 frozen fixtures (three AR1, three non-exponential, three negative-lag primary fits; three low-information stress fits), 12 retained attempts, and all five primary recovery criteria pass. `T3-6` verifies the runner MD5, source commit, denominators, and immutable outputs without rerunning fits.

- [ ] T3-7: RETIRED latent-provider pilot; it does NOT qualify marginal Toeplitz runtime or inference.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-7
  EXPECT: TEMPORAL_HOMTOEP_T3_7_PASS
  EVIDENCE: 2026-09-10 final-source pilot at `0cb70fe7f`: 15/15 finite selected fits and 15 retained starts across three five-seed cells; 39.42 s wall time, 438 MB peak memory, 15/15 explicit profile guards and 15 `NaNs produced` warnings. All 15 `pd_hessian` values are false, so this is a measured diagnosis and blocks profile-calibration/campaign advancement until inference qualification is separately resolved.

- [x] T3-7a: An exact covariance-preserving transformation proves whether the pilot Hessian failure is a free-Toeplitz residual/process ridge.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-7a
  EXPECT: TEMPORAL_HOMTOEP_T3_7A_PASS
  EVIDENCE: 2026-09-10: the dense covariance and likelihood remain unchanged when temporal variance is rescaled, every free lag correlation is inversely rescaled, and residual variance absorbs the diagonal difference. This proves the direct one-observation-per-series--occasion provider cannot separately identify `sd_temporal`, `sigma`, and a fully free homogeneous Toeplitz correlation matrix. It is the reason the selected M contract uses one total covariance scale.

- [x] T3-7c: Independent marginal-Toeplitz candidate spike has finite, positive observed information.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-7c
  EXPECT: TEMPORAL_HOMTOEP_T3_7C_PASS
  EVIDENCE: 2026-09-10 pure-R 80-series by 6-occasion spike: an identified total-covariance Toeplitz likelihood converged and had a minimum numerical-Hessian eigenvalue of 47.77. This was candidate evidence before M selection; it is not recovery or calibration evidence.

- [x] T3-7b: Identified M contract selected for ordinary panel CSV data after reviewing `T3-8-REDESIGN-DECISION.md`.
  EVIDENCE: 2026-09-10 approved temporal programme and continued implementation authorization select M: a total marginal within-series covariance for the existing complete common-schedule panel grammar. R remains a distinct future replicated-observation design.

- [x] M1: Current marginal provider has direct deterministic likelihood, derivative, reduction, and mutation evidence.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-3 && Rscript --vanilla tools/temporal-homtoep-gates.R T3-5
  EXPECT: TEMPORAL_HOMTOEP_T3_3_PASS and TEMPORAL_HOMTOEP_T3_5_PASS
  EVIDENCE: 2026-09-10 exact reverify command emitted both stated receipts after the M-provider rebuild.

- [x] M2: Current marginal provider has parser, row-order, extraction, residual, and simulation evidence.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-1 && Rscript --vanilla tools/temporal-homtoep-gates.R T3-4
  EXPECT: TEMPORAL_HOMTOEP_T3_1_PASS and TEMPORAL_HOMTOEP_T3_4_PASS
  EVIDENCE: 2026-09-10 exact reverify command emitted both stated receipts after the M-provider rebuild.

- [x] M3: Frozen marginal-Toeplitz recovery runner retains all attempts, denominators, source fingerprint, and predefined point-recovery criteria.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R M3
  EXPECT: TEMPORAL_HOMTOEP_M3_PASS
  EVIDENCE: 2026-09-10: the committed runner `tools/run-temporal-homtoep-marginal-recovery.R` emitted `TEMPORAL_HOMTOEP_MARGINAL_RECOVERY_PASS` for 12 retained fixtures and 12 attempts. The reverify gate checks the immutable source commit, runner MD5, all 12 outputs, nine primary selected fits, one attempt per fixture, and every frozen criterion without launching fits.

- [x] M4: Timed marginal-Toeplitz pilot records runtime, memory, point-estimate diagnostics, and denominator completeness.
  CHECK: Rscript --vanilla tools/run-temporal-homtoep-marginal-pilot.R
  EXPECT: TEMPORAL_HOMTOEP_MARGINAL_PILOT_PASS
  EVIDENCE: 2026-09-10: 15/15 selected finite fits and 15/15 positive-definite Hessians across three five-seed cells, with one retained attempt per fixture and no warnings. Post-load median fit times were 0.054--0.066 s and observed post-fit resident memory was 437--449 MB. The immutable artifacts preserve full denominators and source provenance; this is sizing and point-estimate evidence, not interval calibration.

- [ ] T3-8: Profile-calibration contract fixes cells, targets, all-attempt treatment of unavailable intervals, tail summaries and acceptance criteria.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-8
  EXPECT: TEMPORAL_HOMTOEP_T3_8_PASS
  EVIDENCE: pending

- [ ] T3-9: User explicitly approves the measured retained campaign target, storage route and resource ceiling.
  EVIDENCE: pending

- [ ] T3-10: Retained campaign artifacts reverify source, denominator and each frozen criterion without launching new fits.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-10 --reverify
  EXPECT: TEMPORAL_HOMTOEP_T3_10_PASS
  EVIDENCE: pending

- [ ] T3-11: The reader article, formula grammar and likelihood documentation render and direct irregular time to OU.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-11
  EXPECT: TEMPORAL_HOMTOEP_T3_11_PASS
  EVIDENCE: pending

- [ ] T3-12: Package build/check and independent Noether plus Pat reviews close P2 with a complete after-task report.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-12 --reverify
  EXPECT: TEMPORAL_HOMTOEP_T3_12_PASS
  EVIDENCE: pending

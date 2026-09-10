# P2 homogeneous Toeplitz — Unlazy gates

Scope: direct Gaussian temporal Toeplitz after the qualified direct OU parent. The runner path is intentionally reserved until S0 freezes the valid map. Every runnable gate starts pending and must have exact source/provenance evidence before it can pass.

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

- [x] T3-3: Native likelihood, independent dense V, score, Hessian and conditional modes agree at two finite-difference step sizes.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-3
  EXPECT: TEMPORAL_HOMTOEP_T3_3_PASS
  EVIDENCE: 2026-09-10 S2: `test-temporal-homtoep-native.R` independently constructs dense Toeplitz covariance, inverse-Levinson correlations, score, 1e-4 and 1e-5 finite-difference Hessians, and Gaussian conditional modes. The isolated T3-3 runner emitted its pass receipt; T3-1 and T3-2 were reverified after provider enablement.

- [x] T3-4: Row reconstruction, labelled extraction, fitted values, residuals and fresh/conditional simulation agree with the oracle.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-4
  EXPECT: TEMPORAL_HOMTOEP_T3_4_PASS
  EVIDENCE: 2026-09-10 S3: the native test asserts original-row temporal contributions, labelled extraction, fitted values, residuals, unsupported newdata and interval surfaces, and seeded conditional plus independently rebuilt fresh Toeplitz simulations. The isolated T3-4 runner emitted its pass receipt.

- [x] T3-5: AR1 and diagonal reductions plus invalid-map, compressed-schedule, cross-ID and omitted-normalizer mutations fail as designed.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-5
  EXPECT: TEMPORAL_HOMTOEP_T3_5_PASS
  EVIDENCE: 2026-09-10: `test-temporal-homtoep-reductions.R` compares native AR1 and diagonal reductions against independent dense likelihoods, rejects an indefinite direct-lag matrix and irregular schedule, and detects shared-series covariance plus an omitted MVN normalizer. The isolated T3-5 runner emitted its pass receipt.

- [x] T3-6: New fixtures recover AR1, non-exponential and negative-lag valid Toeplitz cells with all starts and failures retained.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-6
  EXPECT: TEMPORAL_HOMTOEP_T3_6_PASS
  EVIDENCE: 2026-09-10 final-source recovery at `b9dacf42d`: 12 frozen fixtures (three AR1, three non-exponential, three negative-lag primary fits; three low-information stress fits), 12 retained attempts, and all five primary recovery criteria pass. `T3-6` verifies the runner MD5, source commit, denominators, and immutable outputs without rerunning fits.

- [x] T3-7: Timed pilot records runtime, memory, profile availability, warnings and denominator completeness.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-7
  EXPECT: TEMPORAL_HOMTOEP_T3_7_PASS
  EVIDENCE: 2026-09-10 final-source pilot at `0cb70fe7f`: 15/15 finite selected fits and 15 retained starts across three five-seed cells; 39.42 s wall time, 438 MB peak memory, 15/15 explicit profile guards and 15 `NaNs produced` warnings. All 15 `pd_hessian` values are false, so this is a measured diagnosis and blocks profile-calibration/campaign advancement until inference qualification is separately resolved.

- [x] T3-7a: An exact covariance-preserving transformation proves whether the pilot Hessian failure is a free-Toeplitz residual/process ridge.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-7a
  EXPECT: TEMPORAL_HOMTOEP_T3_7A_PASS
  EVIDENCE: 2026-09-10: the dense covariance and likelihood remain unchanged when temporal variance is rescaled, every free lag correlation is inversely rescaled, and residual variance absorbs the diagonal difference. This proves the direct one-observation-per-series--occasion provider cannot separately identify `sd_temporal`, `sigma`, and a fully free homogeneous Toeplitz correlation matrix. T3-8 through T3-10 remain pending behind an explicit model-redesign decision.

- [ ] T3-7b: User selects an identified Toeplitz contract after reviewing `T3-8-REDESIGN-DECISION.md`.
  EVIDENCE: pending — choose M (marginal covariance for ordinary panels) or R (replicated latent process). This is a semantic interface decision; no code or campaign can select it implicitly.

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

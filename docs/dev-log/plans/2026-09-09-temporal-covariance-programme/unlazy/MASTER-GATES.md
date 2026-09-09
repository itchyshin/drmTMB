# Temporal covariance Ultra Master Plan — execution ledger

Scope: Master orchestration contract. Each model creates and re-verifies its own executable
ledger. A checked master gate needs a non-pending evidence line. There are 34 gates:
28 runnable and five manual. Nothing below authorizes a remote campaign, push, merge,
release, deployment or external message.

## Phase 0

- [x] M00: User approval, exact source pin, fresh execution worktree and path lease are recorded.
  EVIDENCE: 2026-09-09 user approved execution of master revision e751f9239. P1 starts from a1d01dab3dbcd6e12bec0486ac0425f939f20c2d in /Users/z3437171/local-scratch/lanes/drmTMB-phylo-temporal-ou-exec-v1 on codex/phylo-temporal-ou-exec-v1-20260909; lease codex-phylo-temporal-ou-exec-v1-20260909 is active.
- [x] M01-bootstrap: P1 and source-map gate runners are materialized, self-tested and fail their negative controls.
  CHECK: Rscript --vanilla tools/temporal-source-map-gates.R M01-bootstrap
  EXPECT: TEMPORAL_SOURCE_MAP_M01_BOOTSTRAP_PASS
  EVIDENCE: 2026-09-09 execution commit 405b40bbd: direct command returned TEMPORAL_SOURCE_MAP_M01_BOOTSTRAP_PASS after both runner self-tests rejected their intended controls.
- [x] M01: P1 source, runner and plan agree; the P1 runner rejects a missing fixture.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G1
  EXPECT: PHYLO_TEMPORAL_OU_G1_PASS
  EVIDENCE: 2026-09-09 execution commit 405b40bbd: direct command returned PHYLO_TEMPORAL_OU_G1_PASS; its deleted-fixture negative control failed as required.
- [x] M02: A cited NotebookLM source-map distillation separates verified sources from leads.
  CHECK: Rscript --vanilla tools/temporal-source-map-gates.R M02
  EXPECT: TEMPORAL_SOURCE_MAP_M02_PASS
  EVIDENCE: 2026-09-09 execution commit 405b40bbd: cited map at docs/dev-log/plans/2026-09-09-phylo-temporal-ou/source-map.md returned TEMPORAL_SOURCE_MAP_M02_PASS and labels the inaccessible Pourahmadi record as an unverified lead.
- [x] M03: The source fingerprint, native library, R/TMB versions and worktree state are retained.
  CHECK: Rscript --vanilla tools/temporal-source-map-gates.R M03
  EXPECT: TEMPORAL_SOURCE_MAP_M03_PASS
  EVIDENCE: 2026-09-09 execution commit 405b40bbd: source-fingerprint.md records a1d01dab3, R 4.6.0, TMB 1.9.21, src/drmTMB.cpp SHA-256 and the truthful no-build native-library status; direct M03 returned TEMPORAL_SOURCE_MAP_M03_PASS.

## Phase 1

- [x] P1-grammar: Paired phylo plus independent OU grammar and metadata pass only their admitted combinations.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G2
  EXPECT: PHYLO_TEMPORAL_OU_G2_PASS
  EVIDENCE: 2026-09-09 execution commit 35b17c9b1: direct G2 returned PHYLO_TEMPORAL_OU_G2_PASS; 13 focused paired-layout assertions and standalone temporal regressions passed. This is grammar/layout evidence only, not dense-oracle or inference evidence.
- [x] P1-oracle: Dense covariance, likelihood, score/Hessian and four reductions agree.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G3
  EXPECT: PHYLO_TEMPORAL_OU_G3_PASS
  EVIDENCE: 2026-09-09 execution commit 3c600263b: G3-G5 passed against an independent `ape::vcv()` dense likelihood on an unbalanced, shuffled 12-species fixture. The objective, score, two Hessian steps, and four reductions are covered; no public inference claim follows.
- [x] P1-mutation: Non-separable, off-diagonal, state-sharing and normalizer mutations fail.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G6
  EXPECT: PHYLO_TEMPORAL_OU_G6_PASS
  EVIDENCE: 2026-09-09 execution commit 3c600263b: G6 passed; missing phylogenetic off-diagonal, separable field, shared OU state, missing stable term, omitted normalizer, and misaligned tree each differ from the reference.
- [x] P1-methods: Modes, fitted values, residuals, simulations and public profile-target boundary agree.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G7
  EXPECT: PHYLO_TEMPORAL_OU_G7_PASS
  EVIDENCE: 2026-09-09 execution commit 039f84739: direct G7 returned PHYLO_TEMPORAL_OU_G7_PASS. The 25-assertion suite reconstructs fixed, phylogenetic-stable and independent-OU components for conditional fitted values/residuals and both simulation modes; it retains nested labels and fences off unqualified Wald/non-mean/newdata inference.
- [x] P1-profile: Fixed-mean profile endpoints agree with an independent dense likelihood, while deferred targets and irregular-Hessian warnings remain explicit.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G8
  EXPECT: PHYLO_TEMPORAL_OU_G8_PASS
  EVIDENCE: 2026-09-09 execution commit b9af2fd4b: direct G8 returned PHYLO_TEMPORAL_OU_G8_PASS. A direct dense Cholesky likelihood re-optimized every nuisance parameter and found 90% slope endpoints 0.17577 and 0.59428, matching public endpoints within 0.0004; decay/SD/bootstrap/newdata/endpoint-engine routes remain rejected and non-PD-Hessian warning behavior is tested.
- [ ] P1-pilot: Five-seed pilot has complete denominators and a measured resource estimate.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G10
  EXPECT: PHYLO_TEMPORAL_OU_G10_PASS
  EVIDENCE: pending
- [ ] P1-campaign: Campaign resource ceiling, target and immutable retention route are explicitly approved.
  EVIDENCE: pending
- [ ] P1-close: Recovery, retained calibration if approved, render, check and reviews are complete.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G18 --reverify
  EXPECT: PHYLO_TEMPORAL_OU_G18_PASS
  EVIDENCE: pending

## Phase 2

- [ ] P2-parameterisation: A positive-definite Toeplitz map is selected with derivative and reconstruction evidence.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-2
  EXPECT: TEMPORAL_HOMTOEP_T3_2_PASS
  EVIDENCE: pending
- [ ] P2-grammar: Canonical homtoep grammar, 12-level boundary, common-schedule errors and row reconstruction pass.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-1
  EXPECT: TEMPORAL_HOMTOEP_T3_1_PASS
  EVIDENCE: pending
- [ ] P2-oracle: Dense V, likelihood, score and Hessian agree with the native provider.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-3
  EXPECT: TEMPORAL_HOMTOEP_T3_3_PASS
  EVIDENCE: pending
- [ ] P2-nesting: AR1 and diagonal reductions, invalid-map and time-layout mutations pass.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-5
  EXPECT: TEMPORAL_HOMTOEP_T3_5_PASS
  EVIDENCE: pending
- [ ] P2-evidence: Recovery, measured pilot and any campaign meet their predeclared contract.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-11 --reverify
  EXPECT: TEMPORAL_HOMTOEP_T3_11_PASS
  EVIDENCE: pending
- [ ] P2-close: Article, package check and independent reviews are complete.
  CHECK: Rscript --vanilla tools/temporal-homtoep-gates.R T3-14 --reverify
  EXPECT: TEMPORAL_HOMTOEP_T3_14_PASS
  EVIDENCE: pending

## Phase 3

- [ ] P3-grammar: Canonical hetar1 grammar, 12-level boundary, common-level admissions and labels pass.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-1
  EXPECT: TEMPORAL_HETAR1_T4_1_PASS
  EVIDENCE: pending
- [ ] P3-oracle: D R D covariance and native likelihood agree with the dense oracle.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-3
  EXPECT: TEMPORAL_HETAR1_T4_3_PASS
  EVIDENCE: pending
- [ ] P3-nesting: Homogeneous-AR1 and diagonal reductions plus SD-label mutations pass.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-5
  EXPECT: TEMPORAL_HETAR1_T4_5_PASS
  EVIDENCE: pending
- [ ] P3-evidence: Recovery/pilot/campaign contract is retained and reverified.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-11 --reverify
  EXPECT: TEMPORAL_HETAR1_T4_11_PASS
  EVIDENCE: pending
- [ ] P3-close: Reader workflow, package check and independent reviews complete.
  CHECK: Rscript --vanilla tools/temporal-hetar1-gates.R T4-14 --reverify
  EXPECT: TEMPORAL_HETAR1_T4_14_PASS
  EVIDENCE: pending

## Phase 4

- [ ] P4-admission: Canonical hettoep grammar, eight-level boundary and information diagnostic are frozen.
  CHECK: Rscript --vanilla tools/temporal-hettoep-gates.R T5-1
  EXPECT: TEMPORAL_HETTOEP_T5_1_PASS
  EVIDENCE: pending
- [ ] P4-oracle: D R D Toeplitz covariance, native likelihood and valid-R map agree.
  CHECK: Rscript --vanilla tools/temporal-hettoep-gates.R T5-3
  EXPECT: TEMPORAL_HETTOEP_T5_3_PASS
  EVIDENCE: pending
- [ ] P4-nesting: Homogeneous-Toeplitz and heterogeneous-AR1 reductions plus invalid-R mutation pass.
  CHECK: Rscript --vanilla tools/temporal-hettoep-gates.R T5-5
  EXPECT: TEMPORAL_HETTOEP_T5_5_PASS
  EVIDENCE: pending
- [ ] P4-decision: The pilot either supports the predeclared primary design or retains a defer decision.
  EVIDENCE: pending
- [ ] P4-close: Any implemented T5 model has retained evidence, reader workflow and review.
  CHECK: Rscript --vanilla tools/temporal-hettoep-gates.R T5-14 --reverify
  EXPECT: TEMPORAL_HETTOEP_T5_14_PASS
  EVIDENCE: pending

## Phase 5 and integration

- [ ] P5-trigger: A named scientific use case selects at most one item-6 candidate and rejects generic order/model selection.
  EVIDENCE: pending
- [ ] P5-contract: The selected candidate has its own symbolic contract, oracle and recovery plan.
  CHECK: Rscript --vanilla tools/temporal-item6-gates.R P5-2
  EXPECT: TEMPORAL_ITEM6_P5_2_PASS
  EVIDENCE: pending
- [ ] P5-approval: The user approves the exact candidate implementation plan before code starts.
  EVIDENCE: pending
- [ ] P6-article: The rendered temporal article maps timing and mechanism to each supported model.
  CHECK: Rscript --vanilla tools/temporal-programme-gates.R P6-article
  EXPECT: TEMPORAL_PROGRAMME_P6_ARTICLE_PASS
  EVIDENCE: pending
- [ ] P6-close: Rose reconciles all master/arc gates, retained artifacts, costs and deferrals without rerunning a campaign.
  CHECK: Rscript --vanilla tools/temporal-programme-gates.R P6-close --reverify
  EXPECT: TEMPORAL_PROGRAMME_P6_CLOSE_PASS
  EVIDENCE: pending

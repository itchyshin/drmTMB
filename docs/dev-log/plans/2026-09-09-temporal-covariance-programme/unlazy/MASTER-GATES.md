# Temporal covariance Ultra Master Plan — execution ledger

Scope: Master orchestration contract. Each model creates and re-verifies its own executable
ledger. A checked master gate needs a non-pending evidence line. There are 33 gates:
28 runnable and five manual. Nothing below authorizes a remote campaign, push, merge,
release, deployment or external message.

## Phase 0

- [ ] M00: User approval, exact source pin, fresh execution worktree and path lease are recorded.
  EVIDENCE: pending
- [ ] M01-bootstrap: P1 and source-map gate runners are materialized, self-tested and fail their negative controls.
  CHECK: Rscript --vanilla tools/temporal-source-map-gates.R M01-bootstrap
  EXPECT: TEMPORAL_SOURCE_MAP_M01_BOOTSTRAP_PASS
  EVIDENCE: pending
- [ ] M01: P1 source, runner and plan agree; the P1 runner rejects a missing fixture.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G1
  EXPECT: PHYLO_TEMPORAL_OU_G1_PASS
  EVIDENCE: pending
- [ ] M02: A cited NotebookLM source-map distillation separates verified sources from leads.
  CHECK: Rscript --vanilla tools/temporal-source-map-gates.R M02
  EXPECT: TEMPORAL_SOURCE_MAP_M02_PASS
  EVIDENCE: pending
- [ ] M03: The source fingerprint, native library, R/TMB versions and worktree state are retained.
  CHECK: Rscript --vanilla tools/temporal-source-map-gates.R M03
  EXPECT: TEMPORAL_SOURCE_MAP_M03_PASS
  EVIDENCE: pending

## Phase 1

- [ ] P1-grammar: Paired phylo plus independent OU grammar and metadata pass only their admitted combinations.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G2
  EXPECT: PHYLO_TEMPORAL_OU_G2_PASS
  EVIDENCE: pending
- [ ] P1-oracle: Dense covariance, likelihood, score/Hessian and four reductions agree.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G3
  EXPECT: PHYLO_TEMPORAL_OU_G3_PASS
  EVIDENCE: pending
- [ ] P1-mutation: Non-separable, off-diagonal, state-sharing and normalizer mutations fail.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G6
  EXPECT: PHYLO_TEMPORAL_OU_G6_PASS
  EVIDENCE: pending
- [ ] P1-methods: Modes, simulation, fitted values, residuals and profile boundary agree.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G7
  EXPECT: PHYLO_TEMPORAL_OU_G7_PASS
  EVIDENCE: pending
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

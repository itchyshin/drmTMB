# Temporal covariance programme — Unlazy acceptance ledger

OWNS: `docs/dev-log/plans/2026-09-09-temporal-covariance-programme/**`,
`docs/dev-log/after-task/2026-09-09-temporal-covariance-programme-plan.md`, and
`docs/dev-log/check-log.md` for this plan entry only.

Scope: This ledger governs the temporal-covariance programme, not a claim that
Toeplitz, heterogeneous AR1, heterogeneous Toeplitz, seasonal, random-walk, ARMA or
temporal Matérn is implemented. Each implementation arc must supply its own ledger.
There are 19 gates: 16 runnable and three manual (G0, G12, G17). Implementation and
campaign evidence remains pending until the exact plan is approved; G17 records the
completed independent review of this planning artifact.

- [ ] G0: The user approved this programme order, its independent phylogeny-plus-OU first slice, and the item-6 scientific-trigger boundary.
  EVIDENCE: pending

- [ ] G1: The programme ledger, plan and runner agree on all 19 IDs, and the runner rejects a malformed plan fixture.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G1
  EXPECT: TEMPORAL_PROGRAMME_G1_PASS
  EVIDENCE: pending

- [ ] G2: The plan pins AR1/OU as predecessors and phylogenetic-stable-plus-independent-OU as next, rather than a separable field.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G2
  EXPECT: TEMPORAL_PROGRAMME_G2_PASS
  EVIDENCE: pending

- [ ] G3: Homogeneous Toeplitz has its covariance, common schedule and positive-definite parameterisation decision before fitting.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G3
  EXPECT: TEMPORAL_PROGRAMME_G3_PASS
  EVIDENCE: pending

- [ ] G4: Homogeneous Toeplitz defines AR1 and diagonal reductions plus dense-likelihood, mutation and simulation-oracle requirements.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G4
  EXPECT: TEMPORAL_PROGRAMME_G4_PASS
  EVIDENCE: pending

- [ ] G5: Heterogeneous AR1 has the occasion-SD AR1 covariance and distinguishes process variation from residual sigma.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G5
  EXPECT: TEMPORAL_PROGRAMME_G5_PASS
  EVIDENCE: pending

- [ ] G6: Heterogeneous AR1 specifies homogeneous and diagonal reductions, common-schedule support and extraction/simulation labels.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G6
  EXPECT: TEMPORAL_PROGRAMME_G6_PASS
  EVIDENCE: pending

- [ ] G7: Heterogeneous Toeplitz has its covariance, high-information admission boundary and retained stress cell.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G7
  EXPECT: TEMPORAL_PROGRAMME_G7_PASS
  EVIDENCE: pending

- [ ] G8: The programme keeps temporal, ordinary, phylogenetic, spatial and bivariate residual covariance roles separate.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G8
  EXPECT: TEMPORAL_PROGRAMME_G8_PASS
  EVIDENCE: pending

- [ ] G9: Each item-6 candidate has a scientific trigger and restricted first model; none is an automatic build commitment.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G9
  EXPECT: TEMPORAL_PROGRAMME_G9_PASS
  EVIDENCE: pending

- [ ] G10: The ARMA entry states regular-time, ARMA(1,1), stationarity, invertibility, initial-state, dense/state-space and innovation-simulation requirements.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G10
  EXPECT: TEMPORAL_PROGRAMME_G10_PASS
  EVIDENCE: pending

- [ ] G11: The source receipt distinguishes official glmmTMB documentation, the Matilda guide, completed drmTMB work and a future NotebookLM source map.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G11
  EXPECT: TEMPORAL_PROGRAMME_G11_PASS
  EVIDENCE: pending

- [ ] G12: A campaign has a measured pilot, DRAC/Fir resource ceiling, Totoro retention route and all-attempt denominators, and the user authorizes it.
  EVIDENCE: pending

- [ ] G13: Every model arc requires independent dense covariance, likelihood, score/Hessian where supported, modes and simulation checks before inference claims.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G13
  EXPECT: TEMPORAL_PROGRAMME_G13_PASS
  EVIDENCE: pending

- [ ] G14: Each arc has sequential parser/native/method dependencies and overlaps only evidence and reader work with disjoint ownership.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G14
  EXPECT: TEMPORAL_PROGRAMME_G14_PASS
  EVIDENCE: pending

- [ ] G15: The reader programme requires one rendered workflow and why simpler temporal models were inadequate.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G15
  EXPECT: TEMPORAL_PROGRAMME_G15_PASS
  EVIDENCE: pending

- [ ] G16: The programme lists deferred generalisations so an implementation cannot silently add generic syntax, forecasts, non-Gaussian models or a spatiotemporal field.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G16
  EXPECT: TEMPORAL_PROGRAMME_G16_PASS
  EVIDENCE: pending

- [x] G17: Independent mathematical and reader reviews find the final master plan internally consistent and clear about automatic versus science-triggered work.
  EVIDENCE: 2026-09-09 Noether mathematical review APPROVED; Darwin reader review accepted the repair that specifies one independent ARMA process per id and defers shared shocks.

- [ ] G18: Final reverify reports every programme and implementation-arc ledger without rerunning a campaign; reports reconcile costs and deferred candidates.
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G18 --reverify
  EXPECT: TEMPORAL_PROGRAMME_G18_PASS
  EVIDENCE: pending

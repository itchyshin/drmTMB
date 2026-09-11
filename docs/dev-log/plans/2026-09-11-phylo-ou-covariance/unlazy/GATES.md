# Phylogenetic OU covariance — Unlazy acceptance ledger

- [x] PO0: The user authorized a separate phylogenetic OU covariance arc after temporal P3 closeout.
  EVIDENCE: 2026-09-11 conversation; P3 closed at `57d91deea` before this orientation began.

- [x] PO1: Prior work distinguishes the live Brownian-plus-temporal-OU lane from this `phylo(..., model = "ou")` covariance choice.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO1
  EXPECT: PHYLO_OU_COVARIANCE_PO1_PASS
  EVIDENCE: 2026-09-11 preflight found live `codex/phylo-ou-g12-prep-20260910`; its plan and G13 evidence were read without touching its files.

- [ ] PO2: `phylo()` parses `model = "bm"` and `model = "ou"`; omitted model is existing BM, and malformed values fail early.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO2
  EXPECT: PHYLO_OU_COVARIANCE_PO2_PASS
  EVIDENCE: pending

- [ ] PO3: Native stationary-root OU tree transitions estimate one positive evolutionary-decay parameter while BM is unchanged.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO3
  EXPECT: PHYLO_OU_COVARIANCE_PO3_PASS
  EVIDENCE: pending

- [ ] PO4: Dense `ape::corMartins` covariance, native likelihood, score and two Hessian steps agree.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO4
  EXPECT: PHYLO_OU_COVARIANCE_PO4_PASS
  EVIDENCE: pending

- [ ] PO5: Tree-OU reductions and named mutations fail in the intended direction; BM is an explicit alternative, not an OU boundary.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO5
  EXPECT: PHYLO_OU_COVARIANCE_PO5_PASS
  EVIDENCE: pending

- [ ] PO6: Extraction, diagnostics, conditional modes, fitted values, residuals and seeded simulations expose labelled phylogenetic decay and retain their inference boundary.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO6
  EXPECT: PHYLO_OU_COVARIANCE_PO6_PASS
  EVIDENCE: pending

- [ ] PO7: Frozen local point-recovery fixtures retain starts and failures; their predeclared thresholds are assessed without a coverage claim.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO7
  EXPECT: PHYLO_OU_COVARIANCE_PO7_PASS
  EVIDENCE: pending

- [ ] PO8: Five-fixture timing and feasibility pilot records time, memory and denominator completeness before any longer proposal.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO8
  EXPECT: PHYLO_OU_COVARIANCE_PO8_PASS
  EVIDENCE: pending

- [ ] PO9: Formula reference, likelihood design and reader workflow render with the BM default, OU interpretation and scale-side deferral clear.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO9
  EXPECT: PHYLO_OU_COVARIANCE_PO9_PASS
  EVIDENCE: pending

- [ ] PO10: Independent Noether mathematical review and Pat reader review have no unresolved blocking defect.
  EVIDENCE: pending

- [ ] PO11: Exact-source package check, after-task report, immutable reverify and local closeout commit complete the location-side OU arc.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO11 --reverify
  EXPECT: PHYLO_OU_COVARIANCE_PO11_PASS
  EVIDENCE: pending

- [ ] PO12: A separate scale-side child specifies `sigma ~ phylo(..., model = "ou")`, its own decay parameter, identification tests and evidence gates before any implementation.
  EVIDENCE: pending

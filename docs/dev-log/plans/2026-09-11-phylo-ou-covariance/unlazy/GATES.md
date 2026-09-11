# Phylogenetic OU covariance — Unlazy acceptance ledger

- [x] PO0: The user authorized a separate phylogenetic OU covariance arc after temporal P3 closeout.
  EVIDENCE: 2026-09-11 conversation; P3 closed at `57d91deea` before this orientation began.

- [x] PO1: Prior work distinguishes the live Brownian-plus-temporal-OU lane from this `phylo(..., model = "ou")` covariance choice.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO1
  EXPECT: PHYLO_OU_COVARIANCE_PO1_PASS
  EVIDENCE: 2026-09-11 preflight found live `codex/phylo-ou-g12-prep-20260910`; its plan and G13 evidence were read without touching its files.

- [x] PO2: `phylo()` parses `model = "bm"` and `model = "ou"`; omitted model is existing BM, and malformed values fail early.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO2
  EXPECT: PHYLO_OU_COVARIANCE_PO2_PASS
  EVIDENCE: 2026-09-11: the focused parser gate returned `PHYLO_OU_COVARIANCE_PO2_PASS`. It also confirms an OU marker aborts until its native provider exists, so it cannot silently use Brownian covariance.

- [x] PO3: Native stationary-root OU tree transitions estimate one positive evolutionary-decay parameter while BM is unchanged.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO3
  EXPECT: PHYLO_OU_COVARIANCE_PO3_PASS
  EVIDENCE: 2026-09-11: native focused tests exercised the root and every edge, fit a Gaussian OU-tree model, and retained Brownian-default regression coverage in the parser fixture.

- [x] PO4: Dense `ape::corMartins` covariance, native likelihood, score and two Hessian steps agree.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO4
  EXPECT: PHYLO_OU_COVARIANCE_PO4_PASS
  EVIDENCE: 2026-09-11: native likelihood, automatic score and observed Hessian agreed with an independent dense covariance oracle; finite-difference Hessians at 1e-4 and 1e-5 agreed.

- [x] PO5: Tree-OU reductions and named mutations fail in the intended direction; BM is an explicit alternative, not an OU boundary.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO5
  EXPECT: PHYLO_OU_COVARIANCE_PO5_PASS
  EVIDENCE: 2026-09-11: normalized root-plus-edge density matched the dense all-node covariance. Omitted-root, wrong-transition-variance, and compressed-branch mutations disagreed; BM, row-order temporal kernel, and shared-tree-state mutations also disagreed. The small- and large-decay limits were retained as explicit OU limits, never BM limits.

- [x] PO6: Extraction, diagnostics, conditional modes, fitted values, residuals and seeded simulations expose labelled phylogenetic decay and retain their inference boundary.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO6
  EXPECT: PHYLO_OU_COVARIANCE_PO6_PASS
  EVIDENCE: 2026-09-11: the focused compiled test gate emitted `PHYLO_OU_COVARIANCE_PO6_PASS`. `decay_phylo` is labelled in extraction and target inspection as a positive point estimate with Wald, profile and bootstrap intervals deferred. Fresh simulation now uses the stationary root-plus-edge OU draw, and deterministic seeded checks distinguish it from the generic Brownian draw.

- [x] PO7: Frozen local point-recovery fixtures retain starts and failures; their predeclared thresholds are assessed without a coverage claim.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO7
  EXPECT: PHYLO_OU_COVARIANCE_PO7_PASS
  EVIDENCE: 2026-09-11: all 12 finite local fits and their timings are retained. The predeclared all-fixture intercept threshold failed, while treatment-effect, median phylogenetic-SD and median decay thresholds passed. This failure is retained as an intercept-versus-tree-field separation limitation, so the provider earns no point-recovery or interval claim.

- [x] PO8: Five-fixture timing and feasibility pilot records time, memory and denominator completeness before any longer proposal.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO8
  EXPECT: PHYLO_OU_COVARIANCE_PO8_PASS
  EVIDENCE: 2026-09-11: the first five retained fixtures completed in 3.193 seconds total (median 0.240 seconds; maximum 2.144 seconds), with 5/5 positive-definite Hessians. No longer proposal or campaign is made.

- [x] PO9: Formula reference, likelihood design and reader workflow render with the BM default, OU interpretation and scale-side deferral clear.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO9
  EXPECT: PHYLO_OU_COVARIANCE_PO9_PASS
  EVIDENCE: 2026-09-11: man/phylo.Rd, the formula grammar, likelihood design and a locally rendered formula-grammar article now distinguish Brownian default from evolutionary tree OU, explicitly separate it from temporal OU, and retain the no-interval and no-scale-side boundary.

- [ ] PO10: Independent Noether mathematical review and Pat reader review have no unresolved blocking defect.
  EVIDENCE: pending

- [ ] PO11: Exact-source package check, after-task report, immutable reverify and local closeout commit complete the location-side OU arc.
  CHECK: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO11 --reverify
  EXPECT: PHYLO_OU_COVARIANCE_PO11_PASS
  EVIDENCE: pending

- [ ] PO12: A separate scale-side child specifies `sigma ~ phylo(..., model = "ou")`, its own decay parameter, identification tests and evidence gates before any implementation.
  EVIDENCE: pending

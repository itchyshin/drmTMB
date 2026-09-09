# Phylogenetic stable intercept plus independent OU — Unlazy acceptance ledger

OWNS: R/parse-formula.R, R/temporal.R, R/drmTMB.R, R/methods.R, R/check.R, R/profile.R, R/simulate.R, src/drmTMB.cpp, tests/testthat/test-phylo-temporal-ou*.R, tests/testthat/helper-phylo-temporal-ou-reference.R, tools/phylo-temporal-ou-*.R, docs/design/01-formula-grammar.md, docs/design/03-likelihoods.md, vignettes/phylogenetic-temporal-effects.Rmd, README.md, NEWS.md, _pkgdown.yml, docs/dev-log/known-limitations.md, docs/dev-log/check-log.md, docs/dev-log/plans/2026-09-09-phylo-temporal-ou/**, docs/dev-log/after-task/2026-09-*-phylo-temporal-ou*.md, docs/dev-log/plan-actual/2026-09-*-phylo-temporal-ou*.md

Scope: The first phylogenetic-temporal Gaussian ML slice is a phylogenetically correlated stable intercept plus an independent within-species OU process. It excludes the separable phylogeny-by-OU field and every wider temporal covariance structure.

There are 19 gates: 16 runnable and three manual (G0, G12, G17). Every runnable gate uses the exact future runner `tools/phylo-temporal-ou-gates.R`; its implementation and failure controls are themselves checked by G1 before any execution gate is trusted. All evidence is pending because this is a plan-only ledger.

- [x] G0: The user approved this exact first-slice grammar, source pin and campaign boundary.
  EVIDENCE: 2026-09-09 user authorized execution of the detailed master plan at e751f9239; execution source pinned at a1d01dab3 on codex/phylo-temporal-ou-exec-v1-20260909. Campaign authority remains G12.

- [x] G1: The frozen execution source, plan contract and gate runner agree and fail closed on a missing fixture.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G1
  EXPECT: PHYLO_TEMPORAL_OU_G1_PASS
  EVIDENCE: 2026-09-09 direct command returned PHYLO_TEMPORAL_OU_G1_PASS; runner self-test rejected a missing fixture.

- [x] G2: The paired `phylo()` plus OU grammar accepts only same-species IDs and valid tree/time metadata, preserving unbalanced rows and input order.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G2
  EXPECT: PHYLO_TEMPORAL_OU_G2_PASS
  EVIDENCE: 2026-09-09 direct worker returned PHYLO_TEMPORAL_OU_G2_PASS. Focused paired tests passed 13 assertions, including mismatched IDs, ordinary-intercept exclusion, raw duplicate keys, insufficient species, retained singleton series, and mismatched tree tips.

- [x] G3: An independently coded dense marginal covariance oracle covers non-diagonal phylogeny, irregular elapsed time, unbalanced species sampling and shuffled rows, including a cross-species nonzero-lag entry with selected `A_ij != 0`, `s_a > 0` and finite positive decay that equals stable phylogenetic covariance only.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G3
  EXPECT: PHYLO_TEMPORAL_OU_G3_PASS
  EVIDENCE: 2026-09-09 direct command returned PHYLO_TEMPORAL_OU_G3_PASS. Independent `ape::vcv()` dense likelihood on a 12-species unbalanced, shuffled fixture matched the native objective to 1e-7 and asserted the stable-only cross-species nonzero-lag entry.

- [x] G4: Native likelihood, score and observed Hessian agree with the dense oracle at two finite-difference steps.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G4
  EXPECT: PHYLO_TEMPORAL_OU_G4_PASS
  EVIDENCE: 2026-09-09 direct command returned PHYLO_TEMPORAL_OU_G4_PASS. Dense finite-difference score used 1e-6; Hessians at 1e-4 and 1e-5 agreed and matched inverse `sdr$cov.fixed` at 1e-4.

- [x] G5: The four reductions agree with current independent OU when the stable phylogenetic SD is zero, ordinary phylogenetic intercept when the temporal SD is zero, ordinary-intercept-plus-OU when phylogeny is identity, and the complete unit-spaced covariance `s_b^2 A_ij + I(i=j) s_a^2 phi^|k-l| + I(r=q) sigma^2` with `phi = exp(-decay)`.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G5
  EXPECT: PHYLO_TEMPORAL_OU_G5_PASS
  EVIDENCE: 2026-09-09 direct command returned PHYLO_TEMPORAL_OU_G5_PASS. The independent covariance test exercises all four reductions with `phi = 0.5` at unit spacing.

- [x] G6: On the G3 fixture with selected `A_ij != 0`, `s_a > 0`, finite positive decay and nonzero cross-species lag, mutation tests detect a missing phylogenetic off-diagonal and the wrong separable phylogeny-by-OU covariance; they also detect a shared OU state across species, a wrong OU transition normalizer, a dropped stable intercept and a misaligned tree tip.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G6
  EXPECT: PHYLO_TEMPORAL_OU_G6_PASS
  EVIDENCE: 2026-09-09 direct command returned PHYLO_TEMPORAL_OU_G6_PASS. All six named covariance or normalized-transition mutations differ from the independent reference.

- [x] G7: Conditional modes, fitted values, residuals, fresh simulation and conditional simulation agree with dense references and retain component labels.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G7
  EXPECT: PHYLO_TEMPORAL_OU_G7_PASS
  EVIDENCE: 2026-09-09 direct G7 returned PHYLO_TEMPORAL_OU_G7_PASS. The focused 25-assertion methods suite reconstructed fitted values and residuals from fixed, phylogenetic and OU components; reconstructed conditional and fresh simulations using the corresponding component draw helpers; retained nested component labels; and asserted that OU Wald covariance, non-mean intervals and newdata prediction remain unavailable.

- [ ] G8: Fixed-mean profile endpoints agree with an independently coded dense-profile reference, reject all deferred targets and warn when the fitted Hessian is irregular.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G8
  EXPECT: PHYLO_TEMPORAL_OU_G8_PASS
  EVIDENCE: pending

- [ ] G9: Retained recovery uses the 24 predeclared phylogenetic-signal, OU-decay and imbalance fixtures, preserves all 48 starts and failures, and meets the stated finite-fit and error thresholds without changing seeds.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G9
  EXPECT: PHYLO_TEMPORAL_OU_G9_PASS
  EVIDENCE: pending

- [ ] G10: A five-seed per-cell timed pilot records wall time, memory, profile availability, diagnostics and complete denominators.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G10
  EXPECT: PHYLO_TEMPORAL_OU_G10_PASS
  EVIDENCE: pending

- [ ] G11: The predeclared 95% profile-calibration contract fixes P1–P4, targets, all-attempt denominators, unavailable-endpoint policy, lower/upper-tail reporting, acceptance bounds and Monte Carlo precision; its worker and assessment helper reject incomplete denominators, forged provenance and a known failing coverage fixture.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G11
  EXPECT: PHYLO_TEMPORAL_OU_G11_PASS
  EVIDENCE: pending

- [ ] G12: The measured campaign design, target, resource ceiling, storage route and all-attempt denominator are explicitly authorized.
  EVIDENCE: pending

- [ ] G13: Immutable campaign shards reverify their source fingerprint, complete denominator and every predeclared primary profile-calibration criterion without launching new fits.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G13 --reverify
  EXPECT: PHYLO_TEMPORAL_OU_G13_PASS
  EVIDENCE: pending

- [ ] G14: The reader article distinguishes evolutionary baseline, independent temporal deviation and residual noise; reference/design documentation and pkgdown navigation synchronize.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G14
  EXPECT: PHYLO_TEMPORAL_OU_G14_PASS
  EVIDENCE: pending

- [ ] G15: The source-built phylogenetic-temporal article renders and includes a runnable irregular-time workflow and the profile-inference boundary.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G15
  EXPECT: PHYLO_TEMPORAL_OU_G15_PASS
  EVIDENCE: pending

- [ ] G16: The final exact source passes `R CMD build` and `R CMD check --no-manual`.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G16
  EXPECT: PHYLO_TEMPORAL_OU_G16_PASS
  EVIDENCE: pending

- [ ] G17: Independent Noether mathematical review and Pat reader-workflow review find no unresolved blocking defect.
  EVIDENCE: pending

- [ ] G18: The final reverify reports every runnable gate, retained artifact and manual decision; the after-task and plan-versus-actual reports reconcile scope, cost and deferrals.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G18 --reverify
  EXPECT: PHYLO_TEMPORAL_OU_G18_PASS
  EVIDENCE: pending

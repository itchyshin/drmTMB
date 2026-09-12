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

- [x] G8: Fixed-mean profile endpoints agree with an independently coded dense-profile reference, reject all deferred targets and warn when the fitted Hessian is irregular.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G8
  EXPECT: PHYLO_TEMPORAL_OU_G8_PASS
  EVIDENCE: 2026-09-09 direct G8 returned PHYLO_TEMPORAL_OU_G8_PASS. The dense Cholesky profile re-optimizes all nuisance parameters under fixed beta_x without calling the production profile engine. Its 90% endpoints (0.17577, 0.59428) matched public TMB-profile endpoints within 0.0004; the suite rejects decay/phylogenetic-SD/bootstrap/newdata/endpoint-engine routes and verifies the non-PD-Hessian warning.

- [ ] G9: Retained recovery uses the 24 predeclared phylogenetic-signal, OU-decay and imbalance fixtures, preserves all 48 starts and failures, and meets the stated finite-fit and error thresholds without changing seeds.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G9
  EXPECT: PHYLO_TEMPORAL_OU_G9_PASS
  EVIDENCE: 2026-09-09 FAILED, retained for diagnosis. The corrected 50-species 24-fixture denominator at `docs/dev-log/simulation-artifacts/2026-09-09-phylo-temporal-ou-local-recovery-v4/` retained 24 finite selected fits and 48 starts; log-SD (0.153) and log-decay (0.276) criteria passed, but mean fixed-effect error was 0.182 > 0.150. A separate 80-species diagnostic with the same seeds and thresholds at `...-v6-high-information/` also retained 24/48 and passed SD/decay criteria but fixed-effect error was 0.165 > 0.150. Earlier v1/v2 artifacts retain runner-interface failures; v3 retains the ordered-treatment confounding diagnosis. No seed/threshold change or promotion occurred; a revised decision is required before G9 can pass.

- [x] G9b: Approved five-fixture recovery pilot retains new seeds, contrast/intercept metrics, two starts, wall time and valid provenance without changing G9.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G9b
  EXPECT: PHYLO_TEMPORAL_OU_G9B_PILOT_PASS
  EVIDENCE: 2026-09-10 v2 retained five selected fixtures and ten starts at seeds 2026091301--2026091305; all contrast and decay estimates were finite, total fit time was 4.909 seconds, and provenance includes runner MD5 416b4e0bdb9bcabc7de466d6d5731ca6. v1 is retained with its NA-MD5 runner defect.

- [x] G9b-full: New frozen 24-fixture contrast recovery and 300-tree ensemble intercept study meet the separate G9b-A and G9b-B criteria without replacing failed G9.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G9b-full
  EXPECT: PHYLO_TEMPORAL_OU_G9B_FULL_PASS
  EVIDENCE: 2026-09-10 v5 at source `8918a9ae03e3e16ac796bc1b30280a901fc81675`, runner MD5 `39cbadd821d8a9f801d596462c29bf5c`, retained 24/48 contrast fixtures/starts and 300/600 independent-tree selected fits/starts. G9b-A passed contrast MAE 0.123 (between) and 0.071 (within), median absolute log-SD error 0.163, and median absolute log-decay error 0.280. G9b-B had 100 finite fits per phylogenetic SD and standardized signed intercept bias 0.032, 0.072, and 0.063 for SD 0.3, 0.6, and 1.0. Earlier v1--v4 setup and parser failures remain retained beside v5; none were overwritten. This repairs point-recovery evidence only: G9 stays failed and G10--G13 remain pending.

- [x] G9c: G9b-full is accepted only as the alternative point-recovery prerequisite for the five-seed-per-cell G10 timing and diagnostics pilot; G9 remains failed.
  EVIDENCE: 2026-09-10 user approved G9c in this Codex task. This permits G10 only; it does not qualify profile coverage, Wald covariance, forecasts, `newdata`, a separable phylogeny-by-OU field, or a campaign.

- [x] G10: A five-seed per-cell timed pilot records wall time, memory, profile availability, diagnostics and complete denominators.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G10
  EXPECT: PHYLO_TEMPORAL_OU_G10_PASS
  EVIDENCE: 2026-09-10 checkpointed v2 at source `d274753a122ce1710e6674170cfa5b95259c88f1` retained 20/20 generated and selected fits, 40/40 configured starts, 60/60 fixed-mean profile attempts, and 20/20 diagnostics. Every fit converged with a positive-definite Hessian; every profile was available; no warnings were retained. Total fit/profile elapsed time was 24.826/310.254 seconds and peak R allocation was 371.1 MB. `Rscript --vanilla tools/phylo-temporal-ou-gates.R G10` returned `PHYLO_TEMPORAL_OU_G10_PASS`. The initial v1 preflight bookkeeping failure and non-checkpointed manifest-only attempt remain retained beside the successful v2; G10 does not qualify coverage or authorize G12.

- [x] G11: The corrected 95% profile-calibration contract fixes P1–P4, the common fixed-effect generating values, all-attempt denominators, unavailable-endpoint policy, lower/upper-tail reporting, acceptance bounds and Monte Carlo precision; its worker and assessment helper reject incomplete denominators, forged provenance and a known failing coverage fixture.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G11
  EXPECT: PHYLO_TEMPORAL_OU_G11_PASS
  EVIDENCE: The original `26c4b05c58fb2eae115ca8b0611d67f8244fc6cf` contract remains retained as historical evidence, but assigned its truth vector before sorting the target table and therefore mislabelled P2--P3. Corrected source `0ee980cb0ab4c643099094a4e3ab0e8776451928` retains the same 3,500-row P1--P4 manifest and thresholds under `simulation-artifacts/2026-09-10-phylo-temporal-ou-g11-corrected-target-contract/`; every cell now maps intercept/between/within to 0/0.5/0.5, matching the frozen worker. Focused tests, both self-tests, and `Rscript --vanilla tools/phylo-temporal-ou-gates.R G11` passed. This correction changes no G12 fit or task artifact.

- [x] G12: The measured campaign design, target, resource ceiling, storage route and all-attempt denominator are explicitly authorized.
  EVIDENCE: 2026-09-10 user authorization covered the 3,500-task Rorqual campaign at one CPU, 2 GiB, 30 minutes and at most 60 concurrent tasks. Four released arrays completed all 3,500 tasks; checksum-verified archives and sidecars are retained on Totoro under campaign root `phylo-ou-g12-384048d7-20260910`. The immutable aggregate archive manifest SHA-256 is `fc2a7a43dab7e82e9133f6c70638328e4e203405c8a4bf5b64784c91deaf7333`. G13 still determines the calibration verdict.

- [ ] G13: Immutable campaign shards reverify their source fingerprint, complete denominator and every predeclared primary profile-calibration criterion without launching new fits.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G13 --reverify
  EXPECT: PHYLO_TEMPORAL_OU_G13_PASS
  EVIDENCE: 2026-09-10 corrected-truth closure job `20895722` inspected all 3,500 sealed archives from estimator source `384048d7eb6be3950dcf28a4aef91a3fb616184a` with no model fit, completed in 71 seconds (1 CPU, 4 GiB ceiling), and was reproduced byte-for-byte for the four result tables from Totoro. Six of nine primary rows qualify; the P1/P2/P3 intercept intervals fail the predeclared coverage condition at 0.870/0.922/0.895. The local G13 check deliberately fails closed with those exact rows. Retained result: `simulation-artifacts/2026-09-10-phylo-temporal-ou-g13-truthfix/`. The dense endpoint check, fixed-tree fast/default pilot, and known-covariance GLS comparison are retained as diagnosis only; none establishes a replacement interval. G13 is unmet; no later temporal structure may begin under this plan.

- [x] G14: The reader article distinguishes evolutionary baseline, independent temporal deviation and residual noise; reference/design documentation and pkgdown navigation synchronize.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G14
  EXPECT: PHYLO_TEMPORAL_OU_G14_PASS
  EVIDENCE: 2026-09-09 direct command returned PHYLO_TEMPORAL_OU_G14_PASS. `vignettes/phylogenetic-temporal-effects.Rmd`, formula grammar, likelihood design documentation, limitation register and development-marked pkgdown navigation all distinguish stable tree-correlated variation from independent within-species OU departures. The article visibly retains G9's unqualified recovery status. The 2026-09-11 recheck returned PHYLO_TEMPORAL_OU_G14_PASS after synchronizing the retained G13 intercept-undercoverage boundary.

- [x] G15: The source-built phylogenetic-temporal article renders and includes a runnable irregular-time workflow and the profile-inference boundary.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G15
  EXPECT: PHYLO_TEMPORAL_OU_G15_PASS
  EVIDENCE: 2026-09-09 direct command returned PHYLO_TEMPORAL_OU_G15_PASS. The gate loads the development package, renders the Rmd into an isolated temporary directory, verifies the HTML title/development status/irregular-time workflow, and fails on missing output or contract text.

- [x] G16: The final exact source passes `R CMD build` and `R CMD check --no-manual`.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G16
  EXPECT: PHYLO_TEMPORAL_OU_G16_PASS
  EVIDENCE: 2026-09-11 final source build and `R CMD check --no-manual` completed with `Status: OK` at 0 exit status. Retained command receipt and complete log: `docs/dev-log/simulation-artifacts/2026-09-11-phylo-temporal-ou-closeout/package-check-receipt.txt` and `package-check.log`.

- [x] G17: Independent Noether mathematical review and Pat reader-workflow review find no unresolved blocking defect.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G17
  EXPECT: PHYLO_TEMPORAL_OU_G17_PASS
  EVIDENCE: 2026-09-11 Noether independently confirmed the additive covariance, stationary OU normalizers, stable phylogenetic precision, and dense-oracle G3 result; his archive-integrity finding was repaired by exact source/worker binding and SHA-256 verification. Pat found the profile wording could be read as either unavailable or reportable inference; the vignette, formula grammar, likelihood note, profile help, and `check_drm()` now say calculable interval-feasibility diagnostic, not inference-ready. Neither review left a blocking mathematical or reader-workflow defect.

- [x] G18: The final reverify reports every runnable gate, retained artifact and manual decision; the after-task and plan-versus-actual reports reconcile scope, cost and deferrals.
  CHECK: Rscript --vanilla tools/phylo-temporal-ou-gates.R G18 --reverify
  EXPECT: PHYLO_TEMPORAL_OU_G18_INTERVAL_FEASIBILITY_PASS
  EVIDENCE: 2026-09-11 direct no-refit reverify returned PHYLO_TEMPORAL_OU_G18_INTERVAL_FEASIBILITY_PASS. It rechecked G14--G17, required the exact final source-check receipt, and required the retained red G13 verdict to name all three failed intercept cells. It launched no model fit and did not overwrite campaign evidence.

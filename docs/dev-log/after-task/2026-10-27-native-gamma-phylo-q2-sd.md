# After task: Gamma tree intercept and slope SDs

## 1. Goal

Fit separate predictor-dependent SDs for independent Gamma phylogenetic intercept and numeric-slope fields, preserving tree correlation scaling.

## 2. Implemented

The Gamma builder explicitly opts into one unlabelled phylogenetic intercept plus one numeric slope. The shared positive-continuous validator has a default-false Gamma-only flag; existing animal and related-matrix branches are preserved. Separate selected SD targets use existing coefficient loading and extraction. Base two-field models also require complete responses. No C++ source or compiled artifact changed.

Independent fields satisfy u_k ~ N(0,K), b_k=D_k u_k and Cov(b_k)=D_k K D_k, where D_k=diag(exp(W_k alpha_k)). The Gamma mean is exp(X beta+b_0+x*b_1), with shape=sigma^-2. K is Brownian shared ancestry divided by global tree height. The example pairs phylo(1+x|id,tree=tree) with two coefficient-selected sd(id,level="phylogenetic") formulas.

## 3a. Decisions and Rejected Alternatives

The DGP independently specifies a balanced 64-tip tree with five internal path edges .1 and terminal edge 1.5, height 2. Expected K has diagonal 1 and off-diagonal .1 times common binary-prefix depth divided by 2. No package covariance helper creates the DGP. Seed 2026102713, 64 tips with 20 observations, slope-error tolerance .4 and absolute likelihood/eta/equivalence tolerance 1e-4 were recorded before fitting. No seed or tolerance changed. Assumptions without asking: reuse these bounded single-seed tolerances from prior slices; coverage remains deferred.

## 4. Files Touched

Scoped code is in R/drmTMB.R. New files are tests/testthat/test-gamma-phylo-q2-sd-regression.R, inst/examples/gamma-phylo-q2-sd.R, this report, the matching check-log.d fragment and native-gamma-phylo-q2-sd-20261027 evidence directory. The old positive-continuous structured test now excludes only newly admitted Gamma phylo 1+x from its refusal loop; all case seeds and remaining refusal forms stay intact. Foreign dirty work was preserved.

## 5. Checks Run

The corrected-source focused suite passed 48 checks in 12.386 seconds. Seven Gamma files passed 171 checks with zero failures, errors, warnings or skips in 57.241 seconds, below the 150-second estimate. The separate positive-continuous neighbor passed 198 checks with the same clean outcomes in 18.016 seconds, below its 180-second estimate.

The final-source example converged in 2.643 seconds, estimating SD slopes 0.3280183 and -0.5660805 against truths 0.5 and -0.5. These are one-seed point checks, not general recovery or coverage evidence. No full package check, pkgdown build, calibration or live Julia process ran.

## 6. Tests of the Tests

Before implementation the new tests failed twice at the intercept-only validator in 4.900 seconds. Independent expected K is compared with the tip block after inversion of augmented tree precision. The dense Gamma joint density, analytic score and Hessian, two latent-mode starts, finite differences and absolute Laplace likelihood test internal-node integration. Reordered tree labels with edge remapping and reversed SD formulas test identity. Constant SD formulas agree with the base model.

Named SDs, parameter tables, conditional predictions, save/reload and seeded conditional simulation are checked. Internal nodes and an unused tip retain raw latent values and have NA scaled effects without SD predictors. The unused-tip check covers assembly/extraction only. Lognormal and Tweedie default-flag refusals guard against shared-validator leakage.

## 7a. Issue Ledger

The exact native Gamma mu phylo_numeric_slope tree candidate is saved without shared-ledger promotion. No issue was opened, closed or externally commented on. The full SD programme remains open.

## 8. Consistency Audit

Parent and independent reviewer checked the exact patch and equations. After the repair below, removing only the new flag and branch from the shared validator reproduces its pre-edit bytes. Final source has no remaining P0/P1 finding. The exact Julia Gamma phylo slope route remains refused before setup; this is a static audit, not runtime parity.

The search rg -n 'Gamma.*phylo|gamma.*phylo|structured slopes' covered README.md, docs/dev-log/internal-roadmap.md, NEWS.md, docs/dev-log/known-limitations.md, docs/design/01-formula-grammar.md and vignettes/formula-grammar.Rmd. Broad public maps remain with the documentation lane. Syntax and likelihood parameterization are unchanged; the example and this report document the candidate. No site build or roxygen regeneration was needed for internal-only code and standalone example changes.

Memory receipt: routed project manifest, on-disk graph and prior Gamma/Beta tree receipts supplied context; normalization and covariance lessons shaped the checks. Golden Set: not run; independent numerical and neighbor checks provide current evidence. No expensive sister-repository scouting was repeated.

## 9. What Did Not Go Smoothly

The first edit nested the phylo branch inside the animal branch and still produced two refusal errors in 2.662 seconds. An attempted relocation then allowed phylo tests to pass but incorrectly wrapped existing branches. Independent source review caught this P1 regression before accepting results. The whole shared validator was restored from the owned pre-edit snapshot, then a complete sibling branch was inserted after marker selection. The transient 48-pass run in 12.507 seconds does not support final claims. Its logs remain alongside the corrected-source results. The example was rerun after repair. No seed, fixture or numerical tolerance was changed to repair this control-flow mistake.

Preflight and lease scans took minutes. A neighboring stale refusal was found and narrowed to still-unsupported forms rather than deleting the case.

## 10. Known Residuals

Unused-tip likelihood fitting, weighted or missing-data fits, correlated blocks, labels, multiple slopes, extra random layers, new-data prediction, profile/bootstrap workflows, marginal two-field simulation, calibrated intervals and live Julia parity remain unassessed. The checkout is a dirty candidate; no commit, push, merge or release occurred. The aggregate acceptance gate is UNKNOWN because its existing runner is unavailable.

## 11. Team Learning

A passing focused route cannot prove shared control flow was preserved. Compare an edited shared validator against its before snapshot after removing the intended additions, then run existing provider neighbors.

## 12. Cross-Product Coverage

This slice covers native complete-data Gamma mu with a tree, one independent intercept plus numeric slope, selected group-constant SD predictors, unit weights and fixed-effect sigma. It checks normalization, internal-node integration, extraction, conditional workflows and save/reload. It does NOT cover slope-only or multiple slopes, labels, sigma tree effects, additional layers, missing data, new-data SD prediction, uncertainty workflows, marginal two-field draws, calibration, Julia parity, full checks or release.

## 13. Prose Assessment

The exact-draft assessment is stored separately with the evidence. Scientific and factual judgments are restricted to the saved tests, example and reviewed source. No external references are claimed.

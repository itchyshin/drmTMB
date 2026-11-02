# After Task: Poisson animal SD regression from pedigree input

## 1. Goal

Exercise predictor-dependent SDs for the native Poisson animal q1 intercept when the model receives a pedigree and builds its sparse precision internally.

## 2. Implemented

A seeded test creates 16 unrelated founder pairs and 96 offspring, then simulates Poisson outcomes using a latent animal effect with covariance `D A D`. The reference `A` comes from the dense pedigree relationship helper; the fit uses `animal(1 | id, pedigree = pedigree)`. The test checks that sparse precision reordered by labels equals `solve(A)`, SD-slope recovery, group SD predictions matched by animal name, and equivalence between a constant-SD formula and the existing constant-SD fit.

No production likelihood or builder code changed.

## 3a. Decisions and Rejected Alternatives

The fit and data generator use separate implementations of the pedigree covariance: the generator uses the dense relationship helper, while the model builds sparse pedigree precision. This gives an independent numeric route for the DGP. Predictions are checked by name because the structured group registry returns pedigree node order, which can differ from the factor-level order. Comparing raw vector positions would test an order assumption instead of group identity.

## 4. Files Touched

- `tests/testthat/test-poisson-animal-pedigree-sd-regression.R` adds the synthetic recovery and equivalence test.
- `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`, and `docs/dev-log/general-sd-regression/inventory.md` record this evidence and its boundary.
- `.unlazy/general-sd-regression/GATES.md` and `LOOP/lanes/general-sd-regression/checkpoint.md` record partial gate evidence and continuation state. `docs/dev-log/check-log.d/2026-10-20-poisson-animal-pedigree-sd.md`, `docs/dev-log/check-log.md`, and this report record the checks.

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "poisson-animal-pedigree-sd-regression")'`: 11 assertions passed, with no warnings, failures, or skips.
- The first run caught an output-order mismatch. Source tracing showed predictions use the structured group registry's node labels. The final test checks the names as a set and checks each predicted SD against its group predictor by name.
- Independent static review passed the DGP, name-keyed prediction checks, and covariance ordering; the sparse precision comparison additionally checks pedigree precision against the dense covariance inverse. The combined animal, relatedness-matrix, and grammar regression set passed 95 assertions with one existing `sd_phylo()` deprecation warning, no failures, and no skips. `pkgdown::check_pkgdown()` found no problems. `check-after-task.R` passed the report structure check; its acceptance-ledger verification exited nonzero because the programme still has 11 unrelated unmet gates. `graft build` refreshed 29,642 nodes and 58,167 edges.

## 6. Tests of the Tests

The first run failed because the expected names used factor order, while prediction used pedigree-node order. The groups and values were present; their order differed. After tracing the registry, the test now matches values by group name and checks the non-identity factor ordering explicitly. A separate sparse-versus-dense precision assertion protects the covariance ordering used by the DGP and fit.

## 7a. Issue Ledger

No GitHub issue was changed. The earlier read-only search for animal-model SD work found no matching open issue.

## 8. Consistency Audit

The latent draw uses `t(chol(A)) %*% rnorm(n)` with elementwise group scaling `exp(W alpha)`, so the generated covariance is `D A D`. The formula target is `sd_animal(id)`, and predictions are checked against the fitted group-level SD regression after matching by animal labels. The test does not change covariance scaling or formula syntax.

## 9. What Did Not Go Smoothly

The initial prediction assertion assumed the result would be ordered by factor levels. The fitted pedigree route retains node-label order. The keyed comparison is explicit about that ordering distinction and does not rely on vector position.

## 10. Known Residuals

This is one seeded point-recovery and constant-SD equivalence test. It does not establish interval calibration, pedigree-builder edge cases, additional animal effect shapes, other response families, Julia parity, or general structured-provider support.

## 11. Team Learning

For structured predictions, tests should check group identity and values by names whenever provider node order can differ from data factor order.

## 12. Cross-Product Coverage

This slice covers native R/TMB Poisson with standard Laplace fitting and complete predictor data. It does NOT cover Julia, cross-engine parity, REML, penalized fits, missing-predictor handling, pedigree edge cases, other animal effect shapes, interval calibration, or other response families. The general predictor-dependent-SD goal remains active.

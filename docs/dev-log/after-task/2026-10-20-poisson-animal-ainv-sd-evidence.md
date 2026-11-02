# After Task: Poisson animal SD regression with precision input

## 1. Goal

Add direct-SD point-recovery evidence for the existing native Poisson animal q1 intercept when users supply the inverse relationship matrix through `Ainv`.

## 2. Implemented

A seeded test now fits `animal(1 | id, Ainv = Q)` with `sd(id, level = "animal") ~ z`. It verifies the named precision matrix has a non-identity order, recovers the generating SD slope within the declared tolerance, returns group-level SD predictions, and reproduces the existing constant-SD likelihood.

No production likelihood or builder code changed. The existing known-precision path admitted the fit.

## 3a. Decisions and Rejected Alternatives

The fixture generates the latent effects from a named relationship covariance `A`, then supplies `Q = solve(A)` to the fitted model. Both matrices retain a non-invariant interleaved group order, which makes label alignment observable. The test compares the constant-SD formula with the same animal model without an SD formula. A new likelihood implementation was unnecessary because the existing precision path passed this comparison.

## 4. Files Touched

- `tests/testthat/test-poisson-animal-ainv-sd-regression.R` adds the synthetic recovery and equivalence test.
- `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`, and `docs/dev-log/general-sd-regression/inventory.md` describe the tested input and its limits.
- `docs/dev-log/check-log.d/2026-10-20-poisson-animal-ainv-sd.md`, `docs/dev-log/check-log.md`, and this report record the check.

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "poisson-animal-ainv-sd-regression")'`: 10 assertions passed, with no warnings, failures, or skips.
- Final combined filter `devtools::test(filter = "poisson-animal-ainv-sd-regression|poisson-animal-sd-regression|binomial-animal-sd-regression|poisson-relmat-sd-regression|sd-level-grammar")`: 84 assertions passed, with one existing `sd_phylo()` deprecation-throttle warning and no failures or skips.
- `graft build` refreshed the repository graph to 29,640 nodes and 58,164 edges. Scoped whitespace checks and the required prose check passed for both after-task reports and the new check-log entry.
- `pkgdown::check_pkgdown()` found no problems; Pandoc emitted its existing `--mathml` deprecation warnings.
- Independent static review passed the DGP, precision-matrix alignment, named ordering, and constant-SD equivalence. It recommended locking the non-identity ordering with assertions; those assertions were added and the test rerun successfully.
- The required numbered report structure passed. The full after-task checker returned nonzero because the shared general-SD acceptance ledger still has 11 open gates across other families and engine routes; this evidence slice does not close them.
- The live Julia engine did not run.

## 6. Tests of the Tests

The first run failed before fitting because `Q` existed only inside the fixture result, not in the formula's calling environment. Binding `Q <- fx$Q` in the test resolved the lookup. The final test explicitly checks that the precision matrix names differ from the data factor order and that row and column names match.

## 7a. Issue Ledger

No GitHub issue was changed. The earlier read-only search for animal-model SD work found no matching open issue.

## 8. Consistency Audit

The generated latent field has covariance `D A D`; the model receives `Q = solve(A)` as the animal precision. Public output uses `sd_animal(id)` and group predictions are named by the data factor levels. This test adds a narrow native Poisson precision-input evidence cell; it does not alter the family or formula grammar.

## 9. What Did Not Go Smoothly

The initial test run exposed the model formula's calling-environment lookup for matrix inputs. The fixture output alone does not create a symbol in that environment, so the test now binds the precision matrix locally before fitting.

## 10. Known Residuals

This is one seeded point-recovery and constant-SD equivalence test. It does not establish interval calibration, pedigree-built inputs, animal slopes or blocks, other response families, Julia parity, or general precision-provider support.

## 11. Team Learning

Precision-input tests should assert matrix labels differ from the observation factor order, so later fixture edits cannot silently remove the alignment challenge.

## 12. Cross-Product Coverage

The test exercises native R/TMB Poisson with standard Laplace fitting and complete predictor data. It does NOT cover Julia, cross-engine parity, REML, penalized fits, missing-predictor handling, pedigree-built inputs, other animal providers, or interval calibration. The general predictor-dependent-SD goal remains active.

# After Task: Binomial animal SD regression from pedigree

## 1. Goal

Verify one native binomial animal random-intercept model with pedigree input and a predictor-dependent latent SD.

## 2. Implemented

Added a seeded binary-response fixture with a nontrivial additive relationship matrix. The test simulates latent animal effects with covariance D A D, fits the pedigree animal intercept with a predictor-dependent SD formula, and checks the sparse precision against the dense inverse, log-SD slope recovery, name-keyed group SD predictions, and constant-SD likelihood equivalence. No production source changed.

## 3a. Decisions and Rejected Alternatives

The DGP uses a dense pedigree relationship matrix while the fitted model constructs sparse precision from the pedigree. The two routes are checked numerically after matching labels. Predictions are compared by animal name because pedigree node order and data factor order differ.

## 4. Files Touched

- The new test file adds the synthetic fit and recovery test.
- The inventory records the new family-provider evidence.
- The gate ledger, focused check log, main check log, this report, and goal checkpoint record its scope and checks.

## 5. Checks Run

- The focused test passed all 10 assertions with no warnings, failures, or skips.
- The fit converged, and the recovered log-SD slope was within the fixed test tolerance of 0.25 from truth 0.35.
- Independent static review passed the DGP ordering, precision oracle, recovery test, keyed predictions, and constant-SD comparison.
- The combined animal, relatedness-matrix, and grammar regression set passed 105 assertions with one existing sd_phylo() deprecation warning, no failures, and no skips. It ran no live Julia test.
- pkgdown::check_pkgdown() found no problems. The after-task structure check passed; the full acceptance check remains nonzero because 11 programme-wide gates are still open.

## 6. Tests of the Tests

The fixture asserts that data factor order differs from pedigree labels. Its precision assertion reorders the sparse matrix by names before comparison to the dense covariance inverse. Recovery and prediction are checked against the known group-level SD design, and the constant formula is compared with the existing constant-SD model likelihood.

## 7a. Issue Ledger

No GitHub issue was changed.

## 8. Consistency Audit

The latent effects are drawn as a pedigree-correlated Gaussian vector scaled by exp(alpha_0 + alpha_1 z_g). The response probability is logistic in fixed effects plus the latent animal effect. The model uses a binomial likelihood and the same group-level log-SD predictor. The public syntax is already defined by the existing animal and SD formula grammar.

## 9. What Did Not Go Smoothly

The focused fit completed on the first run. No production code change was needed for this tested combination.

## 10. Known Residuals

This is one seeded point-recovery cell. It does not establish profile or bootstrap interval coverage, all animal provider inputs, other animal effect shapes, missing-predictor behavior, Julia support, or general cross-engine parity.

## 11. Team Learning

Using the dense covariance for the DGP and the package sparse pedigree precision for fitting gives a useful numerical check of the provider mapping within this tested route.

## 12. Cross-Product Coverage

This slice covers native binomial with one q1 animal intercept, pedigree input, complete predictor data, and standard Laplace fitting. It does NOT cover Julia, cross-engine parity, interval calibration, other animal effect shapes, other response families, or arbitrary structured-effect combinations. The general predictor-dependent-SD goal remains active.

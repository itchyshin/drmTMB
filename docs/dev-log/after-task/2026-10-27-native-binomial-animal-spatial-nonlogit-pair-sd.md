# After Task: Native Binomial animal and spatial SD regression

## 1. Goal

Verify the current native Binomial animal plus coordinate-spatial pair with separate predictor-dependent SDs under probit and complementary log-log links.

## 2. Implemented

Added an independent synthetic recovery test for the two non-logit links. Each fit checks convergence, direction and broad magnitude of both log-SD slopes, named animal and spatial SD predictions, and binary marginal simulation. No model-builder or TMB likelihood edit was needed for this evidence slice.

## 3a. Decisions and Rejected Alternatives

Reused the existing q1 additive provider route and its supplied covariance scaling. Kept the two link fits in a new focused test rather than expanding the slower logit input-equivalence test. Interval-coverage validation remains deferred under the approved implementation-first scope.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-spatial-nonlogit-pair-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-spatial-nonlogit-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- This after-task report and the paired check log.

## 5. Checks Run

- Focused native test: 16 expectations passed for probit and cloglog, with no failures or warnings.
- Evidence reconciliation passed: 19,678 candidate rows, 147 linked rows, 19,531 unlinked rows, and 167 evidence records.
- Source manifest pins the R builder, TMB source, and test file; the run transcript is retained beside it.
- No full R suite, full pkgdown build, live Julia run, or interval-coverage campaign was run.

## 6. Tests of the Tests

The test constructs independent animal and spatial latent fields from their covariance matrices and generates link-matched binary responses. It would detect a rejected pair, optimizer failure, wrong SD-slope direction or broad recovery, unlabelled/misaligned predictions, and invalid simulation output. The first attempt exposed an unsupported `info` argument in this testthat version; removing only that argument allowed the model assertions to run.

## 7a. Issue Ledger

No GitHub issue was changed. Two existing required-row candidates, probit and cloglog for animal A covariance plus coordinate-spatial provider pairs, now have hash-verified recovery records. Both remain unreviewed.

## 8. Consistency Audit

The formula targets are `sd_animal(animal_id)` and `sd_spatial(site)`, with one predictor per provider. The synthetic DGP uses the same animal covariance and coordinate-spatial precision pathways as the fit. These results support only the two native link cells tested.

## 9. What Did Not Go Smoothly

The first test run stopped at a testthat API mismatch after fitting the first link. That was a test harness error, not a model failure. The corrected run passed both links. The earlier phylo-plus-spatial ledger records were also found to attach probit and cloglog evidence IDs to the logit candidate; their row keys and source receipt were corrected and reconciled before this slice was recorded.

## 10. Known Residuals

This is one fixed-seed synthetic design per link, not a recovery grid or uncertainty-calibration result. It does not cover Julia parity, other animal input forms under these links, other provider pairs, or other response families. The general SD goal remains active.

## 11. Team Learning

Verify the full evidence-row key, not only its human-readable evidence ID; a link name in an ID does not prove the row was attached to that link. Check testthat assertion signatures in the installed version before attributing a test failure to model code.

## 12. Cross-Product Coverage

- Family: Bernoulli/Binomial.
- Engine: native R/TMB.
- Endpoint: `mu`.
- Links: probit and complementary log-log.
- Effects: one animal A-covariance intercept plus one coordinate-spatial intercept, each with its own SD regression.
- Data: independently generated synthetic outcomes with fixed seeds.
- This slice does NOT cover Julia, interval coverage, other animal representations, other provider pairs, or other families.

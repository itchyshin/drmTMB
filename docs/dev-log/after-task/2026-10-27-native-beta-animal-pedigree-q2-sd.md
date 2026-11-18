# After task: Beta pedigree intercept and slope SDs

## 1. Goal

Fit separate predictor-dependent SDs for independent animal intercept and numeric-slope fields in a native Beta model, using a pedigree with unobserved ancestors.

## 2. Implemented

Two R provider gates now admit pedigree input alongside supplied A and Ainv. The existing coefficient-specific native loading and extraction need no C++ change or rebuild. Complete-response and sigma-without-random-effects boundaries remain in place. Each field has covariance D_k A D_k, with D_k defined by its selected group SD formula. The Beta mean adjustment and precision phi=sigma^-2 are unchanged.

## 3a. Decisions and Rejected Alternatives

The test generates the relationship matrix independently by parent recursion, draws two independent full-pedigree fields, and observes offspring only. The dense likelihood oracle integrates ancestors using the observed covariance submatrix before inversion. A submatrix of full precision would condition on ancestors and test a different model. The fixture uses unrelated founders and full-sib offspring; no inbred or single-known-parent pedigree claim is made. Assumptions without asking: the established .4 point-recovery tolerance and 1e-4 absolute numerical tolerances are retained from the preceding A/Ainv slice. They were recorded before fitting.

## 4. Files Touched

The implementation changes R/drmTMB.R only. The existing test-beta-animal-q2-sd-regression.R replaces its pedigree refusal with positive assembly coverage. The final comment in inst/examples/beta-animal-q2-sd.R now points to the new pedigree example. New files are tests/testthat/test-beta-animal-pedigree-q2-sd-regression.R, inst/examples/beta-animal-pedigree-q2-sd.R, this report, docs/dev-log/check-log.d/2026-10-27-native-beta-animal-pedigree-q2-sd.md and the bounded evidence directory under docs/dev-log/general-sd-regression/evidence/native-beta-animal-pedigree-q2-sd-20261027/. Foreign dirty changes were preserved; no compiled artifact changed.

## 5. Checks Run

The focused test passed 32 expectations with zero failures or errors in 31.088 seconds. The standalone example converged in 8.683 seconds. Its estimated SD slopes were 0.4421660 and -0.3842006, with synthetic truths 0.5 and -0.5. These are one-seed point-fit checks, not general recovery or coverage evidence. The six-file neighboring regression passed 194 expectations with zero failures, errors, warnings or skips in 166.220 seconds, within its 210-second estimate. No full package check, Julia process, interval calibration or pkgdown build ran in this slice.

## 6. Tests of the Tests

Before implementation both new tests failed at the supplied-A/Ainv refusal. The final tests compare pedigree with independently permuted full A and full Ainv providers. The absolute dense Laplace likelihood and conditional predictor checks include the ancestor integration constant. Analytic score and Hessian are checked by finite differences, and two independent mode starts must agree. Raw ancestor values remain finite while scaled ancestor values are NA without ancestor SD predictors. Named offspring SD predictions and save/reload are exercised.

## 7a. Issue Ledger

This closes the bounded implementation gap represented by the native Beta mu animal numeric-slope pedigree candidate. Candidate rows are saved, not promoted in the shared evidence ledger. The broader SD programme and separate sigma endpoint remain open. No issue was closed or external message posted.

## 8. Consistency Audit

The two admission gates and shared q2 field loading were checked together. Parent review found no P0/P1 issue in the scoped mathematical contract or R patch. The prior A/Ainv tests remain in the neighboring regression. Whole-tree diff checking found an unrelated trailing blank line in test-binomial-sd-integration.R; this file was left untouched. The stale pedigree-refusal comment in the original A/Ainv example now points to the new example. Its earlier source-bound receipt remains immutable and describes the preceding source snapshot.

Memory receipt: the routed drmTMB LOAD-FIRST manifest, on-disk graph map and relevant test cards, and the handoff/receipt informed the slice. The independent covariance/oracle rule shaped the tests. No expensive sister-repository scouting was repeated. Golden-Set check was not run; the existing Beta numerical oracle was reused and exercised.

## 9. What Did Not Go Smoothly

Path preflight and lease registry checks took minutes. The scoped lease was reconciled with the parent's canonical R ownership before edits. The first row query used the wrong column name and returned no matches; the corrected family_route query confirmed the exact mu row and excluded sigma. No fit failure required changing the fixture, seed or tolerance.

## 10. Known Residuals

The fixture has 16 unrelated founder pairs, 64 observed offspring and 20 observations per offspring. No inbreeding, single-known-parent, weighted or missing-response validation is established here. Constant-SD pedigree equivalence was not freshly fitted in this slice; A/Ainv constant-SD and q1 pedigree regressions are neighboring evidence. Marginal q2 simulation, interval workflows, calibration, Julia parity and whole-programme completion remain open. The checkout retains extensive shared development edits; no release was made.

## 11. Team Learning

An unobserved ancestor has a latent standardized field value even when its SD regression predictors are unavailable. Preserve that latent value, return NA for its scaled effect, and integrate it through the observed covariance when building an independent likelihood oracle.

## 12. Cross-Product Coverage

This slice covers native Beta mu complete-data point fitting with one independent animal intercept and one numeric slope, group-constant selected SD predictors, and pedigree input. Tests exercise equivalent full covariance/precision providers, ancestor integration, extraction, named SD predictions, conditional means through eta and save/reload. It does NOT cover sigma random effects, correlated labelled blocks, multiple slopes, extra random layers, fresh marginal simulation, new-data prediction, Julia parity, coverage calibration or release checks.

## 13. Prose Assessment

The separate exact-draft assessment is retained in the evidence directory. Science and facts are limited to the saved tests and example. No external reference claim is made.

# After-task: native cloglog phylogenetic SD recovery smoke

## 1. Goal

Give package contributors a deterministic check of predictor-dependent phylogenetic random-intercept SDs for Bernoulli responses with the cloglog link.

## 2. Implemented

Added one synthetic test with 80 tips and 24 binary observations per tip. Its 14 expectations check optimizer flags, directional SD-slope recovery, fitted-row and shuffled new-data predictions, and equivalence between an intercept-only SD formula and the existing scalar-SD model. Model implementation was unchanged.

## 3a. Decisions and Rejected Alternatives

Use a new test file to avoid leased builders and existing tests. Keep the original seed and slope tolerance: truth is 0.5 and absolute error must be below 0.35, with positive sign. This is a broad directional recovery smoke, not repeated-simulation recovery evidence.

## 3. Mathematical Contract

The latent tip field has covariance `D A D`, where `A` is the existing raw tree covariance and `D` contains `exp(log(0.4) + 0.5 * z_species)`. The Bernoulli probability is the cloglog inverse of the location predictor. The fitted formula is `sd(species, level = "phylogenetic") ~ z_species`; its predictor is constant within tip. Predicted SDs describe the kernel multiplier.

## 4. Files Touched

- `tests/testthat/test-binomial-cloglog-phylo-sd-regression.R`.
- `docs/dev-log/general-sd-regression/evidence/native-cloglog-phylo-sd-20261026/`.
- This report and `docs/dev-log/check-log.d/2026-10-26-native-cloglog-phylo-sd.md`.

## 5. Checks Run

`Rscript -e 'devtools::test(filter = "binomial-cloglog-phylo-sd-regression", reporter = "summary", stop_on_failure = TRUE)'` passed three times. The retained rerun exited 0 with 14 expectations and took about 17 seconds including evidence capture. The four-file before/after manifest matched for the test, `R/drmTMB.R`, `src/drmTMB.cpp`, and `DESCRIPTION`. See the evidence directory for output and hashes. Julia was not exercised.

## 6. Tests of the Tests

An independent read-only reviewer confirmed the Cholesky construction gives covariance `A`, tip scaling gives `D A D`, and the generated link matches the fitted cloglog link. Prediction checks compare against an explicit model matrix with varying tip predictors. Constant-SD equivalence compares both log likelihood and SD estimates across two formula routes. The test combines SD regression with the existing phylogenetic and link machinery; no deliberate mutation test was run.

## 7a. Issue Ledger

Read-only `gh issue list --state open --search 'phylogenetic SD cloglog' --limit 5 --json number,title,url` returned tracker #1464. No issue or public capability claim was changed for this test-only slice.

## 8. Consistency Audit

Reviewed `rg -n 'cloglog|phylogenetic.*SD|SD.*phylogenetic' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. No formula grammar or model behavior changed, so design documents, NEWS, tutorials, and pkgdown navigation require no change for this slice. New-data predictions are checked after shuffling requested tip rows, so the assertion also detects predictor-to-tip ordering errors. Existing historical entries remain historical.

## 9. What Did Not Go Smoothly

The shared check log has 451 divergent refs. Extending the lease to the shared checkpoint was refused because another active lane owns it. A separate check-log shard records this result. Neither shared file was edited.

## 10. Known Residuals

The test checks raw optimizer flags with standard errors disabled. It does not establish Hessian quality or calibrated inference. The Julia probit phylogenetic profile failure remains open in the wider programme. Coverage calibration remains deferred under the user's implementation-first direction.

## 11. Team Learning

An unleased test-only row can advance evidence while shared fitters are owned elsewhere. Preserve the independent covariance calculation and describe broad fixed-seed recovery tolerances plainly.

## 12. Cross-Product Coverage

Covers native TMB Bernoulli cloglog phylogenetic random-intercept SD regression with one continuous tip predictor, fitted-row and shuffled new-data SD predictions, and constant-SD equivalence. This slice does NOT cover Julia parity, random slopes, other kernels or families, profiles, bootstrap, or interval coverage. The full goal remains active.

## 13. Prose Assessment

Independent technical report, whole-draft review: perceived AI-like style 3/10, moderate confidence. The fixed protocol headings add repetition; the numerical scope and explicit limitations keep the claims concrete. Scientific and factual gates pass within the retained test and source-manifest evidence; external reference gate is not applicable. Formal exact-draft assessment: NOTASSESSED.

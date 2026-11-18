# After Task: Binomial animal and relmat kernel equivalence

## 1. Goal

Check native Bernoulli SD-regression fits across equivalent animal and relatedness-matrix input forms under probit and complementary log-log links.

## 2. Implemented

Added one deterministic same-data test covering animal `A`, `Ainv`, and pedigree input crossed with relmat covariance `K` and precision `Q`. It compares convergence, marginal log likelihood, SD coefficient vectors, and named SD predictions against `A + K` for both links. No model-builder or likelihood source code changed.

## 3a. Decisions and Rejected Alternatives

The test uses input equivalence rather than a second recovery campaign. `Ainv` is generated from the same `A`, and `Q` from the same `K`; the DGP uses the corresponding covariance matrices. No collaborator data or examples are used. The run is a light implementation check, not calibration.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-relmat-kernel-equivalence-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-relmat-kernel-nonlogit-20261027/`
- `docs/dev-log/after-task/2026-10-27-native-binomial-animal-relmat-kernel-nonlogit-sd.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-animal-relmat-kernel-nonlogit-sd.md`

## 5. Checks Run

- Focused test run 1: 62 expectations passed, 0 failures, 0 warnings, 0 skips; 135.2 seconds.
- Captured focused rerun: exit 0 with testthat `DONE` marker.
- Five-file source manifest: every SHA-256 value matched after the captured run.
- Evidence reconciler: passed with 19,678 candidate rows, 135 linked rows, 19,543 unlinked rows, and 157 evidence records.
- Standard status-inventory searches covered README, roadmap, NEWS, known limitations, formula grammar, formula vignette, and pkgdown configuration. Exact patterns were `rg "meta_gaussian|tau ~|rho ~|meta_known_V\\\\([^V]|meta_known_V\\\\(V = V\\\\).*(current|preferred|stable|default)" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml` and `rg "rho12|sigma1|sigma2|sd\\\\(" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`.
- After-task structure check passed. The gate runner is unavailable, so its state is UNKNOWN.
- Prose check: 0 findings. Targeted whitespace checks passed.
- Full package tests, pkgdown build, and Julia live tests were not run.

## 6. Tests of the Tests

The test combines the new SD formulas with existing animal and relmat structured effects and compares six equivalent input forms on matched data. It would detect changes in likelihood, coefficients, or named predictions caused by covariance-input ordering or inverse-matrix handling. No malformed-input test was added because this test adds no input rule.

## 7a. Issue Ledger

Searched open GitHub issues for `random effect SD`. The broad Phase 18 simulation and profile-likelihood issues do not track this narrow covariance-input equivalence check, so no issue was changed.

## 8. Consistency Audit

The test and receipt describe only native Binomial probit and complementary log-log fits with additive animal and relmat latent fields. No package support, documentation, formula grammar, likelihood, or NEWS claims changed. Julia parity and interval calibration remain unestablished for this cell.

## 9. What Did Not Go Smoothly

The first successful run was not captured to disk, so the same bounded test was run a second time to retain its console transcript. The shared lane preflight also reports duplicate numbered design-document slots across refs; this slice adds no numbered design document. The direct-SD evidence ledger now links eight newly tested rows, after exact-path preflight and a scoped lease.

## 10. Known Residuals

These are matched-fit input-equivalence checks from one synthetic fixture per link. They do not establish recovery accuracy or uncertainty calibration. Only native R/TMB was exercised. The evidence reconciler passes and eight input-combination rows are linked. The rows remain unreviewed.

## 11. Team Learning

Capture the focused transcript on its first run. For structured input variants, generate `Ainv` and `Q` directly from the exact covariance matrices used by the DGP, then compare label-aligned predictions as well as likelihoods.

## 12. Cross-Product Coverage

- Response family: Binomial.
- Engine: native R/TMB.
- Endpoint: `mu`.
- Links: probit and complementary log-log.
- Random effects: two additive independent scalar fields, animal plus relmat, each with predictor-dependent SD.
- Input representations: animal `A`, `Ainv`, and pedigree; relmat `K` and `Q`.
- Fits: six input combinations per link, twelve total.
- Data: independently generated synthetic data.
- This slice does NOT cover Julia, other families, other random-effect types, interval calibration, or independent coefficient-recovery targets.

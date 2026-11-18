# After Task: Julia Binomial animal-slope Ainv bridge under logit

## 1. Goal

Add a focused cross-engine check for the Julia Binomial animal numeric-slope SD route with supplied `Ainv` under logit.

## 2. Implemented

Added a fixed-seed synthetic bridge test comparing native TMB and Julia on the same generated responses. The test checks route and payload mapping, convergence, SD-slope recovery, log likelihood, and fitted group-SD predictions. Linked the exact native and Julia candidate rows to a source-bound receipt. Existing formula and limitation documentation now names logit alongside probit and cloglog for this route.

## 3a. Decisions and Rejected Alternatives

The Julia route and R bridge admission were already implemented. This slice adds an independent logit fixture and native comparison rather than changing likelihood code. `Ainv` is computed from the same relationship covariance used by the DGP. The candidate stays unresolved pending review; this point-fit comparison does not qualify interval calibration or coverage.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-slope-Ainv-logit-sd-bridge.R`
- `NEWS.md`, `README.md`, `docs/design/01-formula-grammar.md`, `docs/dev-log/known-limitations.md`, and `vignettes/formula-grammar.Rmd`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and generated summary
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-slope-Ainv-logit-bridge-live-20261029/`
- `docs/dev-log/check-log.md`, its detailed shard, the lane checkpoint, and this report

## 5. Checks Run

The live focused bridge test passed on macOS with Julia 1.10.0. Its exact command and test log are recorded in the evidence receipt. The fixture checks log-SD slope recovery within 0.5 of truth, cross-engine log-likelihood agreement within 0.1, and group-SD agreement within 0.2. The evidence reconciler passed with 20,350 candidate rows, 195 linked rows, 20,155 unlinked rows, and 218 evidence records. The exact source manifest verifies. `pkgdown::check_pkgdown()` found no problems; it emitted existing Pandoc `--mathml` deprecation warnings. Scoped `git diff --check` passed for this slice. The package-wide check reports an unrelated trailing blank line in `tests/testthat/test-binomial-sd-integration.R`.

## 6. Tests of the Tests

The fixture generates correlated animal slopes with covariance `D A D`, derives `Ainv` from that same `A`, and fits both engines on identical observations. Assertions separately cover route selection, convergence, coefficient recovery, likelihood, and named fitted SD values.

## 7a. Issue Ledger

No issue was created or changed. The focused bridge test is the regression guard for this route.

## 8. Consistency Audit

Logit, probit, and cloglog are now named for this specific Julia animal numeric-slope `Ainv` route in user-facing limitations and formula documentation. This does not imply support for animal pedigree, every animal layout, other providers, or all Binomial combinations. Evidence rows remain unreviewed and no capability status is promoted.

## 9. What Did Not Go Smoothly

The package candidate contains substantial concurrent changes. The package-wide whitespace check therefore reports an unrelated existing issue; this slice was checked by exact source hashes and focused paths.

## 10. Known Residuals

This is one synthetic logit fixture and one animal slope-only layout. It does not establish coverage, interval calibration, pedigree bridge parity, or broad Julia parity. The overall SD goal remains active.

## 11. Team Learning

When the bridge admits multiple links for one structured route, give each link a source-bound same-data comparison and keep those receipts separate from review or support promotion.

Memory receipt: `MEMORY.md:2-5` and `MEMORY.md:55-56`; I kept the candidate evidence and coverage claims bounded. Golden Set: not run; no matching registered case applied. Prose assessment: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-slope-Ainv-logit-bridge.assessment.json`.

## 12. Cross-Product Coverage

Covers one current-candidate native R/TMB and R-to-Julia Binomial animal numeric-slope `Ainv` model under logit, using fixed-seed synthetic data and point/output comparisons.

Does not cover interval calibration, coverage, pedigree, other providers, full package checks, or general parity.

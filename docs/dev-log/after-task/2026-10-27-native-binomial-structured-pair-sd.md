# After Task: Native Binomial structured-pair SD regression

## 1. Goal

Extend native TMB Binomial predictor-dependent SD regression to q1 animal plus relatedness and animal plus coordinate-spatial intercept pairs, and check the existing phylogenetic-tree plus coordinate-spatial pair under probit and cloglog links.

## 2. Implemented

The Binomial builder now admits three exact q1 provider pairs: phylogenetic tree plus coordinate spatial, animal plus relatedness covariance, and animal plus coordinate spatial. Each pair has separate predictor-dependent SD formulas. Probit and cloglog tests extend the phylogenetic plus coordinate-spatial pair. For animal plus spatial, tests cover A covariance, equivalent A-inverse precision, and pedigree inputs. The generic TMB second-field likelihood was already in place, so no C++ likelihood changes were needed.

## 3a. Decisions and Rejected Alternatives

The two providers remain independent latent fields with their existing kernel scales. This slice admits exactly the tested phylo plus spatial, animal plus relatedness, and animal plus spatial pairs. It does not generalize pair admission to other provider combinations or alter the TMB likelihood.

## 3. Mathematical Contract

Each pair contains two independent latent fields, each with its supplied covariance scaling. Their log SDs use separate fixed-predictor designs. Binary outcomes use the selected link. Each SD predictor is constant within its corresponding group. The animal plus relatedness test permutes matrix order to check group-label alignment.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-binomial-phylo-spatial-sd.R`
- `tools/general-sd-regression/universe.py`
- `tools/general-sd-regression/tests/test_universe.py`
- `docs/dev-log/general-sd-regression/required-rows.tsv`
- `docs/dev-log/general-sd-regression/required-universe.md`
- `docs/dev-log/general-sd-regression/universe-contract.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-structured-pair-sd-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-structured-pair-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-spatial-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0. The focused test file produced 60 passing expectations with no failures or warnings. The console output and SHA-256 source manifest are retained in the evidence folder.

`python3 tools/general-sd-regression/tests/test_universe.py` passed all 21 tests. The generated denominator and summary report 19,678 rows after adding the three animal-input plus coordinate-spatial pair candidates. `python3 tools/general-sd-regression/reconcile_evidence.py` passed with 95 linked rows and 117 evidence records.

The evidence reconciler linked the same source-bound run to the native logit/probit/cloglog phylo-spatial rows, the native logit animal-relmat row, and the native logit animal-spatial row. Scoped `git diff --check` passed for this slice. The workspace-wide check reports a trailing blank line in another modified Binomial integration test, which was left untouched. The report structure check passed; the aggregate acceptance ledger remains unknown because its runner dependencies are unavailable.

The finite provider-pair candidate set now includes animal plus coordinate-spatial inputs because that native route is implemented and tested here. The generated universe expands this pair across its declared families, links, engines, and endpoints: the denominator is 19,678 rows, an increase of 336. The Julia rows remain obligations and do not imply Julia support. The universe generator suite passed all 21 tests after updating the explicit pair and blocked-row counts.

An adjacent animal/relatedness regression filter reached an existing test that explicitly fits with `engine = "julia"`, then failed because this test process had no `DRMODELS_JL_PATH`. Three Julia bridge tests skipped because no engine was configured. The adjacent command is not a clean suite pass and gives no new parity result.

## 6. Tests of the Tests

The first non-logit run exposed that the installed testthat version does not accept `info` in `expect_lt()`. After correcting the assertion, the animal plus relatedness fit failed at the intended builder guard. The animal plus spatial route also failed at that guard. Its first 36-site recovery fixture converged but placed the spatial SD slope at a boundary. Increasing the number of sites to 72 improved information and passed the original recovery bound; I did not relax the bound. The final focused run checks convergence, both SD slope recovery bounds, coefficient target names, profile-index separation, group SD predictions, and group-level SD output lengths.

## 7a. Issue Ledger

No issue was opened or changed. The active general SD goal tracks broader family and provider work.

## 8. Consistency Audit

The source builder admits q1 `phylo()` plus coordinate `spatial()`, q1 `animal()` plus `relmat()`, and q1 `animal()` plus coordinate `spatial()` pairs, each with two matching direct-SD formulas. The route rejects missing responses, ordinary random effects, and mesh fields for these pairs. The C++ pair machinery is unchanged. No full-site render or package-wide documentation scan was run because the active documentation-audit lane is already reconciling public claims; I sent it the exact tested scope and evidence path.

## 9. What Did Not Go Smoothly

The initial logged run stopped on a testthat API mismatch after the probit model had fitted. The corrected run passed. The animal plus relatedness test then exposed the intended admission gap before implementation. Some lane-preflight commands stalled during their repository-wide census; no unrelated process was stopped and no source ownership was inferred from an incomplete census.

## 11. Team Learning

When an existing family route is expected to be link-generic, use link-matched synthetic outcomes to verify the likelihood path. Keep these tests distinct from same-data Julia parity and interval calibration.

## 10. Known Residuals

The tested scope is complete-data q1 intercept pairs: tree plus coordinate spatial under logit, probit, and cloglog; animal covariance plus relatedness covariance under logit; and animal pedigree, covariance, or precision plus coordinate spatial under logit. Other structured provider pairs, mesh fields, slopes, correlated fields, incomplete responses, Julia parity, and other response families remain open. Interval coverage is unvalidated and deferred. Public documentation still needs to reflect the exact tested scope through the documentation-audit lane.

## 12. Cross-Product Coverage

This covers native R/TMB Binomial `mu` q1 provider pairs for complete data: phylogenetic plus coordinate-spatial intercepts under logit/probit/cloglog, animal plus relatedness intercepts under logit, and pedigree/A/A-inverse animal plus coordinate-spatial intercepts under logit. It does not cover Julia, interval calibration, other pairs, slopes, or other distributions.

## 13. Next Actions

Continue with the next Bernoulli provider pair in the required universe, one exact pair at a time. Keep Julia parity and uncertainty calibration as separate evidence tasks.

# After Task: Julia Poisson SD smoke test

## 1. Goal

Check that Julia Poisson SD fits preserve public target outputs and agree with the native engine on the selected independent-slope and phylogenetic routes.

## 2. Implemented

Corrected the phylogenetic prediction test oracle to calculate expected predictions from the Julia fit's own coefficients. The prior oracle used TMB coefficients with a tighter prediction tolerance than the cross-engine coefficient tolerance allowed.

## 3a. Decisions and Rejected Alternatives

No production model or parameterization changed. The tested routes use predictor-dependent log SDs, `log(tau) = W alpha`; the phylogenetic route preserves the existing raw tree covariance scale. The warning for maximum tree height 2.5 is expected and the test checks the `sqrt(2.5)` scale factor.

## 4. Files Touched

- `tests/testthat/test-julia-poisson-sd.R`
- `docs/dev-log/check-log.d/2026-10-20-general-sd-julia-poisson-smoke.md`
- This report and its assessment record.

## 5. Checks Run

`DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^julia-poisson-sd$", reporter = "summary", stop_on_failure = TRUE)'` passed after the oracle correction: 3 live Julia bridge tests, 5 model fits. The tests cover Julia intercept outputs, native and Julia independent-slope fits on seeded data, and phylogenetic coefficient agreement, tree scale, likelihood, and predicted SDs. One expected warning reports the raw branch-length scale. The first run failed only at the phylogenetic prediction oracle because it used TMB coefficients; the corrected rerun passed.

The after-task structure check passed. The integrated checker exits 1 because the programme ledger still has open parent and child gates; this partial smoke test does not close them. The saved report's prose check found zero issues, and whitespace checks passed for both new Markdown records.

## 6. Tests of the Tests

The first run demonstrated that the prediction assertion detects an inconsistent oracle. The corrected test compares Julia predictions to a model-matrix calculation using Julia coefficients, while separate assertions check cross-engine coefficients and likelihood. The rerun passed.

## 7a. Issue Ledger

Inspected open issue [#1551](https://github.com/itchyshin/drmTMB/issues/1551), which concerns Julia Poisson/Gamma bridge admission and a `resd` coefficient-label failure. This passing smoke test does not establish that the reported issue is resolved across its stated routes, so no issue comment or status change was made.

## 8. Consistency Audit

The correction affects the test only; production code, formula grammar, likelihood, package documentation, NEWS, roadmap, and capability claims are unchanged. Historical notes and capability status remain intact. The targeted wording scan was `rg -n "full.*rejected|block.*rejected|only diagonal|planned.*implemented" README.md docs/dev-log/internal-roadmap.md NEWS.md docs vignettes`; it returned historical and evidence-snapshot matches, with no edits made from this smoke-test slice.

## 9. What Did Not Go Smoothly

The initial test mixed a Julia prediction with TMB coefficients while requiring agreement tighter than the explicit cross-engine coefficient tolerance. The failure was small, about `4e-8`, and exposed a test inconsistency rather than a demonstrated prediction defect.

## 10. Known Residuals

This smoke test does not validate interval coverage, general recovery, or the full Julia family/provider matrix. The Julia candidate worktree is an unsealed source candidate. The overall general SD regression programme remains open.

## 11. Team Learning

For cross-engine prediction tests, compute each engine's expected prediction from that engine's own fitted coefficients. Test coefficient parity separately at its declared tolerance.

## 12. Cross-Product Coverage

This smoke test covers Julia and native TMB for Poisson ordinary independent-slope and phylogenetic SD routes, plus Julia Poisson intercept target output. It does NOT cover Bernoulli, other response families, other random-effect providers or block types, cross-parameter targets, save/reload, profiling, bootstrap refits, or interval-coverage calibration. Continue with the next unowned, bounded SD slice after checking active path ownership; keep coverage validation deferred and do not treat this smoke test as capability-wide evidence.

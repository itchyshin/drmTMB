# After Task: Native lognormal correlated q2 predictor-dependent SD

## Goal

Add predictor-dependent SD formulas for both coefficients in one ordinary correlated lognormal intercept-slope block, then verify recovery and synchronize the user and developer documentation.

## Implemented

The native lognormal builder now admits coefficient-specific SD formulas for the intercept and slope in one complete-data, unlabelled `(1 + x | id)` block. The existing TMB likelihood already applies the coefficient-specific SD rows and retains the shared block correlation, so no likelihood change was needed. The synthetic example uses independent group-level predictors for the intercept and slope SDs. Here `sigma ~ 1` estimates one residual scale shared across observations and adds no random effect on `sigma`.

## Mathematical Contract

For coefficient `j` in group `g`, the SD is `tau[g,j] = exp(W[g,j] %*% alpha[j])`. The block covariance remains `D[g] R D[g]`, with the existing constant within-block correlation parameterization. The response remains lognormal with one estimated residual `sigma` shared across observations; predictors in each SD formula are constant within group. The new test generates the correlated effects from shared standard-normal draws and checks both SD slopes, group SD predictions against the fitted formulas, and likelihood equivalence when both SD formulas are constant.

## Files Changed

The implementation and regression test are in `R/drmTMB.R` and `tests/testthat/test-lognormal-ordinary-correlated-q2.R`. The worked example and status wording were synchronized in `README.md`, `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, `docs/design/59-structural-slope-and-non-gaussian-map.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `vignettes/formula-grammar.Rmd`, `vignettes/model-map.Rmd`, and `vignettes/predictor-dependent-random-sd.Rmd`. The source-bound evidence receipt is in `docs/dev-log/general-sd-regression/evidence/native-lognormal-correlated-q2-sd-20261027/`; its two target links are in `direct-sd-evidence.tsv`, and reconciliation refreshed `direct-sd-evidence-summary.md`. The check log records the exact commands and results.

## Checks Run

The focused lognormal q2 test passed 40 expectations with no failures, warnings, or skips. Both affected vignettes rendered successfully. `pkgdown::check_pkgdown()` found no problems. Independent review found no likelihood or DGP inconsistency; after the prediction checks and wording were corrected, the reviewer confirmed both findings were resolved. Evidence reconciliation passed with 19,678 candidate rows, 161 linked rows, 19,517 unlinked rows, and 181 evidence records. The full pkgdown build was interrupted after 6 minutes 46 seconds because it exceeded the 3-minute estimate; it was in unrelated article rendering, so no full site-build pass is claimed. No full package suite, `R CMD check`, Julia bridge test, or interval calibration was run.

## Tests Of The Tests

Before the resolver change, the new synthetic test failed with the existing lognormal unsupported-shape error. After enabling the narrow q2 resolver flag, it passed. An independent review then found that prediction assertions did not verify target-to-value mapping and that the residual-scale wording was ambiguous. The test now checks prediction names and values against the fitted log-SD formulas, and the vignette states the scope of `sigma ~ 1`; the reviewer confirmed both corrections. The test passed 40 expectations after the fixes. The generated slope and intercept effects use the same standard-normal draw for the intercept and the correlated component of the slope, so the test DGP matches the fitted covariance structure.

## Consistency Audit

The current roadmap, formula grammar, family map, known-limitations text, NEWS, README, and both formula and model-map vignettes now describe this as one native complete-data lognormal q2 route. The predictor-dependent SD vignette shows the formula and synthetic fit. Exact scan: `rg -n -i 'lognormal.*correlated|correlated.*lognormal|correlated slopes' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/59-structural-slope-and-non-gaussian-map.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd vignettes/predictor-dependent-random-sd.Rmd`. The rendered target guides were checked through successful renders. A full pkgdown build remains unverified.

## GitHub Issue Maintenance

The open-issue search `gh issue list --state open --search 'lognormal correlated q2 random-effect SD' --limit 20` returned only unrelated issue #1463, “Test sweep 3 Oct 2026: what passed.” No issue action was needed.

## What Did Not Go Smoothly

The full pkgdown build took longer than the initial 3-minute estimate because it rendered many unrelated articles. I stopped it after 6 minutes 46 seconds and recorded the result as incomplete. Future estimates for a full site build should use the observed duration of the complete article set and account separately for focused vignette renders.

## Team Learning

When extending an existing correlated block, first check whether the likelihood already consumes group-specific SD rows. In this case, the missing piece was narrow target admission; adding a second covariance implementation would have increased risk without adding support. Independent review caught two narrow gaps in output testing and wording. I sent the DRM parity lane the exact native scope and evidence path so its ledger can track Julia parity as a separate open item.

## Known Limitations

This evidence covers only native R/TMB, complete responses, one unlabelled ordinary q2 block, one estimated residual `sigma` shared across observations, and point recovery. It does not establish interval calibration, Julia parity, labelled blocks, structured effects, other response families, or bivariate lognormal models. The required capability rows remain unresolved until the candidate universe and gate statuses are reconciled; this slice does not close the broad SD-regression goal.

## Next Actions

Implement and document the next ordinary family/effect cell from the active capability ledger. Keep Julia parity as a separate coordinated lane and keep interval-coverage work deferred.

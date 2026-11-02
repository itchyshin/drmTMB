# After Task: Native LogNormal sigma random-slope SD

## 1. Goal

Add a narrow native LogNormal route where a fixed predictor changes the SD of one independent random slope on the residual `sigma` predictor. This is one implementation slice in the broader predictor-dependent random-effect SD programme; interval-coverage calibration remains deferred.

## 2. Implemented

The LogNormal builder now admits one independent numeric random slope in `sigma` only when that coefficient has a matching `sd(group, dpar = "sigma", coef = "x") ~ predictors` formula. The `mu` formula must have no random effect, responses must be complete, and SD predictors must be constant within group. An unpaired `sigma` slope, correlated block, or labelled term remains rejected.

The model is `log(sigma_ig) = X_sigma,ig gamma + x_ig u_g`, with `u_g ~ Normal(0, tau_g^2)` and `log(tau_g) = W_g alpha`. The new fixed-seed test passed coefficient recovery, target naming, and group-level SD prediction checks. It also confirms that the `sigma` slope is still refused without its matching SD formula.

## 3a. Decisions and Rejected Alternatives

The change is limited to the LogNormal adapter. The shared positive-continuous `sigma` validator defaults to intercept-only behavior; the LogNormal builder opts into slopes only when an SD formula is present. Gamma behavior is unchanged. No C++ likelihood change was needed because the existing `sigma` random-effect loop already consumes the selected group SD row.

## 4. Files Touched

- `R/drmTMB.R`, `tests/testthat/test-lognormal-sigma-sd-regression.R`
- `R/random-effect-scale-formulas.R`, `man/random_effect_scale_formulas.Rd`
- `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/general-sd-regression/inventory.md`
- `vignettes/predictor-dependent-random-sd.Rmd`, `vignettes/formula-grammar.Rmd`, `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and `evidence/lognormal-sigma-slope-20261025/`
- This after-task report and its assessment record

## 5. Checks Run

- Test-first RED: the new model failed at the existing LogNormal intercept-only validator.
- Focused final test file: 49 expectations passed, with no failures or skips. Source hashes were stable before and after the run.
- `devtools::document()`: passed.
- `pkgdown::check_pkgdown()`: passed with no problems. Existing Pandoc `--mathml` deprecation warnings remain.
- `vignettes/predictor-dependent-random-sd.Rmd`: rendered successfully from this candidate checkout to `/private/tmp/drmtmb-predictor-dependent-random-sd-lognormal-sigma-slope.html`. The first attempt loaded an older installed worktree; the successful rerun explicitly called `devtools::load_all(".")` before rendering.
- `git diff --check` on the scoped files: passed.
- `python3 tools/general-sd-regression/reconcile_evidence.py --root .`: passed with 19,118 candidate rows, 82 receipt records, 63 linked rows, and 19,055 unlinked rows.
- `check-after-task.R`: report structure passed. The separate unlazy acceptance-ledger check found 13 ledgers but could not run its gate checker, so programme gate state remains UNKNOWN and no gate was advanced.
- A targeted stale-wording scan covered `README.md`, the roadmap, known limitations, both formula guides, the random-scale design guide, the predictor-dependent SD tutorial, the `sd()` help, and NEWS. The LogNormal slope claims now match the tested scope; Gamma `sigma` slopes remain listed as unsupported.
- GitHub search for `random effect SD sigma predictor LogNormal`: no matching open issue found; no issue was opened or changed.

## 6. Tests of the Tests

Before the implementation change, the new test failed on the exact intercept-only guard. The passing synthetic test uses a known SD regression and checks that the fitted coefficient names and group-level predictions follow the selected `sigma` slope target. The negative test checks refusal when the matching SD formula is absent. The receipt is marked `unreviewed`; no independent reviewer promoted this candidate row.

## 7a. Issue Ledger

No matching open GitHub issue was found for the LogNormal residual-scale random-slope SD route. No issue was created, edited, or closed.

## 8. Consistency Audit

The formula reference, model design page, family limitation register, roadmap, tutorial, NEWS, and generated help now describe the same narrow admission. The tutorial render exercised the new syntax. The candidate evidence row remains `direct_sd_claim=none`; a receipt links the focused recovery evidence but does not promote capability or close a programme gate.

Exact stale-wording patterns checked: `lognormal.*sigma.*slope`, `sigma.*slope.*lognormal`, `sigma slopes or labels remain unsupported`, and `lognormal/Gamma \`sigma\` slopes`.

## 9. What Did Not Go Smoothly

The first test command used a test-description string where `devtools::test(filter=)` expects a file-name pattern, so it selected no files. The corrected file filter reproduced the intended RED failure and later passed. The first vignette render loaded a stale installed package from another worktree; explicitly loading this checkout fixed it.

## 10. Known Residuals

This is one native point-recovery fixture. It does not establish calibrated intervals, Julia parity, constant-SD likelihood equivalence for the slope form, profile/bootstrap refit routing for this selected slope, or support for other families, structured effects, intercept-plus-slope blocks, labelled covariance, missing data, or bivariate models. The programme remains open. No commit, merge, release, or email was made.

## 11. Team Learning

For vignette renders in a multi-worktree development session, load the intended checkout with `devtools::load_all(".")` before rendering. Otherwise the setup chunk can attach a stale installed copy and report a syntax failure unrelated to the current candidate source.

## 12. Cross-Product Coverage

This slice covers native TMB fitting for one complete-data LogNormal `sigma` random slope with a matching fixed-predictor SD formula, plus coefficient naming and group-SD prediction. It does NOT cover Julia, other response distributions, structured or correlated effects, intercept-plus-slope blocks, bivariate models, missing-data routes, or interval-coverage calibration. The remaining required family/effect/provider/backend rows stay open.

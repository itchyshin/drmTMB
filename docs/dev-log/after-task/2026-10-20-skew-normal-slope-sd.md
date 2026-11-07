# After Task: Native skew-normal independent-slope SD regression

## 1. Goal

Allow a fixed predictor to explain the standard deviation of one ordinary independent skew-normal location slope, with synthetic recovery checks and accurate documentation.

## 2. Implemented

The native skew-normal builder now accepts `sd(id, coef = "x") ~ w` with `(0 + x | id)`. It uses the existing random-effect scale design and model-type-17 likelihood path. Correlated intercept-slope blocks remain rejected. The fit test checks a seeded positive log-SD trend, named target identity, group-specific SD prediction, simulation, and save/reload. The constant-SD form matches the existing constant-SD model.

The convergence checker now omits the inactive placeholder `sd_mu` design matrix when no SD formula is fitted. This prevents ordinary skew-normal fits from being marked rank-deficient because of an unused 1 by 1 zero matrix.

## 3a. Decisions and Rejected Alternatives

- Reused the existing fixed-predictor SD formula and coefficient selector.
- Kept the existing skew-normal likelihood and response parameterization.
- Kept correlated blocks outside this slice because this route only verifies an independent slope target.
- Treated the single seeded recovery fit as implementation evidence, not interval calibration.

Mathematical alignment:

| Symbol | Formula / implementation | Synthetic draw | Check |
| --- | --- | --- | --- |
| `u_g` | `(0 + x | id)` | `rnorm(n_group, sd = exp(-0.6 + 0.4*w_g))` | The fitted slope SD increases over `w` |
| `log(tau_g)` | `sd(id, coef = "x") ~ w` | `-0.6 + 0.4*w_g` | Estimated slope is within 2.5 fitted SE of 0.4 |
| `mu_ig` | `0.2 + 0.3*x_ig + x_ig*u_g` | Same expression | Fit uses the same independent slope |
| residual distribution | `skew_normal(sigma = 0.65, nu = 1.1)` | Public-to-native skew-normal conversion | Fit specifies fixed `sigma` and `nu` |

## 4. Files Touched

- `R/drmTMB.R`
- `R/check.R`
- `tests/testthat/test-skew-normal-sd-regression.R`
- `tests/testthat/test-skew-normal-sd-integration.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/18-random-effect-scale-models.md`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-20-skew-normal-slope-sd.md`

## 5. Checks Run

- Test-first assembly check failed at the scalar-intercept-only gate before enabling the slope selector.
- `Rscript -e 'devtools::test(filter = "skew-normal-sd-regression", reporter = "summary")'` passed after the builder change.
- `Rscript -e 'devtools::test(filter = "skew-normal-sd-integration", reporter = "summary")'` passed after the inactive-design diagnostic fix.
- Final `Rscript -e 'devtools::test(filter = "skew-normal-sd|check-drm|check-conditioning", reporter = "summary")'` passed. One LAPACK-dependent conditioning test skipped because the near-singular case was not reproducible. Warnings were existing `sd_phylo()` deprecations and a conditioning-test `NaNs produced` warning.
- The updated predictor-dependent SD vignette rendered successfully; Pandoc reported its existing deprecated `--mathjax` option.
- `pkgdown::check_pkgdown()` passed with no problems; Pandoc reported its existing `--mathml` deprecation.
- The central after-task structure checker passed. The prose scan reported zero findings.
- The full working-tree `git diff --check` reports one trailing blank line in another lane's `tests/testthat/test-binomial-sd-integration.R`. The focused skew-normal paths contain no reported whitespace error.

## 6. Tests of the Tests

The assembly test failed before the slope allowance was added. The integration test failed before the diagnostic checker excluded the inactive placeholder matrix. The constant-SD likelihood comparison and correlated-block rejection exercise neighbouring behavior and the unsupported boundary.

## 7a. Issue Ledger

Searched open issues with `gh issue list --state open --search 'skew-normal random-effect SD' --limit 20`. The results included the general skew-normal family issue and broad testing/methods issues, but no issue specifically tracking this SD slope. No issue was changed.

## 8. Consistency Audit

The equation, formula, synthetic draw, target selector, fit extraction, and group-SD prediction agree. The formula grammar, random-effect scale design page, NEWS, and predictor-dependent SD vignette describe the scoped native route and retain the wider limitations. The exact status-inventory scan was:

```sh
rg -n -i 'skew.?normal.{0,100}(intercept.only|intercept random effects|random intercepts only|slope.*SD|SD.*slope)|((intercept.only|random intercepts only).{0,100}skew.?normal)' README.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md docs/design/06-distribution-roadmap.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd NEWS.md
```

The README, internal roadmap, known-limitations file, distribution roadmap, and pkgdown navigation did not require a skew-normal-specific edit for this slice. Existing broader program status remains in progress.

## 9. What Did Not Go Smoothly

The first recovery fit exposed a false rank-deficiency diagnostic from the inactive `sd_mu` placeholder. Inspecting the design matrix and convergence checks isolated the cause; the checker now excludes that matrix only when the model has no SD terms. The repository checkout did not contain its task-report generator, so I used the project protocol and ran the central structure checker directly; it passed.

## 10. Known Residuals

This slice does NOT cover interval calibration, Julia parity, correlated or structured slope blocks, random effects on `sigma` or `nu`, or missing-response skew-normal SD models. One synthetic recovery fit does not show how recovery behaves across sample sizes or designs. The wider predictor-dependent random-effect SD programme remains open.

## 11. Team Learning

When a family has no SD formula, omit its inactive SD placeholder matrix from rank checks. Keep the regression test for an ordinary fit so future scale-formula plumbing does not silently change convergence status.

## 12. Cross-Product Coverage

- Native TMB: ordinary univariate skew-normal location model with one independent numeric random slope and a fixed-predictor SD formula; assembly, seeded recovery, prediction, simulation, save/reload, and constant-SD equivalence were checked.
- Julia: this slice does NOT cover Julia fitting or R-to-Julia parity.
- Inference: this slice does NOT cover 95% interval calibration.

Memory receipt: repository design and after-task protocols were checked; no external memory claim was used.

Golden Set: `test-skew-normal-sd-regression.R`, `test-skew-normal-sd-integration.R`, and the focused `check-drm` regression tests.

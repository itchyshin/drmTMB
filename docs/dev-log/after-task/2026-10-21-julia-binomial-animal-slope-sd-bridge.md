# After Task: Julia Binomial animal-slope SD bridge

## 1. Goal

Connect the existing Binomial animal slope-only SD model to the Julia engine through drmTMB, while keeping its capability claim limited to the tested route.

## 2. Implemented

The R bridge admits one complete-response Binomial animal slope-only term and its matching animal SD formula. It translates the R target `sd_animal(id)` to Julia's single `sd` block and exposes group-level SD predictions. The synthetic bridge fixture now orders the animal factor levels, covariance labels, and SD predictor consistently.

For this route, the latent model is `u ~ N(0, A)`, `b_g = exp(W_g alpha) u_g`, and `eta_i = X_i beta + x_i b_{g_i}`. The SD predictor is constant within animal.

## 3a. Decisions and Rejected Alternatives

Keep the admission exact to one Binomial animal slope-only coefficient with one matching animal SD target. Do not generalize the bridge parser or structured-family registry based on this slice. Do not call the live route parity-tested until the matched R-to-Julia fit and output checks run successfully.

## 4. Files Touched

- `R/julia-bridge.R`: narrow route admission, selected-block mapping, and animal target prediction.
- `tests/testthat/test-julia-binomial-animal-sd-regression.R`: route guards, mock target and prediction checks, and aligned synthetic data.
- `docs/design/01-formula-grammar.md`: scoped candidate status and live-parity boundary.
- `docs/dev-log/check-log.d/2026-10-21-julia-binomial-animal-slope-sd-bridge.md`: check record.
- DRM.jl candidate `src/bridge.jl`: typed schema rendering permits the exact Binomial animal-slope form.
- DRM.jl candidate `src/inference.jl` and `test/test_binomial_sd_regression.jl`: animal marginal simulation, bootstrap refits, and their 30-assertion focused oracle test.

## 5. Checks Run

- Focused R test: mock route and prediction checks passed. A later live rerun in matched local development checkouts executed the R-to-Julia fit and output assertions with no failed assertions. It exercised fitting, SD-slope recovery, target naming, and group-level prediction. Julia dependency installation emitted a precompile warning (`LogExpFunctionsInverseFunctionsExt`, `loglogistic` undefined), so this is a passing focused run with a warning, not a warning-free package check.
- Native TMB synthetic recovery smoke: estimated SD slope 0.684 for truth 0.65; optimizer message reported maximum gradient 2.01e-10. Wald standard errors were unavailable because the Hessian diagnostic was not clean.
- Julia `Meta.parseall` accepted `src/bridge.jl`. The direct animal-slope testset passed 31/31 assertions, including exact seeded marginal simulation and two successful bootstrap refits. The profile-endpoint failure and threaded-profile refusal checks passed as expected; they do not provide a confidence interval.
- JuliaCall used an isolated writable depot under `/private/tmp` ahead of the shared user-level depot. The earlier direct Julia test-file run passed its first 14 assertions, then was stopped during a later fit, so it is not counted as a passing Julia test suite. The later live bridge rerun is a separate, focused R-to-Julia test result and does not supersede that incomplete direct-suite run.
- `git diff --check` passed on the changed R, design, test, and check-log paths.
- `check-after-task.R` accepted the report structure. At the time of this update, the programme ledger records G2 met and the other eight gates open. This bridge sub-slice remains partial evidence and does not close the overall goal.

## 6. Tests of the Tests

The mock prediction test exercises the previously failing animal-target path and verifies the resulting `sdpars` values against `exp(-0.45 + 0.65 z)`. The Julia test also proves that threaded profiling rejects this route before starting endpoint work. The negative route tests continue to reject a mismatched group, extra ordinary random effects, and a multi-coefficient animal block. Earlier live-test output reproduced the original prediction refusal for animal targets.

## 7a. Issue Ledger

No issue action was taken. `gh issue list --repo itchyshin/drmTMB --state open --search 'animal slope SD Binomial Julia bridge' --json number,title` could not connect to GitHub, so the open-issue inventory was unavailable.

## 8. Consistency Audit

The design table identifies this as candidate Julia code and limits the positive evidence to one live R-to-Julia fixture plus one direct Julia inference smoke test. The broader animal and direct-SD tables still distinguish family-specific native routes. The stale-wording search was run over `README.md`, `docs/dev-log/internal-roadmap.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and `_pkgdown.yml` with `animal\(0 \+ x \| id|Julia.*animal|animal.*Julia|sd_animal`.

## 9. What Did Not Go Smoothly

The first live bridge attempt exposed marker-key parsing and then typed-schema mismatches. Those issues were narrowed to the Binomial animal-slope route. JuliaCall initially failed while preparing its shared dependency environment; using a temporary project resolved setup and the focused live test passed.

## 10. Known Residuals

The live test covers one Binomial animal slope-only route. It does not establish broad Julia animal SD support, cross-engine parity beyond this fixture, interval calibration, or coverage. The native smoke recovered the target slope, but its non-clean Hessian diagnostic prevents an inference-readiness claim. Julia profile endpoints are unresolved for this route; the passing bootstrap refits are a software smoke check only.

## 11. Team Learning

For structured predictors, align factor level order, covariance labels, and group-level predictors in the shared synthetic fixture. A bridge's ability to fit is not enough: prediction and returned parameter names need explicit checks too.

## 12. Cross-Product Coverage

This slice covers the drmTMB R-to-Julia adapter and the corresponding Julia Binomial animal slope-only formula schema. It does NOT cover other response families, animal intercepts, other structured providers, correlated or multi-coefficient animal blocks, other parameter endpoints, live cross-engine recovery, profile or bootstrap parity, interval calibration, or coverage.

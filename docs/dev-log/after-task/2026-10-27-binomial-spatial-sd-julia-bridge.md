## 1. Goal

Add tightly scoped Julia bridge support for Binomial coordinate-spatial slope SD regression and verify point parity for logit, probit, and cloglog.

## 2. Implemented

The R bridge admits one coordinate-spatial Binomial random-effect term with a matching group-level SD formula, for an intercept or slope-only loading. It translates the spatial covariance using the existing native coordinate-to-precision helper and passes that covariance through Julia's related-matrix route. The R-facing target remains `sd_spatial(group)` for coefficient extraction and prediction; Julia's internal coefficient block remains `sd`.

The bridge simulator now recognizes this exact route, uses the transformed covariance payload, and applies the slope predictor at the observation level when drawing the latent spatial field.

## 3a. Decisions and Rejected Alternatives

- Reused the existing coordinate covariance helper and related-matrix Julia backend so the bridge uses the same supplied covariance as native TMB. No kernel normalization or new spatial model was introduced.
- Kept admission narrow: one matching spatial target, one field, and no additional random effects. Intercept-plus-slope blocks and mixed providers require separate implementation.
- Assumption made without asking: the bridge route can use the current spatial-to-related-matrix conversion because it preserves the TMB covariance supplied to the fit. If that conversion changes, parity and simulator checks must be rerun.

## 4. Files Touched

- `R/julia-bridge.R`
- `R/julia-simulate.R`
- `tests/testthat/test-julia-binomial-spatial-sd-bridge.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-27-binomial-spatial-sd-julia-bridge.md`

## 5. Checks Run

- Without a Julia path, `devtools::test(filter = "julia-binomial-spatial-sd-bridge", stop_on_failure = TRUE)` passed 13 fit-free route and payload assertions; the live test was skipped as designed.
- With `DRM_JL_PATH` set to the paired Julia worktree, `devtools::test(filter="julia-binomial-spatial-sd-bridge", reporter="summary", stop_on_failure=TRUE)` completed successfully on JuliaCall 1.10.0. The live test exercised logit, probit, and cloglog fits, coefficient and log-likelihood comparison, predicted group SDs, and seeded simulation reproducibility and output validity.
- `git diff --check` passed for the bridge, simulator, focused test, report, and check-log paths.

## 6. Tests of the Tests

Fit-free negative controls reject intercept-plus-slope, an additional IID effect, and a mismatched SD target. The live test fits all three Binomial links and checks both optimizer convergence, SD-slope recovery, cross-engine coefficient and log-likelihood agreement, group-level SD predictions, and repeatability and validity of simulated responses.

## 7a. Issue Ledger

No issue search was run for this bounded implementation slice. Interval coverage remains deferred by the approved programme scope. No new correlation-regression or mixed-provider support is claimed.

## 8. Consistency Audit

Checked formula admission, structured payload conversion, coefficient target labels, `predict()` routing, and the Julia-backed Binomial simulator. The target selector stays `sd(group, level = "spatial")`; the bridge preserves that identity in public outputs while routing to Julia's related-matrix implementation. The direct spatial engine conventions and their limits are documented separately in `2026-10-27-binomial-spatial-sd-slope.md`.

## 9. What Did Not Go Smoothly

The first verification invocation did not set `DRM_JL_PATH`, so it exercised only fit-free checks. The test was rerun with the paired Julia worktree configured and completed the live bridge block.

## 10. Known Residuals

This is point-recovery and cross-engine agreement evidence for one coordinate-spatial Binomial route. It is not interval calibration or coverage validation. The bridge does not add mesh fields, intercept-plus-slope covariance blocks, multiple or mixed structured effects, or spatial SD regression for other response families. Broader Julia parity and family/effect combinations remain open programme work.

## 11. Team Learning

When a bridge re-expresses one structured provider through another backend primitive, test the translated covariance payload and preserve the public target label through fitting, prediction, and simulation.

Memory receipt: `route.py` returned no LOAD-FIRST manifest for this worktree. The repository after-task protocol was read and applied; lane preflight identified this as the `general-sd-regression` branch and reported runtime identity unknown. The spatial and formula target were the scoped adjacent surfaces reviewed.

Golden Set: not applicable to this bridge-marshalling slice.

## 12. Cross-Product Coverage

Covers: drmTMB R-to-Julia bridge; Binomial logit, probit, and cloglog; one coordinate-spatial field with intercept or slope-only loading; fitting, public coefficient extraction, group SD prediction, covariance payload conversion, and basic seeded simulation checks.

Does NOT cover: interval coverage, mesh/projected fields, correlated intercept-slope blocks, multiple or mixed structured effects, non-Binomial families, or a general claim of R/Julia parity beyond this tested route.

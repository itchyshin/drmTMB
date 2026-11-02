# Julia bridge for ZeroOneBeta location-slope SD regression

## 1. Goal

Admit the already-implemented selected independent location-slope SD route for complete-response `zero_one_beta()` fits through `engine = "julia"`, and verify it through the live R-to-Julia bridge against native TMB on one synthetic dataset.

## 2. Implemented

The Julia bridge now admits either one ordinary `mu` random intercept with `sd(id) ~ z` or one independent numeric `mu` slope with a matching selector such as `sd(id, coef = "x") ~ z`. The slope selector must match the sole random-slope coefficient and its grouping factor. Fixed `sigma`, `zoi`, and `coi` intercepts are allowed; random effects on those parameters, mismatched targets, structured terms, and unsupported coefficient layouts remain refused.

The same-data test fits the selected-slope model with native TMB and the paired Julia development candidate. Both fits converge, estimate the SD-predictor coefficient in the simulated direction and within the predeclared point-recovery tolerance, and expose group SDs for the same selected target. The test also covers Julia prediction consistency, fresh-row prediction and save/reload output. This checks bridge plumbing and one recovery cell; it is not broad engine parity.

## 3. Mathematical contract

For the selected random coefficient, the fitted model is `b_g ~ Normal(0, tau_g^2)` with `log(tau_g) = W_g alpha`; for a slope, the row-level latent contribution is `x_i b_g`. The SD formula predictor `W_g` is fixed-effect-only and must be constant within group. The tests retain the coefficient-specific target identity across fit extraction and group-level prediction. Bernoulli/ZeroOneBeta SDs refer to the latent location scale; no free response residual SD is introduced.

## 3a. Decisions and Rejected Alternatives

The bridge admits only the exact selected numeric slope matching the sole independent `mu` slope. It does not treat this one fit as general Julia parity, widen support to structured or correlated effects, or claim calibrated uncertainty. A separate new public interface was unnecessary because the reserved `coef` selector and candidate backend route already existed.

## 4. Files Touched

- `R/julia-bridge.R`: exact ZeroOneBeta admission for a matching intercept or selected independent slope.
- `tests/testthat/test-julia-zero-one-beta-sd.R`: admission boundaries and same-data live-engine integration checks.
- `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`, `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`, and `vignettes/formula-grammar.Rmd`: current support boundary and candidate-source qualification.
- `docs/dev-log/check-log.d/2026-10-21-julia-zeroonebeta-sd-slope-bridge.md` and this report: verification receipts.

## 5. Checks Run

- Focused R test: `DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRM_JL_JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_DEPOT_PATH=/private/tmp/julia-depot:/Users/z3437171/.julia OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "^julia-zero-one-beta-sd$")'` passed: 35 assertions, 0 failures, warnings or skips; 2 live Julia fits; 80.9 seconds.
- Scoped `git diff --check` over the files in this lane passed. A repository-wide diff check still reports a pre-existing extra blank line at EOF in `tests/testthat/test-binomial-sd-integration.R`, outside this lane.
- `rmarkdown::render("vignettes/formula-grammar.Rmd", output_file = "formula-grammar-bridge-check.html", output_dir = "/private/tmp", quiet = TRUE)` passed. Pandoc printed its existing deprecated `--mathjax` option warning.
- The matched Julia source checkout was `70dbf564eb670144c63c08f61ea099084d95add2`; the drmTMB candidate checkout was `425bee81572c625a634b2b083050c5c57c1dc1f1`.

## 6. Tests of the Tests

Admission tests reject a mismatched random-effect group, a selector naming a different slope, an unselected slope, and random effects on `sigma` or `zoi`. The integration test compares both engines on identical simulated observations and checks finite estimates, coefficient naming, recovery direction, a broad coefficient-agreement tolerance, group SDs, `predict()`, fresh-row prediction, and save/reload. These controls show that the bridge exercises selected-slope identity and output plumbing; they do not establish exact likelihood equality or uncertainty reliability.

## 7a. Issue Ledger

No issue was created or changed. A repository issue search was not performed, so this report makes no claim that no related issue exists.

## 8. Consistency Audit

The formula grammar, random-effect SD design page, capability adapter map, formula-grammar vignette, and NEWS now distinguish native support from a matched local Julia development-candidate result. The Julia result is not described as support in the current shared or released DRM.jl. Structured effects and interval calibration remain open. Existing ZeroOneBeta boundary-mixture semantics and fixed `sigma`, `zoi`, and `coi` behavior are unchanged.

## 9. What Did Not Go Smoothly

The first test run exposed an incorrect test expectation about where native TMB stores direct group SDs: the test looked under `random_sd`, while the public fit stores them in `sdpars`. The assertion was corrected to check the public output. The resulting live test passed. Julia's default depot was read-only in this sandbox; the test succeeded with a writable temporary depot and the existing user depot as a secondary path.

## 10. Known Residuals

This establishes one complete-response ZeroOneBeta mean-slope cell only. It does not establish general same-likelihood engine parity, profile or bootstrap behavior for this Julia slope, interval calibration, structured effects, correlated coefficients, additional random effects, missing-response behavior, or current shared/released DRM.jl support. The full R package test suite and pkgdown build were not run. Coverage validation remains deferred by the user's direction.

## 11. Team Learning

For a candidate backend parity slice, a same-data bridge test should check public target identity and downstream outputs in addition to whether the backend admission gate accepts the formula. Candidate-source pins belong in the receipt so later readers can distinguish local parity from support in a shared release.

## 12. Cross-Product Coverage

**Covers:** complete-response ZeroOneBeta with fixed `sigma`, `zoi`, and `coi`, one ordinary independent `mu` intercept or one selected independent numeric `mu` slope; candidate Julia bridge admission; same-data point-recovery direction and group-SD output check; Julia prediction, fresh-row prediction, and save/reload; rejection of mismatched group/coefficient targets and excluded parameter structures.

**Does not cover:** broad engine parity or exact likelihood agreement; Julia profile or bootstrap for this slope; interval calibration; correlated or structured effects; other dpars or families through this exact bridge route; missing responses; released DRM.jl support; full package checks. Continue the family/effect/backend inventory against the active general-SD goal.

### Prose assessment

Self-review: 9/10 naturalness for an engineering receipt; factual and scientific claims are bounded to the recorded tests and source pins; no external references are used. This is not an independent prose assessment.

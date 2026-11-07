# After Task: NB2 animal-intercept SD bridge smoke

## Goal

Connect the new Julia NB2 animal-intercept SD fit to the R bridge and record what is verified on each side.

## Implemented

Added a deterministic R fixture and bridge tests for `animal(1 | id, A = A)` with `sd(id, level = "animal") ~ z`. A static test verifies family admission, formula selector preservation, covariance payload, and SD coefficient labels. A live native-versus-Julia fit test is present but remains unverified because JuliaCall's dependency bootstrap fails before model execution.

The paired Julia candidate implements the latent model `u ~ N(0, R)`, `b = D u`, with `D[g,g] = exp(z_g' alpha)` and NB2 size `exp(-2 eta_sigma)`. It follows the existing Julia animal convention by converting supplied `A` to a correlation matrix. The R/TMB route retains its established supplied-matrix scale; matching SD interpretation is established only for unit-diagonal `A`.

## Mathematical Contract

The predictor-dependent SD belongs to the latent animal coefficient on `mu`; `sigma ~ 1` keeps NB2 dispersion fixed. The model uses a sparse Laplace approximation over the animal effects. The public SD is the coefficient-scale multiplier after the Julia route's existing correlation normalization. `nAGQ` is rejected for this structured sparse-Laplace route rather than silently ignored.

## Files Changed

- `tests/testthat/test-julia-negbinomial-sd.R`
- Paired Julia candidate: `src/negbinomial.jl`, `test/test_nb2_animal_sd_regression.jl`, and `test/test_negbinomial_sd_regression.jl`.
- This report and `docs/dev-log/check-log.d/2026-10-22-nb2-animal-sd-cross-engine-bridge.md`.

The tested Julia candidate was dirty at HEAD `70dbf564e`; content hashes at readback were `src/negbinomial.jl` `ac900a352b014d235e4ff12b767b243fb0acff2a697cbb183f474517f7b80c6f` and `test/test_nb2_animal_sd_regression.jl` `3e462e1c389bf84c8d1eff46824472f5aabf385650439e0fdd14dab5aaf42b88`. The new R bridge test hash is `c83553c23e5856228daf8e56b162c0b9a77638ac25b06d7fcb13364b0044fa19`.

## Checks Run

- Julia direct fit test: 8/8 passed in 14.4 seconds with Julia 1.10.0, one Julia thread, and one BLAS thread.
- R static bridge test run: passed; the two live-engine tests were skipped because no DRM.jl path was supplied. The static checks confirm the SD target and `A` matrix survive bridge payload construction.
- Live R-to-Julia run: not completed. The native TMB fits returned in both test cases, but the following JuliaCall setup did not reach a Julia model fit within the 3-minute and 5-minute limits. The nonzero exits followed my interruptions and do not establish that setup itself fails; fit assertions did not run.
- Whitespace scan: passed for the new R test, this report, and the check-log entry.

## Tests Of The Tests

The Julia fixture uses fixed truth `alpha = (-0.65, 0.4)` and a correlated `A`. Assertions check the recovered SD-slope sign and error, group-to-row SD mapping, and same-data equivalence to the constant-SD animal model. The R static bridge test checks the exact serialized `sd(id, animal) ~ z` term, parameter labels, and covariance payload. The live test is designed to check convergence and point recovery on both engines, but has not yet exercised those assertions.

## Consistency Audit

The Julia direct test and fitter use the same first-seen group order; the fixture reorders `A` to match that order. The R formula parser labels the target `sd(id, animal)`, and the bridge payload preserves that selector and the supplied covariance. No public parity claim is made for non-unit-diagonal covariance matrices or for the live bridge fit.

## GitHub Issue Maintenance

No issue was opened, closed, or commented on. The work remains part of the active general SD-regression programme.

## What Did Not Go Smoothly

The first bridge run lacked Julia on the login-shell path and the test formula did not bind `A` in its local environment. After binding `A` and setting `DRM_JL_JULIA_HOME`, the native TMB fits returned, but JuliaCall did not finish loading `RCall` within either bounded attempt. Both packages listed by JuliaCall's bootstrap are present in the default Julia environment. The direct Julia test and static bridge test were run separately so their evidence would remain useful.

## Team Learning

For bridge tests that depend on a user-local Julia installation, set `DRM_JL_JULIA_HOME` explicitly and test formula-to-payload translation separately from live engine startup. A bootstrap failure is environment evidence, not model-fit evidence.

## Known Limitations

This is one Julia NB2 animal mean-intercept cell. The live R-to-Julia fit, profile/bootstrap refits, non-unit-diagonal covariance parity, other animal coefficient shapes, other structured providers, broader family parity, and interval coverage remain unverified. Coverage calibration is deferred for the programme.

## Next Actions

Diagnose why JuliaCall spends more than five minutes loading the already-installed `RCall`, then rerun the live bridge test. After that, add the animal route to the user-facing NB2 guide and reconcile its exact row in the programme evidence ledger. The overall goal remains active.

Prose assessment: Style 2/10, medium confidence; this is a technical after-task note. Science and facts were checked against the direct Julia test output, static bridge test output, and current source; references are not applicable. Self-review, 2026-10-22; no comparison controls reviewed.

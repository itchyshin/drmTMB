# After task: precision-input quick wins for predictor-dependent SDs

Date: 2026-11-01. Lane: general-sd-regression. Slice type: test-only, no source changes.

## What changed

One new test file, `tests/testthat/test-structured-sd-q-ainv-quickwins.R`. It checks five routes that the slice named. Poisson and NB2 slope-only `relmat(0 + x | id, Q = Q)` with `sd(id, level = "relmat") ~ z`. Gaussian, Poisson and NB2 ordinary `(1 | site)` plus `animal(1 | id, Ainv = Ainv)` intercepts, each with its own SD formula. All five routes already built and fitted on the current branch, so no source file was touched and no route is newly refused.

Existing tests already reach these routes in part. The Poisson and NB2 slope files fit Q but compare it to a K oracle, and the Poisson and NB2 intercept files fit Ainv inside a provider loop. The Gaussian file checks Ainv only by equality with the A fit. The new file fits from the precision matrix alone and checks every route against its own oracle, so the Q and Ainv paths no longer rely on the equivalence argument.

## Evidence

Oracle. One dense, drmTMB-independent Laplace routine over the standardised latent with the SD scaling in the loading matrix, and the exact marginal normal density for Gaussian. The covariance used by the oracle is `solve(Q)` computed in the test, so it shares no code with the package. Covariances are non-unit-diagonal (scale 1.6 or 1.7) with matrix row order different from factor-level order, and the data factor levels are reversed or shuffled.

Tolerances were fixed before the first run and were not changed: oracle 1e-4 absolute on the log-likelihood (Gaussian 1e-6), constant-SD equivalence 1e-4, Q versus K and Ainv versus A 1e-4, predict versus coefficients 1e-8, SD slope recovery within 0.6 (Gaussian 0.8), emulated-bug sensitivity above 0.05.

Emulated bugs that move the oracle by more than 0.05: SDs attached to reversed levels, SD predictor sign flipped, and the precision matrix read as a covariance. The ordinary-block SDs are reversed in the intercept tests.

Refusals pinned by message: SD predictor varying within a level ("constant within" or "varies within"), an SD formula for a level the model lacks ("does not match"), a Q without dimnames ("non-empty row and column names"), and missing-response integration for the Poisson intercept route ("non-inflated model").

Command and result, Mac, one R process, `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MAKEFLAGS=-j2 NOT_CRAN=true`: `testthat::test_file("tests/testthat/test-structured-sd-q-ainv-quickwins.R")` gave passed 92, failed 0, error 0, skipped 0 on the first run, and again after the refusal patterns were added.

## Not covered

Standard errors, profile targets, simulation-based coverage, missing responses beyond the one refusal, the Julia engine, and Gaussian slope-only Q. Gaussian slope-only relmat with K is covered by an existing file. The test needs no new engine layer.

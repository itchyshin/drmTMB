# After Task: Gamma shared spatial-kernel SD comparison

## 1. Goal

Add a synthetic point comparison for one Gamma structured-intercept SD model
that passes the same spatially derived covariance matrix to native TMB and the
Julia bridge.

## 2. Implemented

The Gamma spatial SD test file now contains a second fixture. It constructs a
positive-definite exponential-distance covariance, normalizes it to unit
diagonal, simulates responses from the predictor-dependent SD model, and fits
the same named matrix through `relmat(1 | site)` on both engines. The test
checks convergence, point likelihood, SD coefficients, and named group-SD
predictions.

## 3a. Decisions and rejected alternatives

The comparison uses `Cov(b) = D K D` with one fixed, unit-diagonal `K` shared by
both engines. This isolates the Gamma structured-SD fit from their different
coordinate-range and jitter defaults. It does not route the coordinate
`spatial()` formula through Julia, and does not change either engine's kernel.

## 4. Files touched

- `tests/testthat/test-gamma-spatial-sd-regression.R`
- `docs/dev-log/check-log.d/2026-10-22-gamma-spatial-shared-k-parity.md`
- This after-task report.

## 5. Checks run

- R parse of the test file: passed.
- `DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" JULIA_DEPOT_PATH=/private/tmp/codex-general-sd-julia-depot:/Users/z3437171/.julia OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-spatial-sd-regression", reporter = "summary")'`: exit 0, no failed assertions, and the live Julia bridge ran.
- `git diff --check` for the test and evidence files: passed.
- JuliaCall logged a startup warning: its dependency-install command returned
  status 1 and `LogExpFunctionsInverseFunctionsExt` reported an undefined
  `loglogistic`. The focused test nevertheless completed with exit status 0.
- Full package and documentation checks were not run.

## 6. Tests of the tests

The first bridge attempt stopped before fitting because Julia tried to write
its usage log under the protected default depot. Using only the task-local
depot then exposed that it lacked JuliaCall's `Suppressor` package. Putting the
task-local depot before the existing depot allowed JuliaCall to load the
candidate and run the comparison. The test compares both fitted coefficients
and group predictions after aligning them by site name.

## 7. Consistency audit

Both engines receive the same unit-diagonal matrix and the same SD formula.
The test's route is `relmat`, not the coordinate `spatial()` marker. The
coordinate-spatial capability note therefore continues to say that
cross-engine coordinate parity is unestablished. This one point comparison
does not close a family-wide or provider-wide parity gate.

## 7a. Issue ledger

No GitHub issue or pull request was changed. Issue state was not checked.

## 9. What did not go smoothly

The first two JuliaCall starts failed before the model fit due depot access and
an incomplete task-local package depot. The third run reached both engines but
printed the Julia package-extension warning described above. The final test
process exited successfully, but the warning remains visible for follow-up.

## 11. Team learning

For structured cross-engine comparisons, build one fixed covariance object and
pass it through both APIs. This separates likelihood and SD-target differences
from engine-specific coordinate-kernel defaults.

## 10. Known residuals

This is one Gamma intercept comparison on one synthetic dataset. It does not
establish coordinate-marker parity, other covariance scales, random slopes,
other response families, output serialization, marginal simulation,
profile/bootstrap behavior, or interval calibration. JuliaCall's startup
warning also remains unresolved.

## 12. Cross-product coverage

The test is evidence for one native/Julia Gamma structured-SD cell with a
shared unit-diagonal covariance. It is not evidence that
`spatial(1 | site, coords = coords)` has identical range semantics across the
engines. Next, resolve the ownership boundary for the shared Julia bridge and
add a coordinate-to-fixed-covariance bridge check; continue the remaining
family/effect inventory and preserve calibrated uncertainty as an ultimate
finish requirement.

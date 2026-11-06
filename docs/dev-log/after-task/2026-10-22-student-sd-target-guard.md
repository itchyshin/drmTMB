# After Task: Reject unsupported Student-t SD endpoints

Date: 2026-10-22

## Goal

Prevent Student-t `sd()` formulas for unsupported distributional parameters from being silently ignored.

## Implemented

The Student-t builder now rejects SD endpoints other than `mu` and the separately diagnosed `sigma` endpoint. The regression test uses `sd(id, dpar = "nu") ~ w` and requires a clear error. Existing Student-t `mu` intercept and independent-slope SD routes are unchanged.

## Mathematical Contract

The implemented Student-t SD regression applies to a latent random effect in the `mu` predictor, with `log(tau_g) = X_sd,g beta_sd`. It does not model the SD of latent effects in `sigma` or `nu`.

## Files Changed

- `R/drmTMB.R`: reject unsupported Student-t SD endpoint selectors.
- `tests/testthat/test-student-sd-regression.R`: add the `dpar = "nu"` rejection case and remove an extra blank line at EOF.
- `docs/dev-log/check-log.d/2026-10-22-student-sd-target-guard.md`: retain exact checks and boundaries.
- `docs/dev-log/check-log.md`: link the verification record.
- `LOOP/lanes/general-sd-regression/checkpoint.md`: record this verified slice and the next bridge gap.

## Checks Run

The test-first command
`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "student-sd-regression", reporter = "summary")'`
failed before the code change because the `dpar = "nu"` formula did not throw. After the guard was added, the corrected command
`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "student-sd-regression", reporter = "summary")'`
passed all 28 assertions.

The broader Student filter
`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "student", reporter = "summary")'`
passed. Its first run skipped three live Julia tests because `DRM_JL_PATH` was unset. With explicit Julia paths, the live command
`DRM_JL_PATH="$PWD/../general-sd-julia" DRM_JL_JULIA_HOME="/Users/z3437171/.juliaup/bin" JULIA_DEPOT_PATH="/private/tmp/drmTMB-julia-depot:/Users/z3437171/.julia" OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-student-sd", reporter = "summary")'`
passed with two live Julia tests.

`git diff --check -- R/drmTMB.R` passed. The new test file was checked for trailing whitespace and extra blank lines at EOF.

## Tests Of The Tests

The new assertion failed before the guard, confirming the test detects the silent-drop behavior. It passed after the fix.

## Consistency Audit

The exact inventory search was:

```sh
rg -n 'sd\(id, dpar = "nu"\)|Student-t random-effect SD formulas currently support only|Student scale-endpoint SD regression' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml
```

The formula grammar and predictor-dependent-SD vignette already describe the Student-t location-only boundary. No public documentation change was needed for this error-path correction. The global implementation inventory remains incomplete across families, effect types, and engines.

## GitHub Issue Maintenance

An open-issue search for the exact `sd(id, dpar = "nu")` syntax returned no match. The issue tracker was left unchanged.

## What Did Not Go Smoothly

The builder classified `sd()` as an SD term but only forwarded `mu` entries and specially rejected `sigma`. A `nu` target therefore passed through without being fitted. The initial live Tweedie bridge comparison also exposed a separate fixed-effects-only admission guard; that work remains open because it touches a heavily shared bridge file.

## Team Learning

When a builder recognizes a generic `sd()` prefix, it must validate every parsed target parameter before selecting the subset implemented by that family. Otherwise an unsupported term can look accepted while changing no fitted parameter.

## Known Limitations

Student-t SD regression remains limited to the `mu` endpoint and the already documented ordinary intercept or independent-slope shapes. This change adds no `sigma` or `nu` SD fit, structured Student-t SD route, or interval-coverage evidence. Programme-wide coverage validation remains deferred by the active lane goal.

## Next Actions

Reconcile ownership and the relevant edits to `R/julia-bridge.R`, then add a narrowly admitted Tweedie ordinary slope-SD bridge route and make the same-data live parity test pass. The current test reaches the exact fixed-effects-only refusal before Julia starts.

# After Task: Zero-One Beta Random-Intercept SD Bridge

## Goal

Connect the bounded native Zero-one Beta mean-intercept SD-regression route to
the Julia engine and state its support boundary accurately.

## Implemented

Both engines fit `log(s_g) = alpha_0 + alpha_1 z_g` for one ordinary `mu`
random intercept. Julia admission requires complete responses, a group-constant
SD predictor, and fixed-intercept `sigma`, `zoi`, and `coi` formulas.

## Mathematical Contract

The SD model applies to the latent `mu` intercept on the logit scale. It does
not add a Bernoulli-style residual scale to the zero-one beta mixture. The
interior beta scale and the zero/one mixture parameters remain fixed in this
slice.

## Files Changed

- `R/julia-bridge.R`: exact Julia route predicate and FE-fence exception.
- `R/julia-family-registry.R`: updated family support comment.
- `tests/testthat/test-julia-zero-one-beta-sd.R`: route refusals and synthetic
  live bridge test.
- `docs/design/01-formula-grammar.md` and `vignettes/formula-grammar.Rmd`:
  family support inventory.
- `docs/design/02-family-registry.md`: model equation, example, and limits.
- `docs/dev-log/check-log.d/2026-10-20-zero-one-beta-sd-julia-bridge.md`:
  exact test receipts.
- Direct Julia implementation and tests are in the separate
  `DRModels.jl` worktree at `70dbf564eb670144c63c08f61ea099084d95add2`
  (`codex/general-sd-regression`): `src/zeroonebeta.jl` and
  `test/test_zeroonebeta_sd_regression.jl`.

## Checks Run

- R/TMB source was exercised at `425bee81572c625a634b2b083050c5c57c1dc1f1`;
  Julia source was exercised at `70dbf564eb670144c63c08f61ea099084d95add2`.
- Julia direct focused test: 14/14 passed.
- Existing Julia Zero-one Beta test: 6/6 passed.
- Live R-to-Julia synthetic bridge test: passed, including convergence,
  coefficient recovery, prediction, and save/reload assertions.
- Native filtered suite `zero-one-beta-sd`: assembly and integration tests
  passed; the live Julia case skipped because the Julia path was not set in
  that run. The dedicated live bridge run above exercised Julia.
- `pkgdown::check_pkgdown()`: no problems found; Pandoc emitted existing
  `--mathml` deprecation warnings.
- GitHub open-issue search for `sd regression` in `itchyshin/drmTMB`: no
  matching open issue; no issue action taken.

## Tests Of The Tests

The bridge test includes negative cases for missing SD formulas, random
mixture-parameter effects, slopes, mismatched groups, and structured effects.
The Julia implementation's focused test passed before this bridge was added.

## Consistency Audit

The documentation and route predicate agree on one ordinary mean intercept,
fixed mixture parameters, and no structured or slope route. Interval
calibration remains explicitly open. The broader family table and other
support claims still require audit as the goal continues.

## GitHub Issue Maintenance

Searched open issues for `sd regression`; no matching issue was found. No issue
was created, commented on, or closed.

## What Did Not Go Smoothly

The first live bridge attempt stalled during JuliaCall setup because the
sandbox could not write a pidfile in the user's Julia depot. A bounded retry
with depot access completed successfully. The native aggregate filtered run
also took longer than its initial estimate but finished within the extended
wait.

## Team Learning

When a JuliaCall test stops at setup, inspect the helper's direct error before
diagnosing the model. Here the setup failure was a filesystem permission
problem. The test did not reach route or likelihood evaluation.

## Known Limitations

This slice does not support Zero-one Beta random slopes, structured effects,
or random effects on `sigma`, `zoi`, or `coi` in Julia. No interval-coverage
calibration was performed. The Julia code remains in a separate `DRModels.jl`
candidate worktree and has not been integrated or landed.

## Next Actions

Continue the broader family and effect-type map, reconcile candidate worktrees
with the DRM.jl owner, and schedule interval calibration as a later phase.

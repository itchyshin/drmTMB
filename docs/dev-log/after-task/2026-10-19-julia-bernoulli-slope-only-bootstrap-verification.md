# After Task: Julia Bernoulli Slope-Only Bootstrap Verification

## Goal

Verify that a Julia Bernoulli correlated intercept-slope model with only the slope SD depending on predictors can bootstrap-refit successfully.

## Implemented

No code change was needed. The current Julia test already fits the slope-only target, builds its marginal simulator, and checks one successful bootstrap refit.

## Mathematical Contract

The slope SD varies by its fixed predictor while the intercept SD remains constant. The correlated block retains the shared constant correlation parameter. The bootstrap check tests that refitting this target preserves the model's parameter map.

## Files Changed

- The existing test is in `../general-sd-julia/test/test_binomial_sd_regression.jl`.
- `docs/dev-log/check-log.md` records this verification.
- This report records the evidence and its boundary.

## Checks Run

- `JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH="/private/tmp/drmTMB-julia-depot:/Users/z3437171/.julia" julia --project=. -e 'include("test/test_binomial_sd_regression.jl")'` from `../general-sd-julia`: all test sets passed, **105 assertions total**, including one slope-only bootstrap attempt used successfully; process exit code 0. Wall time was about 1 minute 45 seconds, including compilation.

## Tests Of The Tests

The slope-only test checks `attempted == 1`, `used == 1`, and `failed == 0` for `bootstrap_result`, with a fixed random seed and `failures = :error`.

## Consistency Audit

This was a verification-only change. It adds no support claim and does not alter Julia or R/TMB behavior. The test file includes other Bernoulli routes, all of which passed in this run.

## GitHub Issue Maintenance

No matching open issue was identified for the slope-only bootstrap verification gap. The issue tracker is unchanged.

## What Did Not Go Smoothly

Julia compilation produced no output for the first minute. The same live process then completed all tests successfully; no duplicate run was started.

## Team Learning

Review findings should be checked against the current checkout before making edits. This bootstrap test was already present, so execution evidence was the needed repair.

## Known Limitations

One successful bootstrap refit verifies routing and basic execution, not interval calibration or recovery. Full Bernoulli calibration and the programme gates remain open.

## Next Actions

Resolve the current-source calibration design and complete the separate Bernoulli recovery and uncertainty evidence.

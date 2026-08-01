# Lane C Z5 — zero-one-beta sigma q1 slope after-task report

## 1. Goal

Validate only `mc-0576`: ordinary ML `zero_one_beta()` under
`bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1)`. The maximum claim is
local technical point-fit recovery.

## 2. Implemented

The sigma q1 gate admits one unlabelled ordinary slope only when the fixed
sigma RHS is the identical raw symbol used inside `(0 + x | id)`. Its existing
`u_sigma`/`log_sd_sigma` model-15 carrier, natural-scale extraction, full
mixture-plus-normal-prior oracle, and direct target remain active. The direct
target is visible but not profile-ready.

## 3a. Decisions and Rejected Alternatives

`sigma ~ z + (0 + x | id)`, `sigma ~ I(x^2) + (0 + x | id)`, multiple fixed
terms, intercept random effects in the slope route, labels, covariance,
mu/zoi/coi random effects, structured providers, missing response, profiles,
intervals, bootstrap, and coverage are outside the q1 contract.

## 4. Files Touched

`R/drmTMB.R` contains the exact-expression validation. The focused target,
profile-fence, oracle, gradient, dependency, and neighbour tests are in
`tests/testthat/test-zero-one-beta.R`. The source-bound runner and retained
output are in `tools/run-lane-c-zob-sigma-slope-local-recovery.R` and
`docs/dev-log/implementation-recovery/2026-07-30-lane-c-z5-zob-sigma-slope-local-run-1/`.

## 5. Checks Run

The focused test file passed after `pkgload::load_all()`. The runner was rerun
against source SHA `4ca285784a76ba0e37c3087a9d005178d95987f5`; all four fixed
seeds converged with `pdHess = TRUE`, gradients at most 0.00477, inactive
clamps, finite non-boundary SDs, and mean relative SD error 0.0613.
`python3 tools/capability_ledger.py --check` passed. The ledger is unchanged
until the completion panel returns GO.

## 6. Tests of the Tests

The oracle evaluates the zero, one, and interior-beta mixture plus the latent
standard-normal penalty. Tests compare its objective and central-FD gradient
to TMB AD and ensure a nonzero sigma SD changes the objective. The runner
retains each seed, source SHA, runner MD5, zero/one atom counts, per-group atom
and interior support, log-sigma range, clamp state, and a zero-true-SD
diagnostic.

## 7a. Issue Ledger

No issue was opened or closed. `mc-0576` remains `not_implemented` until the
fresh panel clears a point-fit-only transition.

## 8. Consistency Audit

The first Noether/Fisher/Rose panel found an incomplete runner and an overly
broad predictor gate. The repaired gate, profile fence, reader wording, and
full receipt were reviewed again; a final panel is required after this exact
expression repair. Future-extension, Lane A/B, ledger status, and Mission
Control cards have not changed.

## 9. What Did Not Go Smoothly

The initial compact receipt omitted atom/support, log-scale, clamp, and
zero-true-SD diagnostics. A first repair still matched variable names rather
than the full fixed expression, allowing `I(x^2)`. Both defects were retained
in Git history, repaired, and the four-seed fixture was rerun rather than
waived.

## 10. Known Residuals

This receipt cannot support an interval, calibration, coverage, or
inference-ready claim. It cannot support any atom random effect, another sigma
slope form, joint distributional-parameter effect, structured provider, or
missing-response route. The zero-true-SD run is diagnostic only.

## 11. Team Learning

For an exact random-slope contract, matching variable names is not enough:
the fixed design expression and random multiplier must match as raw terms.
For mixture recovery, atom support and clamp state are part of the evidence,
not optional runner metadata.

## 12. Cross-Product Coverage

This covers only univariate model type 15, ordinary ML, a complete observed
response, fixed `mu`/`zoi`/`coi` intercepts, and one matching ordinary sigma
slope. It does NOT cover REML, aggregation, missingness, alternative links,
other distributions, `mu`/`zoi`/`coi` random effects, covariance, labels,
structured providers, profiles, intervals, bootstrap, coverage, association,
or native bivariate/high-q routes.

# After Task: LogNormal sigma-endpoint SD verification

## Goal

Verify the native LogNormal sigma-endpoint random-intercept SD formula and add
a check that its predictor is constant within groups.

## Implemented

Added the within-group rejection test and removed a duplicate LogNormal
sigma-endpoint row from the formula grammar table. The fitting implementation
was already present in the candidate before this verification slice; this
slice did not change the likelihood builder.

## Mathematical Contract

For group `g`, the fitted latent effect is `b_g ~ Normal(0, tau_g^2)` with
`tau_g = exp(W_g alpha)` inside the implementation's soft-clamp range, and
`log(sigma_i) = X_sigma,i beta_sigma + b_g`. The SD formula models variation
in a random intercept on `log(sigma)`, not variation in residual `sigma`.
This slice uses complete responses, fixed-effect `mu`, and one ordinary sigma
random intercept.

An independent read-only review found no critical mismatch in the likelihood
scale and confirmed that the endpoint-specific scale also enters marginal
simulation. That review did not exercise profile execution. A later focused
test checked fitted-data conditional `sigma` prediction against the fixed
predictor plus the fitted random-effect contribution and checked `sigma(fit)`
against the exponentiated link prediction. The bounded profile smokes below
test direct SD-slope interval execution only.

## Files Changed

`tests/testthat/test-lognormal-sigma-sd-regression.R`,
`docs/design/01-formula-grammar.md`, `docs/dev-log/check-log.md`,
`docs/dev-log/check-log.d/2026-10-22-lognormal-sigma-sd-validation.md`,
`LOOP/lanes/general-sd-regression/checkpoint.md`, and this report. The test
exercises the existing implementation; no likelihood code changed in this
slice.

## Checks Run

The focused `lognormal-sigma-sd-regression` test passed after adding a seeded
120-group profile workflow check. The adjacent
`lognormal-(location-scale|sd-assembly|sd-integration|sigma-sd-regression)`
sweep passed with no reported failures. Both commands used
`OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, and `MKL_NUM_THREADS=1`.

An exploratory profile-interval call on the 400-group recovery fit exceeded
roughly two minutes and was interrupted. It returned no result and is not a
pass. Two smaller same-seed profile smokes then completed. With 36 groups and
12 observations per group, the fitted SD slope was -0.3279 and its 95% profile
interval was [-1.0568, 0.2807], which missed the generating value 0.4. With
120 groups and the same 12 observations per group and seed, the estimate was
0.6471 and the interval was [0.3045, 1.0681], which contained 0.4. These two
fits show that the profile path can return finite intervals and that the small
design can miss the truth; they do not estimate interval coverage. The Julia
test runner reported that no live Julia tests ran.

## Tests Of The Tests

The new negative case makes the SD predictor vary by row within each `id` and
expects an error containing `constant within`. The passing recovery test also
checks coefficient estimates against independent synthetic truth, finite
coefficient covariance, profile-target registration, fitted group-level SDs,
marginal simulation, save/reload prediction, and likelihood/coefficient
equivalence to the constant-SD fit. The new profile test checks a finite 95%
interval for the SD slope on one predeclared 120-group synthetic fit and
confirms that this interval contains the generating slope. Its scope is one
seeded interval; it provides no repeated-sample coverage estimate.

The conditional-output test compares the public link and response predictions
to independently assembled fixed and random-effect contributions for this
fitted data set. It does not test prediction on new data or bootstrap refits.

## Consistency Audit

The formula grammar now has one LogNormal sigma-endpoint row. Its status names
the latent `log(sigma)` target and group-constant predictor rule, records the
tested outputs and profile smokes, and states that coverage is uncalibrated and
Julia support is unverified. The predictor-SD vignette already contains a
matching synthetic example. The exact status inventory search is recorded in
the check-log detail file. No navigation change was needed.

## GitHub Issue Maintenance

The requested open-issue search could not reach `api.github.com`, so overlap
remains unverified. No issue was opened or changed.

## What Did Not Go Smoothly

The first attempt to exercise a profile interval on the large recovery fit was
too slow for a light unit-test check. It was stopped without claiming a
profile result. Smaller profile smokes completed, but the 36-group interval
missed the true slope while the 120-group interval contained it. A single fit
at each group count cannot establish coverage or identify the reason for the
difference. One initial command also failed on shell quoting before the
profile call; moving the R code to a temporary script resolved that issue.

## Team Learning

Keep profile workflow checks separate from large point-recovery fixtures. A
small timed fit should establish a practical runtime before profile execution
is added to routine regression tests.

## Known Limitations

This is one native TMB cell. The profile workflow returned finite intervals
for two small synthetic fits and now has a deterministic regression test, but
its coverage is uncalibrated. The larger 400-group profile has not completed.
Julia parity and bootstrap-refit integrity remain unverified, as does broader
response-family support. No interval calibration is implied.

## Next Actions

Audit the paired Julia candidate and its shared DRM.jl ownership, then continue
with the next unclassified response-family, random-effect, or engine row. Keep
the full capability universe open; this slice does not close the programme.

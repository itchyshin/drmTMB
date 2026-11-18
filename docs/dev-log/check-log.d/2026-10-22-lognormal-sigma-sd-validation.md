# LogNormal sigma-endpoint SD regression verification

Date: 2026-10-22

## Scope

Verified the existing native TMB route for one complete-data LogNormal sigma
random intercept with fixed-effect `mu` and `sd(id, dpar = "sigma") ~ w`.
Added a negative test requiring the SD predictor to be constant within each
group. Removed one duplicate LogNormal sigma-endpoint row from the formula
grammar table and kept its full tested boundary in the remaining row.

## Checks

Passed:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "lognormal-sigma-sd-regression", reporter = "summary", stop_on_failure = FALSE)'
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "lognormal-(location-scale|sd-assembly|sd-integration|sigma-sd-regression)", reporter = "summary", stop_on_failure = FALSE)'
```

## Conditional sigma output follow-up, 2026-10-22

Added checks that fitted-data `predict(fit, dpar = "sigma", type = "link")`
equals the fixed sigma predictor plus
`sigma_random_effect_contribution(fit, dpar = "sigma")`, and that
`sigma(fit)` equals the exponentiated link prediction. The focused command
`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "lognormal-sigma-sd-regression", reporter = "summary")'`
exited 0 with all tests passing. The runner reported zero live Julia tests, so
this is native conditional-output evidence only. It adds no Julia parity,
bootstrap-refit, or interval-coverage evidence.

The focused route checks recovery, finite coefficient covariance, profile-target
registration/readiness, group-level SD prediction, marginal response
simulation, save/reload prediction, constant-SD likelihood/coefficient
equivalence, and rejection of row-varying within-group SD predictors. The
neighboring LogNormal sweep also passed. These are native TMB checks; the
reported runner states that no live Julia tests ran.

An exploratory `confint(..., method = "profile")` call for the SD slope on the
400-group recovery fit remained active beyond roughly two minutes and was
interrupted. It produced no interval result and is not counted as a pass. The
test retains profile target readiness and finite covariance checks only.

## Interpretation and limits

The fitted SD is for a random intercept on the latent `log(sigma)` predictor,
not for residual `sigma`. This is one native endpoint/effect-shape cell. It
does not establish actual profile execution, bootstrap-refit integrity,
interval coverage, Julia parity, or support for other `sigma` random-effect
shapes.

Status inventory search used:

```sh
rg -n 'sd\([^)]*,[[:space:]]*dpar = "sigma"\)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml
```

The command found one formula-grammar status row, one grammar example, and the
predictor-SD vignette example. README, the internal roadmap, NEWS, known
limitations, the formula-grammar vignette, and pkgdown navigation had no match
for this target syntax. No

## Profile smoke follow-up, 2026-10-22

The initial 400-group profile call was interrupted after roughly two minutes.
I then used the same independent lognormal DGP and seed for two bounded
profile checks, with `mu = 0.2`, fixed `sigma` predictor `-0.4`, and
`log(tau_g) = log(0.32) + 0.4 w_g`. Both fits used 12 observations per group
and `confint(..., level = 0.95, method = "profile")` on
`fixef:sd(id, dpar = "sigma"):w`.

At 36 groups, the fit converged and returned a finite interval
[-1.056766, 0.2807031] around estimate -0.3279157; the interval missed truth
0.4. At 120 groups, the fit converged and returned [0.3044929, 1.068088]
around estimate 0.6470594; the interval contained truth 0.4. The first smoke
took about 10 seconds and the second about 35 seconds including startup and
fitting. This is one replicate at each design size, so the result verifies
profile execution only and provides no coverage estimate. The larger
400-group profile remains unverified because its call was stopped.

Exact reproduction scripts were written under `/private/tmp` and run with
`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1`. The scripts are
`/private/tmp/drmTMB_lognormal_sigma_profile_smoke.R` and
`/private/tmp/drmTMB_lognormal_sigma_profile_smoke_120.R`.

The 120-group case is now in
`tests/testthat/test-lognormal-sigma-sd-regression.R` as an integration smoke.
The focused `lognormal-sigma-sd-regression` filter passed after this addition,
and the neighboring
`lognormal-(location-scale|sd-assembly|sd-integration|sigma-sd-regression)`
filter also passed. These checks exercise one fixed seeded profile result;
they are not a repeated-sample coverage assessment.

Exact rerun commands:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "lognormal-sigma-sd-regression", reporter = "summary", stop_on_failure = FALSE)'
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "lognormal-(location-scale|sd-assembly|sd-integration|sigma-sd-regression)", reporter = "summary", stop_on_failure = FALSE)'
```

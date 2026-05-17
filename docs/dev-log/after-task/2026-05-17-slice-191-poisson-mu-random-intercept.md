# After Task: Slice 191 Poisson Mu Random Intercept

## Goal

Implement the first ordinary non-Gaussian `mu` random-intercept path where the
fixed-effect likelihood and recovery checks were already stable enough to
extend.

## Implemented

Ordinary Poisson models now fit unlabelled `mu` random intercepts with syntax
such as:

```r
bf(count ~ x + (1 | id))
```

The random effect enters the log-mean predictor for non-zero-inflated Poisson
models. The fitted SD appears in `sdpars$mu`, fitted group effects appear in
`random_effects$mu`, and `profile_targets()` exposes the SD as a direct
`log_sd_mu` target transformed by `exp`.

## Mathematical Contract

For observation `i` in group `g[i]`, the fitted Slice 191 model is:

```text
y_i | mu_i ~ Poisson(mu_i)
log(mu_i) = offset_i + X_mu[i, ] beta_mu + b_{g[i]}
b_g = sd_mu u_g
u_g ~ Normal(0, 1)
```

This slice does not add Poisson random slopes, labelled random-effect
covariance blocks, zero-inflated Poisson random effects, a fitted Poisson
`sigma`, known sampling covariance, phylogenetic or spatial Poisson effects,
or covariance between `mu` and other non-Gaussian distributional parameters.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-poisson-mean.R`
- `tests/testthat/test-zi-poisson.R`
- `tests/testthat/test-comparators.R`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-191-poisson-mu-random-intercept.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-poisson-mean.R tests/testthat/test-zi-poisson.R tests/testthat/test-comparators.R`
- `air format README.md NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/05-testing-strategy.md docs/design/33-phase-6c-core-random-effects.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd`
- `Rscript -e "devtools::test(filter = 'poisson-mean', reporter = 'summary')"`: passed.
- `Rscript -e "devtools::test(filter = 'zi-poisson', reporter = 'summary')"`: passed.
- `Rscript -e "devtools::test(filter = 'comparators', reporter = 'summary')"`: passed.
- `Rscript -e "devtools::test(filter = 'poisson-mean|zi-poisson|comparators|profile-targets', reporter = 'summary')"`: passed.
- `Rscript -e "devtools::test(filter = 'cumulative-logit|student-location-scale|gaussian-random-intercepts', reporter = 'summary')"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `rg -n "Poisson.*random effects.*not yet implemented|Fixed-effect univariate Poisson mean models|Poisson.*fixed-effect.*only|non-Gaussian families \\| Fixed-effect likelihoods only|Non-Gaussian families \\| Fixed-effect non-Gaussian families are implemented; random slopes" README.md ROADMAP.md NEWS.md docs vignettes R tests`: returned only historical after-task/check-log lines plus updated current-scope rows.
- `rg -n "zoi|coi|one-inflation|zero-one" README.md ROADMAP.md NEWS.md docs vignettes R tests`: confirmed the bounded-response one-inflation lane is documented as planned.
- `git diff --check`: passed.

## Tests Of The Tests

The new Poisson recovery test checks convergence, positive-definite Hessian,
fixed-effect recovery, random-effect SD recovery, correlation between fitted
and simulated group effects, response-scale predictions, and the direct
`profile_targets()` SD row. The comparator test checks the overlapping
Poisson GLMM against `lme4::glmer()`. The zero-inflated Poisson negative test
now requires the clearer unsupported random-effect message.

The first local test run failed because the Poisson TMB random-effect data had
been wired into the neighbouring cumulative-logit block instead of the Poisson
block. The failure produced NaN Laplace gradients and broke existing Gaussian
comparator tests, which confirmed that the tests were exercising the TMB data
contract rather than only parser state.

## Consistency Audit

`NEWS.md`, `README.md`, `ROADMAP.md`, formula grammar docs, family registry,
testing strategy, validation debt, known limitations, and the model-map/formula
grammar vignettes now describe the same boundary: ordinary Poisson `mu` random
intercepts are fitted for non-zero-inflated Poisson models; Poisson slopes,
labelled covariance blocks, zero-inflated Poisson random effects, NB2 random
effects, bounded-response zero-one inflation, and non-Gaussian cross-parameter
covariance remain planned.

## What Did Not Go Smoothly

The first implementation patch touched the wrong family block in
`make_tmb_data()`. The fix was to re-check the family-specific TMB data rows
with line-numbered inspection and a small manual `MakeADFun()` probe before
rerunning tests.

## Team Learning

Ada kept Slice 191 limited to the first fitted non-Gaussian `mu` random
intercept. Boole pinned the grammar boundary around ordinary `(1 | id)` only.
Gauss and Noether verified that the random effect enters `eta_mu`, not `mu`.
Fisher and Curie added recovery, lme4 comparator, and profile-target checks.
Pat and Darwin kept the user-facing docs clear about what an applied count user
can fit now. Grace kept validation serial after the TMB data wiring issue.
Rose recorded the cross-parameter covariance and `zoi`/`coi` lanes as future
gates rather than implied features.

## Known Limitations

The fitted Slice 191 path is ordinary Poisson `mu` random intercepts only.
Poisson random slopes, labelled Poisson covariance blocks, zero-inflated
Poisson random effects, NB2 random effects, non-Gaussian scale/shape random
effects, `zoi`/`coi` random effects, and cross-parameter covariance among
non-Gaussian latent effects remain future work.

## Next Actions

Slice 192 should define and test the one-slope boundary for non-Gaussian `mu`.
The most natural next code target is to keep Poisson slopes explicitly
unsupported until the slope recovery grid is chosen, then move to NB2-style
`mu` random intercepts only if the Poisson boundary remains stable.

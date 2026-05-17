# After Task: Slice 192 Poisson Mu Random Slope

## Goal

Define and test the first non-Gaussian one-slope boundary by extending ordinary
non-zero-inflated Poisson `mu` random effects from random intercepts to
independent numeric random slopes.

## Implemented

Ordinary Poisson models now accept unlabelled independent `mu` random slopes
such as:

```r
bf(count ~ x + (0 + x | id))
bf(count ~ x + (1 | id) + (0 + x | id))
```

The slope enters the log-mean predictor through the existing `mu_re_value`
matrix and `u_mu` / `log_sd_mu` random-effect machinery. The fitted slope SD
appears in `sdpars$mu`, `random_effects$mu`, and `profile_targets()` as a
direct `log_sd_mu` profile target.

The slice keeps correlated Poisson slope blocks such as `(1 + x | id)`,
labelled covariance blocks such as `(1 | p | id)`, zero-inflated Poisson random
effects, NB2 random effects, and cross-parameter non-Gaussian covariance
planned.

## Mathematical Contract

For observation `i` in group `g[i]`, the fitted independent-slope model is:

```text
y_i | mu_i ~ Poisson(mu_i)
log(mu_i) = X_mu[i, ] beta_mu + sd_x u_x[g[i]] x_i
u_x[g] ~ Normal(0, 1)
sd_x = exp(log_sd_mu[x])
```

With an intercept plus an independent slope:

```text
log(mu_i) = X_mu[i, ] beta_mu + sd_0 u_0[g[i]] + sd_x u_x[g[i]] x_i
cor(u_0, u_x) = 0
```

That zero-correlation rule is the public Slice 192 boundary.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-poisson-mean.R`
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

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-poisson-mean.R tests/testthat/test-comparators.R`
- `air format R/drmTMB.R README.md NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/05-testing-strategy.md docs/design/33-phase-6c-core-random-effects.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd tests/testthat/test-poisson-mean.R tests/testthat/test-comparators.R`
- `Rscript -e "devtools::test(filter = 'poisson-mean', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'comparators', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'poisson-mean|zi-poisson|comparators|profile-targets', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `rg -n 'Poisson.*random slopes|Poisson slopes|Poisson random-intercept|Poisson.*random intercepts are implemented|Slice 191 Poisson path|ordinary Poisson `mu` random intercepts|Non-Gaussian families \\| Fixed-effect likelihoods plus ordinary Poisson `mu` random intercepts' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests`:
  returned only current status rows, tests, and Slice 191 historical rows.
- `git diff --check`: passed.

## Tests Of The Tests

The new Poisson slope recovery test would have failed before this slice because
`validate_poisson_mu_random_terms()` rejected `(0 + x | id)`. The comparator
test checks the overlapping intercept plus independent slope GLMM against
`lme4::glmer()`. The unsupported-input test now checks that correlated Poisson
slope blocks still error before optimization.

## Consistency Audit

README, NEWS, ROADMAP, the formula grammar, family registry, testing strategy,
Phase 6c random-effect status note, validation-debt register, known
limitations, and model-map/formula-grammar vignettes now say the same thing:
ordinary non-zero-inflated Poisson `mu` supports unlabelled random intercepts
and independent numeric random slopes, while correlated slopes and labelled
non-Gaussian covariance remain planned.

No C++ template edit was required in this slice. The Slice 191 Poisson branch
already used `mu_re_value(i, j)`, so the new work was to open the R validation
gate and add recovery/comparator evidence.

## What Did Not Go Smoothly

One stale-wording scan was first run with a double-quoted shell pattern
containing backticks, so `zsh` tried to execute ``mu``. I reran the scan with a
single-quoted pattern and recorded the successful command above.

## Team Learning

Ada kept the slice to the one-slope boundary rather than opening correlated
Poisson slope covariance. Gauss and Noether confirmed that the existing TMB
Poisson random-effect path already matched the slope equation. Fisher and Curie
required both simulation recovery and an `lme4::glmer()` comparator. Pat and
Darwin kept the docs phrased as a count-model capability, not a broad
non-Gaussian random-effect claim. Grace checked pkgdown. Rose caught the stale
wording and the shell quoting issue.

## Known Limitations

Slice 192 does not add correlated Poisson random slopes, labelled Poisson
covariance blocks, zero-inflated Poisson random effects, NB2 random effects,
non-Gaussian scale or shape random effects, `zoi`/`coi` random effects, or
cross-parameter non-Gaussian covariance.

## Next Actions

Slice 193 should move to the non-Gaussian residual-scale feasibility gate, with
NB2 `mu` random intercepts still visible as the next count-family
implementation candidate before the broader scale/shape/ZI/ordinal decisions.

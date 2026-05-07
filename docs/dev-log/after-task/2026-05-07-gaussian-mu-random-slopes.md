# After-Task Report: Gaussian `mu` Random Slopes

Date: 2026-05-07

## Task

Add the next mixed-model step after Gaussian `mu` random intercepts: simple
numeric random slopes in the univariate Gaussian location formula.

## Outcome

Implemented conservative random-slope support for the univariate Gaussian
`mu` formula:

```r
drmTMB(
  bf(y ~ x1 + (0 + x1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

The current independent intercept-plus-slope syntax is:

```r
drmTMB(
  bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

Correlated blocks such as `(1 + x1 | id)` and labelled covariance blocks such
as `(1 + x1 | p | id)` are still intentionally rejected. Those forms imply
random-effect covariance parameters that this phase does not yet estimate.

## Equation Check

The implemented symbolic model is:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + sum_j z_j[i] sd_j u_j[g_j[i]]
log(sigma_i) = X_sigma[i, ] beta_sigma
u_j[g] ~ Normal(0, 1)
sd_j = exp(theta_j)
```

For `(1 | id)`, `z_j[i] = 1`. For `(0 + x | id)`, `z_j[i] = x_i`.

This matches the R syntax and the TMB contribution:

```cpp
mu(i) += mu_re_value(i, j) * sd_mu_re(mu_re_term(idx)) * u_mu(idx);
```

## Files Changed

- `R/drmTMB.R`
  - replaced random-intercept-only parsing with simple `mu` random-effect
    parsing;
  - added `0 + x` random-slope parsing and clear rejection for unsupported
    correlated block syntax;
  - added random-effect design values through `model$random$mu$value`;
  - updated random-effect starting values for intercept and slope terms.
- `src/drmTMB.cpp`
  - added `DATA_MATRIX(mu_re_value)`;
  - multiplied each random-effect contribution by its design value.
- `R/methods.R`
  - updated fitted-data conditional prediction to include random-slope
    contributions.
- `tests/testthat/test-gaussian-random-intercepts.R`
  - added random-slope simulation recovery;
  - added independent intercept-plus-slope tests;
  - added missingness handling for random-slope variables;
  - added rejection tests for `(x | id)`, `(1 + x | id)`, and non-numeric
    random-slope variables.
- `docs/design/*.md`, `vignettes/*.Rmd`, `README.md`, `ROADMAP.md`, `NEWS.md`,
  and `docs/dev-log/known-limitations.md`
  - updated the implemented grammar, equations, caveats, and roadmap.

## Validation

Commands run:

```text
Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"
Rscript -e "devtools::test()"
Rscript -e "devtools::document()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check()"
Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
Rscript -e "pkgdown::build_site()"
git diff --check
air --version
```

Results:

- targeted random-effect tests: 44 passed, 0 failed;
- full `devtools::test()`: 186 passed, 0 failed;
- `devtools::document()`: completed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed;
- `devtools::check()`: 0 errors, 0 warnings, 1 system-clock note;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed;
- `air` is not installed locally.

## Consistency Audit

- Formula grammar now states that `(0 + x | id)` is implemented and
  `(1 + x | id)` is reserved for correlated covariance blocks.
- Gaussian math now includes the random-effect design multiplier `z_j[i]`.
- Likelihood docs now match the TMB implementation.
- Vignettes and README no longer describe the Gaussian `mu` random-effect path
  as random-intercept-only.
- Known limitations now name the remaining gap precisely: correlated random
  intercept/slope blocks, not all random slopes.

## What Did Not Go Smoothly

- The first implementation temptation was to make `(1 + x | id)` work as
  independent terms. That would have copied a familiar syntax while silently
  changing its usual covariance meaning. The final implementation avoids that
  by requiring explicit `(1 | id) + (0 + x | id)` syntax for independent terms.
- Stale wording was easiest to miss in vignettes, especially caveat sections
  written before this phase. The after-task scan caught and corrected the main
  stale sentence.
- The random-effect test file name still says `random-intercepts`; it now also
  covers random slopes. Renaming can wait until the next small cleanup to avoid
  churn during this modelling change.

## Team Learning

- Boole should keep guarding the distinction between familiar syntax and
  implemented covariance semantics.
- Noether should insist that every new formula term has a matching symbolic
  object; here that object was `z_j[i]`.
- Gauss should continue checking that random-effect scale parameters remain on
  unconstrained log scales and that random effects stay non-centered until we
  have a reason to change.
- Curie should add comparator tests against `lme4` once correlated versus
  independent covariance semantics are implemented clearly enough to compare.
- Rose should keep using stale-wording scans after every phase, including
  vignettes, README, roadmap, NEWS, and known limitations.

## Remaining Limitations

- Correlated random intercept/slope blocks are not implemented.
- Labelled covariance blocks such as `(1 + x | p | id)` are not implemented.
- Random effects in `sigma`, `mu1`, and `mu2` are not implemented.
- Factor and multi-column random slopes are not implemented.
- Phylogenetic A-inverse and spatial SPDE random effects remain planned.

## Next Step

The next coherent modelling task is either:

1. implement correlated Gaussian `mu` random-effect covariance blocks for
   `(1 + x | id)` and then labelled `(1 + x | p | id)`; or
2. add comparator tests for the independent random-slope case where it overlaps
   with a clearly equivalent `lme4` model.

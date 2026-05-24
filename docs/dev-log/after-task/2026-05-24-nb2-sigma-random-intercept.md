# After Task: NB2 Sigma Random-Intercept Gate

## Goal

Fit the ordinary, non-zero-inflated NB2 grouped overdispersion random intercept:

```r
bf(count ~ x, sigma ~ z + (1 | id))
```

The task keeps this gate narrow. It does not admit Poisson `sigma` random
effects, NB2 `sigma` slopes, labelled NB2 scale covariance, joint `mu`/`sigma`
random effects, zero-inflated/truncated/hurdle NB2 scale random effects,
structured NB2 `sigma`, or spatial/animal/`relmat()` count-scale routes.

## Implemented

`drm_build_nbinom2_spec()` now extracts ordinary `sigma` bar terms, validates
that they are independent intercept-only terms, builds the same grouped random
effect structure used by Gaussian `sigma`, and passes it to TMB for ordinary
NB2 models. The NB2 TMB branch adds the grouped contribution to `log_sigma`
before evaluating the NB2 density and adds a standard normal latent-effect prior
with a fitted `log_sd_sigma` scale.

The fitted route appears through `sdpars$sigma`, `random_effects$sigma`,
`sigma()`, `predict(fit, dpar = "sigma")`, `profile_targets()` with direct
target `sd:sigma:(1 | id)`, and `check_drm()` random-effect replication
diagnostics. Shared post-fit helpers now recognize NB2 `sigma` random effects
without opening other non-Gaussian scale routes.

## Mathematical Contract

The fitted model is:

```text
y_i | b ~ NB2(mu_i, size_i = 1 / sigma_i^2)
log(mu_i) = offset_i + x_i beta_mu
log(sigma_i) = z_i beta_sigma + b_id[i]
b_id ~ Normal(0, sd_sigma^2)
Var(y_i | b) = mu_i + sigma_i^2 * mu_i^2
```

Here `sigma` is the public NB2 overdispersion scale. The random intercept
models grouped overdispersion heterogeneity on `log(sigma)`; it is not a
Gaussian residual SD and it is not applicable to Poisson, which has no fitted
`sigma` distributional parameter.

## Files Changed

- `R/drmTMB.R`
- `R/check.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-nbinom2-location-scale.R`
- `tests/testthat/test-nongaussian-scale-boundary.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/65-implementation-map-slices-341-355.md`
- `vignettes/count-nbinom2.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/implementation-map.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-24-nb2-sigma-random-intercept.md`

## Checks Run

```sh
air format NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/33-phase-6c-core-random-effects.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/design/65-implementation-map-slices-341-355.md vignettes/count-nbinom2.Rmd vignettes/distribution-families.Rmd vignettes/formula-grammar.Rmd vignettes/implementation-map.Rmd vignettes/model-map.Rmd vignettes/source-map.Rmd
Rscript -e "devtools::test(filter = 'nbinom2-location-scale|nongaussian-scale-boundary', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'NB2 `sigma` random effects remain planned|NB2 `sigma` random effects outside Wave A|NB2, truncated NB2, and hurdle NB2 `sigma` formulas remain fixed-effect only|Poisson `sigma` random intercepts|Poisson scale random effects now fit|joint `mu`/`sigma` random effects are fitted' README.md ROADMAP.md NEWS.md docs/design vignettes -g '!*.html'
rg -n 'bf\(count ~ x, sigma ~ z \+ \(1 \| id\)\)|log-`sigma` random-intercept|direct `log_sd_sigma`|NB2 `sigma` random intercepts' README.md ROADMAP.md NEWS.md docs/design vignettes tests/testthat/test-nbinom2-location-scale.R -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "NB2 sigma random" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "nbinom2 sigma" --limit 20 --json number,title,state,url,labels
git diff --check
```

Results:

- `air format` completed without output.
- The focused test run passed for `nbinom2-location-scale`,
  `nongaussian-scale-boundary`, and filter-adjacent
  `truncated-nbinom2-location-scale`.
- `pkgdown::check_pkgdown()` reported no problems.
- The direct stale-claim scan returned no hits.
- The positive scan found the new syntax, `log_sd_sigma` target wording, and
  test evidence in source docs and tests.
- `git diff --check` was clean.

## Tests Of The Tests

The new positive test simulates grouped NB2 overdispersion, fits
`sigma ~ z + (1 | id)`, checks convergence and `pdHess`, verifies fixed-effect
recovery, checks the fitted `sdpars$sigma` against the simulated SD, compares
estimated and simulated group overdispersion effects, and confirms that
`predict(dpar = "sigma")` and `sigma()` include the random-effect contribution.

Negative tests keep planned neighbours closed: NB2 `sigma` slopes, labelled
scale blocks, joint `mu`/`sigma` random effects, and zero-inflated NB2 `sigma`
random effects all error before fitting.

## Consistency Audit

README, ROADMAP, NEWS, formula grammar, family registry, likelihood notes,
validation-debt, readiness matrix, simulation programme, implementation map,
model map, source map, count tutorial, family tutorial, and tests now agree on
the bounded claim: ordinary NB2 log-`sigma` random intercepts fit. Poisson has
no fitted `sigma` parameter, and NB2 `sigma` slopes, structured scale effects,
zero-inflated/truncated/hurdle scale random effects, and joint `mu`/`sigma`
random effects remain planned.

The prose pass was written for applied ecology and evolution users: the docs
name the analysis question as grouped overdispersion heterogeneity and keep the
scale interpretation tied to `Var(y_i) = mu_i + sigma_i^2 * mu_i^2`.

## GitHub Issue Maintenance

Commands run:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "NB2 sigma random" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "nbinom2 sigma" --limit 20 --json number,title,state,url,labels
```

The direct `"nbinom2 sigma"` search returned no open issues. The broader
`"NB2 sigma random"` search returned #128, "Clarify random-effect slope
capacity across location and scale blocks", and #57, "Slices 97-99: proportion
example and non-Gaussian tutorial gate". Neither issue directly owns this
ordinary NB2 `sigma` random-intercept implementation, so no issue action was
taken.

## What Did Not Go Smoothly

The thread crashed after the code and focused tests were mostly in place, so
the resume had to reconstruct state from `git status`, diffs, tests, and local
dev-log evidence. One shell search used unescaped backticks and zsh tried to
interpret words such as `sigma`; that command was rerun with safe quoting before
the final stale scan.

## Team Learning

Rose should treat non-Gaussian `sigma` wording as a high-risk stale-status
surface after any count-family scale change. Pat should insist that public docs
say what an applied user can fit next, not only what remains planned.

## Known Limitations

No formal NB2 `sigma` random-intercept simulation grid has been run. The route
has focused deterministic recovery and boundary tests, not operating-
characteristic evidence over group count, observations per group, mean count,
true overdispersion, and true scale SD.

The first gate is independent and intercept-only. It does not support NB2
`sigma` slopes, labelled covariance, simultaneous `mu` and `sigma` random
effects, zero-inflated/truncated/hurdle NB2 scale random effects, or structured
NB2 `sigma` effects.

`pkgdown::build_site()` was not rerun in this resume; `pkgdown::check_pkgdown()`
passed.

## Next Actions

Add a small NB2 log-`sigma` random-intercept smoke grid before promoting the
route beyond focused-test evidence. Keep the grid separate from the existing
Poisson/NB2 `mu` random-effect and Poisson/NB2 phylogenetic q=1 lanes.

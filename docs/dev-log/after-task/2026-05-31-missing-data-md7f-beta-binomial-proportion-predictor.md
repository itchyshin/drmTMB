# After Task: Missing Data MD7f Beta-Binomial Proportion Predictor

## Goal

Finish the denominator-aware proportion branch of the non-Gaussian
missing-predictor module.

## Implemented

MD7f adds `beta_binomial()` as a predictor-model family for one missing
proportion predictor in a univariate Gaussian location model. The user-facing
syntax keeps the fitted response model and the predictor model separate:

```r
drmTMB(
  bf(y ~ z + mi(cover), sigma ~ 1),
  data = dat,
  impute = list(
    cover = impute_model(
      success ~ z,
      family = beta_binomial(),
      trials = trials
    )
  ),
  missing = miss_control(predictor = "model")
)
```

The response model uses `mi(cover)`, where `cover` is the response-model
proportion predictor. The impute model uses integer `success` counts and known
integer `trials` denominators to define the predictor likelihood. Observed
`cover` values must match `success / trials` up to numerical tolerance.

## Mathematical Contract

For the missing predictor,

```text
logit(p_xi) = W_i alpha
phi_x = exp(log_sigma_mi)
success_i ~ beta_binomial(trials_i, p_xi, phi_x)
cover_i = success_i / trials_i
```

Observed predictor rows contribute the beta-binomial predictor likelihood:

```text
log p(success_i | trials_i, p_xi, phi_x)
```

Missing predictor rows sum over all admissible success counts:

```text
log L_i =
  log sum_{s = 0}^{trials_i}
    p(s | trials_i, p_xi, phi_x)
    p(y_i | mu_i(s / trials_i), sigma_i) ^ observed_y_i
```

Rows where both the response and the proportion predictor are missing
contribute zero direct likelihood because the latent success-state
probabilities sum to one, and they remain in original-row accounting.

## Files Changed

- `R/missing-data.R`: captures `trials` safely in `impute_model()`, validates
  denominator-aware beta-binomial predictor inputs, maps the family to TMB
  `mi_family = 12`, and finalizes `imputed()` output with conditional
  proportion means and success-state probabilities.
- `R/drmTMB.R`: updates public missing-data documentation, dense known-`V`
  guards, missing-data version labelling, beta-binomial missing-predictor scale
  handling, and `sigma_mi_*` coefficient extraction.
- `src/drmTMB.cpp`: uses the beta-binomial missing-predictor likelihood branch
  with deterministic summation over `0:n_i` success states.
- `tests/testthat/test-missing-predictor-beta-binomial.R`: adds likelihood,
  response-mask, `imputed()`, metadata, and validation tests.
- `tests/testthat/test-phylo-utils.R`: updates manual TMB test scaffolds with
  the new `mi_successes` and `mi_trials` data objects required by the compiled
  template.
- `vignettes/missing-data.Rmd` and
  `pkgdown-site/articles/missing-data.html`: add the denominator-aware
  proportion missing-predictor example.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: record the syntax, likelihood, and
  implementation-slice boundary.
- `NEWS.md`, `man/drmTMB.Rd`, `man/miss_control.Rd`, `man/impute_model.Rd`,
  and `man/imputed.Rd`: update public release and reference documentation.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-beta-binomial.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-beta-binomial.R')"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "devtools::load_all(); rmarkdown::render('vignettes/missing-data.Rmd', output_dir = 'pkgdown-site/articles', output_file = 'missing-data.html', quiet = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
air format --check R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-beta-binomial.R tests/testthat/test-phylo-utils.R
git diff --check
```

Results:

- Focused `test-missing-predictor-beta-binomial.R`: 27 expectations, no
  failures, warnings, or skips.
- Existing `test-beta-binomial.R`: 78 expectations, no failures, warnings, or
  skips.
- Combined `devtools::test(filter = 'missing-predictor')`: 376 expectations,
  no failures, warnings, or skips.
- Focused `test-phylo-utils.R` after the manual scaffold update: 79
  expectations, no failures, warnings, or skips.
- Full `devtools::test()`: 9,077 expectations, no failures, warnings, or
  skips.
- `rmarkdown::render()` rebuilt
  `pkgdown-site/articles/missing-data.html`.
- `pkgdown::check_pkgdown()`: no problems found.
- `air format --check` and `git diff --check` passed.

## Tests Of The Tests

The beta-binomial predictor test independently recomputes `logLik(fit)` from
the observed beta-binomial predictor density, the Gaussian response likelihood,
and deterministic summation over `0:n_i` success states for missing predictor
values. A second likelihood check repeats that calculation with missing
responses included. Validation tests cover missing denominators, denominator
expressions, fractional successes, successes greater than trials, missing
trials, grouped predictor formulas, mismatched observed proportions, and rows
where `cover` is observed but the success count is missing.

## Consistency Audit

```sh
rg -n "beta_binomial|beta-binomial|MD7f|denominator-aware|conditional_proportion_mean" R/missing-data.R R/drmTMB.R src/drmTMB.cpp tests/testthat/test-missing-predictor-beta-binomial.R tests/testthat/test-phylo-utils.R vignettes/missing-data.Rmd pkgdown-site/articles/missing-data.html docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md man/drmTMB.Rd man/miss_control.Rd man/impute_model.Rd man/imputed.Rd
rg -n "denominator-aware beta-binomial predictor models remain planned|beta-binomial predictor models remain planned|beta_binomial.*not implemented|beta_binomial.*Unsupported missing-predictor|MD7f.*planned|denominator-aware.*planned" R man NEWS.md docs/design vignettes pkgdown-site/articles/missing-data.html tests/testthat/test-missing-predictor-beta-binomial.R
```

The positive scan confirmed current MD7f wording in the implementation,
generated Rd files, design docs, article source, rendered article, tests, and
`NEWS.md`. The stale scan returned only current broad future-boundary wording
and did not find current missing-data docs claiming that denominator-aware
beta-binomial missing predictors remain unimplemented.

This slice also completes the fixed-effect one-missing-predictor
non-Gaussian module currently covered by the missing-data lane: binary,
ordered, unordered, strict beta proportions, zero-one beta proportions,
denominator-aware beta-binomial proportions, Poisson counts, NB2 counts,
zero-truncated NB2 positive counts, lognormal positive continuous predictors,
Gamma positive continuous predictors, and Tweedie semi-continuous predictors.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "beta-binomial missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "denominator-aware missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "proportion missing predictor" --limit 20
```

All three searches returned no issue rows, so no issue was commented on,
closed, or opened for MD7f in this pass.

## What Did Not Go Smoothly

The first full package test run exposed a non-feature failure in manual TMB
phylogeny test scaffolds. The compiled template now requires
`mi_successes` and `mi_trials`, so manual `TMB::MakeADFun()` tests need to
provide those data objects even when they do not exercise missing predictors.
The scaffold was updated and the full suite then passed.

## Team Learning

Denominator-aware proportions need an explicit count process. Treating a
proportion as a continuous beta predictor is not enough when the denominator is
known and small, because the support is discrete and the likelihood must sum
over admissible integer successes.

## Known Limitations

MD7f is one fixed-effect denominator-aware beta-binomial missing predictor in
a univariate Gaussian location model. Multiple missing predictors, grouped or
structured non-Gaussian predictor models, transformed or interacted `mi()`
terms, hurdle count predictors, EM/profile engines, REML, simulation-based
imputed summaries, response imputation, measurement-error models, and pigauto
interoperability remain planned.

## Next Actions

- Keep the current module boundary at one fixed-effect missing predictor until
  the joint model for multiple missing predictors is designed explicitly.
- Add grouped or structured non-Gaussian predictor models only after choosing a
  family-specific random-effect contract.
- Keep measurement-error models separate from missing predictors because they
  require an observation-error layer for noisy observed predictors, not only a
  latent predictor model for missing values.

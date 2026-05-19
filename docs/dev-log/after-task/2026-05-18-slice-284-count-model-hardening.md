# After Task: Slice 284 Count-Model Hardening

## Goal

Harden the count-model evidence layer so Poisson, NB2, zero-truncated NB2,
zero-inflated Poisson, zero-inflated NB2, and hurdle NB2 surfaces have explicit
fixed-effect interval evidence for their fitted count dpars, while keeping the
ordinary Poisson/NB2 `mu` random-effect boundary visible.

## Implemented

The count test files now assert that `confint()` returns Wald fixed-effect rows
for each fitted count-family distributional parameter:

- Poisson: `mu`;
- NB2 and zero-truncated NB2: `mu` and `sigma`;
- zero-inflated Poisson: `mu` and `zi`;
- zero-inflated NB2: `mu`, `sigma`, and `zi`;
- hurdle NB2: `mu`, `sigma`, and `hu`.

The count tutorial now states the current boundary directly: fixed-effect
Poisson, NB2, zero-inflated Poisson, zero-inflated NB2, zero-truncated NB2, and
hurdle NB2 are fitted; ordinary non-zero-inflated Poisson and NB2 `mu` models
also fit unlabelled random intercepts and independent numeric random slopes;
zero-inflated, hurdle, truncated, and scale-side count routes remain
fixed-effect only.

## Mathematical Contract

No likelihood, link, random-effect, or parser contract changed. This slice
only adds interval-surface assertions for already-fitted fixed-effect count
dpars. The tests keep `hu` as the public hurdle probability dpar while
confirming that the internal TMB parameter remains `beta_zi`, matching the
existing hurdle implementation.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `tests/testthat/test-poisson-mean.R`
- `tests/testthat/test-nbinom2-location-scale.R`
- `tests/testthat/test-truncated-nbinom2-location-scale.R`
- `tests/testthat/test-zi-poisson.R`
- `tests/testthat/test-zi-nbinom2.R`
- `tests/testthat/test-hurdle-nbinom2.R`
- `vignettes/count-nbinom2.Rmd`

## Checks Run

```sh
air format tests/testthat/test-poisson-mean.R tests/testthat/test-nbinom2-location-scale.R tests/testthat/test-truncated-nbinom2-location-scale.R tests/testthat/test-zi-poisson.R tests/testthat/test-zi-nbinom2.R tests/testthat/test-hurdle-nbinom2.R vignettes/count-nbinom2.Rmd
air format NEWS.md ROADMAP.md
Rscript -e "devtools::test(filter = 'poisson-mean|nbinom2-location-scale|truncated-nbinom2-location-scale|zi-poisson|zi-nbinom2|hurdle-nbinom2', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|phase18-nbinom2-mu-random-effect', reporter = 'summary')"
Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/count-nbinom2.Rmd", output_dir = tempfile("count-nbinom2-render-"), quiet = FALSE)'
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

All checks passed. `pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

The new expectations check the exact `confint()` row names and TMB parameter
families, so a missing `zi`, `hu`, or `sigma` interval row would fail. The
existing count tests still compare fitted likelihoods to independent
calculations, exercise offsets and response-scale methods, and reject
unsupported count random effects. The Phase 18 Poisson/NB2 smoke tests keep
the fitted mixed-count evidence separate from the fixed-effect zero-inflated,
truncated, and hurdle routes.

## Consistency Audit

Exact searches used:

```sh
rg -n 'implemented count path is intentionally fixed-effect|count path is intentionally fixed-effect|fixed-effect and univariate|meta_known_V\(V = V\) with counts|random effects in NB2 `sigma` or `zi`' vignettes/count-nbinom2.Rmd vignettes/distribution-families.Rmd docs/design README.md ROADMAP.md NEWS.md
rg -n 'Slice 284|Count-family tests|fixed-effect Wald interval rows|ordinary non-zero-inflated Poisson/NB2|zero-inflated NB2|hurdle NB2|confint\(fit\)|fixef:hu|fixef:zi|fixef:sigma' NEWS.md ROADMAP.md vignettes/count-nbinom2.Rmd tests/testthat/test-poisson-mean.R tests/testthat/test-nbinom2-location-scale.R tests/testthat/test-truncated-nbinom2-location-scale.R tests/testthat/test-zi-poisson.R tests/testthat/test-zi-nbinom2.R tests/testthat/test-hurdle-nbinom2.R
```

The remaining "fixed-effect and univariate" hits are unrelated design notes or
historical roadmap rows. The current count tutorial now says the fitted
mixed-count route is ordinary non-zero-inflated Poisson/NB2 `mu` random
intercepts and independent numeric slopes.

## What Did Not Go Smoothly

The first broad source search was too noisy because it matched every count
equation and test helper. I narrowed the audit to the stale boundary phrase,
the preferred count/`meta_V()` wording, and the new interval-evidence rows.

## Team Learning

Ada kept the slice to evidence hardening rather than widening count syntax.
Curie and Fisher focused the new assertions on interval rows that Phase 18
reports can reuse. Pat and Darwin pushed the tutorial boundary from "not
implemented" toward "what can I fit today?" Grace required the rendered count
article plus pkgdown pass. Rose flagged the stale fixed-effect-only wording
before it could survive another slice.

## Known Limitations

This slice does not add zero-truncated NB2 random effects, zero-inflated count
random effects, hurdle random effects, NB2 `sigma` random effects, correlated
or labelled count slopes, structured count effects, COM-Poisson, or
mixed-response count models.

## Next Actions

- Slice 285 should do the same evidence-style pass for beta, beta-binomial,
  and planned zero-one-inflation routes.
- Future count hardening should add likelihood or boundary evidence one route
  at a time: zero-truncated NB2 `mu`, zero-inflated count random effects,
  count-side scale random effects, or count structured effects should not be
  bundled into one broad change.

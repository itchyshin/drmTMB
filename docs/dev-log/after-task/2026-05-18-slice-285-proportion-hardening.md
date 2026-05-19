# After Task: Slice 285 Proportion Hardening

## Goal

Harden the fitted beta and beta-binomial proportion paths without opening new
zero-one-inflation, random-effect, structured, mixed-response, or
meta-analysis likelihood routes.

## Implemented

Fixed-effect `beta()` and `beta_binomial()` fits now have explicit Wald
interval row tests for their fitted `mu` and `sigma` coefficients. The
proportion tutorial and status docs now state that the fitted bounded-response
path is fixed-effect and univariate, while fixed-effect `zoi`/`coi`,
zero-one-inflation, random effects, structured dependence, mixed responses, and
bounded-response `meta_V(V = V)` routes remain planned or blocked.

## Mathematical Contract

The slice does not change likelihood parameterization. Both fitted families
retain `logit(mu)`, `log(sigma)`, and internal beta precision
`phi = 1 / sigma^2`. The new interval checks only assert that the public fixed
coefficients map to the expected TMB blocks: `beta_mu` for `mu` rows and
`beta_sigma` for `sigma` rows.

## Files Changed

- `tests/testthat/test-beta-location-scale.R`
- `tests/testthat/test-beta-binomial.R`
- `vignettes/proportion-beta-binomial.Rmd`
- `docs/design/02-family-registry.md`
- `docs/design/34-validation-debt-register.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-213216-codex-checkpoint.md`

## Checks Run

```sh
air format tests/testthat/test-beta-location-scale.R tests/testthat/test-beta-binomial.R vignettes/proportion-beta-binomial.Rmd docs/design/02-family-registry.md docs/design/34-validation-debt-register.md NEWS.md ROADMAP.md
Rscript -e "devtools::test(filter = 'beta-location-scale|beta-binomial', reporter = 'summary')"
Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/proportion-beta-binomial.Rmd", output_dir = tempfile("proportion-render-"), quiet = FALSE)'
rg -n 'meta_known_V\(V = V\) with beta|fixed `zoi` and `coi` likelihoods should come before|zero-one-inflated beta.*fitted|beta-binomial zero-inflation.*fitted|implemented bounded-response path is intentionally fixed-effect|fixed-effect `zoi` or `coi` likelihoods' vignettes/proportion-beta-binomial.Rmd vignettes/distribution-families.Rmd docs/design README.md ROADMAP.md NEWS.md
rg -n 'Slice 285|Proportion-family tests|fixed-effect beta and beta-binomial|fixef:sigma|meta_V\(V = V\)|fixed-effect `zoi`|Wald interval row checks' NEWS.md ROADMAP.md docs/design/02-family-registry.md docs/design/34-validation-debt-register.md vignettes/proportion-beta-binomial.Rmd tests/testthat/test-beta-location-scale.R tests/testthat/test-beta-binomial.R
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript -e "devtools::test(reporter = 'summary')"
Rscript tools/codex-checkpoint.R --goal "Slice 285 proportion hardening" --next "stage, commit, push, and open draft PR"
```

All commands passed. The stale-wording search returned only intended planned or
blocked boundary text, including the current tutorial row that structural 0/1
continuous proportions are not a fitted `drmTMB` path yet.

## Tests Of The Tests

The new assertions would fail if `confint()` dropped beta or beta-binomial
fixed-effect rows, mislabeled `fixef:mu` or `fixef:sigma`, mapped rows to the
wrong TMB parameter block, or returned a non-Wald status for these fitted
fixed-effect coefficients. The same test files already compare beta and
beta-binomial log likelihoods to independent `dbeta` and beta-binomial
calculations and keep boundary and unsupported-input failures in place.

## Consistency Audit

The family registry now names fixed-effect Wald interval evidence for beta and
beta-binomial. The validation-debt register records that Slice 285 did not open
`zoi` or `coi` likelihoods. The proportion tutorial now leads with the fitted
route a new applied user should use: counted successes and failures go through
`beta_binomial()`, and strict interior continuous proportions go through
`beta()`.

## What Did Not Go Smoothly

The first patch attempt for the beta-binomial test targeted a response-scale
prediction block that lives in a later test. I corrected it by adding the
interval assertions to the first beta-binomial fit test beside the existing
model-type, convergence, and trial-count checks.

## Team Learning

Ada kept the slice bounded to evidence and documentation. Fisher and Curie
strengthened the inference contract by checking interval rows in addition to
the existing independent-likelihood comparators. Pat and Darwin made the
tutorial boundary more direct for proportion users. Grace confirmed the full
test suite, pkgdown check, and whitespace check pass. Rose kept the stale
`meta_known_V()` and `zoi`/`coi` wording synchronized with the current
implemented-versus-planned status. No spawned subagents were used.

## Known Limitations

No new bounded-response likelihood, formula grammar, random-effect support,
structured dependence, bivariate or mixed-response route, profile interval
producer, or simulation grid was added. Fixed-effect `zoi`/`coi`,
zero-one-inflated beta, ordered beta, beta-binomial zero-inflation,
bounded-response `meta_V(V = V)`, and proportion random effects remain future
work.

## Next Actions

Continue with Slice 286 by documenting the continuous-shape and skewness
boundary before any simulation or likelihood work. Keep residual `nu` or
skewness effects separate from any future latent-effect `skew(id)` grammar.

# After Task: Slice 288 Mixed-Family Status

## Goal

Audit and harden the status of two-response mixed-family combinations without
opening any Gaussian-count, Gaussian-proportion, count-proportion, ordinal
mixed, or higher-dimensional response route.

## Implemented

Mixed-response bivariate combinations remain planned. The all-Gaussian
composed-family spellings, `family = c(gaussian(), gaussian())` and
`family = list(gaussian(), gaussian())`, remain the only composed-family route
that fits. Tests now cover mixed-family errors for both `c()` and `list()`
spellings, including reversed Gaussian-Poisson order and a Gaussian-beta
combination. The family registry, distribution-family tutorial, NEWS, ROADMAP,
and pre-simulation matrix now require a joint likelihood or
copula/latent-variable contract before any mixed-response route is fitted.

## Mathematical Contract

No likelihood changed. The fitted two-response surface remains all-Gaussian
with `mu1`, `mu2`, `sigma1`, `sigma2`, and residual `rho12`. Mixed-response
routes must later decide what cross-response dependence means: an observed
residual correlation, a latent residual correlation, a copula parameter, a
shared random effect, or no residual association parameter.

## Files Changed

- `tests/testthat/test-biv-gaussian.R`
- `docs/design/02-family-registry.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `vignettes/distribution-families.Rmd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-214925-codex-checkpoint.md`

## Checks Run

```sh
air format tests/testthat/test-biv-gaussian.R docs/design/02-family-registry.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/distribution-families.Rmd NEWS.md ROADMAP.md
Rscript -e "devtools::test(filter = 'biv-gaussian|family-link-contract|source-map', reporter = 'summary')"
Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/distribution-families.Rmd", output_dir = tempfile("distribution-families-render-"), quiet = FALSE)'
rg -n 'Slice 288|Mixed-response|mixed-response|Gaussian-count|Gaussian-proportion|count-proportion|family = c\(gaussian\(\), poisson\(\)\)|list\(gaussian\(\), poisson\(\)\)|one-response and two-response|gllvmTMB|joint likelihood|copula' NEWS.md ROADMAP.md docs/design/02-family-registry.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/distribution-families.Rmd tests/testthat/test-biv-gaussian.R README.md vignettes/model-map.Rmd
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 288 mixed-family status" --next "stage, commit, push, and open draft PR"
```

All commands passed.

## Tests Of The Tests

The new tests would fail if `family = list(gaussian(), poisson())`,
`family = c(poisson(), gaussian())`, or `family = c(gaussian(), beta())`
started routing to a likelihood instead of producing the mixed-response
boundary. Existing bivariate tests still cover the positive all-Gaussian
`c()` and `list()` composed-family paths and the rejection of three response
families.

## Consistency Audit

The roadmap now marks Slice 288 done locally. The family registry and
pre-simulation matrix both say mixed-response bivariate families are not ready
until they have a joint likelihood or copula/latent-variable contract,
prediction, simulation, extractors, intervals, examples, and comparator or
independent-likelihood tests. The distribution-family tutorial tells users
that Gaussian-count examples are a planned direction, not runnable syntax.

## What Did Not Go Smoothly

No blocker emerged. The main risk was scope creep: a mixed Gaussian-count
route is scientifically tempting, but opening it now would outrun the
likelihood and interpretation contract.

## Team Learning

Ada kept the slice to boundary hardening. Boole checked composed-family syntax
for both `c()` and `list()` spellings. Emmy kept the object/API story tied to
the existing bivariate Gaussian engine. Fisher and Curie kept simulation
admission behind a joint-likelihood and comparator gate. Pat and Darwin kept
ecological mixed-response examples framed as future use cases. Grace confirmed
pkgdown and the bivariate tests. Rose kept higher-dimensional multivariate
models assigned to `gllvmTMB`. No spawned subagents were used.

## Known Limitations

No mixed-response bivariate likelihood, residual-association parameter,
copula, shared-random-effect bridge, extractor, interval, simulation, or
worked example was added.

## Next Actions

Continue with Slice 289 by auditing prediction, extractor, plotting, `vcov`,
`corpairs()`, and `emmeans` status across the fitted surfaces before any new
helper or user-facing plotting claim is made.

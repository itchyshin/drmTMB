# After Task: Variability Orientation Contract

## Goal

Clarify how `drmTMB` reconciles the public `sigma` grammar with families and
comparator software that use precision, size, shape, or variance parameters.

## Implemented

- Added the design rule that larger public `sigma` should mean larger modelled
  variability, dispersion, or heterogeneity.
- Documented that some likelihoods still use internal or comparator parameters
  such as beta precision `phi`, NB2 size `theta`, Gamma shape, or Student-t
  `nu`.
- Added a conversion table to `vignettes/distribution-families.Rmd`.
- Added a short warning in `vignettes/which-scale.Rmd` so users do not transfer
  the Gaussian `sigma^2` shortcut to every family.
- Added the orientation contract to `docs/design/03-likelihoods.md` and the
  README landing text.

## Mathematical Contract

For implemented mean-scale families, `sigma` is the public variability-facing
quantity:

```text
larger sigma -> larger modelled variability
```

This means precision-like likelihoods are inverted internally where needed. For
example, beta and beta-binomial models use `phi = 1 / sigma^2`, and NB2 models
use `theta = 1 / sigma^2` or `size = 1 / sigma^2`. Student-t `nu` remains a
shape parameter: larger `nu` means lighter tails, not larger variability.

## Files Changed

- `README.md`
- `docs/design/03-likelihoods.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/which-scale.Rmd`

## Checks Run

- `air format README.md docs/design/03-likelihoods.md vignettes/distribution-families.Rmd vignettes/which-scale.Rmd`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`

## Tests Of The Tests

This was a documentation and design-contract change, so no new unit test was
added. Existing tests already check the implemented parameter conversions for
beta, beta-binomial, Gamma, NB2, hurdle NB2, and Student-t models.

## Consistency Audit

The README, family-selection vignette, scale-selection vignette, and likelihood
design document now tell the same story: `sigma` is stable syntax, but users
must convert to family-specific variance, precision, size, or shape summaries
before comparing with another package or paper.

## What Did Not Go Smoothly

The old wording was technically correct in scattered places but did not give
users one rule to carry between families. The new wording makes that rule
visible before the detailed formulas.

## Team Learning

- Pat: an applied user should not need to know whether a model is internally
  using precision before interpreting a `sigma` coefficient.
- Boole: stable syntax is good only when the semantic direction is stable too.
- Fisher: comparator checks must transform `sigma` to the comparator's
  parameterization before comparing numeric estimates.
- Rose: keep the user-facing rule and the internal/comparator table together so
  future family additions do not drift.

## Known Limitations

- Tweedie, COM-Poisson, ordinal scale/discrimination, and skew-normal scale or
  shape conventions remain design work.
- The table covers implemented families only; future families must add their
  own row before the feature is considered documented.

## Next Actions

- Add the same orientation row to any future family checklist.
- When implementing Tweedie or skew-normal models, decide separately which
  parameter is a public `sigma`, which parameter is shape, and how increasing
  each parameter changes biological variability.

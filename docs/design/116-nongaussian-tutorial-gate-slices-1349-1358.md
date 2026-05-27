# Non-Gaussian Tutorial Gate: Slices 1349-1358

This note records the reader-facing follow-through after the fixed-effect
zero-one beta source and artifact lanes. The reader is an applied ecology,
evolution, or environmental-science user choosing between count, success-rate,
strict continuous proportion, and exact-boundary continuous proportion models.

## Claim

The non-Gaussian tutorial route is now coherent for the fitted count and
bounded-response examples. It teaches fixed-effect count examples in
`vignettes/count-nbinom2.Rmd`, bounded-response examples in
`vignettes/proportion-beta-binomial.Rmd`, and sends contributors to the
implemented source map when they need code, tests, and design evidence.

## Reader Route

The proportion decision table is:

```text
successes out of known trials -> beta_binomial()
continuous proportions strictly inside (0, 1) -> beta()
continuous proportions on [0, 1] with structural exact boundaries -> zero_one_beta()
```

`beta()` and `beta_binomial()` also have ordinary unlabelled `mu` random
intercepts as first mixed-model slices. `zero_one_beta()` is fixed-effect only:
`mu`, `sigma`, `zoi`, and `coi` formulas can vary with predictors, but bar
terms in those parameters still belong to the planned ledger.

## Source Evidence

- `vignettes/source-map.Rmd` now lists `zero_one_beta()` in the router,
  `model_type = 15`, and the implemented-path table.
- `vignettes/drmTMB.Rmd` sends readers with trial counts, strict continuous
  proportions, or structural exact boundaries to the same proportions article.
- `vignettes/model-map.Rmd` lists fixed-effect zero-one beta among fitted
  one-response family routes while keeping zero-one beta random effects and
  structured bounded responses planned.
- `_pkgdown.yml` already places "Proportions and success rates" under Applied
  Family Tutorials, so the synchronized route is visible on the built site.

## Boundary

This slice does not add formula grammar, likelihood code, tests, or new
simulation artifacts. It also does not close the future bounded-response
random-effect programme. Random slopes, random effects in `sigma`, `zoi`, or
`coi`, `sd(group) ~ ...`, known covariance, `phylo()`, `spatial()`,
`animal()`, `relmat()`, ordered beta, beta-binomial zero inflation, denominator
shorthand for zero-one beta, and bivariate or mixed bounded-response models
remain planned until they have implementation, recovery, diagnostics, and
reader-facing evidence.

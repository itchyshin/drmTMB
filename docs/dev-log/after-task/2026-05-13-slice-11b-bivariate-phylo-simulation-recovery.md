# After Task: Slice 11B Bivariate Phylogenetic Simulation Recovery

## Goal

Add CRAN-safe simulation evidence for the fitted bivariate phylogenetic
`mu1`/`mu2` mean-mean correlation.

## Implemented

`tests/testthat/test-phylo-gaussian.R` now includes a deterministic simulation
with 32 tips and replicated observations per species. The data-generating model
uses matching intercept-only `phylo()` terms in `mu1` and `mu2`, positive
phylogenetic mean-mean correlation, nonzero residual `rho12`, and fixed
residual scales. The fitted model must converge, recover the positive
phylogenetic correlation within a moderate tolerance, recover the phylogenetic
SDs and residual scales, and report the same correlation through `corpairs()`.

## Mathematical Contract

```text
[a_mu1, a_mu2] ~ MatrixNormal(0, Q_aug^{-1}, Sigma_phylo)
cor(Sigma_phylo[1,2]) = rho_phylo
rho12 = residual within-observation correlation
```

This test exercises the first fitted bivariate phylogenetic location layer. It
does not test spatial covariance, phylogenetic scale effects, or q=4
location-scale covariance.

## Files Changed

- `tests/testthat/test-phylo-gaussian.R`
- `ROADMAP.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-11b-bivariate-phylo-simulation-recovery.md`

## Checks Run

- `air format R/check.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-check-drm.R ROADMAP.md docs/design/15-location-coscale-phylogenetic-extension.md docs/design/16-phylo-spatial-common-math.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`: passed.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm")'`: passed with 165 expectations.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm|corpairs|summary|profile-targets")'`: passed with 620 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.

## Tests Of The Tests

The new test uses known simulation parameters and checks recovery on both the
random-effect scale (`sdpars$mu`, `corpars$phylo`) and the response scale
(`sigma()`, `rho12()`). It also checks the public correlation-pair reporting
surface instead of only reading internal parameters.

## Consistency Audit

The roadmap and common-math design note now say the bivariate phylogenetic
mean-mean layer has deterministic simulation recovery evidence. They still mark
spatial models and full q=4 phylogenetic location-scale covariance as planned.

## What Did Not Go Smoothly

The first interactive probe used `tree = sim$tree`, and the formula grammar
correctly rejected it. The test therefore follows the public contract:
bind `tree <- sim$tree` and use `tree = tree` inside `phylo()`.

## Team Learning

Curie should keep these recovery tests deterministic and moderate. One large,
stable positive-correlation simulation gives useful evidence without turning
routine checks into a long simulation study.

## Known Limitations

This is one positive-correlation recovery scenario. Longer optional simulations
are still needed for weak phylogenetic signal, near-zero phylogenetic SD, high
residual noise, negative phylogenetic correlations, and simultaneous
phylogenetic plus non-phylogenetic species effects.

## Next Actions

Use the fitted layer in examples with clear diagnostics. Do not move into
spatial covariance until the user explicitly reopens that lane.

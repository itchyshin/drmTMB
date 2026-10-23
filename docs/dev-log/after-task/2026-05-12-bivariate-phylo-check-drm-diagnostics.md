# After Task: Bivariate Phylogenetic check_drm Diagnostics

## Goal

Add a first-pass diagnostic for the newly implemented bivariate phylogenetic
`mu1`/`mu2` covariance block, and record the species-covariance scope decision
without opening phylogenetic scale effects.

## Implemented

`check_drm()` now adds a `biv_phylo_mu_covariance` row when a bivariate
Gaussian fit includes matching intercept-only
`phylo(1 | species, tree = tree)` terms in `mu1` and `mu2`. The row reports
the number of observed species, the minimum fitted observations per species,
the number of singleton species, and the smallest ratio of fitted phylogenetic
location SD to the matching residual scale.

The diagnostic returns `ok` when observed species are replicated and both
phylogenetic SDs are non-negligible relative to residual scale. It returns a
`note`, not a warning, when a species has fewer than two fitted observations or
when one phylogenetic SD is tiny relative to residual scale. The note tells the
user to inspect identifiability before interpreting the phylogenetic
mean-mean correlation.

The documentation now records that non-phylogenetic species covariance should
use the ordinary labelled group-level path, for example matching
`(1 | species_block | species)` terms in `mu1` and `mu2`. The `phylo()` path is
reserved for tree-structured covariance through `corpars$phylo`.

## Mathematical Contract

The diagnostic is attached to the existing fitted block:

```text
mu1_i = X_mu1[i, ] beta_mu1 + a_1[species_i]
mu2_i = X_mu2[i, ] beta_mu2 + a_2[species_i]
[a_1, a_2] ~ MVN(0, A %x% Sigma_phylo)
```

It does not add new likelihood terms. It inspects whether the observed species
replication and fitted phylogenetic SDs give the already-fitted correlation a
reasonable interpretation surface.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `NEWS.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md docs/design/16-phylo-spatial-common-math.md docs/dev-log/known-limitations.md vignettes/phylogenetic-spatial.Rmd`
- `Rscript -e "devtools::test(filter = 'check-drm|phylo')"`: 187 passed.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: 95 passed after final
  formatting.
- `Rscript -e "devtools::test()"`: 1980 passed.
- `Rscript -e "devtools::document()"`: regenerated `man/check_drm.Rd`.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.

## Tests Of The Tests

The new test fits a small bivariate phylogenetic Gaussian model, then checks
three diagnostic branches: replicated species with non-tiny phylogenetic SDs,
a mutated singleton-species case, and a mutated tiny phylogenetic SD relative
to residual scale. This keeps the test focused on diagnostic routing rather
than asking a tiny example to prove long-run covariance recovery.

## Consistency Audit

The check documentation, NEWS, phylogenetic/spatial design note, known
limitations, and phylogenetic tutorial now agree on the narrow scope:
bivariate phylogenetic `mu1`/`mu2` covariance is implemented for matching
intercept-only terms; phylogenetic slopes, phylogenetic scale effects,
structured `rho12`, and spatial effects remain planned.

## What Did Not Go Smoothly

The original next-action wording could have been read as adding new modelling
surface. The safer interpretation was diagnostic-only: expose weak
identifiability signals for the fitted location block, and keep scale effects
outside the likelihood until longer simulation evidence exists.

## Team Learning

- Ada should close next-action items by deciding whether they are modelling,
  diagnostic, or documentation work before touching TMB code.
- Fisher should treat tiny phylogenetic SDs relative to residual scale as an
  interpretation warning sign for the correlation, not as proof of a failed
  fit.
- Pat needs the tutorial to say which species-covariance syntax to try when
  the user does not have or does not want to use a phylogeny.
- Rose should keep phylogenetic scale effects out of implemented wording until
  there is code, recovery evidence, `corpairs()` rows, and examples.

## Known Limitations

- The diagnostic is a first-pass replication and fitted-SD check, not a formal
  identifiability test or long-run coverage simulation.
- It does not check separability when both phylogenetic and non-phylogenetic
  species effects are included; that richer model is still planned.
- Phylogenetic effects in `sigma1`, `sigma2`, and `rho12` remain planned.

## Next Actions

1. Add a reader-facing mammal or species example only after choosing a real
   dataset where ordinary species covariance and phylogenetic covariance answer
   different biological questions.
2. Keep collecting bivariate phylogenetic simulation evidence before adding
   phylogenetic slopes or scale effects.
3. Consider a future `check_drm()` separability row if ordinary species and
   phylogenetic species effects are ever allowed in the same fit.

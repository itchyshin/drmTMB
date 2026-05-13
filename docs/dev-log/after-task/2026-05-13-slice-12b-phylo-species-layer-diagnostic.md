# After Task: Slice 12B Phylo And Species Layer Diagnostic

## Goal

Guard the case where a bivariate model includes both a phylogenetic mean-mean
layer and an ordinary species-level covariance layer.

## Implemented

`check_drm()` now records whether a bivariate phylogenetic `mu1`/`mu2` fit also
contains an ordinary labelled group-level `mu1`/`mu2` covariance block using
the same grouping factor. When that overlap is present and the phylogenetic
correlation is not near the boundary, the `biv_phylo_mu_covariance` row returns
`note` and includes `same_group_covariance=true` in the diagnostic value.

The diagnostic message tells users to inspect profiles or simpler comparison
models before interpreting phylogenetic and non-phylogenetic species
correlations as cleanly separated.

## Mathematical Contract

The supported fitted layers remain distinct:

```text
rho12                            residual within-observation correlation
cor_species(mu1, mu2)             ordinary group-level species covariance
cor_phylo(mu1, mu2)               tree-structured phylogenetic covariance
```

The diagnostic does not claim these layers are always identifiable in finite
data. It marks the separation problem when both species-level layers use the
same grouping factor.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `ROADMAP.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/29-mammal-location-coscale-route.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-12b-phylo-species-layer-diagnostic.md`

## Checks Run

- `Rscript -e 'devtools::document()'`: passed and regenerated `man/check_drm.Rd`.
- `Rscript -e 'devtools::test(filter = "check-drm")'`: passed with 119 expectations.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm|corpairs|summary|profile-targets")'`: passed with 620 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.

## Tests Of The Tests

The new diagnostic test fits a model with both `(1 | species_residual |
species)` and matching `phylo(1 | species, tree = tree)` terms, then stabilizes
the fitted phylogenetic SD and correlation values to isolate the metadata
condition being tested. It checks the row status, the
`same_group_covariance=true` value, and the reader-facing warning text.

## Consistency Audit

The mammal route note no longer describes ordinary and phylogenetic mean-mean
covariance as future-only steps. It now says the first mean-mean layers are
implemented, while the same-group diagnostic guards overinterpretation.

## What Did Not Go Smoothly

A quick simulation probe showed that ordinary species and phylogenetic species
effects can trade signal. That pushed this slice toward a diagnostic note,
rather than a brittle recovery claim for the combined model.

## Team Learning

Fisher and Rose should keep identifiability caveats close to the fitted
surface. If a user can write the model, the first diagnostic should tell them
where interpretation is fragile.

## Known Limitations

The note is a first-pass guard. It does not compare nested models, compute a
separation metric, or decide whether a specific combined fit is scientifically
interpretable.

## Next Actions

Add optional longer simulations for simultaneous phylogenetic plus ordinary
species covariance once the current phylo-only evidence is committed.

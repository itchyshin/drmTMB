# After Task: Structural-Parity Status Refresh

## Goal

Keep the structural-dependence reader route current after the post-0.1.3
animal-pedigree, animal/`relmat()`, and spatial q=2 slices landed.

## Implemented

The structural-dependence tutorial no longer tells users that the animal
pedigree spelling is planned. It now says the fitted animal q=2 path includes
constant `corpairs(level = "animal")` rows for matching labelled pedigree,
`A`, or `Ainv` terms, while predictor-dependent animal `corpair()` regression
and sparse large-pedigree precision construction remain planned.

The article-split design note and the parity snapshot now match the current
fitted state: dense-pedigree animal intercepts, animal/`relmat()` q=2 location
covariance, and coordinate-spatial q=2 location covariance are fitted first
slices with smoke/artifact evidence, not broad parity.

## Mathematical Contract

No likelihood or formula grammar changed. This slice only corrected prose so
the text separates fitted constant q=2 structured location covariance from
planned predictor-dependent structured `corpair()` regression, q=4
location-scale blocks, structured slopes, spatial or relatedness `sigma`, and
large sparse precision routes.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `docs/design/53-structural-dependence-article-split.md`
- `docs/dev-log/structural-dependence-parity-2026-05-20.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
rg -n 'pedigree spelling is still planned|planned pedigree construction|animal.*pedigree.*planned|bivariate.*relmat.*planned|relmat.*bivariate.*planned|spatial, animal, and `relmat\(\)` rows as planned boundaries' vignettes/phylogenetic-spatial.Rmd docs/design/53-structural-dependence-article-split.md docs/dev-log/structural-dependence-parity-2026-05-20.md docs/design/39-visualization-grammar.md README.md ROADMAP.md NEWS.md
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian|spatial-gaussian')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

- The focused fitted-surface tests passed 158 expectations with no warnings or
  skips.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

This was a prose/status slice, so the key test was not new unit-test code. The
neighboring fitted-surface test run still exercised the animal/`relmat()` and
spatial model routes referenced by the corrected prose.

## Consistency Audit

The stale-wording scan no longer finds the current tutorial sentence that
called the pedigree spelling planned. Remaining hits are current status text
or historical NEWS/ROADMAP entries that either say the dense pedigree route is
fitted or keep sparse large-pedigree precision and richer covariance paths
planned.

## GitHub Issue Maintenance

Issue #147 remains open because it still tracks sparse large-pedigree
construction, structured slopes, `sigma` relatedness models, q=4 blocks,
predictor-dependent `corpair()` regression, direct-SD grammar, and non-Gaussian
structured effects. A short issue comment should be added after this branch is
merged so the issue ledger points to the current parity snapshot.

## What Did Not Go Smoothly

The stale sentence survived because it lived in an inference section rather
than the main status table, which had already been updated. Future status
refreshes should scan the full tutorial, not only the visible route table.

## Team Learning

Pat's check is to read prose in order, not just inspect status tables. Rose's
check is to scan for exact stale phrases from the previous slice before closing
the next slice.

## Known Limitations

This slice does not add examples, figures, simulations, or new fitted models.
Formal coverage reports and ecological examples for the new q=2 artifacts
remain future work.

## Next Actions

After merge, comment on issue #147 with the updated fitted/planned split.
Then move to the structural-dependence gallery refresh so spatial, animal, and
`relmat()` rows stop appearing only as planned boundaries.

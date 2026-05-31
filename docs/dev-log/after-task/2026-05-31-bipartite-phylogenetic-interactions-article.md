# After Task: Bipartite Phylogenetic Interactions Article

## Goal

Add a reader-facing article for the first `phylo_interaction()` route so applied
users can tell when to use the two-tree pair-level marker, when to use ordinary
independent pair effects, and when a planned richer bipartite model is still
needed.

## Implemented

The new article `vignettes/bipartite-phylogenetic-interactions.Rmd` introduces
the pair-level Gaussian/Poisson/NB2 `mu` slice, gives a small count example, and
shows the status boundary for independent pair effects, lower-level `relmat()`
precision input, additive partner main phylogenies, and binary incidence
models.

The article is linked from `_pkgdown.yml`, the structural-dependence overview,
and the phylogenetic structured-effects article.

## Mathematical Contract

The article presents the same contract used in the implementation:

```text
eta_i = X_i beta + z[a_i, b_i]
vec(z) ~ Normal(0, sd_pair^2 (A_partner2 kron A_partner1))
```

It explains that `eta_i` is the Gaussian location mean or the count-model log
mean, depending on the family.

## Files Changed

- `vignettes/bipartite-phylogenetic-interactions.Rmd`
- `vignettes/phylogenetic-models.Rmd`
- `vignettes/structural-dependence.Rmd`
- `_pkgdown.yml`
- `docs/dev-log/check-log.md`

## Checks Run

The final check-log entry records the exact commands. The relevant article
checks were:

- `air format` completed on `vignettes/bipartite-phylogenetic-interactions.Rmd`
  and linked status files.
- The article code parsed with `xfun::split_source()`.
- The article rendered with `rmarkdown::render()`.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site(lazy = TRUE, preview = FALSE)` built the article,
  Articles index, navbar link, structural-dependence link, phylogenetic-models
  link, reference page, and NEWS page.
- Rendered scans found "Two-tree phylogenetic interactions",
  `phylo_interaction()`, the `Q_pair` alignment warning, ordinary NB2 wording,
  and the #447 NEWS link on the expected built pages.
- `devtools::check(args = c("--no-manual"), error_on = "never")` completed in
  7m 11s with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The article examples are backed by the focused `test-phylo-interaction.R` fits
for Gaussian, Poisson, and NB2 models. The article itself is rendered during
the final audit, and the built site is scanned for the article, reference page,
Reference index entry, and NEWS entry.

## Consistency Audit

The article avoids claiming support for binary/Bernoulli incidence, simultaneous
partner main phylogenies plus an interaction, structured pair slopes, labelled
count covariance, or simultaneous structured layers. It explicitly tells users
to precompute `pair_id` for independent pair random effects because ordinary
`(1 | plant:pollinator)` parser sugar is not the supported route yet.

## GitHub Issue Maintenance

The article is part of issue #447 because discoverability is necessary for the
first fitted `phylo_interaction()` slice to be usable.

## What Did Not Go Smoothly

The article needed to be careful about the ecological wording. A plant-pollinator
example can tempt readers toward binary incidence or a full additive bipartite
decomposition, but this first slice only fits one pair-level structured field
for Gaussian and ordinary count means.

## Team Learning

- Darwin: examples should name real paired ecological data shapes, not only
  matrix algebra.
- Pat: the article should tell users exactly what to do for independent pair
  effects now.
- Rose: article navigation is part of the capability slice, not optional
  polish.

## Known Limitations

The article documents only the first q=1 pair-level route. It is not a tutorial
for binary incidence networks, full community matching models, simultaneous
structured layers, or additive partner main phylogenies plus an interaction.

## Next Actions

If #447 lands, consider a later grammar issue for ordinary colon-group parser
sugar and a separate design issue for the additive two-tree model.

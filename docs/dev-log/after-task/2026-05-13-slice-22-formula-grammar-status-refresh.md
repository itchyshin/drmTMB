# After Task: Slice 22 Formula Grammar Status Refresh

## Goal

Bring the public formula grammar article up to date with the newest covariance,
direct-SD, bivariate phylogenetic, and reserved-correlation syntax work.

## Implemented

- Added formula grammar status rows for:
  - the ordinary all-four q4 bivariate covariance block;
  - `sd1(id) ~ x_group` and `sd2(id) ~ x_group`;
  - matching bivariate `mu1`/`mu2` `phylo()` terms;
  - reserved `corpair()` formula syntax.
- Updated the bivariate covariance section with all-four q4 syntax.
- Explained that the fitted `corpairs()` output still uses `mean-*` classes,
  while `location-*` class names are accepted as filter aliases.
- Rebuilt the local pkgdown formula grammar article.

## Mathematical Contract

The article now describes the fitted ordinary q4 block:

```r
drm_formula(
  mu1 = y1 ~ x + (1 | p | ID),
  mu2 = y2 ~ x + (1 | p | ID),
  sigma1 = ~ z + (1 | p | ID),
  sigma2 = ~ z + (1 | p | ID),
  rho12 = ~ w
)
```

This estimates one four-dimensional group-level covariance block for location
and scale random intercepts, with residual `rho12` still separate.

## Files Changed

- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md`

The local generated article
`pkgdown-site/articles/formula-grammar.html` was rebuilt for review.

## Checks Run

- `air format vignettes/formula-grammar.Rmd`
- `Rscript -e "pkgdown::build_article('formula-grammar')"`
- `Rscript -e 'devtools::test(filter = "package-skeleton|biv-gaussian|corpairs", reporter = "summary")'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n 'future phylogenetic and spatial pair classes remain planned|full cross-parameter covariance blocks spanning more than one pair|ordinary q=4|sd1\\(id\\)|location-location|corpair\\(id' vignettes/formula-grammar.Rmd pkgdown-site/articles/formula-grammar.html`
- `git diff --check`

## Tests Of The Tests

This was a documentation status slice. The targeted tests cover the parser and
extractor surfaces mentioned by the article: `package-skeleton`,
`biv-gaussian`, and `corpairs`.

## Consistency Audit

The stale article phrasing that treated phylogenetic pair classes as future
only was removed. The article now says spatial pair classes remain planned,
while ordinary q4 and the first bivariate phylogenetic mean-mean row are
fitted.

## What Did Not Go Smoothly

No issue. This was a straightforward user-facing status refresh.

## Team Learning

Pat and Rose both matter here: new syntax is only helpful if the navigation
article names what is fitted, what is reserved, and what remains planned.

## Known Limitations

- The formula grammar article is a map, not a worked tutorial.
- Spatial terms and full phylogenetic q4 location-scale blocks remain planned.

## Next Actions

If more user-facing refresh time is available, update the phylogenetic-spatial
article's quick status box in the same style.

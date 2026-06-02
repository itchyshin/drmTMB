# After Task: Bipartite phylogenetic interactions article

## Goal

Add a reader-facing pkgdown article for the first fitted `phylo_interaction()`
slice. The article should be discoverable by users searching for two-tree,
bipartite, or pair-level phylogenetic models, while keeping "A tale of two
phylogenies" as a memorable opening hook.

## Implemented

`vignettes/bipartite-phylogenetic-interactions.Rmd` now teaches the current
route:

```r
visits ~ floral_density +
  phylo_interaction(
    1 | plant:pollinator,
    tree1 = plant_tree,
    tree2 = pollinator_tree
  )
```

The article fits a small Poisson count example with two toy trees, then points
readers to `ranef()` and `profile_targets()`. It separates supported code from
planned code: ordinary independent pair effects use a precomputed `pair_id`;
`relmat()` remains the lower-level precision route; additive partner main
phylogenies plus `phylo_interaction()` remain planned.

The article is listed in `_pkgdown.yml` under both the Tutorials navbar and the
Structured Dependence article index. The structural-dependence and phylogenetic
structured-effects articles now link to it.

## Mathematical Contract

For observation `i` with first partner `a_i` and second partner `b_i`, the
article states:

```text
eta_i = X_i beta + z[a_i, b_i]
vec(z) ~ Normal(0, sd_pair^2 (A_partner2 kron A_partner1))
```

For Poisson and NB2 models, `eta_i` is the log mean. For Gaussian models,
`eta_i` is the location mean. The article does not claim binary/Bernoulli
incidence, reciprocal evolutionary dynamics, or simultaneous structured layers.

## Files Changed

- `vignettes/bipartite-phylogenetic-interactions.Rmd`
- `vignettes/structural-dependence.Rmd`
- `vignettes/phylogenetic-models.Rmd`
- `_pkgdown.yml`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-bipartite-phylogenetic-interactions-article.md`

## Checks Run

```sh
air format vignettes/bipartite-phylogenetic-interactions.Rmd vignettes/structural-dependence.Rmd vignettes/phylogenetic-models.Rmd _pkgdown.yml
Rscript --vanilla -e "invisible(parse(text = xfun::split_source('vignettes/bipartite-phylogenetic-interactions.Rmd')$src)); cat('article code parse ok\n')"
Rscript --vanilla -e "pkgload::load_all('.', export_all = FALSE, helpers = FALSE, attach_testthat = FALSE); rmarkdown::render('vignettes/bipartite-phylogenetic-interactions.Rmd', output_dir = tempfile('drmtmb-bipartite-article-'), quiet = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n "Two-tree phylogenetic interactions|A tale of two phylogenies|ordinary NB2|Q_pair.*must match|phylo_interaction\\(|bipartite-phylogenetic-interactions" pkgdown-site/articles/bipartite-phylogenetic-interactions.html pkgdown-site/articles/index.html pkgdown-site/articles/structural-dependence.html pkgdown-site/articles/phylogenetic-models.html pkgdown-site/reference/index.html
git status --short --ignored pkgdown-site
git diff --check
```

Outcomes:

- Article code parse: printed `article code parse ok`.
- Source-tree article render: passed with `pkgload::load_all()`.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: completed successfully and wrote the new article.
- Rendered pkgdown scan: found the new article page, navbar entry, article
  index entry, structural-dependence link, phylogenetic-models link, reference
  index navbar entry, the opening hook, and rendered `phylo_interaction()`
  output.
- `git diff --check`: passed.
- Averroes performed a read-only pkgdown-editor review. No blocking issues were
  found; the title/navigation were adjusted for broader discoverability, the NB2
  wording now says "ordinary NB2", and the `relmat()` section now warns that
  `Q_pair` row and column names must match the pair factor levels exactly.

## Tests Of The Tests

This is documentation, not a new likelihood feature. The runnable article chunk
fits the current Poisson `mu` pair-interaction route, which exercises the same
public syntax users will copy. The unsupported ordinary colon-group parser,
`relmat()` pair precision route, and additive partner-phylogeny syntax are shown
with `eval = FALSE` so pkgdown does not silently promote them to fitted
examples.

## Consistency Audit

The rendered-site scan checks the article page, article index,
structural-dependence article, phylogenetic-models article, and reference index
navbar. The article keeps the status boundary aligned with the existing
`phylo_interaction()` reference page and formula-grammar table: Gaussian,
Poisson, and NB2 `mu` are fitted; binary incidence, additive partner main
phylogenies plus interaction, structured pair slopes, and simultaneous
structured layers remain planned.

## GitHub Issue Maintenance

The article is now tied to issue #447, which tracks the first
`phylo_interaction()` implementation and reader-facing documentation slice.
The preceding implementation task found no pre-existing matching issue before
the main-thread startup audit created #447.

## What Did Not Go Smoothly

A standalone `rmarkdown::render()` initially loaded the previously installed
`drmTMB`, which does not know the new marker and therefore rejected the formula.
Rerunning the render after `pkgload::load_all()` tested the current source tree
and passed. The full `pkgdown::build_site()` command also installed and used the
current source package before rendering.

## Team Learning

- Boole: use the searchable title "Two-tree phylogenetic interactions" and keep
  "A tale of two phylogenies" as the hook.
- Pat: show a complete runnable count example before discussing lower-level or
  future routes.
- Rose: keep unsupported additive and binary-incidence routes visibly separated
  from fitted syntax.
- Grace: a rendered navigation scan is part of the closeout, because clean
  pkgdown output alone does not prove users can find the article.

## Known Limitations

The article documents the first q=1 pair-level structured `mu` field only. It
does not add fitted binary incidence models, additive partner main phylogenies,
structured pair slopes, labelled count covariance, simultaneous structured
layers, or direct ordinary `(1 | plant:pollinator)` parser support.

## Next Actions

1. Add the ordinary colon-group parser sugar if the project wants direct
   `(1 | plant:pollinator)` for independent pair effects.
2. Design the additive route that combines two partner main `phylo()` terms plus
   `phylo_interaction()`.
3. Keep binary incidence models in the family-design lane rather than teaching
   them through the count article.

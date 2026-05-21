# After Task: Structural-Dependence Overview Index

## Goal

Add the first small navigation slice for the structural-dependence article split:
an overview page that helps applied readers choose the right structured layer
before they enter the long technical tutorial.

## Implemented

`vignettes/structural-dependence.Rmd` now gives a route table for five reader
questions: additive genetic or individual relatedness, phylogenetic dependence,
coordinate spatial dependence, planned simultaneous phylo-plus-spatial structure,
and lower-level `relmat()` known matrices. The page sends detailed examples to
the existing `phylogenetic-spatial.Rmd` article and sends compact syntax checks
to the formula grammar.

The Getting Started and model-map articles now point structural-dependence
questions to the overview first. `_pkgdown.yml` lists both the overview and the
existing detailed article in the tutorial menu.

## Mathematical Contract

No model code, likelihood, formula grammar, extractor, or interval logic changed.
The overview is a reader-facing map of existing fitted and planned states. It
keeps residual coscale `rho12` separate from latent `corpairs()` rows, and it
keeps known sampling covariance in the meta-analysis route rather than
`relmat()`.

## Files Changed

- `vignettes/structural-dependence.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-map.Rmd`
- `_pkgdown.yml`
- `docs/design/53-structural-dependence-article-split.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`

## Checks Run

```sh
air format vignettes/structural-dependence.Rmd vignettes/drmTMB.Rmd vignettes/model-map.Rmd NEWS.md _pkgdown.yml docs/design/53-structural-dependence-article-split.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-structural-dependence-overview-index.md
Rscript -e "devtools::load_all('.', quiet = TRUE); pkgdown::build_article('structural-dependence', new_process = FALSE, quiet = TRUE); pkgdown::build_article('drmTMB', new_process = FALSE, quiet = TRUE); pkgdown::build_article('model-map', new_process = FALSE, quiet = TRUE)"
gh issue view 31 --json number,title,state,labels,body,url
rg -n 'Structural dependence\]\(phylogenetic-spatial\.html\)|Structural dependence overview|structural-dependence\.html|Structural dependence details' vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/structural-dependence.Rmd _pkgdown.yml
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

- The touched pkgdown articles rebuilt: `structural-dependence`, `drmTMB`, and
  `model-map`.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

No test files changed. The article build verifies that the new overview article
is renderable and that the two edited navigation articles still build after
their links changed.

## Consistency Audit

The prose-style pass kept the target reader as an applied ecology, evolution, or
environmental-science user choosing a model route. The overview names fitted
first slices and planned boundaries in the route table instead of asking the
reader to infer support from examples buried in the detailed article.

The link scan confirmed that Getting Started, the model map, and pkgdown now
route users to `structural-dependence.html` first, while the new overview still
links to `phylogenetic-spatial.html` as the detailed tutorial.

## GitHub Issue Maintenance

Issue #31, "Phase 6b: upgrade tutorials and user-facing learning path", is the
matching tutorial-path ledger. It remains open because this slice starts the
structural-dependence split but does not complete the full tutorial source-map,
output-interpretation, and stale-claim audit for Phase 6b.

## What Did Not Go Smoothly

The first draft added the overview but left some existing model-map links
pointing directly to the long article. Pat's check caught that before the slice
closed.

## Team Learning

When a new overview page is added, the useful-user audit should include upstream
entry points such as Getting Started and model-map tables, not only pkgdown
navigation.

## Known Limitations

This slice does not split the detailed 1,691-line structural-dependence article
into animal, phylogenetic, spatial, combined-layer, and `relmat()` articles. It
only adds the first overview page and keeps the existing detailed tutorial as
the destination for examples and equations.

## Next Actions

Split the detailed structural-dependence article one route at a time, starting
with the animal-model page because it is now the first reader route and has both
pedigree and known-matrix fitted first slices.

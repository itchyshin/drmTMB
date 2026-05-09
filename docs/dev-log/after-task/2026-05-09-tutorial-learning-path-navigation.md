# After Task: Tutorial Learning Path Navigation

## Goal

Make the pkgdown tutorial menu and get-started article guide users from their
scientific or statistical question to the right tutorial, without starting a
larger documentation rewrite.

## Implemented

- Added a compact learning-path table to `vignettes/drmTMB.Rmd`.
- Updated `_pkgdown.yml` tutorial menu labels so the site uses the current
  meta-analysis and phylogenetic-spatial tutorial titles.
- Added a `NEWS.md` bullet for the navigation improvement.

## Mathematical Contract

No model equation or likelihood changed. The contract for this pass is
documentation alignment: each tutorial label should point to the implemented
or planned parameter it teaches, such as `sigma`, `sd(group)`, `rho12`,
`meta_known_V(V = V)`, or `phylo()`.

## Files Changed

- `_pkgdown.yml`
- `vignettes/drmTMB.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-tutorial-learning-path-navigation.md`

## Checks Run

```sh
Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE)"
Rscript -e "pkgdown::build_site()"
Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Results:

- get-started article render: passed;
- pkgdown build: passed;
- pkgdown check: no problems found;
- `git diff --check`: clean.

## Tests Of The Tests

This was a documentation-navigation change only. The generated pkgdown HTML was
searched for the new learning-path heading, updated menu labels, and stale
meta-analysis menu label.

## Consistency Audit

Search run:

```sh
rg -n "Learning path|Start with the question|Mean effects and heterogeneous heterogeneity|Implemented phylogeny and planned space|Mean effects and residual heterogeneity|Structured dependence$" pkgdown-site/articles/drmTMB.html pkgdown-site/articles/index.html pkgdown-site/news/index.html pkgdown-site/pkgdown.yml _pkgdown.yml vignettes/drmTMB.Rmd NEWS.md
```

The generated site contains the learning path and updated tutorial menu labels.
No stale generated-site hit remains for the old meta-analysis menu label.

## What Did Not Go Smoothly

Nothing substantial. The main choice was scope control: this task deliberately
did not revise tutorial content beyond navigation and the get-started learning
path.

## Team Learning

- Ada should keep small documentation-navigation fixes small.
- Rose-style forest-and-trees checks do not need to be large; a precise stale
  label scan can be enough when no model behaviour changed.
- Token efficiency improved here by using targeted reads and no subagents.

## Known Limitations

- The learning path is still based on simulated tutorial examples.
- It should be revisited after real ecology, evolution, or environmental
  datasets are added.

## Next Actions

1. Add a real-data example when the first stable tutorial dataset is selected.
2. Add a compact visual summary to the main Gaussian location-scale tutorial.
3. Continue keeping pkgdown navigation synchronized with tutorial titles.

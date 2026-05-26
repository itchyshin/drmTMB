# After Task: Phylogenetic Direct-SD Public Syntax Cleanup

## Goal

Remove stale `sd_phylo*()` examples from public reader-facing phylogenetic
documentation. The current syntax to teach is
`sd(..., level = "phylogenetic")`, `sd1(..., level = "phylogenetic")`, and
`sd2(..., level = "phylogenetic")`; the old names remain deprecated
compatibility aliases, not the tutorial path.

## Implemented

Updated the phylogenetic tutorial row, companion phylogenetic-spatial tutorial,
model-map status row, implementation-map row, which-scale wording, package
overview tutorial, structural-dependence link text, and README status wording so
they use the generic level-targeted direct-SD syntax for current examples.

## Mathematical Contract

No mathematical contract changed. This is a prose and example-syntax cleanup for
the already fitted phylogenetic direct-SD route.

## Files Changed

- `README.md`
- `vignettes/phylogenetic-models.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/which-scale.Rmd`
- `vignettes/implementation-map.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/structural-dependence.Rmd`
- `vignettes/model-map.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
rg -n 'sd_phylo\(|sd_phylo1\(|sd_phylo2\(|sd_phylo\*' README.md vignettes docs/design docs/dev-log/check-log.md NEWS.md
air format README.md vignettes/phylogenetic-models.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/which-scale.Rmd vignettes/implementation-map.Rmd vignettes/drmTMB.Rmd vignettes/structural-dependence.Rmd vignettes/model-map.Rmd
Rscript -e "pkgdown::build_article('phylogenetic-models', new_process = FALSE)"
rg -n 'sd_phylo\(|sd_phylo1\(|sd_phylo2\(|sd_phylo\*' pkgdown-site/articles/phylogenetic-models.html
rg -n 'sd\(species, level = "phylogenetic"\)|sd1\(species, level = "phylogenetic"\)|sd2\(species, level = "phylogenetic"\)' pkgdown-site/articles/phylogenetic-models.html
git diff --check
gh issue list --repo itchyshin/drmTMB --state open --search "sd_phylo" --limit 10 --json number,title,state,url
```

The rendered local article now contains the preferred `sd()`, `sd1()`, and
`sd2()` formulas in the direct-SD row and no `sd_phylo*()` spelling in that
rendered page.

## Tests Of The Tests

No package tests changed because no parser, likelihood, extractor, or diagnostic
behavior changed. The rendered-article grep is the direct regression check for
the user-visible issue.

## Consistency Audit

The public learning files touched by this cleanup no longer teach
`sd_phylo*()` as current syntax. Remaining `sd_phylo*()` matches in NEWS,
design docs, and historical check-log entries describe deprecated
compatibility or past implementation work and were left in place so the project
history remains accurate.

## GitHub Issue Maintenance

Open issue search used `sd_phylo` and found broad issue #31, "Phase 6b:
upgrade tutorials and user-facing learning path", plus issue #147 for future
animal and `relmat()` structured effects. No issue was updated from this dirty
local documentation branch because the correction is a narrow stale-wording
cleanup on already implemented syntax.

## What Did Not Go Smoothly

The first scan focused on the screenshot article and its companion pages, then
`vignettes/model-map.Rmd` surfaced as one more public stale row. Rose added it
to the cleanup before closing.

## Team Learning

Ada kept this as a public-docs correction rather than reopening the modelling
slice. Pat checked the reader path: new users now see only the current
level-targeted syntax in tutorials and status tables. Rose checked that legacy
names remain only where the text explicitly treats them as compatibility or
history. These were role perspectives, not spawned agents.

## Known Limitations

The public GitHub Pages site will not change until the corrected sources are
included in the next pkgdown deployment. This cleanup does not remove deprecated
compatibility aliases from code or historical project notes.

## Next Actions

Deploy or merge the corrected docs through the normal pkgdown workflow so
`itchyshin.github.io/drmTMB/articles/phylogenetic-models.html` refreshes from
the local source fix.

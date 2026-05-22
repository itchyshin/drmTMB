# After Task: Structural Dependence Fast CI Clarification

## Goal

Continue the comprehensive page audit by rendering the structural-dependence
article and making its covariance-interval guidance match the current fast CI
workflow.

## Implemented

- Confirmed the rendered `phylogenetic-spatial` page has no active article
  figures beyond the pkgdown logo.
- Added the quick direct Wald screen,
  `confint(fit, parm = "variance_components")`, before the slower profile
  example.
- Updated the profile example to show `profile_precision = "fast"` as the
  first-pass control for long phylogenetic or spatial SD/correlation profiles.
- Preserved the statistical caution that boundary-sensitive structured SDs and
  correlations still need profile diagnostics before final reporting.

## Mathematical Contract

No model code changed. The article now says the same thing as the interval
implementation: direct SD Wald intervals use the fitted log-SD scale, direct
correlation Wald intervals use the guarded atanh correlation-link scale, and
profile intervals remain the better final check when likelihood shape or
boundaries matter.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/audits/2026-05-21-function-page-figure-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-structural-dependence-fast-ci.md`

## Checks Run

```sh
air format vignettes/phylogenetic-spatial.Rmd docs/dev-log/audits/2026-05-21-function-page-figure-audit.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-structural-dependence-fast-ci.md
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('phylogenetic-spatial', new_process = FALSE, quiet = TRUE)"
rg -n 'phylogenetic-spatial_files/figure-html|<img' pkgdown-site/articles/phylogenetic-spatial.html
rg -n 'confint\(fit_phylo_mean, parm = "variance_components"\)|profile_precision = "fast"|quick direct Wald screen|Use Wald intervals only|not a public `confint\(method = "bootstrap"\)` route' vignettes/phylogenetic-spatial.Rmd pkgdown-site/articles/phylogenetic-spatial.html -S
Rscript -e "devtools::test(filter = 'profile-targets|phylo-gaussian|spatial-gaussian', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "phylogenetic spatial profile CI OR profile_precision OR confidence interval" --limit 20
```

## Tests Of The Tests

The focused tests cover the profile-target inventory and the fitted
phylogenetic/spatial Gaussian routes described by the article. This slice did
not add a new model or interval algorithm.

## Consistency Audit

The article now teaches the same order as `model-workflow`: start with fast
direct Wald intervals for routine screening, then profile the exact structured
SD or correlation target when likelihood shape matters. The q=4 derived-row
boundary and planned spatial/phylogenetic neighbours were not expanded.

## GitHub Issue Maintenance

The issue search found the tutorial-learning-path issue #31, the structured
slope issue #33, the visualization issue #58, and the bootstrap interval issue
#265. This narrow article clarification contributes to the learning-path and
interval ledgers but does not close any of them. No issue was closed.

## What Did Not Go Smoothly

The page is long and mostly prose/tables, so the rendered-figure check was
important even though it found no active article PNGs. The audit should still
record that absence instead of silently skipping the figure lane.

## Team Learning

Fisher's point for this page is practical: "profile is preferred" and "fast
Wald exists" are not contradictory. Users need both sentences on long
phylogenetic and spatial models.

## Known Limitations

This pass did not audit every structured-dependence example for runtime,
coverage, or result quality. It only corrected the interval workflow text on
the current public page.

## Next Actions

1. Continue with `simulation-plot-grammar`, where the active work is likely to
   be figure and evidence-grain QA.
2. Continue the function/reference inventory after the high-risk public pages
   are synchronized.

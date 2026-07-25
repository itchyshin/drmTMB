# Final clean-worktree validation receipt

## Revision and commands

The validation worktree was created directly from the merged audit revision
`1a972b8e6e1c60cec85ca116c0f1463fc2bf4214` on branch
`codex/pkgdown-formal-closeout`. The formal-closeout edits change audit evidence
only; they do not change an R source, vignette source, Rd file, package export,
or `_pkgdown.yml`.

The following commands completed in that clean worktree on 2026-07-22:

```r
files <- sort(list.files("man", pattern = "[.]Rd$", full.names = TRUE))
stopifnot(length(files) == 68L)
invisible(lapply(files, tools::checkRd))
pkgdown::check_pkgdown(pkg = ".")
pkgdown::build_site(pkg = ".", preview = FALSE)
```

The Rd command printed `checkRd_ok 68 topics`; `pkgdown::check_pkgdown()`
reported `No problems found` both before and after the full build. The first
sandboxed full build could not resolve `cloud.r-project.org` for the CRAN
sidebar; the permitted clean-worktree rerun completed and generated the route
inventory below. This is local rendering evidence, not a deployment or CRAN
check.

## Inventory read-back

| Surface | Method | Result |
| --- | --- | ---: |
| Authored sources | `find vignettes -name '*.Rmd'` | 35 |
| Article routes | `find pkgdown-site/articles -name '*.html'` | 36 |
| Rd topics | `find man -name '*.Rd'` | 68 |
| Canonical reference routes | sitemap URLs under `reference/` | 69 |
| Generated reference HTML files | `find pkgdown-site/reference -name '*.html'` | 98 |
| NAMESPACE exports | `rg '^export\\(' NAMESPACE` | 51 |
| Search/sitemap | file existence | both present |

The article count is exact: 35 authored sources plus `articles/index.html`.
The reference counts are not contradictory. The sitemap contains 68 canonical
topic routes plus `reference/index.html` (69 total). pkgdown additionally writes
29 no-index alias/redirect pages for method aliases; together they produce the
98 physical reference HTML files reported by the original audit.

## Alias/redirect routes (29)

`AIC.drmTMB`, `BIC.drmTMB`, `bf`, `centile_chart.drmTMB`, `check_drm.drmTMB`,
`corpairs.drmTMB`, `deviance.drmTMB`, `df.residual.drmTMB`,
`exceedance.drmTMB`, `fitted_distribution.drmTMB`, `fixef.drmTMB`,
`imputed.drmTMB`, `is_converged.default`, `is_converged.drmTMB`, `logLik.drmTMB`,
`marginal_parameters.drmTMB`, `nobs.drmTMB`, `predict_parameters.drmTMB`,
`prediction_grid.drmTMB`, `ranef.drmTMB`, `rho12.drmTMB`, `sd`, `sd1`, `sd2`,
`sd_phylo`, `sd_phylo1`, `sd_phylo2`, `structured_effects.default`, and
`structured_effects.drmTMB`.

Each is a `meta refresh` redirect to its canonical topic page. They preserve
stable method URLs and do not increase the number of audited Rd topics or
exports.

## Boundary

This receipt verifies the reader-surface build and inventory only. It does NOT
cover deployment, a CRAN check, cross-platform validation, a Julia-engine fit,
new simulation evidence, or any capability promotion.

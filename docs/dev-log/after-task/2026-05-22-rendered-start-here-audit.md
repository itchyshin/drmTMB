# After Task: Rendered Article Checklist And Start Here Audit

Date: 2026-05-22

## Goal

Begin the article audit sweep with rendered evidence, then improve the
first-user path across `drmTMB`, `model-map`, and `model-workflow`.

## Implemented

- Added `docs/dev-log/audits/2026-05-22-rendered-article-checklist.md`, a
  rendered checklist for all 26 pkgdown articles.
- Rewrote the opening of `vignettes/drmTMB.Rmd` so the first screen starts from
  the user task: fit a first model, check the fitted object, and find the next
  article.
- Added a short cross-link in `vignettes/model-map.Rmd` that sends first-time
  users back to `drmTMB` before they use the capability map.
- Added a short orientation sentence in `vignettes/model-workflow.Rmd` that
  names its place in the Start Here path.

## Mathematical Contract

No likelihood, formula grammar, or TMB parameterization changed. The prose edits
preserve the existing contract: one formula per distributional parameter,
`sigma` as residual scale, `rho12` as residual coscale/correlation, Wald
intervals as the fast default for direct rows, SD intervals on the fitted
log-SD scale, and correlation intervals on the guarded Fisher-z/atanh scale.

## Files Changed

- `vignettes/drmTMB.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/model-workflow.Rmd`
- `docs/dev-log/audits/2026-05-22-rendered-article-checklist.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-22-rendered-start-here-audit.md`

## Checks Run

```sh
air format vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/model-workflow.Rmd docs/dev-log/audits/2026-05-22-rendered-article-checklist.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-22-rendered-start-here-audit.md
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('drmTMB', new_process = FALSE, quiet = TRUE); pkgdown::build_article('model-map', new_process = FALSE, quiet = TRUE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = TRUE)"
Rscript -e "pkgdown::build_site()"
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'Start here when you want to fit a first model|broader implemented map lives|If you have not fit a model yet|In the `Start Here` path|Rendered Article Checklist|bivariate-coscale|simulation-plot-grammar' vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/model-workflow.Rmd docs/dev-log/audits/2026-05-22-rendered-article-checklist.md pkgdown-site/articles/drmTMB.html pkgdown-site/articles/model-map.html pkgdown-site/articles/model-workflow.html -S
rg -n 'bootstrap|profile_precision|variance_components|random_effects|correlations|Wald|Fisher|atanh|log-SD|derived_interval_unavailable|gr\(|meta_known_V|meta_V|spatial q=4|q=4 spatial|Poisson q=1|ordinary Poisson|profile_targets|conf\.status' vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/model-workflow.Rmd -S
rg -n 'gr\(|meta_known_V|meta_V|bootstrap|profile_precision|variance_components|random_effects|correlations|Fisher|atanh|log-SD|derived_interval_unavailable|Poisson q=1|q=4 spatial|spatial q=4' R man tests/testthat -S
gh issue list --search "article audit OR tutorial navigation OR figure gallery OR confidence eye OR profile bootstrap" --limit 20
git diff --check
```

The focused article rebuilds passed. The full pkgdown site rebuilt cleanly, and
`pkgdown::check_pkgdown()` reported no problems.

## Consistency Audit

The rendered checklist flags the next audit work instead of hiding it. The
main figure follow-ups are `figure-gallery`, `simulation-plot-grammar`,
`bivariate-coscale`, and `model-workflow`. The stale-status scans found the
current CI contract in source, docs, and tests: direct-target bootstrap is in
`confint()`, `summary(..., method = "bootstrap")` remains unsupported, fast
profile precision is documented, SD intervals use log-SD scale language, and
correlations use the guarded Fisher-z/atanh scale.

## GitHub Issue Maintenance

Issue search found #31, #58, #255, #265, #57, #4, and #147 as related open
ledgers. This slice supports #31 directly and prepares #58/#255/#265 follow-up
work, but it does not close any issue.

## What Did Not Go Smoothly

The rendered HTML figure count is not the same as the number of PNG files left
in article figure directories, because old renders can leave stale image files.
The checklist therefore records rendered `<img>` tags in article bodies rather
than counting every PNG on disk.

## Team Learning

Start-page prose should not carry the full feature ledger. The first article
should help a reader fit one model and move to the correct map; the status map
should carry the detailed implemented-versus-planned boundary.

## Known Limitations

This was not the Florence/Fisher one-by-one figure audit. It did not inspect
each rendered image directly, fix alt text, add Confidence Eye displays, or
rewrite the full article set.

## Next Actions

1. Audit `location-scale` as the first core applied tutorial.
2. Run the figure-heavy pass for `model-workflow`, `bivariate-coscale`,
   `figure-gallery`, and `simulation-plot-grammar`.
3. Draft the dedicated inference article plan for Wald/profile/bootstrap,
   `profile_precision = "fast"`, and Confidence Eye-compatible language.

# After Task: Article Audit Sweep Map And Navigation Slice

Date: 2026-05-22

## Goal

Start the comprehensive article audit and make the first public-site
reorganization small enough to validate: an audit map, a navigation-only
pkgdown grouping change, and a title fix for the long structural-dependence
detail article.

## Review Roles

Ada kept the slice scoped to audit and navigation. Aquinas, Goodall, and
Helmholtz were spawned reviewers for pkgdown structure, applied-user flow, and
developer-note/system drift. Pat, Darwin, Fisher, Florence, Boole, Noether,
Emmy, Grace, and Rose supplied the standing review perspectives recorded in the
check log. No spawned reviewers are still running.

## What Changed

- Added `docs/dev-log/audits/2026-05-22-article-audit-sweep-map.md` as the
  durable map for the 26-article sweep.
- Reorganized `_pkgdown.yml` article groups so the public site now has separate
  paths for first users, model choice, applied family tutorials,
  structured-dependence routes, inference/diagnostics/figures, validation, and
  developer notes.
- Moved `figure-gallery` out of early Tutorials and into the inference,
  diagnostics, and figures path.
- Moved `implementation-map` out of first-user model guides and into the
  simulation/validation path.
- Retitled `vignettes/phylogenetic-spatial.Rmd` from `Structural dependence`
  to `Structural dependence details` and updated the vignette index entry to
  match, so the overview and detail pages are no longer rendered with the same
  title.

## Validation

Checks run:

```sh
air format _pkgdown.yml vignettes/phylogenetic-spatial.Rmd docs/dev-log/audits/2026-05-22-article-audit-sweep-map.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-22-article-audit-sweep-map.md
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('phylogenetic-spatial', new_process = FALSE, quiet = TRUE)"
Rscript -e "pkgdown::build_site()"
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'Diagnostics & Validation|Start Here|Choose Your Model|Applied Family Tutorials|Structural dependence details|Simulation and Validation|Inference, Diagnostics, and Figures' _pkgdown.yml pkgdown-site/articles/index.html pkgdown-site/articles/phylogenetic-spatial.html -S
gh issue list --search "article audit OR tutorial navigation OR pkgdown navigation OR developer notes OR figure gallery" --limit 20
git diff --check
```

`pkgdown::build_site()` finished cleanly after the title/index-entry fix.
`pkgdown::check_pkgdown()` reported no problems. The rendered HTML search found
the new article-index groups and the `Structural dependence details` title.

## Issue And Scope Notes

The issue search found #31, #58, #57, and #255 as related open ledgers. This
slice supports those issues but does not close them. It does not rewrite
article prose, fix substandard figures, add Confidence Eye displays, implement
new CI methods, or reorganize raw `docs/design/*.md` files into public
articles.

## Next Slices

1. Add the rendered-page checklist for all 26 articles.
2. Audit the Start Here triad: `drmTMB`, `model-map`, and `model-workflow`.
3. Create the dedicated inference article plan for Wald/profile/bootstrap,
   profile precision, and future Confidence Eye display language.
4. Run the Florence/Fisher figure sweep for `figure-gallery`,
   `simulation-plot-grammar`, and tutorial figures with intervals.

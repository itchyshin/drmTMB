# After-Task Report: Slices 469-478 Stale Promise Audit

## Active Perspectives

Ada ran the audit and kept it source-first. Rose looked for old promises that
should now be closed or reworded. Grace checked whether stale rendered HTML was
tracked before treating it as a project artifact. Pat focused on promises a new
user would read as implemented behaviour.

## Goal

Review current-facing status pages and recent after-task notes for stale
implemented-versus-planned claims after the Ayumi, q4 fallback, pkgdown, and
reference-page slices.

## Findings

- Current source status pages now consistently distinguish full q4 derived
  correlations from block-diagonal q4 fallback direct targets.
- Public bootstrap confidence intervals remain correctly described as not
  implemented, even though developer-only and Phase 18 private bootstrap
  helpers exist.
- `animal()` and `relmat()` remain correctly described as exported, documented,
  parsed/planned markers, not fitted model paths.
- Coordinate spatial one-slope `mu` support is correctly described as fitted;
  mesh/SPDE, spatial scale, bivariate spatial covariance, and spatial
  `corpair()` remain planned.
- Historical after-task reports contain old statements that were true when
  written. Ada left those alone and relied on newer after-task reports and
  current status pages to supersede them.
- Ignored generated files such as `vignettes/model-map.html` are not tracked
  and are ignored by `.gitignore`, so Ada did not edit or rely on them.

## Checks Run

```sh
rg -n "phylogenetic scale terms planned|phylogenetic or spatial terms in sigma|only.*mu1.*mu2|first fitted bivariate phylogenetic|not yet fitted|not implemented yet|planned but not implemented|remain planned|Next Actions|TODO|FIXME|bootstrap intervals|public bootstrap|animal models|animal\\(\\).*implemented|spatial.*bivariate|q4.*derived-only|q=4.*derived-only" README.md NEWS.md ROADMAP.md docs/design vignettes docs/dev-log/after-task --glob '!docs/dev-log/after-task/2026-05-19-slices-*.md'
rg -n "Next Actions|Known Limitations|not implemented|planned|future|blocked|needs|TODO|FIXME" docs/dev-log/after-task/2026-05-19-slices-*.md
rg -n "animal|relmat|phylo|spatial|bootstrap|profile|simulation|pkgdown|reference|examples|shape|skew|student|t" docs/dev-log/after-task/2026-05-19-slices-*.md
git ls-files vignettes/*.html
git check-ignore -v vignettes/model-map.html pkgdown-site/articles/model-map.html
rg -n "q=4 correlations are derived-only for intervals|phylogenetic scale terms planned|phylogenetic or spatial terms in sigma|first fitted bivariate phylogenetic" vignettes/*.html
git status --short vignettes/model-map.html vignettes/drmTMB.html vignettes/source-map.html vignettes/convergence.html
```

## Validation Notes

- `git ls-files vignettes/*.html` returned no tracked vignette HTML files.
- `.gitignore` explicitly ignores both `vignettes/*.html` and `pkgdown-site/`.
- The tracked source pages and current pkgdown build carry the corrected q4
  fallback wording from slices 433-458.

## Known Limitations

The scan was intentionally high-signal and current-facing. It did not rewrite
historical after-task reports, and it did not produce a full backlog of every
planned feature in the repository.

## Next Actions

Run a bounded validation choice next: either a focused `devtools::test()`
subset across the changed phylogenetic/profile/reference paths, or a full test
suite if Ada decides the larger worktree is stable enough for the time budget.

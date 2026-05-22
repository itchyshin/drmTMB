# After Task: Function, Page, and Figure Audit Kickoff

## Goal

Start Steps 2 and 3 after final validation and packaging: build the first
function/reference and page-status inventories, render the high-priority figure
page, inspect the riskiest figures directly, and record what remains for the
Florence-led polish pass.

## Implemented

The prior CI/C++/audit-map work was validated and committed in three commits:

- `1b889134` Extract first C++ helper headers
- `42929588` Add fast direct CI routes
- `8f2fd999` Launch CI and figure audit maps

The new function/reference audit is recorded in
`docs/dev-log/audits/2026-05-21-function-reference-inventory.md`. It found that
all exported names are present in the pkgdown reference index, either directly
or through grouped S3 topics.

The page-status audit is recorded in
`docs/dev-log/audits/2026-05-21-page-status-inventory.md`. It identifies
`figure-gallery`, `model-workflow`, `model-map`, `implementation-map`,
`simulation-plot-grammar`, and `phylogenetic-spatial` as the first rendered
review targets.

The figure audit kickoff is recorded in
`docs/dev-log/figure-audits/2026-05-21-audit-kickoff/figure-audit.md`. Five
high-risk figures were inspected directly from rendered PNGs.

## Mathematical And Visual Contract

No model likelihood changed. This slice aligned public wording with the
implemented interval contract:

- Direct random-effect SD targets can receive fast Wald intervals through
  `confint()`.
- Modelled `sd(group) ~ x` surfaces evaluated on a grid are not those direct
  targets and still mark unavailable Wald surface intervals.
- Direct fitted correlation displays should say guarded atanh-style
  correlation-link scale, not sample-correlation Fisher-z by default.

For figures, the audit uses the Florence standard: each figure must identify
the estimand, visual data grain, uncertainty source, and missing or unsupported
cells.

## Files Changed

- `vignettes/model-workflow.Rmd`
- `vignettes/figure-gallery.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/audits/2026-05-21-function-reference-inventory.md`
- `docs/dev-log/audits/2026-05-21-page-status-inventory.md`
- `docs/dev-log/figure-audits/2026-05-21-audit-kickoff/figure-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-function-page-figure-audit-kickoff.md`

## Checks Run

```sh
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = FALSE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = FALSE)"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = FALSE)"
rg -n 'direct random-effect SD surface|direct random-effect SD surfaces|Fisher.s z scale|Fisher-z.*public|stacked' vignettes/figure-gallery.Rmd vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md pkgdown-site/articles/figure-gallery.html pkgdown-site/articles/model-workflow.html -S
git diff --check
```

## Tests Of The Tests

No new test code was added. The full package test suite and R CMD check were
run before the packaging commits. The rendered figure audit used visual
inspection of generated PNGs rather than source-only review.

## Consistency Audit

The first function inventory found no exported function missing from pkgdown
navigation. The first page inventory confirms that source-only review is not
enough for the figure-heavy pages.

The immediate stale-text scan no longer finds the corrected "direct
random-effect SD surface" or Fisher-z-scale wording in the rendered
figure-gallery/model-workflow pages.

## GitHub Issue Maintenance

No GitHub issue was updated in this local audit kickoff. The next PR should
summarize the audit findings and decide whether to open separate figure-polish
issues or keep them in the existing dev-log lane.

## What Did Not Go Smoothly

The rendered gallery surfaced exactly the kind of wording drift the audit was
meant to catch: old interval language survived in figure subtitles and alt
text after the CI contract changed. This confirms that figure review needs
Fisher, Rose, Pat, and Grace before Florence does final visual polish.

## Known Limitations

The figure audit is only started. Five high-risk figures were inspected. The
full gallery, `model-workflow`, `model-map`, `implementation-map`,
`simulation-plot-grammar`, and `phylogenetic-spatial` still need complete
rendered-image and rendered-page review.

## Next Actions

1. Commit this kickoff slice.
2. Continue the rendered figure audit with the rest of `figure-gallery`.
3. Add explicit "not targeted" labels to the simulation bias panel.
4. Reduce legend weight in coefficient and correlation raindrop displays.
5. Rebuild the full pkgdown site before any deploy or PR closeout.

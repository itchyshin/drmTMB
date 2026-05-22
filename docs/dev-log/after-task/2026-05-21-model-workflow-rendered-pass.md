# After Task: Model Workflow Rendered Figure Pass

## Goal

Continue the comprehensive audit by inspecting the rendered
`model-workflow` figures, fixing reader-facing inconsistencies, and recording
the active-image evidence before moving to the next high-risk page.

## Implemented

- Added a small article-local plotting theme and stable colour palette.
- Named the active plotting chunks and added figure alt text.
- Reworked the combined `mu`/`sigma` temperature display so `mu` uses habitat
  colour, while `sigma` uses one neutral line because the model formula is
  `sigma ~ temperature`.
- Made the standalone `sigma` plot use one row per temperature instead of two
  duplicated habitat rows.
- Tightened the two-point habitat contrast panel and restyled the raw and
  fitted model displays.
- Recorded a per-figure rendered audit table under
  `docs/dev-log/figure-audits/2026-05-21-model-workflow/`.

## Mathematical Contract

The model did not change. The article still fits
`bf(growth ~ temperature + habitat, sigma ~ temperature)` with a Gaussian
location-scale likelihood. The display now matches that contract more closely:
habitat can separate `mu` predictions, but it should not imply a separate
`sigma` curve when habitat is absent from the `sigma` formula.

## Files Changed

- `vignettes/model-workflow.Rmd`
- `docs/dev-log/audits/2026-05-21-function-page-figure-audit.md`
- `docs/dev-log/figure-audits/2026-05-21-model-workflow/figure-audit.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-model-workflow-rendered-pass.md`

## Checks Run

```sh
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = TRUE)"
air format vignettes/model-workflow.Rmd docs/dev-log/audits/2026-05-21-function-page-figure-audit.md docs/dev-log/figure-audits/2026-05-21-model-workflow/figure-audit.md docs/dev-log/team-improvements.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-model-workflow-rendered-pass.md
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = TRUE)"
rg -n "model-workflow_files/figure-html|<img" pkgdown-site/articles/model-workflow.html
rg -n 'sigma \(habitat not in formula\)|Because `sigma ~ temperature` has no habitat term|fig.alt' vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html -S
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "model workflow figure OR figure audit OR confidence interval" --limit 20
Rscript -e "devtools::test(filter = 'plot-parameter-surface|predict-parameters', reporter = 'summary')"
```

## Tests Of The Tests

This was a rendered-document and figure-audit slice, not a code-path test
change. The test-of-evidence was direct inspection of all active rendered
images referenced by `model-workflow.html` after rebuilding the article.

## Consistency Audit

The active HTML now references five named figure files with alt text:
`temperature-surface-plot`, `habitat-contrast-plot`, `raw-growth-plot`,
`mu-temperature-plot`, and `sigma-temperature-plot`. The ignored pkgdown image
folder still contained stale `unnamed-chunk-*` PNGs from previous renders, so
the audit records the active HTML references as the authoritative figure
inventory.

## GitHub Issue Maintenance

The issue search found #58, the broad Phase 17 visualization issue, plus #255
and #265 for simulation and bootstrap interval follow-up. This slice contributes
to #58 but does not close it because exported plotting contracts, simulation
figures, and remaining high-risk pages are still open. No issue was closed.

## What Did Not Go Smoothly

The first directory listing overstated the rendered figure count because
pkgdown left stale ignored PNGs from earlier unnamed chunks. Rose's process
fix is to inventory the HTML image references before judging figure coverage.

## Team Learning

Florence and Fisher caught that figure quality includes estimand fidelity: a
visually ordinary legend can imply a model term that is not in the formula.
Grace added the active-HTML-reference check as a reproducibility habit for
future pkgdown figure audits.

## Known Limitations

This pass does not redesign exported plotting helpers or certify the remaining
high-risk pages. `figure-gallery` and `model-workflow` now have rendered passes;
`model-map`, `implementation-map`, `phylogenetic-spatial`, and
`simulation-plot-grammar` remain in the comprehensive audit queue.

## Next Actions

1. Continue the rendered page audit with `model-map` and `implementation-map`.
2. Continue the simulation figure pass with `simulation-plot-grammar`.
3. Return to the function/reference inventory once the highest-risk visual
   pages have active rendered evidence.

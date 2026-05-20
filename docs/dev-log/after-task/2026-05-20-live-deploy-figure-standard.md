# After Task: Live Deploy Figure Standard

## Goal

Close the post-merge loop for PR #264 by checking the deployed pkgdown figures,
repairing any remaining visible figure failures, and recording the model-output
figure standard for future examples.

## Implemented

- Merged PR #264, then verified the post-merge `R-CMD-check` and chained
  `pkgdown` deploy passed.
- Inspected live deployed figure PNGs one by one for the figure gallery and
  simulation grammar pages.
- Repaired three live-rendered figure issues: a clipped simulation bias
  subtitle, crowded coverage/power `n=` annotations, and a long empirical
  marginal caption that belonged in the subtitle or prose.
- Added a visualization-grammar rule that every substantive worked example
  should include a model-output figure once the table contract is stable.
- Recorded live-deploy visual evidence under
  `docs/dev-log/figure-audits/2026-05-20-live-deploy-followup/`.

## Mathematical Contract

No likelihood, estimator, formula grammar, or interval calculation changed.
The task changed only presentation and documentation. The repaired figures keep
their existing statistical contracts:

- bias displays show pseudo-replicate errors plus mean bias and 95% MCSE;
- coverage and power displays show replicate-block proportions plus aggregate
  proportions and 95% binomial MCSE;
- empirical marginal `mu` summaries show fitted-row `mu` predictions and
  averaged row-wise 95% Wald prediction limits, not raw responses.

## Files Changed

- `vignettes/figure-gallery.Rmd`
- `vignettes/simulation-plot-grammar.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/figure-audits/2026-05-20-live-deploy-followup/`

## Checks Run

```sh
Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/simulation-plot-grammar.Rmd', output_dir = '/tmp/drmtmb-live-figure-fixes/simulation-plot-grammar', output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = '/tmp/drmtmb-live-figure-fixes/figure-gallery', output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Rendered PNGs opened directly:

- `/tmp/drmtmb-live-figure-fixes/simulation-plot-grammar/simulation-plot-grammar_files/figure-html/bias-rmse-display-1.png`
- `/tmp/drmtmb-live-figure-fixes/simulation-plot-grammar/simulation-plot-grammar_files/figure-html/coverage-power-display-1.png`
- `/tmp/drmtmb-live-figure-fixes/figure-gallery/figure-gallery_files/figure-html/empirical-marginal-summary-1.png`

`pkgdown::check_pkgdown()` reported no problems, and `git diff --check` was
clean.

## Tests Of The Tests

This is a documentation and rendered-figure repair, so no unit test was added.
The validation criterion is visual: each changed PNG was opened after render and
checked for clipping, alignment, and uncertainty wording.

## Consistency Audit

The figure and prose now agree on data grain and interval provenance. The
simulation figures do not use raindrop compatibility displays because they show
simulation operating characteristics rather than fitted-effect confidence
distributions. The empirical marginal figure explicitly says the faint points
are fitted-row `mu` predictions, not raw responses.

## GitHub Issue Maintenance

Open issues were inspected after the live-deploy pass. Issue #58 remains the
main visualization-layer ledger, and issue #255 remains the simulation artifact
ledger. Comments were added to #58 and #255 linking the PR #266 follow-up
rather than opening a duplicate issue.

## What Did Not Go Smoothly

The earlier figure audit still over-trusted a contact sheet and a local render.
It missed details that were obvious on the deployed page: subtitle clipping,
caption crowding, and cramped inline labels. The team process now treats live
deployed PNG inspection as part of the visual gate when a user has already
reported figure quality problems.

## Team Learning

Florence owns the final scientific figure standard, but this was a shared miss.
Fisher needed to catch interval-source wording and annotation crowding, Pat
needed to ask whether the reader could decode the figure without squinting, and
Grace needed to require output-size inspection after deploy. Rose recorded the
failure pattern in `docs/dev-log/team-improvements.md`.

## Known Limitations

The figure gallery and simulation grammar are still recipe articles, not an
exported plotting API. Some panels remain deliberately illustrative until Phase
18 produces stable result schemas with replicate rows, aggregate rows, MCSE
columns, manifests, and failure ledgers.

## Next Actions

1. Use the new model-output figure standard when updating worked examples.
2. Continue Phase 18 interval and convergence work with figures that expose
   replicate grain, interval source, and failure status from the beginning.
3. Keep structural-dependence examples balanced across `phylo()`, planned
   `animal()`, planned `spatial()`, and planned `relmat()` without implying
   unfitted support.

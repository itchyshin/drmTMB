# 2026-05-20 - Raindrop And Coverage Figure Rescue

## Purpose

Ada reopened the figure-gallery and simulation-plot grammar after reader-facing
QA found that several figures were still visually poor, over-ornamental, or
unclear about uncertainty. The goal was to make inference figures use
raindrop-style compatibility displays where intervals are central, while
keeping simulation coverage and power figures focused on replicate or
replicate-block data plus Monte Carlo uncertainty.

## Role Review

- Ada coordinated the edits and kept simulation and inference display contracts
  separate.
- Florence rejected the oversized two-panel raindrop display and kept the final
  coefficient raindrops compact, row-aligned, and publication-oriented.
- Fisher required every interval, drop, and block point to name its source and
  warned that simulation coverage is Bernoulli replicate data, not a smooth
  likelihood by default.
- Pat checked that a new reader can tell that coverage/power dots are
  replicate-block summaries and that large points/bars are aggregate
  proportions with binomial MCSE.
- Rose recorded the repeated pattern: source-level plot edits are not enough;
  rendered figures must be inspected one by one before the task is called done.
- Grace verified that the focused vignette renders complete and that inspected
  PNGs were saved as durable QA evidence.

These were role perspectives, not spawned subagents.

## Changes

- Added a project-local `figure-visual-audit` skill so future visual work has a
  hard rendered-image gate, shared role accountability, explicit uncertainty
  provenance, and a rule against fake replicate-level clouds from aggregates.
- Updated `AGENTS.md` and `docs/design/39-visualization-grammar.md` so figure
  quality is shared across Florence, Fisher, Pat, Rose, Grace, Boole, Noether,
  Curie, Darwin, and Ada.
- Replaced the coefficient "confidence cloud" display with compact
  raindrop-style rows on a shared fitted coefficient scale. The vignette now
  warns that shared coefficient axes are only appropriate when predictors are
  standardized, commensurate, or converted to named contrasts.
- Replaced the correlation interval display with raindrop-style compatibility
  rows on Fisher's `z` scale, while keeping residual `rho12`, ordinary group,
  and phylogenetic layers visually distinct.
- Changed simulation coverage/power examples away from required raindrop
  shapes. They now show replicate-block proportions plus aggregate points and
  95% binomial MCSE intervals, with prose saying formal reports should use
  stored replicate rows or stored block summaries.
- Shortened clipped figure subtitles and reduced crowded axis ticks in the
  gallery coverage panel.

## Evidence

Focused renders:

```sh
Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = '/tmp/drmtmb-figure-rescue/figure-gallery-final3', output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/simulation-plot-grammar.Rmd', output_dir = '/tmp/drmtmb-figure-rescue/simulation-plot-grammar-final2', output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

`pkgdown::check_pkgdown()` found no problems. `git diff --check` was clean.

Rendered images inspected and saved:

- `docs/dev-log/figure-audits/2026-05-20-raindrop-coverage-rescue/figure-gallery-raindrop-coefficients.png`
- `docs/dev-log/figure-audits/2026-05-20-raindrop-coverage-rescue/figure-gallery-correlation-raindrops.png`
- `docs/dev-log/figure-audits/2026-05-20-raindrop-coverage-rescue/figure-gallery-coverage-blocks.png`
- `docs/dev-log/figure-audits/2026-05-20-raindrop-coverage-rescue/simulation-coverage-power-blocks.png`

## Remaining Limitations

- The simulation replicate-block dots in the gallery and grammar article are
  illustrative fixture blocks. Formal Phase 18 reports should consume stored
  replicate rows or stored block summaries from the simulation artifact schema.
- Raindrop rows are implemented here as vignette recipes, not exported plotting
  helpers. Exporting them needs a stable table contract for likelihood/profile,
  bootstrap, and Wald-derived compatibility objects.
- Shared coefficient-scale displays are not safe for arbitrary predictors. The
  figure must standardize predictors, use named contrasts, or facet when units
  differ.

# gllvmTMB Visual Lessons For drmTMB Figure Audit

## Scope

This note records the sister-package visual lessons used during the first
`drmTMB` figure-gallery polish pass. It does not port `gllvmTMB` code. The
local `gllvmTMB` branch inspected here has uncommitted plot-helper work, so the
source is useful as a design signal rather than a stable external API.

## Source Read

The current local `gllvmTMB` helper
`../gllvmTMB/R/plot-covariance-tables.R` builds pairwise correlation and
Sigma-table plots from tidy extractor rows. The useful design details for this
audit are:

- row labels carry the trait-pair or layer identity;
- redundant colour/fill legends are hidden when the row labels already name
  the target;
- finite interval rows draw intervals or compatibility shapes, while rows
  without finite intervals remain visible as point estimates;
- raindrops are described as frequentist compatibility displays, not posterior
  densities;
- the plot object carries source-data metadata for later inspection.

The same branch also reinforces that public figures should start from
report-ready extractor rows rather than matrix-indexing examples when the goal
is user teaching.

## Transfer To drmTMB

For `drmTMB`, the immediate transfer is visual rather than architectural:
lighter legends, row-label-first layer naming, and explicit missing-interval
visibility. The `figure-gallery` coefficient and correlation raindrops now
hide redundant legends because their row labels name the fixed-effect, SD,
correlation, and structured-layer targets. The modelled `sd(site)` surface now
adds a site-level predictor rug, which makes the design support visible without
putting raw response observations on an SD axis.

No `gllvmTMB` plotting helper was copied, and no package dependency or
provenance update is needed for this slice.

## Later Transfer Candidates

1. Add a small internal plot-contract helper for future gallery fixtures, so
   each figure can expose source rows, interval status, and visual data grain.
2. Prefer extractor-row examples for covariance and correlation figures rather
   than hand-indexed matrix snippets when the public function is ready.
3. Keep row labels and facet labels doing more explanatory work than legends
   on dense figure-gallery panels.

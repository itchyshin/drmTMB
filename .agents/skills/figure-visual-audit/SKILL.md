---
name: figure-visual-audit
description: Audit and improve drmTMB figures, figure galleries, pkgdown articles, simulation reports, and ggplot recipes when plots look poor, inconsistent, misleading, too sparse, missing raw or replicate data, or need Florence, Rose, Pat, Fisher, and Grace visual QA before being called done.
---

# Figure Visual Audit

Use this skill before declaring visualization work complete, and whenever a
reader says a rendered figure looks strange, ugly, inconsistent, too sparse, or
misleading.

## Shared Accountability

Do not treat poor figures as Florence's fault alone. Florence owns the final
scientific-figure standard, but the gate fails earlier if the statistical,
reader, systems, and reproducibility checks let an incomplete plot through.
Several team perspectives must cultivate visual judgment. A useful scientific
figure is not decoration; it helps users understand the model, helps reviewers
see the evidence, and helps the team catch wrong assumptions before they become
text. Beauty means legible hierarchy, honest uncertainty, informative negative
space, coherent colour, and a display that makes the result easier to reason
about than the table alone.

## Standing Roles

- Ada coordinates the audit and decides what changes before merge.
- Florence reviews the rendered image as a scientific figure: composition,
  hierarchy, labels, accessibility, and whether the plot looks publication
  ready.
- Rose searches for repeated failure patterns across figures, prose, NEWS,
  ROADMAP, after-task reports, and check logs.
- Pat checks whether an applied reader can decode the figure without knowing
  the implementation history.
- Fisher checks that the visual data grain matches the claim: raw observations,
  fitted-row predictions, replicate errors, aggregate means, MCSE intervals,
  profile intervals, and missing cells must not be blurred together.
- Grace verifies renderability, pkgdown readiness, and reproducibility.
- Boole checks whether the figure code and public syntax are memorable and do
  not make unsupported syntax look implemented.
- Noether checks that equations, parameter labels, axes, and prose all name the
  same estimand and reporting scale.
- Curie checks whether simulation figures expose the replicate-level or
  aggregate artifacts actually produced by the runner.
- Darwin checks whether the biological question is visible and not buried under
  package-internal terminology.

Say explicitly when these are role perspectives rather than spawned agents.

## Visual Taste Standard

Before changing code, ask what the figure should help the reader do: compare
surfaces, detect bias, see uncertainty, locate missing support, understand a
distributional parameter, or choose the next diagnostic. Then judge the figure
against that purpose:

- A beautiful result figure has a clear visual hierarchy: the main comparison is
  visible first, uncertainty second, provenance and caveats nearby.
- Empty space should guide comparison, not make one point float in a giant
  panel.
- Colour should group meaningfully across articles and remain readable without
  the legend.
- Missing or unsupported cells should feel intentional, not like plotting bugs.
- Raw or replicate-level marks should add understanding; if they become noise,
  summarise them but keep the data grain explicit.
- A figure should help the package team too. If a plot hides non-convergence,
  failed intervals, missing surfaces, or impossible estimates, it is not ready.

## Workflow

1. Inventory the target figures and promises. Search the Rmd, NEWS, ROADMAP,
   design notes, check log, and after-task reports for the article names,
   figure titles, and claims such as "visual check", "raincloud", "raw",
   "replicate", "MCSE", "confidence", "supported", and "planned".
2. Render the actual article or report. Prefer `pkgdown::build_article()` for
   pkgdown pages and `rmarkdown::render(..., output_options =
   list(self_contained = FALSE))` for focused local checks.
3. Extract the rendered PNGs and inspect them one by one. A contact sheet is a
   navigation aid only; it is not enough evidence by itself.
4. Write or update a per-figure audit table with: figure title or chunk,
   source object, visual data grain, uncertainty source, missing-cell display,
   reader risk, verdict, and fix.
5. Run Rose's pattern scan before editing. Common failure patterns are:
   summary-only plots when row-level or replicate-level data are available;
   fake raw data reconstructed from aggregates; invisible or tiny intervals;
   empty faceted panels with one point floating in whitespace; dodged points
   whose locations no longer align with clouds or intervals; unsupported cells
   that disappear silently; titles or subtitles promising uncertainty that the
   figure does not visibly show; implemented-versus-planned status ambiguity;
   clipped labels, cramped legends, and inconsistent palettes or scales.
6. Edit the smallest recipe or prose needed to fix the figure. Do not add a new
   exported plotting helper unless the table contract is stable and tested.
7. Re-render and inspect every changed figure directly. Save durable evidence
   under `docs/dev-log/figure-audits/<date-or-slice>/` when the figure gate is
   part of a meaningful task.
8. Close with a check-log entry and after-task report that names the figures
   inspected and the remaining limitations.

## Hard Gates

- Do not call a figure done from source inspection alone.
- Do not call a gallery visually checked unless the rendered images were
  inspected one by one and Rose recorded cross-figure patterns.
- Do not show raw-response points on a `sigma`, `rho12`, SD, or correlation
  axis. Fitted-row predictions or simulation replicate errors can be shown on
  their own derived axis when the caption names that data grain.
- Do not draw error bars, ribbons, whiskers, or shaded intervals without
  saying what they mean and where they came from: Wald confidence interval,
  profile confidence interval, bootstrap interval, binomial MCSE for coverage,
  RMSE MCSE, or another named source.
- For inference summaries where the interval itself is the message, prefer a
  raindrop-style compatibility display or another visual cue that makes values
  near the estimate look more compatible than values near the interval boundary.
  Do not use posterior language unless the plotted object is genuinely Bayesian.
- Do not put coefficients on one comparative axis unless the predictors are
  standardized, share a meaningful unit, or have been converted to explicit
  contrasts. Otherwise facet or label the units so visual magnitude comparisons
  are not misleading.
- Simulation coverage and power displays do not require raindrops. Their first
  duty is to show the replicate or replicate-block data grain, the aggregate
  proportion, and the named Monte Carlo uncertainty interval.
- Do not fake replicate-level clouds from aggregate summaries. If only
  aggregate rows exist, use aggregate points and uncertainty bars and say so.
- Missing, unsupported, or not-targeted cells should remain visible through
  blank lanes, boundary marks, captions, or support tables.
- Use at most 10 cores for render, simulation, bootstrap, or profile work.

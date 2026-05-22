# Figure Audit: Article Figures First Triage

Date: 2026-05-22

## Scope

This is the first figure-heavy triage after the article navigation sweep. It
checks the rendered figure surfaces that the rendered article checklist flagged
for immediate attention:

- `model-workflow`
- `bivariate-coscale`
- `figure-gallery`
- `simulation-plot-grammar`

This pass does not certify every gallery figure as final publication artwork.
It records rendered evidence, fixes the blocking `bivariate-coscale` display
defects, and gives the finite-interval figures their public `Confidence Eye`
name while leaving the deeper per-figure polish pass queued.

## Evidence Files

Contact sheets:

- `model-workflow-contact.png`
- `bivariate-coscale-contact.png`
- `figure-gallery-contact-1.png`
- `figure-gallery-contact-2.png`
- `simulation-plot-grammar-contact.png`
- `confidence-eye-correlation-display-fixed.png`
- `figure-gallery-coefficient-confidence-eye.png`
- `figure-gallery-variance-confidence-eye.png`
- `figure-gallery-mixed-confidence-eye.png`
- `figure-gallery-location-scale-fit-polished.png`
- `figure-gallery-parameter-surface-polished.png`
- `figure-gallery-residual-scale-check-polished.png`
- `figure-gallery-random-effect-sd-surface-polished.png`
- `figure-gallery-discrete-comparison-polished.png`
- `figure-gallery-cat-cat-interaction-polished.png`
- `figure-gallery-emmeans-display-polished.png`
- `figure-gallery-emmeans-factor-grid-polished.png`
- `figure-gallery-emmeans-interaction-grid-polished.png`
- `figure-gallery-emmeans-boundary-polished.png`
- `figure-gallery-correlation-boundaries-polished.png`
- `figure-gallery-simulation-bias-polished.png`
- `figure-gallery-simulation-coverage-polished.png`

The contact sheets were generated from rendered `pkgdown-site/articles/*`
figure PNGs. The two changed `bivariate-coscale` figures were also inspected
individually after rerendering.

The `confidence-eye-*`, `figure-gallery-*-confidence-eye.png`, and
`figure-gallery-*-polished.png` files are the rendered evidence for this repair.
They use fresh filenames so the app and review notes do not reuse cached
thumbnails from rejected raindrop/CI-line drafts. The
`pkgdown-site/dev/articles/figure-gallery_files/` mirror was also refreshed
from the current article render because it still contained a stale pre-repair
PNG.

## Rejected Draft

The first Confidence Eye edit in this slice was rejected after rendered review.
It renamed existing raindrop/error-bar style panels before returning to the
visual idea itself. That produced cluttered figures with extra bars or outlines
and did not satisfy the user-facing design: finite confidence region plus
hollow estimate circle, with no invented uncertainty.

Rose records this as a process failure: do not retrofit an old uncertainty
panel and call it a Confidence Eye. Start from the visual grammar, then render
and inspect the figure before recording it as fixed.

## Fresh Case-by-case Target

Ada records the repaired target as a case-by-case decision, not a universal
template. The standing roles are perspectives for this audit, not spawned
agents. Pat and Darwin protect raw-data displays when the reader needs sample
grain, spread, outliers, or repeated-measures structure. Fisher checks whether
the uncertainty source matches the estimate and claim. Florence checks rendered
hierarchy and consistency inside each figure family. Rose watches for repeated
drift, especially applying Confidence Eyes to line plots or hiding available raw
observations behind a summary-only panel.

| Figure family | Purpose | Preferred display pattern |
| --- | --- | --- |
| Raw-data plus fitted trend | Show sample support and fitted direction together. | Raw observations stay visible; fitted slopes use lines plus confidence bands when available. |
| Model-surface plot | Compare fitted distributional parameters on their own scales. | Lines or surfaces with bands when supplied; do not put raw response points on `sigma`, SD, or `rho12` axes. |
| Row-wise interval summary | Help readers compare estimates and finite interval evidence row by row. | Confidence Eye only for selected row-wise summaries with real interval provenance. |
| Point or cell summary | Show fitted means, contrasts, or EMMs. | Dots with intervals; raw data may be added when they clarify sample support. |
| Simulation summary | Show replicate behaviour and aggregate operating characteristics. | Replicate or replicate-block dots plus aggregate points and named MCSE intervals. |
| Support-boundary strip | Explain what is fitted, boundary, partial, or planned. | Explicit status marks and labels; no decorative uncertainty. |

## Findings

| Article | Rendered figures | Alt text after pass | Visual verdict | Action |
| --- | ---: | --- | --- | --- |
| `model-workflow` | 5 | complete | Readable first-pass workflow figures; no obvious clipping or empty interval bands in rendered triage. | No source edit in this pass. |
| `bivariate-coscale` | 2 | fixed | The residual `rho12` curve had no alt text, no uncertainty display, and a transparent/base-plot rendering that failed on dark backgrounds. The group-level `corpairs()` plot had no alt text and unreadable long row labels. | Added `fig.alt`, changed the residual curve to a white-background ggplot with a 95% Wald ribbon from `predict_parameters()`, and gave `plot_corpairs()` compact labels plus a title/subtitle that states intervals are not drawn. |
| `figure-gallery` | 21 | complete triage | Contact-sheet triage found the gallery broadly readable, but the first Confidence Eye attempt was rejected. The repaired coefficient, variance-component, mixed-parameter, and correlation-row figures now use pale finite regions plus hollow estimate circles. The correlation-row figure uses Fisher-z/atanh confidence regions for residual, group, phylogenetic, spatial, animal, and `relmat()` rows. A later one-by-one pass found several figures technically correct but visually clunky: point-interval summaries were too airy, the parameter-surface figure made shared `sigma` look habitat-specific, and some compact teaching panels were too loud for their data grain. | Named the finite-interval display `Confidence Eye`, removed default CI bars, filled estimate dots, outer outlines, and stale titles/subtitles from the Confidence Eye examples, clarified that CI-line overlays are optional variants rather than the default, compacted the discrete/EMM point-interval family, softened the global gallery theme, made shared `sigma` explicit, strengthened support rugs, tightened support-boundary strips, and used dotted target lines in simulation summaries. |
| `simulation-plot-grammar` | 5 | complete | Rendered panels are readable and keep replicate dots, aggregate points, MCSE intervals, and failure ledgers visible. | No source edit in this pass; future pass should check MCSE/provenance wording figure by figure. |

## Repaired Figures

`bivariate-coscale-rho12-curve`

- Data grain: fitted residual correlation on a `newdata` disturbance grid.
- Uncertainty source: 95% Wald interval from `predict_parameters()`.
- Problem: empty alt text and transparent base-plot rendering were fragile
  outside a white pkgdown page. The point-only line also underused available
  uncertainty.
- Fix: added alt text and a white-background ggplot display with a 95% Wald
  ribbon.

`bivariate-coscale-group-corpairs-plot`

- Data grain: two fitted correlation rows from `corpairs(fit_group)`, one
  residual row and one group-level `mu1`/`mu2` random-intercept row.
- Uncertainty source: none drawn in this example.
- Problem: empty alt text and default long
  `level | class | parameter` labels made the row labels unreadable.
- Fix: added alt text, compact display labels, and a title/subtitle that name
  the residual and individual-level layers while saying intervals are not
  drawn.

`figure-gallery` correlation-row Confidence Eye

- Data grain: compact `corpairs()`-style fitted correlation-row table for
  residual `rho12`, group, phylogenetic, spatial, animal, and `relmat()`
  layers.
- Uncertainty source: illustrative finite 95% intervals transformed on
  Fisher's `z`/atanh scale.
- Problem: the first edit relabelled a cluttered existing display instead of
  designing from the Confidence Eye grammar. A later draft still showed black
  interval bars and filled points, which contradicted the default design.
- Fix: repaired the six-row correlation display itself: pale finite confidence
  regions, hollow point-estimate circles, no outer outline, no default CI bar,
  and row labels that name the correlation layer. Subtle row guides remain an
  acceptable variant when they read as lane guides rather than interval bars.
  The fixed render is saved as
  `confidence-eye-correlation-display-fixed.png`.

`figure-gallery` coefficient, mixed-parameter, and variance-component
Confidence Eyes

- Data grain: fitted coefficient, residual-SD, group-SD, and random-effect
  correlation rows from the gallery models.
- Uncertainty source: fast Wald intervals; SD rows are shaped on the log-SD
  scale and displayed on the SD scale, while the correlation row is shaped on
  Fisher's `z` scale and displayed as a correlation.
- Problem: the previous mixed display still carried faceting machinery, strip
  labels, filled dots, and bar-like interval cues. It looked like an internal
  diagnostic rather than the default Confidence Eye. A later consistency check
  found that the coefficient, mixed-parameter, and correlation-row examples also
  needed the same bottom-axis treatment as the variance-component anchor.
- Fix: replaced the mixed display with a single clean row display, standardized
  the row displays on slim lenses, hollow point estimates, dotted zero
  references where meaningful, vertical scale grids, and bottom axes, and saved
  the inspected coefficient, variance-component, and mixed-parameter renders as
  `figure-gallery-coefficient-confidence-eye.png`,
  `figure-gallery-variance-confidence-eye.png`, and
  `figure-gallery-mixed-confidence-eye.png`.

`figure-gallery` point-interval summary family

- Data grain: fitted habitat means, categorical fitted cell means, `emmeans`
  marginal means, and named temperature-slice marginal means.
- Uncertainty source: Wald intervals from `predict_parameters()` for the
  direct prediction summaries and asymptotic `emmeans` intervals for the
  `emmeans` bridge examples.
- Problem: the figures were statistically honest but too sparse for their
  canvas. The first direct prediction panel was also titled as a "contrast"
  while showing fitted means.
- Fix: added a compact point-interval theme, shortened the one/two-row panels,
  rounded interval segments, corrected the direct prediction title to fitted
  means, gave the categorical panel a more specific title, and changed the
  temperature-slice EMM display into a connected trend with intervals. The
  inspected renders are saved as `figure-gallery-discrete-comparison-polished.png`,
  `figure-gallery-cat-cat-interaction-polished.png`,
  `figure-gallery-emmeans-display-polished.png`,
  `figure-gallery-emmeans-factor-grid-polished.png`, and
  `figure-gallery-emmeans-interaction-grid-polished.png`.

`figure-gallery` broader polish pass

- Data grain: raw/fitted displays, model-surface displays, derived scale
  checks, support-boundary strips, and simulation operating-characteristic
  summaries.
- Uncertainty source: unchanged from the source figures; the pass changed
  visual hierarchy and labels, not statistical intervals.
- Problem: several figures were technically correct but visually heavier or
  more ambiguous than needed. The shared `sigma ~ temperature` surface looked
  like a habitat-specific curve, the global gallery theme made compact panels
  feel oversized, the site-level support rug was too quiet, and simulation
  target lines were not visually aligned with the dotted-null convention.
- Fix: softened the base gallery theme, made the `sigma` surface a green
  "shared sigma" curve with matching ribbon, shortened several subtitles,
  strengthened the site-support rug, tightened the two support-boundary strips,
  and used dotted target/reference lines for the simulation bias and coverage
  panels. Representative inspected renders are saved as
  `figure-gallery-location-scale-fit-polished.png`,
  `figure-gallery-parameter-surface-polished.png`,
  `figure-gallery-residual-scale-check-polished.png`,
  `figure-gallery-random-effect-sd-surface-polished.png`,
  `figure-gallery-emmeans-boundary-polished.png`,
  `figure-gallery-correlation-boundaries-polished.png`,
  `figure-gallery-simulation-bias-polished.png`, and
  `figure-gallery-simulation-coverage-polished.png`.

## Figure-gallery Case-by-case Triage

| Chunk | Data grain | Uncertainty source | Verdict |
| --- | --- | --- | --- |
| `location-scale-fit` | Raw observations plus fitted mean lines. | 95% Wald bands from `predict_parameters()`. | Polished theme and legend; keep raw-data plus fitted-trend grammar. |
| `parameter-surface` | Fitted `mu` and shared `sigma` surfaces on response scales. | Wald bands where finite. | Polished to show `sigma` as shared; no raw response points on `sigma`. |
| `residual-scale-observed-check` | Absolute residual magnitudes plus expected absolute residual curve. | None drawn. | Polished subtitle; keep derived observed-check grammar. |
| `confidence-distribution-slopes` | Row-wise fixed-effect estimates. | Wald intervals shaped as Confidence Eyes. | Fixed and accepted. |
| `shape-inflation-rho12-panels` | Fitted `nu`, `zi`, and `rho12` curves on response scales. | Wald bands. | Keep parameter-panel grammar. |
| `random-effect-variance-components` | Residual and group SD rows. | Wald intervals shaped on log-SD scale. | Fixed and accepted. |
| `coefficient-intervals` | Mixed fixed-effect, SD, and correlation rows. | Wald intervals, log-SD shaping for SDs, Fisher-z shaping for correlation. | Fixed and accepted. |
| `random-slope-modes` | Raw repeated observations plus fitted site and population trajectories. | Shrunken modes, not variance intervals. | Keep raw repeated-measures grammar. |
| `random-effect-sd-surface` | Fitted among-site SD curve plus predictor support rug. | No interval supplied. | Polished support rug; keep point/line-only. |
| `discrete-comparison` | Fitted habitat means. | Wald intervals from `predict_parameters()`. | Polished as compact point-interval display. |
| `cat-cat-interaction` | Raw observations plus fitted cell means. | Wald intervals from `predict_parameters()`. | Polished title; raw observations remain useful. |
| `emmeans-display` | `emmeans` habitat marginal means. | Asymptotic `emmeans` intervals. | Polished as compact point-interval display. |
| `emmeans-factor-grid` | `emmeans` habitat means by season. | Asymptotic `emmeans` intervals. | Polished as compact point-interval display. |
| `emmeans-interaction-grid` | `emmeans` habitat means across named temperature slices. | Asymptotic `emmeans` intervals. | Polished as connected point-interval trend. |
| `empirical-marginal-summary` | Fitted-row `mu` predictions plus plug-in marginal summaries. | Averaged row-wise Wald prediction limits. | Keep richer fitted-row distribution grammar. |
| `emmeans-boundary-strip` | Supported and unsupported `emmeans` target statuses. | None; status display only. | Polished as compact support-boundary grammar. |
| `cont-cont-interaction` | Raw observations plus fitted temperature slopes at moisture slices. | Wald confidence bands. | Keep raw-data plus fitted-slice grammar. |
| `correlation-display` | Fitted correlation rows. | Illustrative finite intervals shaped on Fisher-z scale. | Fixed and accepted. |
| `correlation-layer-boundaries` | Correlation-layer support statuses. | None; status display only. | Polished as compact support-boundary grammar. |
| `simulation-operating-characteristics-1` | Fixture replicate errors plus aggregate bias. | 95% MCSE intervals. | Polished dotted reference line; keep simulation-replicate grammar. |
| `simulation-operating-characteristics-2` | Replicate-block coverage plus aggregate coverage. | 95% binomial MCSE intervals. | Polished dotted target line; keep simulation-coverage grammar. |

## Remaining Figure Work

The one-by-one gallery triage found no remaining blocking visual defect after
the Confidence Eye and point-interval fixes. This is still a teaching gallery,
not a final manuscript figure set. Future publication polishing can tune
individual panels for a specific paper layout, but the current article now has
a coherent grammar: raw-data displays keep raw evidence, model surfaces stay on
parameter scales, row-wise interval summaries use Confidence Eyes only when
appropriate, point summaries use compact point intervals, simulation summaries
show replicate or block evidence plus MCSE intervals, and support-boundary
strips do not invent uncertainty.

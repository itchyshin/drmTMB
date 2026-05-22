# Full Gallery Figure Audit: 2026-05-20

## Scope

Ada, Florence, Pat, Fisher, Grace, and Rose reran the rendered-gallery audit
after the user pointed out that the previous review had still missed obvious
visual problems. These were role perspectives, not spawned agents.

Grace rebuilt the gallery and simulation grammar pages locally, Florence
inspected the rendered PNGs rather than only reading source, Fisher checked
that uncertainty wording named the interval source, Pat checked whether a new
reader could interpret the plot without hidden jargon, and Rose recorded why
the earlier pass failed.

Contact sheets used for navigation:

- `before-contact-sheet.png`
- `after-contact-sheet.png`
- `after-contact-sheet-v2.png`
- `after-contact-sheet-v3.png`

Contact sheets are evidence for navigation only. They do not replace opening
and checking individual figures when a figure is controversial or user-facing.

## What Failed Before

The earlier audit was too weak. It mixed source review, selected rendered
figures, and a contact sheet, but it did not enforce a one-figure-at-a-time
visual gate. That let several problems remain visible online: sparse emmeans
panels, vague residual-magnitude wording, an empty random-effect SD surface,
and interval figures that used bars where a compatibility or raindrop display
would teach more clearly.

The process correction is now explicit: a figure is not "checked" unless the
rendered output was inspected for alignment, missing uncertainty, raw or
replicate grain, label honesty, interval provenance, and whether it actually
helps a reader see what the fitted model says.

## Repairs Made

- Converted the coefficient interval display from thick interval bars to
  raindrop-style Wald compatibility displays with central 66% and 95%
  intervals.
- Replaced sparse habitat and emmeans vertical point-range panels with compact
  horizontal interval displays so the estimates and their Wald intervals sit on
  the same scale and are not clipped by the viewport.
- Shortened the residual-magnitude y label and clarified that the green curve
  is sigma converted to expected absolute residual size.
- Added visible points to the fitted among-site SD surface so it no longer
  reads as an unsupported raw-growth curve.
- Kept simulation operating-characteristic displays as replicate/MCSE displays,
  not inference raindrops. This preserves the distinction between simulation
  uncertainty and confidence distributions for fitted effects.

## Figure Inventory

| Rendered figure | Status after repair | Notes |
| --- | --- | --- |
| `cat-cat-interaction-1.png` | acceptable | Shows raw observations plus fitted cell means; uncertainty source is named. |
| `coefficient-intervals-1.png` | repaired | Now uses raindrop compatibility displays; fixed the grouping artifact from an intermediate draft. |
| `confidence-distribution-slopes-1.png` | acceptable | Raindrop display is appropriate for fitted coefficient compatibility. |
| `cont-cont-interaction-1.png` | acceptable | Raw observations, fitted lines, and uncertainty bands are visible. |
| `correlation-display-1.png` | superseded | The older raindrop confidence display was later rejected for the correlation-row default; use the refreshed Confidence Eye artifact with pale regions and hollow estimates. |
| `correlation-layer-boundaries-1.png` | acceptable | Planned and fitted support are visually separated. |
| `discrete-comparison-1.png` | repaired | Horizontal interval display avoids the sparse two-point vertical plot. |
| `emmeans-boundary-strip-1.png` | watch | Honest support boundary, but still dense; revisit when the emmeans article is split. |
| `emmeans-display-1.png` | repaired | Horizontal interval display is easier to scan than the original sparse vertical panel. |
| `emmeans-factor-grid-1.png` | repaired | Season-conditioned intervals now use a compact horizontal layout. |
| `emmeans-interaction-grid-1.png` | acceptable | Interaction estimates are visible; keep as teaching figure. |
| `empirical-marginal-summary-1.png` | acceptable | Shows fitted-row distribution and mean intervals; not raw responses. |
| `location-scale-fit-1.png` | acceptable | Raw observations and fitted confidence bands are visible. |
| `parameter-surface-1.png` | acceptable | Location and sigma surfaces are separated by panel and labelled by scale. |
| `random-effect-sd-surface-1.png` | repaired | Added points and clearer title/subtitle; intervals remain honestly unavailable. |
| `random-effect-variance-components-1.png` | acceptable | Simple component display; no false interval claim. |
| `random-slope-modes-1.png` | acceptable | Site trajectories show random-slope behaviour directly. |
| `residual-scale-observed-check-1.png` | repaired | Label and subtitle now explain residual magnitudes and sigma conversion. |
| `shape-inflation-rho12-panels-1.png` | acceptable | Future-facing multipanel grammar, with distinct targets. |
| `simulation-operating-characteristics-1.png` | acceptable | Illustrative simulation bias display with pseudo-replicate grain. |
| `simulation-operating-characteristics-2.png` | acceptable | Coverage bars and MCSE intervals align in the current render. |
| `bias-rmse-display-1.png` | acceptable | Bias display keeps replicate-level error visible. |
| `bias-rmse-display-2.png` | acceptable | RMSE uncertainty is separated by facets; no fake inference density. |
| `convergence-runtime-display-1.png` | watch | Useful diagnostic summary, but the visual hierarchy can be improved later. |
| `coverage-power-display-1.png` | acceptable | Simulation uncertainty is shown as faint replicate points plus MCSE intervals. |
| `failure-ledger-display-1.png` | watch | Honest failure accounting, but could use a better reader-first design. |

## Future Rule

Once the gallery grammar is stable, every substantive worked example should
include a model-output figure that helps readers see what the fitted model says,
not just a printed table. The figure should name the estimand, the reporting
scale, the uncertainty source, and whether the display is raw data, fitted
prediction, simulation replicate grain, Wald confidence, profile likelihood,
bootstrap, or a planned-but-unsupported boundary.

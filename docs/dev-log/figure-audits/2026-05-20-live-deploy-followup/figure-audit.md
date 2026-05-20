# Live Deploy Figure Follow-Up: 2026-05-20

## Scope

Ada, Florence, Fisher, Pat, Grace, and Rose checked the deployed pkgdown site
after PR #264 merged and the `pkgdown` workflow deployed. These were role
perspectives, not spawned agents.

The live deploy confirmed that the major gallery repairs had landed, but it
also exposed three remaining polish failures that the local contact-sheet review
had described too generously. This follow-up records the rendered-image evidence
and the source repairs.

## Live Figures Inspected

| Figure | Live deploy finding | Repair in this PR |
| --- | --- | --- |
| `figure-gallery/empirical-marginal-summary-1.png` | The plot tried to carry a long caption inside the image, and the explanatory text sat too close to the bottom edge. | Moved the data-grain and interval-source explanation into a two-line subtitle. The rendered PNG now says the faint points are fitted-row `mu` predictions, not raw responses, and that points/bars average row-wise 95% Wald prediction limits. |
| `simulation-plot-grammar/bias-rmse-display-1.png` | The subtitle clipped on the right edge of the PNG. | Shortened the subtitle while keeping the visual contract: clouds/dots are pseudo-replicate errors; points/bars are mean bias with 95% MCSE. |
| `simulation-plot-grammar/coverage-power-display-1.png` | Inline `n=` labels made the panel feel cramped and risked misalignment with the points and bars. | Removed the inline `n=` labels, kept the `n_interval` column in the table, and added prose explaining that MCSE uses that cell-level `n`. |

Rendered evidence saved in this folder:

- `bias-rmse-display-1.png`
- `coverage-power-display-1.png`
- `empirical-marginal-summary-1.png`

## Pattern Found

Rose's pattern call is that "locally rendered" was treated as a binary status,
but the visual gate needs a per-figure verdict at the output size the reader
will actually see. A figure can render successfully and still fail because a
subtitle clips, a caption hangs off the image, or an annotation crowds the
geometry it is trying to explain.

## Standard Reinforced

The visualization grammar now says that every substantive worked example should
include a model-output figure once its table contract is stable. The figure must
name the estimand, reporting scale, data grain, uncertainty source, and missing
support status. Source code, contact sheets, and successful `pkgdown` builds are
not enough evidence when the figure itself is the reader's main result.

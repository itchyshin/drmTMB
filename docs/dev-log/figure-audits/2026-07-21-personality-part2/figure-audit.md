# Figure audit: Part II personality example

## Purpose

The figures should let an applied reader distinguish the three fitted parts of
the repeated-measures model: expected exploration score, between-individual
SD, and within-individual residual SD. They should not imply that a fitted
point estimate carries an uncertainty interval.

## Audit table

| Figure | Source object | Visual data grain | Uncertainty source | Reader risk | Verdict and refinement |
|---|---|---|---|---|---|
| `personality-data-figure` | all 480 simulated observations, 80 observed individual means, and two population-level fitted `mu` values | grey marks are observations; blue ticks are individual means; vermillion lines are fitted sex means | none shown | a distribution-only display could conflate within- and between-individual variation | PASS after faceting by sex, retaining one shared vertical scale, ordering individuals within sex, directly labelling the fitted mean, and naming every mark in the caption |
| `personality-component-figure` | six population-level predictions from `predict()` | one fitted natural-scale value for each sex and each of `mu`, `sd(individual)`, and `sigma` | none shown | connecting lines could be mistaken for trajectories or intervals; free vertical scales prevent cross-panel slope comparison | PASS with numeric labels, separate facets, zero included in every panel, and a caption stating that lines aid comparison and are not uncertainty intervals |

## Florence and Tufte review

Florence recommended preserving the repeated-measures hierarchy instead of
using violins or rainclouds, because marginal distributions cannot separate
between-individual from within-individual variation. The Tufte review supported
direct labels, an accessible Okabe-Ito blue/vermilion palette, no redundant
legend, and one small fitted-component comparison. The resulting article uses
two compact figures and hides their construction code so the tutorial remains
short for readers.

## Cross-figure checks

- The first figure shows raw observations only on the response axis.
- The second figure shows fitted parameter values only; it does not place raw
  responses on an SD axis.
- No error bars, ribbons, whiskers, or posterior language appear.
- Captions name the plotted grain and the absence of uncertainty intervals.
- Alt text states the biological comparison without depending on colour.
- Both figures were rendered at 144 dpi and inspected individually from the
  generated PNGs.

## Residual limitation

The tutorial reports point estimates of sex-specific repeatability but does not
plot or claim uncertainty for that nonlinear derived quantity. A calibrated
repeatability interval remains outside this documentation-only change.

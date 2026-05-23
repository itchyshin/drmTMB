# Rendered Figure QA: Slices 46-50

Date: 2026-05-23

## Scope

This note records the next rendered-figure pass after PR #307 merged. The slice
set covered:

46. verify and merge PR #307, then start a fresh branch from updated `main`;
47. update `animal-models` status wording for one-slope and residual-scale
    structured-intercept routes that are now fitted;
48. add animal-model rendered checks: known additive relationship heatmap,
    fitted residual-`sigma` versus animal-location-SD intervals, and a q=2
    animal mean-mean Confidence Eye;
49. update `relmat-known-matrices` status wording for one-slope and
    residual-scale structured-intercept routes that are now fitted;
50. add `relmat()` rendered checks: known relatedness heatmap, fitted
    residual-`sigma` versus known-matrix-location-SD intervals, and a q=2
    `relmat()` mean-mean Confidence Eye, then rebuild and validate.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

Before editing, the focused animal and `relmat()` guide articles were table-heavy
and had no article-specific rendered checks. After editing and rebuilding, the
target pages contained six new figure files:

- `animal-models_files/figure-html/animal-relatedness-matrix-1.png`
- `animal-models_files/figure-html/animal-sd-figure-1.png`
- `animal-models_files/figure-html/animal-q2-confidence-eye-1.png`
- `relmat-known-matrices_files/figure-html/relmat-known-matrix-1.png`
- `relmat-known-matrices_files/figure-html/relmat-sd-figure-1.png`
- `relmat-known-matrices_files/figure-html/relmat-q2-confidence-eye-1.png`

## Visual Decisions

The animal and `relmat()` matrix heatmaps are raw structural-input figures.
They show the known additive relatedness matrix or user-supplied relatedness
matrix that controls the latent random-effect covariance. They do not draw
intervals because the matrix is not model-estimated uncertainty.

The SD displays are model-summary figures. They compare residual `sigma` with
the structured location SD from the fitted univariate Gaussian model. Both rows
use response-scale point estimates and 95% Wald intervals from
`confint(..., parm = "variance_components")`.

The animal and `relmat()` q=2 correlation rows are Confidence Eyes because
`corpairs(..., conf.int = TRUE)` supplies finite 95% profile intervals for the
latent mean-mean correlation row. The dotted vertical line marks zero
correlation. Raw observations do not appear on these correlation axes.

## Visual Inspection

Florence inspected the regenerated PNGs after rebuilding:

- `animal-relatedness-matrix-1.png`: the heatmap reads as known additive
  relatedness rather than uncertainty.
- `animal-sd-figure-1.png`: residual `sigma` and animal location SD are
  separated with hollow estimates and finite 95% Wald intervals.
- `animal-q2-confidence-eye-1.png`: the Confidence Eye has a visible profile
  interval, hollow estimate, and dotted zero line.
- `relmat-known-matrix-1.png`: the heatmap reads as a supplied relatedness
  matrix for experimental lines.
- `relmat-sd-figure-1.png`: residual `sigma` and `relmat()` location SD are
  separated with finite 95% Wald intervals.
- `relmat-q2-confidence-eye-1.png`: the final render has a real profile
  interval eye. The first render was a lone point because the simulated profile
  bounds were `NA`; that example was replaced before the slice was accepted.

## Remaining Work

The next rendered-figure pass can move to pages that still rely mostly on
tables, status text, or raw code output. The same case-by-case visual rule
should hold: raw matrices and raw observations are useful when they are the
reader evidence, fitted SDs should carry named interval provenance, and
Confidence Eyes should be reserved for finite fitted-interval summaries such as
correlation rows.

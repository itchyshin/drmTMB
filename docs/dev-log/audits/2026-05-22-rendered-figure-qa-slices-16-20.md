# Rendered Figure QA: Slices 16-20

Date: 2026-05-22

## Scope

This note records the next small rendered-figure pass after PR #300 merged. The
slice set covered:

16. merge PR #300 and start a fresh branch from `main`;
17. close the current generated-reference alt-text gap for
    `plot_corpairs()` and `plot_parameter_surface()` with a pkgdown
    post-build patch;
18. re-render the reference, simulation, structural-correlation, and gallery
    targets that carry the highest visual risk;
19. polish the `simulation-plot-grammar` convergence/runtime and failure-ledger
    figures so status data remain visible without a one-rule-fits-all
    Confidence Eye display;
20. record the current figure decision table in the visualization grammar.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, Curie, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

The following pages were checked after the branch started:

| Page | Rendered images | Missing alt text | Notes |
| --- | ---: | ---: | --- |
| `simulation-plot-grammar` | 5 | 0 | Convergence/runtime and failure-ledger figures polished. |
| `phylogenetic-spatial` | 2 | 0 | Animal and `relmat()` q=2 Confidence Eyes still render correctly. |
| `figure-gallery` | 21 | 0 | Re-inventoried as the broad visual reference page. |
| `plot_corpairs()` reference | 1 | 0 after post-processing | `downlit` emits empty alt in raw reference examples; the deployed site now patches this image after build. |
| `plot_parameter_surface()` reference | 1 | 0 after post-processing | Same generated-reference post-build route. |

## Visual Decisions

The reference-page accessibility issue is generated-site plumbing, not an
article prose problem. `downlit` currently emits reference example plot images
with `alt=""`. This slice adds `tools/fix-pkgdown-reference-alt.R` and calls it
from the pkgdown deployment workflow after `pkgdown::build_site()` and the
existing favicon fix. That keeps the roxygen examples readable while giving the
deployed reference images meaningful alt text.

`simulation-plot-grammar` should not turn readiness and failure figures into
Confidence Eyes. Bias, RMSE, coverage, and power already carry MCSE intervals
where the uncertainty source is part of the claim. Convergence, `pdHess`,
runtime, and failure-ledger displays are status summaries. Their job is to make
the data grain visible, not to imply interval inference where none was computed.

## Visual Inspection

Florence inspected the changed rendered PNGs:

- `simulation-plot-grammar_files/figure-html/bias-rmse-display-1.png`: retained
  as a replicate-error display with mean bias and MCSE intervals.
- `simulation-plot-grammar_files/figure-html/bias-rmse-display-2.png`: retained
  as an aggregate RMSE point-and-MCSE display.
- `simulation-plot-grammar_files/figure-html/coverage-power-display-1.png`:
  retained as block-level proportions plus aggregate binomial MCSE intervals.
- `simulation-plot-grammar_files/figure-html/convergence-runtime-display-1.png`:
  revised to row-wise status and runtime summaries, with the two units kept in
  separate facet rows.
- `simulation-plot-grammar_files/figure-html/failure-ledger-display-1.png`:
  revised to separate status rows by surface, so rare warnings, boundaries,
  errors, and skipped cells remain visible beside the dominant `ok` count.
- `phylogenetic-spatial_files/figure-html/animal-q2-correlation-eye-1.png` and
  `relmat-q2-correlation-eye-1.png`: still show one-row q=2 Confidence Eyes with
  dotted zero references and profile intervals.
- `reference/plot_corpairs-1.png` and `reference/plot_parameter_surface-1.png`:
  still render the intended plotting-helper examples; the generated HTML now
  receives meaningful image alt text after post-processing.

## Remaining Work

The reference alt-text patch is intentionally narrow. If future pkgdown
reference examples add more generated plot images, `tools/fix-pkgdown-reference-alt.R`
should be extended with explicit image-specific alt text rather than applying a
generic placeholder. The broader visual grammar now has a decision table, but it
will still need case-by-case review whenever a new simulation report or article
adds a new figure type.

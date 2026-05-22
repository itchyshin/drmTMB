# Rendered Figure QA: Slices 6-10

Date: 2026-05-22

## Scope

This note records the next figure-QA pass after PR #298 merged. The slice set
covered:

6. merge PR #298 and start a fresh branch from `main`;
7. rebuild the next structural and reference targets from rendered pages;
8. add rendered q=2 structural-correlation displays to
   `phylogenetic-spatial`;
9. update the `animal-models` and `relmat-known-matrices` leaf pages so q=2
   correlation reports request interval provenance before plotting;
10. update the `plot_corpairs()` reference example so every fitted row in the
    example carries interval evidence.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace, Boole,
Noether, Rose, and the prose-style reviewers. They are review perspectives, not
spawned agents.

## Rendered Inventory

The following pages were rebuilt:

| Page | Rendered images | Missing alt text | Captions | Notes |
| --- | ---: | ---: | ---: | --- |
| `phylogenetic-spatial` | 2 | 0 | 2 | New animal and `relmat()` q=2 Confidence Eyes. |
| `animal-models` | 0 | 0 | 0 | Leaf page now gives the interval-aware plotting pattern. |
| `relmat-known-matrices` | 0 | 0 | 0 | Leaf page now gives the interval-aware plotting pattern. |
| `plot_corpairs()` reference | 1 | 1 | 0 | Example image now shows all four rows with Confidence Eyes; pkgdown reference example images do not expose the article-style `fig.alt`/`fig.cap` hooks. |
| `predict_parameters()` reference | 0 | 0 | 0 | Checked as a core plotting-table producer. |
| `plot_parameter_surface()` reference | 1 | 1 | 0 | Existing reference example remains a fitted-surface example; no source change was needed. |

## Visual Decisions

The q=2 animal and `relmat()` examples in `phylogenetic-spatial` are fitted
model estimates with profile intervals, so they now render as Confidence Eyes.
The examples use actual fitted `corpairs(..., conf.int = TRUE)` rows, not a
schematic table. The simulation seed for that section was set explicitly to
produce finite profile bounds for both q=2 structural correlations; the earlier
seed produced a one-sided `relmat()` profile and would have made the caption
overclaim uncertainty.

The `animal-models` and `relmat-known-matrices` leaf pages remain concise route
pages rather than fitted-data galleries. Their new prose tells users to request
`corpairs(..., conf.int = TRUE)` before plotting q=2 correlations, and it keeps
q=4 rows separate because current q=4 correlations are derived rows whose
tables can show `conf.status` without profile Confidence Eyes.

The `plot_corpairs()` reference example now gives the residual `rho12` row
finite profile-style bounds too. That avoids teaching the pattern that a fitted
residual correlation should float as a lone point when interval evidence is
available.

## Visual Inspection

Florence inspected the rendered PNGs:

- `animal-q2-correlation-eye-1.png`: one-row animal q=2 Confidence Eye with a
  hollow point estimate, pale 95% profile region, and dotted zero reference.
- `relmat-q2-correlation-eye-1.png`: one-row `relmat()` q=2 Confidence Eye with
  a hollow point estimate, pale 95% profile region, and dotted zero reference.
- `plot_corpairs-1.png`: reference example now shows Confidence Eyes for
  residual, group, phylogenetic, and scale-scale rows.
- `plot_parameter_surface-1.png`: existing reference example remains a
  line/ribbon surface with explicit interval provenance in the example data.

## Issue Check

`gh issue list --search "figure OR visualization OR caption OR corpairs OR Confidence Eye" --limit 30`
returned open issue #58, "Phase 17: visualization layer for fitted models and
simulation outputs", as the relevant overlapping issue. This slice should
update #58 after the PR is opened.

## Remaining Work

Reference example images still lack article-style alt text in the generated
pkgdown HTML. The source examples are clearer, but a future accessibility slice
should decide whether to customize reference-page example images or document
that limitation separately from article figures.

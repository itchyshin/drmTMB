# Rendered Figure QA: Slices 36-40

Date: 2026-05-22

## Scope

This note records the next rendered-figure pass after PR #304 merged. The slice
set covered:

36. merge PR #304, start a fresh branch from `main`, and inventory rendered
    figures for `location-scale`, `which-scale`, and `phylogenetic-spatial`;
37. add a raw-plus-fitted `mu` figure and a separate fitted `sigma` contrast to
    the `location-scale` tutorial;
38. add fitted `sigma` and fitted `sd(population)` scale-audit figures to
    `which-scale`;
39. tighten the animal and `relmat()` q=2 Confidence Eyes in
    `phylogenetic-spatial`;
40. rebuild, inspect, and validate the changed article figures.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, Curie, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

Before editing, `location-scale` and `which-scale` had no referenced rendered
article images. `phylogenetic-spatial` had two referenced Confidence Eye
figures:

- `phylogenetic-spatial_files/figure-html/animal-q2-correlation-eye-1.png`
- `phylogenetic-spatial_files/figure-html/relmat-q2-correlation-eye-1.png`

After editing and rebuilding, the target pages contained six referenced article
images:

- `location-scale_files/figure-html/location-scale-growth-figure-1.png`
- `location-scale_files/figure-html/location-scale-sigma-contrast-figure-1.png`
- `which-scale_files/figure-html/which-scale-residual-sigma-figure-1.png`
- `which-scale_files/figure-html/which-scale-population-sd-figure-1.png`
- `phylogenetic-spatial_files/figure-html/animal-q2-correlation-eye-1.png`
- `phylogenetic-spatial_files/figure-html/relmat-q2-correlation-eye-1.png`

## Visual Decisions

The `location-scale` growth figure is a response-scale figure. It shows raw
growth points together with fitted `mu` lines and 95% Wald bands from
`predict_parameters()`. This is the only new figure in this slice that uses raw
response points.

The `location-scale` `sigma` contrast is a fitted residual-SD figure. It uses
horizontal point intervals because the focal predictor is discrete habitat, and
it states that the bars are 95% Wald intervals from `predict_parameters()`.
Raw growth points stay out of this panel.

The `which-scale` residual-scale figure is a fitted `sigma` surface over
temperature. It uses a line and 95% Wald ribbon because `sigma ~ temperature`
is a continuous fitted residual-scale model and the prediction table supplies
finite Wald bounds.

The `which-scale` random-effect-scale figure is a fitted `sd(population)`
display. It deliberately shows point estimates only. The prediction table marks
the modelled random-effect-SD surface as `interval_source = "not_available"`,
so adding interval bars would invent uncertainty. The figure title and caption
state that no supported interval is drawn.

The `phylogenetic-spatial` animal and `relmat()` q=2 figures remain Confidence
Eye targets because they are row-wise fitted latent-correlation summaries with
profile intervals. The edits add visible titles, subtitles that name the 95%
profile intervals and dotted zero line, and level-specific colour.

## Visual Inspection

Florence inspected the regenerated PNGs after rebuilding:

- `location-scale-growth-figure-1.png`: raw response values and fitted `mu`
  Wald bands are visually separated and labelled.
- `location-scale-sigma-contrast-figure-1.png`: the fitted residual-SD contrast
  is visible with horizontal 95% Wald intervals and no raw response points.
- `which-scale-residual-sigma-figure-1.png`: the fitted residual-SD surface and
  95% Wald band are visible on a `sigma` axis.
- `which-scale-population-sd-figure-1.png`: the point-only random-effect-SD
  display is intentionally interval-free and uses the population-level habitat
  mapping, not observation-row habitat.
- `animal-q2-correlation-eye-1.png`: the Confidence Eye uses a dotted zero
  line, coloured interval region, and readable title/subtitle.
- `relmat-q2-correlation-eye-1.png`: the Confidence Eye remains broad, as the
  fitted interval is broad, and the title/subtitle make the uncertainty source
  explicit.

## Remaining Work

The next slice can move beyond these three pages. Good candidates are
`spatial-models`, `phylogenetic-models`, and any remaining model-map or
workflow figures that still depend on tables where a small fitted display would
help users distinguish raw response, fitted distributional parameter,
simulation replicate, and fitted correlation layers.

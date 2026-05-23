# Rendered Figure QA: Slices 51-60

Date: 2026-05-23

## Scope

This note records the rendered-figure pass after PR #308 merged. The slice set
covered:

51. merge PR #308 and start a fresh branch from updated `origin/main`;
52. refresh the active article inventory for the next figure target;
53. choose `convergence` as the next page because it was table-only but asks
    readers to separate optimizer, Hessian, and uncertainty states;
54. add a rendered `check_drm()` status map from three tiny fitted examples;
55. add a rendered optimizer-budget versus fixed-gradient diagnostic panel;
56. render and inspect the changed `convergence` article images;
57. update the rendered article checklist so `convergence` records two active
    figures;
58. update the visualization grammar with the `check_drm()` diagnostic display
    rule;
59. validate the changed article, alt text, targeted diagnostic tests, diff
    hygiene, and pkgdown metadata;
60. record this audit, the after-task note, and issue/PR maintenance.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, Curie, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

Before editing, `convergence` had no referenced rendered article images. After
editing and rebuilding, the page contained two referenced article images:

- `convergence_files/figure-html/convergence-check-map-1.png`
- `convergence_files/figure-html/convergence-gradient-budget-1.png`

Both images have article alt text in the rendered HTML.

## Visual Decisions

The `check_drm()` status map is a diagnostic-status figure. It compares three
actual tiny fitted examples: a clean Gaussian fit, the same model run with
`drm_control(se = FALSE)`, and a deliberately under-budgeted random-effect fit.
The visual object is the diagnostic status returned by `check_drm()`: `ok`,
`note`, `warning`, or not applicable. It is not an interval display, not a
Confidence Eye, and not a probability.

The gradient/budget panel is also diagnostic. It plots recorded function
evaluation counts and maximum fixed-gradient size from the same tiny fits. The
dotted vertical line marks the `check_drm()` fixed-gradient warning threshold.
The first render used bars on a log scale, which distorted the visual
comparison; the accepted render uses lollipop points and threshold marks
instead.

## Visual Inspection

Florence inspected the regenerated PNGs after rebuilding:

- `convergence-check-map-1.png`: the map clearly separates clean optimization,
  skipped uncertainty, and low-budget warnings. It does not imply interval
  uncertainty.
- `convergence-gradient-budget-1.png`: the second render uses points and
  lollipop segments on the log scale, making the warning threshold and the
  under-budgeted gradient visible without bar distortion.

## Remaining Work

The convergence article still does not expose a full `plot_diagnostics()`
helper. That is deliberate: the visualization grammar keeps diagnostic plots as
article recipes until the `check_drm()` visual data contract is stable enough
to test as an exported plotting helper. The next rendered-figure pass can move
to `large-data` or family-specific articles.

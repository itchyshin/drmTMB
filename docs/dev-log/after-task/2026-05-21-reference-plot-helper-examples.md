# After Task: Reference Plot Helper Examples

## Goal

Continue the comprehensive reference audit by improving the rendered
`plot_parameter_surface()` and `plot_corpairs()` examples, which had become
public-facing substandard figures.

## Implemented

- Replaced the `plot_parameter_surface()` example's tiny fitted model with a
  controlled compatible prediction table.
- Kept interval provenance explicit with `conf.status = "wald"` and
  `interval_source = "wald"` in the surface fixture.
- Reworked the `plot_corpairs()` example to use short labels, four illustrative
  rows, point-only and profiled interval statuses, and a single panel.
- Added a minimal ggplot theme in both examples so the generated reference
  images are readable while keeping the helpers themselves small.
- Recorded rendered-image evidence under
  `docs/dev-log/figure-audits/2026-05-21-reference-plot-helpers/`.

## Mathematical Contract

No fitted-model calculation changed. The plot helpers still consume compatible
tables and draw only the estimates and intervals already present in those
tables. The examples now demonstrate that contract directly instead of relying
on a tiny model fit whose `sigma` surface was numerically unhelpful.

## Files Changed

- `R/plot-parameter-surface.R`
- `R/plot-corpairs.R`
- `man/plot_parameter_surface.Rd`
- `man/plot_corpairs.Rd`
- `docs/dev-log/audits/2026-05-21-function-reference-inventory.md`
- `docs/dev-log/figure-audits/2026-05-21-reference-plot-helpers/figure-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-reference-plot-helper-examples.md`

## Checks Run

```sh
air format R/plot-parameter-surface.R R/plot-corpairs.R docs/dev-log/audits/2026-05-21-function-reference-inventory.md docs/dev-log/figure-audits/2026-05-21-reference-plot-helpers/figure-audit.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-reference-plot-helper-examples.md
Rscript -e "devtools::document()"
Rscript -e "pkgdown::build_reference()"
find pkgdown-site/reference -maxdepth 1 \( -name 'plot_*.png' -o -name '*corpairs*.png' -o -name '*surface*.png' \) -print -exec file {} \;
rg -n 'theme_minimal|sigma block|phylo mu1-mu2|conf.status = "wald"|plot_parameter_surface\(pred|plot_corpairs\(pairs' R/plot-parameter-surface.R R/plot-corpairs.R man/plot_parameter_surface.Rd man/plot_corpairs.Rd pkgdown-site/reference/plot_parameter_surface.html pkgdown-site/reference/plot_corpairs.html -S
Rscript -e "devtools::test(filter = 'plot-parameter-surface|plot-corpairs|predict-parameters|corpairs', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "plot helper reference figure OR visualization layer OR corpairs predict_parameters" --limit 20
```

## Tests Of The Tests

The rendered-reference images were visually inspected after rebuilding
pkgdown's reference pages. Focused plot, prediction, and correlation-pair tests
cover the helper mechanics and provenance filtering; the rendered PNG check
covers the public figure quality.

## Consistency Audit

The reference examples now match the helper contract: input tables carry
estimate, interval, and provenance columns; helpers draw what those tables
already contain; and rows without supported intervals remain visible rather
than being silently dropped.

## GitHub Issue Maintenance

Issue search found #58, the broad visualization-layer issue. This slice
contributes reference-page figure cleanup but does not close #58.

## What Did Not Go Smoothly

The original `plot_parameter_surface()` reference example was technically
valid but visually misleading: a tiny `sigma ~ x` fit created an enormous
scale-panel range. The fix was to use a controlled helper input rather than
asking a fragile toy model to be a teaching fixture.

## Known Limitations

This pass improves only the reference examples. It does not add new plotting
arguments, themes, or article-level figure designs.

## Next Actions

1. Continue the function/reference audit with `corpairs()` and
   `predict_parameters()` prose and examples.
2. Keep the broader exported plotting API review under #58.

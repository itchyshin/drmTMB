# After Task: Slice 89 Worked-Example Inventory

## Goal

Audit the current tutorial layer after the Phase 10-13 foundation PR landed, and
name the next worked-example slices without adding new model behaviour.

## Implemented

- Added `docs/design/37-worked-example-inventory.md`.
- Classified current pages as worked tutorials, guides, secondary tutorials, or
  split-pressure pages.
- Prioritized Slice 90 for the flagship Gaussian location-scale tutorial and
  Slice 91 for the structured-dependence reader route.
- Updated `docs/design/21-tutorial-style.md` so future tutorial edits use the
  Slice 89 inventory before adding examples.
- Added Phase 6e to `ROADMAP.md` with Slices 89-92.

## Mathematical Contract

No formula grammar, likelihood parameterization, TMB code, or extractor behavior
changed. The only contract recorded here is a tutorial contract:

```text
worked tutorial = question + data + equation + syntax + output
                + plot/table + interpretation + diagnostics + boundary
guide           = status map, scale vocabulary, post-fit workflow,
                  family choice, large-data advice, or developer guidance
```

## Files Changed

- `ROADMAP.md`
- `docs/design/21-tutorial-style.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/after-task/2026-05-16-slice-89-worked-example-inventory.md`
- `docs/dev-log/check-log.md`

## Checks Run

- source inventory scans over current vignettes for headings, output calls,
  diagnostics, plots/tables, profile targets, `rho12()`, `sigma()`, and
  `corpairs()`;
- `_pkgdown.yml` inspection for current guide/tutorial placement;
- `pkgdown::build_site()`;
- `pkgdown::check_pkgdown()`;
- `git diff --check`.

## Tests Of The Tests

No testthat tests were added because Slice 89 is documentation planning only.
The useful validation is source inspection against the tutorial contract,
rendered-site validation, and a whitespace check.

## Consistency Audit

- Ada: Slice 89 starts a new Phase 6e tutorial-maturation lane after PR #46
  merged into `main`; it does not alter Phase 10-13 model scope.
- Jason: each tutorial page now has an inventory status and a named next action.
- Darwin: the next biological teaching win is the Gaussian location-scale
  flagship, because it explains why variance is a modelled signal.
- Pat: `phylogenetic-spatial.Rmd` has high value but high cognitive load; it
  needs a route before it gets more examples.
- Noether: the inventory keeps residual `rho12`, group-level `corpairs()`,
  phylogenetic covariance, and coordinate spatial fields in separate layers.
- Rose: future tutorial work should fill one named gap at a time and should not
  turn guide pages into overloaded worked tutorials.

## What Did Not Go Smoothly

The tutorial layer is already much richer than the initial Phase 6b source map,
so a simple "missing yes/no" table would have underreported progress. The
inventory uses conservative status labels instead: `ready enough`, `needs
focused polish`, `guide, not tutorial`, and `split pressure`.

## Known Limitations

Slice 89 did not edit the tutorials themselves or run tutorial examples beyond
the pkgdown render. Slices 90 and 91 should make the next reader-facing edits
and repeat the rendered-site gate.

## Next Actions

1. Slice 90: deepen `vignettes/location-scale.Rmd` as the flagship worked
   tutorial.
2. Slice 91: add a reader route and self-contained coordinate-spatial path to
   `vignettes/phylogenetic-spatial.Rmd`.
3. Slice 92: run the tutorial maturation gate after Slices 90-91.

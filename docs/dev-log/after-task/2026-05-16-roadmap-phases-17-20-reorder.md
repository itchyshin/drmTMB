# After Task: Roadmap Phases 17-20 Reorder

## Goal

Reorder the late roadmap so visualization comes before the simulation evidence
programme, then add two new phases: comprehensive simulation/power/coverage
evidence and one-off comparator demonstrations. Move CRAN and paper preparation
after those evidence layers.

## Implemented

Updated `ROADMAP.md` so:

- Phase 17 is now Visualization, Marginal Effects, and Reader-Facing Inference;
- Phase 18 is now Comprehensive Simulation, Power, Accuracy, and Coverage
  Evidence;
- Phase 19 is now Comparator Demonstrations With Other Packages;
- Phase 20 is now CRAN Release and Paper Preparation.

The ordering preserves the user's intended logic: visualization helpers should
arrive before comprehensive simulations because simulation studies need
plot-ready summaries for bias, root-mean-square error, empirical coverage,
convergence, interval width, and power curves.

## Files Changed

- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-roadmap-phases-17-20-reorder.md`

## Checks Run

- `PATH=/opt/homebrew/bin:$PATH air format ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-roadmap-phases-17-20-reorder.md`:
  passed.
- `git diff --check`: passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `git diff --unified=0 -- ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-roadmap-phases-17-20-reorder.md | LC_ALL=C rg -n '^\+.*[^\x00-\x7F]' || true`:
  returned no added non-ASCII.

## Tests Of The Tests

No package tests were added because this task changed roadmap prose only.

## Consistency Audit

- `rg -n "Phase 17|Phase 18|Phase 19|Phase 20|visualization and marginal|Release Hardening|Teaching, and Papers|CRAN Release|Comparator Demonstrations|Comprehensive Simulation" ROADMAP.md README.md NEWS.md docs/design docs/dev-log/known-limitations.md docs/dev-log/after-task/2026-05-16-roadmap-phases-17-20-reorder.md`:
  confirmed the new Phase 17-20 headings and top roadmap summary.
- `rg -n "Phase 18.*visualization|visualization.*Phase 18|Phase 17.*CRAN|CRAN.*Phase 17|Phase 19.*repeated simulation|one-off.*Phase 18" ROADMAP.md README.md NEWS.md docs/design docs/dev-log/known-limitations.md --glob '!docs/dev-log/check-log.md'`:
  returned only the intentional Phase 17 sentence that says visualization
  helpers should be designed with Phase 18 simulations in mind.
- `rg -n "Phase 18 records the visualization|Phase 18: Visualization|Phase 17: Release Hardening|Release Hardening, Teaching, and Papers" ROADMAP.md README.md NEWS.md docs/design docs/dev-log/known-limitations.md docs/dev-log/after-task/2026-05-16-roadmap-phases-17-20-reorder.md || true`:
  returned no stale old phase labels.

## What Did Not Go Smoothly

The main wording risk was conflating Phase 18 and Phase 19. The roadmap now
states that Phase 18 is the repeated operating-characteristics layer, while
Phase 19 is the one-off model-overlap and communication layer.

## Team Learning

Ada accepted the user's proposed order with one augmentation: Phase 17 should
build plot-ready data contracts, not only polished figures. Curie and Fisher
made simulation/power/coverage the evidence layer for package accuracy. Jason
kept package comparisons separate from simulation claims. Grace moved CRAN and
paper preparation to the final phase, after simulation and comparator evidence
exist. Rose required the top roadmap release-boundary paragraph to change with
the phase headings.

## Known Limitations

No visualization helpers, simulation helpers, comparator articles, or release
artifacts were implemented in this task. This is a roadmap-ordering change.

## Next Actions

When Phase 17 starts, design visualization data helpers with Phase 18 simulation
summaries in mind. When Phase 18 starts, define the first power/coverage
scenario before writing generalized simulation infrastructure.

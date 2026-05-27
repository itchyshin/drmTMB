# Phase 18 Parallel Lane Protocol, Slices 1399-1408

This note records how `drmTMB` can run two distribution or random-effect
artifact lanes at the same time without weakening the evidence standard. The
reader is an agent or contributor who wants more throughput than one branch at
a time, but still wants each fitted claim to remain auditable.

## Purpose

Phase 18 distribution work is slow because each admitted surface needs a
likelihood claim, formula boundary, DGP, fit summariser, smoke runner, grid
writer, manifest, failure ledger, interval rows, tests, documentation, and
check-log evidence. That discipline is deliberate. The safe speed-up is to
parallelize independent lane construction, not to merge broad claims faster
than the validation can support.

## Parallelizable Work

Two teams can work in parallel when their lanes have separate source files,
separate tests, and no shared likelihood or formula-grammar design question.
Good candidates are:

- fixed-effect artifact lanes for already fitted families;
- ordinary `mu` random-intercept artifact lanes after the lane template is
  stable;
- lane-local DGP, summariser, smoke-runner, grid-writer, and malformed-neighbour
  tests;
- lane-local design notes and after-task reports.

Parallel teams should not independently change the same global status files.
`NEWS.md`, `README.md`, `ROADMAP.md`, `docs/dev-log/check-log.md`, and broad
Phase 18 overview tables are integration artifacts. Ada, Grace, and Rose should
merge those updates one lane at a time.

## Non-Parallel Work

The following work should stay serial unless a separate design decision splits
it first:

- formula grammar changes;
- likelihood parameterization changes;
- shared profiling, bootstrap, or simulation-runner helpers;
- exported user-facing APIs;
- broad README, ROADMAP, pkgdown, or release-status rewrites;
- any task that changes what a neighbouring surface is claimed to support.

These tasks affect the package contract. Parallel branches can still do source
inspection or write design drafts, but one integrator should land the contract
change.

## Branch Contract

Each parallel lane starts from the same current `origin/main` and uses its own
branch. A lane branch should be able to answer five questions before review:

1. Which fitted route is admitted?
2. Which neighbouring routes remain planned or unsupported?
3. Which files are lane-local and which files are shared integration files?
4. Which tests prove the lane works and which tests prove malformed neighbours
   still fail?
5. Which artifacts would a future first-wave or Actions runner consume?

If a lane needs a shared helper change, stop the parallel work and land the
helper first. Otherwise the two lanes will invent slightly different contracts
and the integration step will become the real implementation.

## Validation Contract

Each lane must pass the same minimum local gate before it is offered for
integration:

- parse the new lane files;
- run the focused lane test;
- run the neighbouring malformed-input or unsupported-boundary tests;
- run the first-wave summary or Actions dry-run test when the lane is admitted
  to those runners;
- run `pkgdown::check_pkgdown()` when reference or navigation files changed;
- run stale-positive and stale-negative wording scans for the fitted claim and
  its boundaries.

The integrator then merges lane PRs serially. After the first lane merges, the
second lane is refreshed from `origin/main`, conflicts are resolved, focused
tests rerun, and CI is allowed to pass before merge.

## Role Split

Parallel teams are bounded workers, not independent claim owners:

- Curie builds the lane-local DGP, summariser, smoke runner, grid writer, and
  tests.
- Boole checks that the public formula remains memorable and already supported.
- Gauss and Noether check that the DGP, likelihood, and parameter labels match.
- Fisher keeps the evidence tier honest: smoke, artifact, pilot, or formal
  coverage.
- Pat checks that an applied user would not infer support for neighbouring
  slopes, scale random effects, structured effects, or mixed-response models.
- Grace runs the reproducibility and CI gates.
- Rose scans for stale wording and accumulated process drift.
- Ada integrates one lane at a time and owns the global status edits.

Florence joins when the lane changes a rendered figure, report, gallery, or
visual diagnostic.

## Merge Policy

Parallel distribution work is complete only after serial integration:

1. Merge or park any existing green PRs before starting new branches.
2. Land shared helper changes first.
3. Open one PR per distribution lane.
4. Keep lane-local documentation on the lane branch.
5. Merge the first lane after focused tests, pkgdown checks where relevant, and
   GitHub Actions pass.
6. Refresh the second lane from updated `main`.
7. Resolve global-status conflicts in one place.
8. Rerun focused tests and let GitHub Actions pass before the second merge.

This preserves the current accuracy standard while allowing two independent
distribution lanes to move at the same time.


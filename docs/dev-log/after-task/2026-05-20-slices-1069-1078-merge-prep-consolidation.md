# Slices 1069-1078: Merge-Prep Consolidation

## Goal

Convert the broad local slice work into a reviewable merge payload without
adding more fitted-model surface area.

## Team Roles

- Ada classified the dirty tree, made the consolidation decisions, and staged
  the merge payload.
- Grace owned validation: focused tests, full tests, pkgdown, and package check.
- Rose watched for local-only evidence, stale generated files, and merge risk.
- Curie checked the Phase 18 runner and warning-ledger behavior.
- Florence kept the rendered figure-audit evidence visible but small.
- Pat checked that docs and reports preserve reader-facing status boundaries.

No spawned subagents were used in this consolidation slice.

## Consolidation Decisions

- Keep package code, tests, vignettes, design docs, after-task reports, Ayumi
  markdown summaries, local stress-test scripts, and small figure-audit images
  in the merge payload.
- Keep bulky generated Ayumi CSV/RDS stress outputs local-only.
- Keep recovery checkpoints local-only; they are handoff aids, not review
  payload.
- Add `inst/sim/results/` to `.Rbuildignore` so local simulation artifacts do
  not enter source builds.

## Cleanup

`phase18_result_failures()` now collapses duplicate warning messages within a
replicate before writing warning/error ledger rows. This keeps repeated profile
warnings such as `collapsing to unique 'x' values` from being counted twice in
first-wave report ledgers while preserving the raw manifest warning count.

## Validation

Focused Phase 18 validation:

```sh
Rscript -e "devtools::test(filter = '^phase18-(sim-runner|nbinom2-mu-random-effect|first-wave-summary-report|first-wave-summary-smoke-runner)$')"
```

- 162 expectations, 0 failures, 0 warnings, 0 skips.

Full package tests:

```sh
Rscript -e "devtools::test()"
```

- 5480 expectations, 0 failures, 0 warnings, 0 skips.

Pkgdown:

```sh
Rscript -e "pkgdown::check_pkgdown()"
```

- No problems found.

Package check:

```sh
Rscript -e "devtools::check(document = FALSE, error_on = 'warning')"
```

- 0 errors, 0 warnings, 1 NOTE.
- The NOTE was `unable to verify current time`, an environment timestamp check.

Whitespace:

```sh
git diff --check
```

- Clean.

## Remaining Risk

This branch is broad. It is ready for a review/merge candidate commit, but a
human review should still skim the combined `NEWS.md`, `ROADMAP.md`, and Phase
18 documentation because those files now summarize many sequential slices.

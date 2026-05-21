# After Task: Animal/Relmat Q2 Phase 18 Smoke Runner

## Task Goal

Add the first executable Phase 18 smoke path for known-matrix `animal()` and
`relmat()` matching q=2 bivariate Gaussian location covariance. This turns the
ADEMP sheet into a small runnable DGP/fit/summarise/resume contract while
keeping broad grids, grid writers, pedigree construction, structured slopes,
`sigma` structured effects, q=4 blocks, and non-Gaussian structured effects
out of scope.

## Files Created Or Changed

- `inst/sim/dgp/sim_dgp_animal_relmat_q2.R`
- `inst/sim/fit/sim_summarise_animal_relmat_q2.R`
- `inst/sim/run/sim_run_animal_relmat_q2_smoke.R`
- `tests/testthat/test-phase18-animal-relmat-q2-smoke.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-20-animal-relmat-q2-smoke-runner.md`

## Checks Run

Checks run:

```sh
air format inst/sim/dgp/sim_dgp_animal_relmat_q2.R inst/sim/fit/sim_summarise_animal_relmat_q2.R inst/sim/run/sim_run_animal_relmat_q2_smoke.R tests/testthat/test-phase18-animal-relmat-q2-smoke.R
Rscript -e "devtools::test(filter = 'phase18-animal-relmat-q2-smoke', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'phase18.*animal|animal-relmat-gaussian', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check()"
git diff --check
```

Outcomes:

- `air format` completed without changes after the final edits.
- The focused `phase18-animal-relmat-q2-smoke` test passed.
- The combined `phase18.*animal|animal-relmat-gaussian` related tests passed.
- `pkgdown::check_pkgdown()` reported no problems.
- `devtools::check()` passed in 4m15s with 0 errors, 0 warnings, and 0 notes.
- `git diff --check` was clean.

## Consistency Audit

The runner uses `structured_surface` for the condition-level animal versus
`relmat()` choice because the Phase 18 registry already owns a `surface`
column. The summary rows separate fixed `mu1`/`mu2` coefficients, public
residual scales, structured SDs, structured correlation, and residual `rho12`.
The readiness matrix now says this lane has smoke-runner evidence, not broad
grid evidence.

## Tests Of The Tests

The focused test checks deterministic DGP output, stored `K`/`Q` truth,
residual-covariance arithmetic, two-cell animal/`relmat()` smoke fitting,
result-directory resume behaviour, parameter row names, finite estimates, and
input validation. The first version of the smoke test failed because a
condition column named `surface` collided with the registry's `surface` column;
renaming that field to `structured_surface` made the test exercise the
intended code path.

## What Did Not Go Smoothly

The initial runner returned two replicate errors because `phase18_cell_registry()`
prepends its own `surface` column and the DGP saw `animal_relmat_q2` instead of
`animal` or `relmat`. The failure was useful: it caught a manifest-shaping
problem before any artifact writer existed.

## Team Learning And Process Improvements

Emmy and Rose should keep checking Phase 18 condition-column names against the
registry schema before new surfaces are added. Curie and Fisher should continue
to test result resumption and parameter-row naming in the same smoke test,
because those are what later grid writers and Florence-facing reports will
consume.

## Design-Doc Updates

The Phase 18 programme, readiness matrix, and animal/`relmat()` ADEMP sheet now
state that a first q=2 DGP, summariser, and smoke runner exist. They still mark
broad grids as pending a grid writer and formal-condition runner.

## Pkgdown And Documentation Updates

`inst/sim/README.md` now lists the animal/`relmat()` q=2 ADEMP sheet, DGP,
summariser, and smoke runner. No user-facing pkgdown article was added in this
slice.

## GitHub Issue Maintenance

This slice remains part of issue #147. A PR should reference the issue after
the branch is pushed.

## Known Limitations And Next Actions

The next implementation step is a small grid writer or formal-condition runner
that writes aggregate, replicate, manifest, failure, and interval-status CSVs.
The current smoke runner does not add profile or bootstrap intervals and does
not admit pedigree-to-`Ainv`, structured slopes, `sigma` structured effects,
q=4 location-scale blocks, predictor-dependent `corpair()` regressions,
direct-SD grammar, or non-Gaussian structured effects.

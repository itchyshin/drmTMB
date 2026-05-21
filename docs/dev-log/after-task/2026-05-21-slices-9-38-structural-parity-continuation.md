# After-Task Report: Structural Parity Slices 9-38

Date: 2026-05-21

## Task

Continue the post-0.1.3 structural-dependence parity lane through slice 38
without turning planned spatial, slope, direct-SD, combined-layer, or
non-Gaussian routes into fitted claims.

## What Changed

The fitted implementation work was deliberately narrow. Slices 10-14 add the
Phase 18 animal/`relmat()` q=4 smoke scaffold:

- `phase18_dgp_animal_relmat_q4()` generates known-matrix all-four
  `mu1`/`mu2`/`sigma1`/`sigma2` Gaussian data with four endpoint SDs, six
  endpoint correlations, and residual `rho12` stored as separate truth layers.
- `phase18_run_animal_relmat_q4_smoke()` fits matching all-four `animal()` or
  `relmat()` formulas with point-estimate smoke settings.
- `phase18_summarise_animal_relmat_q4_smoke()` and
  `phase18_write_animal_relmat_q4_grid_outputs()` write the same aggregate,
  replicate, manifest, failure, profile-status, interval-evidence,
  diagnostic, and interval-failure artifact shape as the q=2 lane.
- Requested q=4 structured-correlation profile rows are marked
  `derived_interval_unavailable`, because those correlations are derived from
  the unstructured q=4 parameterization rather than direct profile targets.

Slices 15-38 are status-guard and reader-map slices. They add
`docs/design/59-structural-slope-and-non-gaussian-map.md`, update the
readiness matrix, and extend the slice ledger so applied users can see that
spatial q4, structured slopes for phylo/animal/`relmat()`, direct-SD grammar,
combined structured layers, and non-Gaussian structured dependence remain
planned or blocked.

## Why This Is Useful For Users

Applied users now get a more honest answer to two practical questions:

- animal/`relmat()` q=4 location-scale models have focused point-estimate
  smoke artifacts, but q=4 latent correlations still do not have supported
  direct intervals;
- random-slope parity is incomplete: ordinary Gaussian, Gaussian `sigma`,
  coordinate-spatial Gaussian `mu`, Poisson `mu`, and NB2 `mu` have fitted
  slope routes, while phylogenetic, animal, `relmat()`, and bivariate slope
  routes remain planned.

The non-Gaussian structural-dependence answer is also explicit: ordinary
Poisson and NB2 `mu` random effects are fitted first slices, but `phylo()`,
`spatial()`, `animal()`, and `relmat()` are not fitted inside non-Gaussian
likelihoods yet.

## Checks

```sh
air format inst/sim/dgp/sim_dgp_animal_relmat_q4.R inst/sim/fit/sim_summarise_animal_relmat_q4.R inst/sim/run/sim_run_animal_relmat_q4_smoke.R inst/sim/run/sim_summary_animal_relmat_q4_smoke.R inst/sim/run/sim_write_animal_relmat_q4_grid.R tests/testthat/test-phase18-animal-relmat-q4-smoke.R tests/testthat/test-phase18-animal-relmat-q4-grid-writer.R
air format docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md docs/design/55-phase-18-animal-relmat-q2-interval-status.md docs/design/57-structural-parity-next-slices.md docs/design/58-phase-18-animal-relmat-q4-ademp.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md inst/sim/README.md
Rscript -e "devtools::test(filter = 'phase18-animal-relmat-q4', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian|phase18-animal-relmat-q4', reporter = 'summary')"
rg -n "spatial q4.*(implemented|fitted)|non-Gaussian structural.*(implemented|fitted)|phylo\\(1 \\+.*Implemented|animal\\(1 \\+.*Implemented|relmat\\(1 \\+.*Implemented|q4.*profile-ready|derived.*profile-ready" README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat --glob "!docs/dev-log/**"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

## Outcomes

- Focused q4 smoke/grid tests passed.
- Existing animal/relmat Gaussian tests plus the new q4 Phase 18 tests passed.
- `pkgdown::check_pkgdown()` reported no problems.
- The stale-claim scan found only planned or derived-not-profile-ready wording
  in the profile-likelihood design note.

## Standing Roles

- Ada kept the implementation scoped to q4 animal/`relmat()` artifacts and the
  rest as status guards.
- Pat checked that the status maps answer what an applied user can fit today.
- Fisher and Curie kept simulation evidence separate from broad
  operating-characteristic claims.
- Grace checked pkgdown and release hygiene.
- Rose kept fitted, planned, blocked, and derived-interval-unavailable rows
  separate.

No spawned subagents were used.

## Remaining Work

Broad q4 animal/`relmat()` operating-characteristic grids still need larger
replicate runs, figure review, and an interpretation plan for near-boundary
endpoint correlations. Phylogenetic, animal, and `relmat()` one-slope fitting
remain the main structured-slope parity gap after this slice.

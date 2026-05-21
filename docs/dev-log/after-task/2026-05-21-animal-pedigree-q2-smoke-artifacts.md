# After Task: Animal Pedigree Q2 Smoke Artifacts

## Goal

Give the Phase 18 q=2 animal smoke and artifact machinery one cell that fits
the public `animal(1 | p | id, pedigree = pedigree)` spelling, so dense
pedigree support is tested in the same evidence path as the known `A`/`Ainv`
animal route.

## Implemented

`phase18_animal_relmat_q2_conditions()` now accepts
`matrix_argument = "pedigree"` for `structured_surface = "animal"`. The
matching DGP helper builds a deterministic small pedigree, records it in the
truth object, builds the dense additive relationship matrix with
`drm_pedigree_additive_relationship()`, and uses that matrix for simulation.
The smoke runner fits the condition with matching labelled
`animal(1 | p | id, pedigree = pedigree)` terms in `mu1` and `mu2`.

`matrix_argument = "pedigree"` remains animal-only. `relmat()` still uses
known covariance or precision matrices through `K` or `Q`; impossible
`relmat()`/`pedigree` cells are filtered out by the condition grid or rejected
by the DGP helper.

## Mathematical Contract

For the pedigree smoke cell, the structured location effect has covariance

```text
Cov(u_a[g], u_b[h]) = S[a, b] * A_pedigree[g, h]
```

where `A_pedigree` is the dense additive relationship matrix built from the
recorded `id`, `dam`, and `sire` table. The response-level residual covariance
still uses `sigma1`, `sigma2`, and `rho12`; that residual coscale remains a
separate layer from the animal correlation reported by
`corpairs(level = "animal")`.

## Files Changed

- `inst/sim/dgp/sim_dgp_animal_relmat_q2.R`
- `inst/sim/run/sim_run_animal_relmat_q2_smoke.R`
- `tests/testthat/test-phase18-animal-relmat-q2-smoke.R`
- `tests/testthat/test-phase18-animal-relmat-q2-grid-writer.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md`
- `docs/design/55-phase-18-animal-relmat-q2-interval-status.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-animal-pedigree-q2-smoke-artifacts.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_animal_relmat_q2.R inst/sim/run/sim_run_animal_relmat_q2_smoke.R tests/testthat/test-phase18-animal-relmat-q2-smoke.R tests/testthat/test-phase18-animal-relmat-q2-grid-writer.R
Rscript -e "devtools::test(filter = 'phase18-animal-relmat-q2-smoke|phase18-animal-relmat-q2-grid-writer')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Outcomes:

- The focused test run passed 80 expectations after this report and the design
  ledger were updated.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

The new DGP test compares the recorded pedigree-derived matrix to an
independent call to `drm_pedigree_additive_relationship(pedigree)` and checks
that `Q` is the inverse of that matrix. The smoke-runner test fits one q=2
pedigree cell and checks that the expected fixed-effect, residual, animal SD,
animal correlation, and `rho12` rows are present. The validation test rejects a
`relmat()`/`pedigree` DGP request, and the grid-writer test proves the mixed
animal/relmat condition grid drops the impossible cell while retaining the
animal pedigree cell.

## Consistency Audit

Ada, Boole, Noether, and Rose synchronized the Phase 18 ADEMP sheet,
interval-status contract, simulation programme, and readiness matrix. Rose ran
stale-wording scans for matrix-only q=2 wording, planned-pedigree language, and
accidental `relmat(pedigree = ...)` support claims. The hits were the intended
`relmat()`/`pedigree` rejection text, the failure-ledger sparse
pedigree-to-`Ainv` note, current animal-only pedigree claims, and older
historical check-log entries. The current claim is narrow: dense
animal-pedigree q=2 smoke artifacts exist, but formal structured
SD/correlation and residual `rho12` coverage still require explicit profile
requests.

## GitHub Issue Maintenance

No new issue comment was attempted in this slice. Issue #147 remains the
standing animal/`relmat()` ledger from the previous pedigree-first route, and
the local check-log entry records this smaller simulation-artifact extension.

## What Did Not Go Smoothly

The first documentation patch targeted text that had shifted during the
previous 0.1.3 release and pedigree-first merge. Ada re-read the exact design
sections before applying the smaller patch. The focused tests were rerun after
the documentation ledger was finished.

## Team Learning

Pat's user check caught the practical gap: applied users care whether the
public pedigree syntax appears in the same evidence path as matrix inputs, not
only whether `A` and `Ainv` work. Fisher and Curie kept the slice evidence-based
by requiring a smoke fit and matrix-equivalence check. Rose kept the report from
turning a smoke cell into a formal coverage claim.

## Known Limitations

This slice does not add sparse large-pedigree inverse construction, ASReml-like
scalability, animal structured slopes, animal `sigma` terms, q=4
location-scale blocks, predictor-dependent animal `corpair()` regressions,
generic direct-SD grammar, or a formal 500-replicate coverage result. It adds a
small dense-pedigree q=2 smoke/artifact cell.

## Next Actions

- Open a small PR against `main` if the branch stays clean.
- Keep the next animal/relmat step separate: sparse large-pedigree construction
  needs its own design gate and tests before any scalability claim.

# After Task: Slice 293 Gaussian Location-Scale ADEMP Sheet

## Goal

Create the first one-page ADEMP design sheet for an admitted Phase 18 lane
before writing new DGP or grid code.

## Implemented

`docs/design/47-phase-18-gaussian-location-scale-ademp.md` now records the
Gaussian location-scale simulation design in ADEMP order: aims,
data-generating mechanism, estimands, methods, performance measures, and a
Williams-style self-audit. The sheet ties directly to the existing
`phase18_dgp_gaussian_ls()` and `phase18_gaussian_ls_conditions()` helpers and
keeps the first formal grid to the current eight-cell condition set before any
larger grid is considered.

The Phase 18 blueprint and simulation README now link to the sheet. NEWS and
ROADMAP record Slice 293 as the first post-blueprint ADEMP sheet.

## Mathematical Contract

No likelihood, formula grammar, simulation code, fitted model, extractor,
interval method, or test fixture changed. This slice documents the design
contract for the existing Gaussian location-scale simulation helpers.

## Files Changed

- `docs/design/47-phase-18-gaussian-location-scale-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-224009-codex-checkpoint.md`

## Checks Run

```sh
air format docs/design/47-phase-18-gaussian-location-scale-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n "Gaussian Location-Scale ADEMP|phase18_dgp_gaussian_ls|phase18_gaussian_ls_conditions|coef\\(fit, dpar = \\\"mu\\\"\\)|coef\\(fit, dpar = \\\"sigma\\\"\\)|sigma\\(fit, newdata|500 replicates|Williams|Morris|one-page ADEMP|Slice 293" docs/design/47-phase-18-gaussian-location-scale-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n "external comparator|animal\\(\\)|relmat\\(\\)|shape/skewness|random-effect|phylogenetic|spatial|comprehensive all-feature|DGP code" docs/design/47-phase-18-gaussian-location-scale-ademp.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 293 Gaussian location-scale ADEMP sheet" --next "stage, commit, push, and open draft PR"
```

All checks passed.

## Tests Of The Tests

No executable tests changed. The relevant checks are design-contract scans:
they confirm the sheet uses the existing Gaussian helper names and public
estimator routes, names the 500-replicate MCSE target, and keeps random-effect,
phylogenetic, spatial, shape/skewness, `animal()`, and `relmat()` surfaces out
of this one-response Gaussian location-scale design.

## Consistency Audit

The sheet follows the Slice 292 rule that admitted lanes get one-page ADEMP
sheets before new code. It keeps public `sigma` on the response scale while
tracking fitted `sigma` coefficients on the log scale, matching the existing
simulation summariser. It does not add an external comparator or collapse this
fixed-effect surface with neighbouring random-effect or structured-effect
surfaces.

## What Did Not Go Smoothly

The first estimator-output draft used a shorthand `coef(fit, "mu")` style. The
readback pass corrected it to the package's explicit `coef(fit, dpar = "mu")`
and `coef(fit, dpar = "sigma")` form.

## Team Learning

Ada kept the slice as an ADEMP sheet rather than code. Curie checked that the
condition levels match the existing helper defaults. Fisher checked that the
MCSE and coverage claims are labelled as design targets. Pat checked that a
future report writer can see the fitted model and estimands without opening the
helper code. Rose checked that neighbouring surfaces stay outside the sheet.
Grace confirmed formatting, pkgdown, and whitespace checks. No spawned
subagents were used.

## Known Limitations

No simulation run, DGP change, runner change, or result table was added. The
formal grid still needs an implementation slice that uses this sheet, records
replicate seeds, and writes aggregate, manifest, warning/error, and coverage
outputs.

## Next Actions

Use this sheet to drive the first formal Gaussian location-scale grid, or write
the next one-page ADEMP sheet for another admitted lane such as
`meta_V(V = V)` or paired Poisson/NB2 `mu` random effects.

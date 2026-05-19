# After Task: Slice 294 Meta-Analysis Known-V ADEMP Sheet

## Goal

Create a one-page ADEMP design sheet for the admitted Gaussian
`meta_V(V = V)` Phase 18 lane before expanding vector or dense known-`V` grids.

## Implemented

`docs/design/48-phase-18-meta-v-ademp.md` now records the Gaussian
meta-analysis known-`V` simulation design in ADEMP order: aims,
data-generating mechanism, estimands, methods, performance measures, and a
Williams-style self-audit. The sheet ties directly to the existing
`phase18_dgp_meta_v()` and `phase18_meta_v_conditions()` helpers.

The Phase 18 blueprint and simulation README now link to the sheet. NEWS and
ROADMAP record Slice 294 as the `meta_V(V = V)` ADEMP sheet.

## Mathematical Contract

No likelihood, formula grammar, simulation code, fitted model, extractor,
interval method, or test fixture changed. The sheet keeps known sampling
covariance `V` as input data and public residual `sigma` as the fitted
heterogeneity estimand.

## Files Changed

- `docs/design/48-phase-18-meta-v-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-224503-codex-checkpoint.md`

## Checks Run

```sh
air format docs/design/48-phase-18-meta-v-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n 'Meta-Analysis Known-V ADEMP|phase18_dgp_meta_v|phase18_meta_v_conditions|meta_V\(V = V\)|known sampling covariance|input data|public residual `sigma`|unique\(as.numeric\(sigma\(fit\)\)\)|500 replicates|Williams|Morris|Slice 294' docs/design/48-phase-18-meta-v-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n 'tau|proportional sampling-variance models|animal models|latent relatedness|known sampling covariance \| supplied `V`|no estimator|V.*input data|estimated interval target' docs/design/48-phase-18-meta-v-ademp.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 294 meta_V ADEMP sheet" --next "stage, commit, push, and open draft PR"
```

All checks passed.

## Tests Of The Tests

No executable tests changed. The design-contract scans check that the sheet uses
the existing `meta_V(V = V)` helper names, names public residual `sigma`, and
keeps known sampling covariance `V` out of estimator and interval-target
status. They also keep proportional sampling-variance, animal, and latent
relatedness comparators outside this first grid.

## Consistency Audit

The sheet follows the Slice 292 rule that admitted lanes get one-page ADEMP
sheets before new code. It preserves the project scale convention: meta-analysis
residual heterogeneity is public `sigma`, while `V` is supplied known sampling
covariance. It does not introduce `tau ~`, `meta_gaussian()`, proportional
sampling variance, or latent relatedness syntax.

## What Did Not Go Smoothly

The first evidence scan used shell backticks around `sigma`, so zsh tried to
execute that token before `rg` ran. I reran the scan with single quotes and
recorded the safe command.

## Team Learning

Ada kept the slice as a design sheet. Curie checked the condition levels against
the existing `phase18_meta_v_conditions()` helper. Fisher checked the MCSE and
coverage targets. Pat checked that report writers can see which quantities are
estimated and which are input data. Rose checked that `V`, `sigma`, animal
models, and proportional sampling variance stay separated. Grace confirmed
formatting, pkgdown, and whitespace checks. No spawned subagents were used.

## Known Limitations

No simulation run, DGP change, runner change, or result table was added. The
formal vector/dense known-`V` grid still needs a separate implementation slice
that uses this sheet.

## Next Actions

Continue the one-page ADEMP sequence with paired Poisson/NB2 `mu` random
effects, or use the Gaussian location-scale and `meta_V(V = V)` sheets to start
their formal grid implementation slices.

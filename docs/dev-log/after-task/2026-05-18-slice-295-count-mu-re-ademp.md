# After Task: Slice 295 Count Mu Random-Effect ADEMP Sheet

## Goal

Create a one-page ADEMP design sheet for the paired ordinary Poisson/NB2 `mu`
random-effect Phase 18 lane before expanding the count pilot grid.

## Implemented

`docs/design/49-phase-18-count-mu-random-effect-ademp.md` now records the
paired count simulation design in ADEMP order: aims, data-generating mechanism,
estimands, methods, performance measures, and a Williams-style self-audit. The
sheet ties directly to the existing `phase18_dgp_poisson_mu_re()`,
`phase18_dgp_nbinom2_mu_re()`, and `phase18_summarise_count_mu_re_pilot()`
helpers.

The Phase 18 blueprint and simulation README now link to the sheet. NEWS and
ROADMAP record Slice 295 as the paired count `mu` random-effect ADEMP sheet.

## Mathematical Contract

No likelihood, formula grammar, simulation code, fitted model, extractor,
interval method, or test fixture changed. The sheet keeps the first count grid
to ordinary non-zero-inflated Poisson/NB2 `mu` random intercepts and independent
numeric slopes. Zero-inflated, hurdle, zero-truncated, structured,
correlated-slope, and labelled covariance count models remain failure-ledger
rows.

## Files Changed

- `docs/design/49-phase-18-count-mu-random-effect-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-225015-codex-checkpoint.md`

## Checks Run

```sh
air format docs/design/49-phase-18-count-mu-random-effect-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n 'Count Mu Random-Effect ADEMP|phase18_dgp_poisson_mu_re|phase18_dgp_nbinom2_mu_re|phase18_summarise_count_mu_re_pilot|profile level|0\.70|Poisson|NB2|sd:mu|zero-inflated|hurdle|zero-truncated|Slice 295' docs/design/49-phase-18-count-mu-random-effect-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n 'mixed-response|structured|correlated-slope|labelled covariance|failure ledger|profile-failed|0\.95 profile grid|DGP code|comprehensive all-feature' docs/design/49-phase-18-count-mu-random-effect-ademp.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 295 count mu random-effect ADEMP sheet" --next "stage, commit, push, and open draft PR"
```

All checks passed.

## Tests Of The Tests

No executable tests changed. The design-contract scans check that the sheet uses
the existing Poisson, NB2, and paired-pilot helper names, names direct `sd:mu`
profile targets, records the current 0.70 profile-level caveat, and keeps
zero-inflated, hurdle, zero-truncated, structured, correlated-slope, and
labelled covariance count paths out of this grid.

## Consistency Audit

The sheet follows the Slice 292 rule that admitted lanes get one-page ADEMP
sheets before new code. It keeps Poisson and NB2 on ordinary non-zero-inflated
`mu` random-effect routes, keeps NB2 `sigma` fixed-effect only, and separates
fixed-effect Wald coverage from direct random-effect SD profile coverage.

## What Did Not Go Smoothly

The profile-coverage wording needed care because the current summariser default
is `profile_level = 0.70`, not a 95% interval. The sheet now states that any
0.95 profile grid needs a separate runtime-budget decision.

## Team Learning

Ada kept the slice as a design sheet. Curie checked the condition levels and
paired-pilot outputs against the existing helpers. Fisher checked the Wald
versus profile coverage distinction. Pat checked that a report writer can see
which count paths are fitted and which remain failure-ledger rows. Rose checked
the blocked count-neighbour list. Grace confirmed formatting, pkgdown, and
whitespace checks. No spawned subagents were used.

## Known Limitations

No simulation run, DGP change, runner change, or result table was added. The
formal paired count grid still needs a separate implementation slice that uses
this sheet and chooses a runtime budget for profile intervals.

## Next Actions

Continue the ADEMP sequence with fixed-effect beta/beta-binomial or
fixed-effect ordinal, or use the Gaussian location-scale, `meta_V(V = V)`, and
count sheets to start formal grid implementation slices.

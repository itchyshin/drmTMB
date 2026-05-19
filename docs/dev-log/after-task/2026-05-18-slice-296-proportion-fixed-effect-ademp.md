# After Task: Slice 296 Proportion Fixed-Effect ADEMP Sheet

## Goal

Create a one-page ADEMP design sheet for the admitted fixed-effect
`beta()`/`beta_binomial()` Phase 18 lane before adding bounded-response DGP
helpers or broad grids.

## Implemented

`docs/design/50-phase-18-proportion-fixed-effect-ademp.md` now records the
fixed-effect proportion simulation design in ADEMP order: aims,
data-generating mechanism, estimands, methods, performance measures, and a
Williams-style self-audit. The sheet separates strict continuous proportions
from successes out of known trial totals, names denominator generation, and
keeps public `sigma` distinct from internal precision `phi = 1 / sigma^2`.

The Phase 18 blueprint and simulation README now link to the sheet. NEWS and
ROADMAP record Slice 296 as the fixed-effect proportion ADEMP sheet.

## Mathematical Contract

No likelihood, formula grammar, simulation code, fitted model, extractor,
interval method, or test fixture changed. The sheet admits only fixed-effect
`beta()` and `beta_binomial()` models with `mu ~ x` and `sigma ~ z`. Exact 0/1
continuous boundary mass, `zoi`/`coi`, random effects, structured effects,
known sampling covariance, and mixed-response bounded models remain
failure-ledger rows.

## Files Changed

- `docs/design/50-phase-18-proportion-fixed-effect-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-230024-codex-checkpoint.md`

## Checks Run

```sh
air format docs/design/50-phase-18-proportion-fixed-effect-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
sed -n '1,260p' docs/design/50-phase-18-proportion-fixed-effect-ademp.md
rg -n 'Proportion Fixed-Effect ADEMP|beta\(\)|beta_binomial\(\)|denominator|strict continuous|exact 0/1|zoi|coi|meta_V\(V = V\)|500 replicates|Williams|Morris|Slice 296' docs/design/50-phase-18-proportion-fixed-effect-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n 'random effects|structured effects|known sampling covariance|mixed-response|failure ledger|phi|public `sigma`|precision|0/1 continuous|DGP helpers' docs/design/50-phase-18-proportion-fixed-effect-ademp.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript tools/codex-checkpoint.R --goal "Slice 296 proportion fixed-effect ADEMP sheet" --next "stage, commit, push, and open draft PR"
```

All checks passed.

## Tests Of The Tests

No executable tests changed. The design-contract scans check that the sheet
names the fixed-effect beta and beta-binomial routes, denominator generation,
exact-boundary handling, public `sigma`, internal `phi`, and the blocked
bounded-response neighbours.

## Consistency Audit

The sheet follows the Slice 292 rule that admitted lanes get one-page ADEMP
sheets before new code. It agrees with the family registry and proportion
tutorial: `beta()` is for continuous proportions strictly inside `(0, 1)`,
`beta_binomial()` is for successes out of known trials, and zero-one inflation
or random effects are not fitted for bounded responses.

## What Did Not Go Smoothly

The broad status scan necessarily found older roadmap rows that describe beta
and beta-binomial `mu` random effects as later candidates. Those rows are still
true for random effects; the new sheet admits only fixed-effect proportion
models.

## Team Learning

Ada kept the slice in the design lane. Pat checked that a reader sees the
measurement-process split before model syntax. Fisher checked the Wald coverage
and MCSE language. Curie checked that new DGP helpers remain future work rather
than implied implementation. Rose checked the blocked bounded-response
neighbour list. Grace confirmed formatting, pkgdown, and whitespace checks. No
spawned subagents were used.

## Known Limitations

No simulation DGP helper, runner, result table, formal grid, or executable test
was added. The next implementation slice should add explicit beta and
beta-binomial DGP helpers under `inst/sim/` before any broad proportion report
claims operating characteristics.

## Next Actions

Continue the ADEMP sequence with fixed-effect ordinal, bivariate Gaussian
`rho12`, Student-t `nu`, or structured-effect admitted subsets, or implement
the proportion DGP helpers described in this sheet.

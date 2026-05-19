# After Task: Slice 298 Bivariate Residual Rho12 ADEMP Sheet

## Goal

Create a one-page ADEMP design sheet for the admitted bivariate Gaussian
residual `rho12` Phase 18 lane before adding a bivariate residual-correlation
DGP helper or broad grid.

## Implemented

`docs/design/52-phase-18-bivariate-rho12-ademp.md` now records the bivariate
Gaussian residual-correlation simulation design in ADEMP order: aims,
data-generating mechanism, estimands, methods, performance measures, and a
Williams-style self-audit. The sheet defines response-specific mean and scale
predictors, the residual covariance matrix, guarded response-scale `rho12`,
row-specific residual-correlation grids, and boundary diagnostics.

The Phase 18 blueprint and simulation README now link to the sheet. NEWS and
ROADMAP record Slice 298 as the bivariate residual `rho12` ADEMP sheet.

## Mathematical Contract

No likelihood, formula grammar, simulation code, fitted model, extractor,
interval method, or test fixture changed. The sheet admits only bivariate
Gaussian residual-correlation grids. Group-level `corpairs()`, phylogenetic or
spatial correlations, known sampling covariance `V`, random effects in
`rho12`, mixed-response families, and bivariate random slopes remain separate
design or failure-ledger rows.

## Files Changed

- `docs/design/52-phase-18-bivariate-rho12-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-230811-codex-checkpoint.md`

## Checks Run

```sh
air format docs/design/52-phase-18-bivariate-rho12-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
sed -n '1,300p' docs/design/52-phase-18-bivariate-rho12-ademp.md
rg -n 'Bivariate Residual Rho12 ADEMP|biv_gaussian\(\)|rho12|residual covariance|0\.99999999|sigma1|sigma2|corpairs\(\)|known sampling covariance|random effects in `rho12`|500 replicates|Williams|Morris|Slice 298' docs/design/52-phase-18-bivariate-rho12-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n 'group-level|structured correlations|known sampling covariance|random effects in `rho12`|mixed-response|bivariate random slopes|failure ledger|profile coverage|rho12_boundary|new DGP helper' docs/design/52-phase-18-bivariate-rho12-ademp.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript tools/codex-checkpoint.R --goal "Slice 298 bivariate rho12 ADEMP sheet" --next "stage, commit, push, and open draft PR"
```

All checks passed.

## Tests Of The Tests

No executable tests changed. The design-contract scans check that the sheet
names `biv_gaussian()`, residual `rho12`, `sigma1`/`sigma2`, the guarded
correlation transform, response-scale residual covariance, `rho12_boundary`,
and the correlation layers that must stay out of this grid.

## Consistency Audit

The sheet follows the Slice 292 rule that admitted lanes get one-page ADEMP
sheets before new code. It agrees with the cross-dpar correlation gate and the
bivariate-coscale tutorial: residual `rho12` is a within-observation
correlation layer, not a group-level, phylogenetic, spatial, or known-sampling
covariance layer.

## What Did Not Go Smoothly

The broad scan for `rho12` returned a large amount of historical and tutorial
evidence. That was useful for this slice because it made the main risk obvious:
the sheet had to separate residual `rho12` from `corpairs()` and known sampling
covariance rather than summarizing all bivariate correlation evidence together.

## Team Learning

Ada kept the slice in the design lane. Pat checked that the reader can see what
`rho12` means biologically before seeing formulas for other correlation
layers. Fisher checked the Wald versus profile coverage distinction. Curie
checked that a new bivariate DGP helper remains future work. Rose checked the
blocked bivariate neighbours. Grace confirmed formatting, pkgdown, and
whitespace checks. No spawned subagents were used.

## Known Limitations

No simulation DGP helper, runner, result table, formal grid, or executable test
was added. The next implementation slice should add an explicit bivariate
residual `rho12` DGP helper under `inst/sim/` before any broad bivariate
correlation report claims operating characteristics.

## Next Actions

Continue the ADEMP sequence with bivariate group-level `corpairs()`,
Student-t `nu`, or structured-effect admitted subsets, or implement the
bivariate residual `rho12` DGP helper described in this sheet.

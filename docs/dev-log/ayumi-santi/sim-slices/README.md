# Ayumi/Santi Simulation Slice Summary

These artifacts finish the no-real-data simulation path for the
Ayumi/Santi phylogenetic protocol work.

## Completed Slices

1. q2 Objective 1 mini-grid: `q2-mini-grid-summary.csv`.
2. univariate ecogeographic PLSM positive control: `univariate-plsm/summary.csv`.
3. q4 bivariate PLSM diagnostic positive control: `q4-positive-control/summary.csv`.
4. lifestyle/nest-habitat split-fit analogue: `split-fit-class-contrast/summary.csv`.
5. integration summary: this file.

## Run Highlights

- q2 mini-grid: 3 converged cells, all `pdHess = TRUE`; largest gradient 0.000554.
- univariate PLSM: truth `mu`-`sigma` phylogenetic correlation 0.7, estimate 0.893, gradient 0.000344.
- q4 bivariate PLSM: 6 phylogenetic correlation rows, convergence 0, `pdHess = TRUE`, gradient 0.00262.
- split-fit class contrast: terrestrial, aquatic, aerial all converged with `pdHess = TRUE`.

## Interpretation Boundary

All inputs are simulated. These runs test model routes, extraction, and
diagnostic reporting. They do not make biological claims for Ayumi or
Santi's real datasets.

## Next With Real Data

Run `tools/ayumi-santi-q2-objective1-runner.R --dry-run true` on the
prepared mammal and avian Objective 1 datasets, then fit one representative
tree for each if the preflight tables are clean.

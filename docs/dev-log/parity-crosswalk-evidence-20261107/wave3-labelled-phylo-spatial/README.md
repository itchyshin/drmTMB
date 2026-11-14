# Wave 3: labelled (correlated) phylo and spatial q2, R versus Julia

Reader: whoever decides parity-matrix verdicts for `phylo|spatial(1 + x | p | g)` with one SD formula per coefficient. Evidence only; no verdict or matrix script was changed.

Julia: DRModels.jl branch `claude/labelled-phylo-spatial-20261108` (commit `8df5119df`, based on `claude/q2-wave2-merge-20261107`, pushed, no PR). Native R: drmTMB 0.8.1 (temporary library, `DRMTMB_LIB`). ML on both sides.

## Fixture

`make_data.R` (seed 2026110801, rho = 0.5): one balanced 64-tip ultrametric tree (height 2) and the same 64 ids on an 8 x 8 grid, 16 rows per id (1024 rows), latent unit fields (u0, u1) ~ N(0, R kron C), `b_k = s_k[g] u_k`, SDs depend on `z0` / `z1`. Kernels: `ape::vcv(tree, corr = TRUE)`; `exp(-d / median d) + 1e-6 I`. One dataset per route, one seed.

## What native R fits (checked first; `r_fit.R`, `r_probe_const.R`)

| Shape | Native R 0.8.1 |
| --- | --- |
| Gaussian phylo, Gaussian spatial, NB2 phylo, Poisson spatial | fits with both SD formulas |
| Poisson phylo | REFUSES SD formulas ("multiple structured coefficients"); fits the labelled term with constant SDs |
| NB2 spatial | REFUSES the labelled term outright (with or without SD formulas) |

The refusals come from the R gates `allow_poisson_structured_q2_sd` (labelled `phylo` excluded) and the NB2 labelled-covariance gate. Julia fits both cells.

## Agreement at the optimum (Julia minus R)

| Route | n par | Max abs diff | Max diff (R-SE units) | rho (R) | rho diff | Max SE rel diff | Log-lik (R) | Log-lik diff |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Gaussian phylo | 8 | 2.2e-12 | 1.3e-11 | 0.6198 | -1.4e-12 | 3.3e-7 | -901.3718 | -2.7e-12 |
| Gaussian spatial | 8 | 1.0e-11 | 7.0e-11 | 0.2406 | 3.0e-12 | 3.2e-7 | -825.7117 | 5.8e-12 |
| NB2 phylo | 8 | 1.2e-7 | 3.9e-7 | -0.0693 | 5.6e-8 | 4.8e-6 | -1927.1049 | -1.9e-11 |
| Poisson spatial | 7 | 1.5e-7 | 4.2e-7 | 0.2760 | -1.8e-8 | 3.4e-6 | -1759.1769 | -1.8e-10 |
| Poisson phylo, constant SDs (`sd(...) ~ 1`) | 5 | 4.8e-8 | 2.9e-7 | 0.5301 | 2.9e-8 | 3.9e-7 | -1842.3414 | -7.1e-10 |

All fits converged in both languages. Parameters compared are the mean coefficients, sigma (where present), the SD-formula coefficients (so the SDs) and `eta_cor_phylo` (so rho). Per-parameter rows: `comparison_by_parameter.csv`; summary: `comparison_summary.csv`.

## Julia-only cells (no native R counterpart)

- Poisson phylo with both SD formulas (`z0`, `z1`): log-lik -1840.1864, rho 0.5296, converged. Validated by the dense Laplace oracle in the Julia test only. The constant-SD restriction of the same Julia fit matches R (table above).
- NB2 spatial with both SD formulas: log-lik -1913.4567, rho -0.1520, converged. Oracle only. R cannot fit this shape at all.

## Honest gaps

- Two of six routes have no full native-R comparison (above); one of them is compared only as its constant-SD restriction.
- One dataset and seed per route: likelihood agreement at the optimum, not recovery or coverage.
- On the Julia test fixture (32 sites, seed 202611081) the spatial Poisson fit ran to the rho -> 1 boundary and did not converge, so the test uses seed 1 (interior optimum). Weak identification of rho on a smooth 32-site kernel is expected; the boundary case is not an R-versus-Julia comparison.
- Mesh/SPDE spatial, REML, missing responses and offsets are not covered.

Rerun from this directory: `Rscript make_data.R`; `DRMTMB_LIB=<lib> Rscript r_fit.R`; `DRMTMB_LIB=<lib> Rscript r_probe_const.R`; `julia --project=<DRModels test env> julia_fit.jl`; `Rscript compare.R`.

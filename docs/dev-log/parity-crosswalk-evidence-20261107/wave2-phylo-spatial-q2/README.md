# Wave 2: phylo and spatial (1 + x | g) q2 with one SD formula per coefficient, R versus Julia

Reader: whoever decides parity-matrix verdicts for these rows. This folder is evidence only; no verdict or matrix script was changed.

Julia branch `claude/phylo-spatial-q2-20261107` (DRModels.jl, commit `b5c0d9f9c`, pushed, not merged, no PR), based on `claude/q2-final-20261107`. Native R: drmTMB 0.8.1 built from `origin/main` (temporary library). ML on both sides.

## What R does (checked before writing Julia)

R fits all six shapes (`r_fit.R`, convergence code 0 each): `phylo(1 + x | id, tree = tree)` and `spatial(1 + x | id, coords = coords)` with `sd(id, level = "phylogenetic"|"spatial", coef = "(Intercept)") ~ z0` and `coef = "x"` `~ z1`, for `gaussian()`, `poisson()` and `nbinom2()`.

Kernel conventions, confirmed by recomputing R's Gaussian log-likelihood with a dense MvNormal (`conv_check.R`, agreement to 1e-9):

- phylo: `ape::vcv(tree, corr = TRUE)`, the height-normalised tip correlation. The fixture tree has height 2, so a raw-branch-length kernel would not have matched.
- spatial (coordinates): `exp(-d / median positive distance) + 1e-6 I`, range fixed (`drm_spatial_coords_precision`).

## Fixture

One balanced 64-tip ultrametric tree (tip edges 1.5, internal 0.1, height 2) and the same 64 ids on an 8 x 8 grid; 16 rows per id, 1024 rows. `make_data.R` writes the data, tree and coordinates, which are stored here.

## Agreement at the optimum (Julia minus R)

| Case | Parameters | Max abs diff | Max diff (R-SE units) | Max SE rel diff | Log-lik (R) | Log-lik diff |
| --- | --- | --- | --- | --- | --- | --- |
| Gaussian phylo | 7 | 5.3e-12 | 2.8e-11 | 3.3e-7 | -907.7386 | 4.0e-11 |
| Poisson phylo | 6 | 5.9e-7 | 2.1e-6 | 3.0e-3 | -1549.2297 | 2.9e-10 |
| NB2 phylo | 7 | 1.3e-7 | 5.3e-7 | 1.1e-6 | -1702.7235 | -8.9e-11 |
| Gaussian spatial | 7 | 4.2e-11 | 3.9e-10 | 3.2e-7 | -888.8679 | -3.2e-11 |
| Poisson spatial | 6 | 3.9e-8 | 2.5e-7 | 2.0e-6 | -1725.8661 | -2.3e-10 |
| NB2 spatial | 7 | 5.5e-8 | 5.7e-7 | 2.0e-5 | -1842.6911 | -1.3e-11 |

All fits converged in both languages. Per-parameter rows are in `cmp_<case>.csv`; `summary.csv` holds the table.

**SE caveat, Poisson phylo.** The 3.0e-3 relative SE gap is on the weakly identified slope-SD block (SEs 0.62 and 1.02). It comes from the finite-difference Hessian step (h = 1e-4) of the shared Poisson q2 Laplace helper, not from the model: with h = 3e-3 the Julia SEs are 0.6198146 and 1.022228 against R's 0.6198470 and 1.0222670 (3e-5 relative; `se_probe.jl`). The shared helper was not changed in this lane because the animal and relmat routes also use it.

## Julia tests

`test/test_phylo_spatial_q2_sd.jl` (33 assertions, about 1 minute): for each of the six shapes, on a 32-tip tree or 32-site grid, the fitted log-likelihood matches an independent oracle at the fitted theta. For Gaussian the oracle is a dense MvNormal (atol 1e-6). For Poisson and NB2 it is a dense ForwardDiff Laplace in the standardised latent (atol 1e-5). The phylo correlation in the oracle is built by hand from shared-path lengths, not from package code. The file also tests refusals: a non-ultrametric tree, unused `K`, a single SD formula, a tip with no rows, and Binomial still refusing. Gamma `coef(intercept)` on `phylo(1 | g)` returns the same fit as the selector-free target. Neighbouring files (16, including the animal/relmat q2, #620 phylo slope, spatial slope and Gamma/Binomial phylo SD tests) all pass.

## Not covered

- Mesh/SPDE `spatial(..., mesh = )` q2: not attempted. The coordinate route is a fixed kernel.
- Non-ultrametric trees: Julia refuses them, and R's correlation scale requires ultrametricity too.
- REML, missing responses, labelled `(1 + x | p | g)` correlation, offsets for NB2.
- `predict`, `simulate` and R-bridge export for these new routes were not wired or tested. These are direct-Julia fits only.
- One dataset and seed per case. This is likelihood agreement at the optimum, not recovery or coverage.

Rerun: `Rscript make_data.R`; `Rscript r_fit.R <case>` for each case; `julia --project=<DRModels test env> julia_fit.jl`; `Rscript compare.R`. Paths in the scripts point at this session's scratchpad.

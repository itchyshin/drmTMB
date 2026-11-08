# Multi-seed R versus Julia agreement for the SD-regression routes

Reader: whoever weighs whether the single-dataset agreement in the earlier evidence folders generalises across simulated datasets. This is agreement at the maximum-likelihood optimum only. It is not coverage, calibration or recovery, and no verdict or matrix file was changed.

Julia: DRModels.jl branch `claude/q2-wave2-merge-20261107`, commit `9c9572e3a` (worktree branch `claude/multiseed-evidence-20261108`, no Julia source edited). Native R: drmTMB 0.8.1 from the `origin/main` temporary library used by the earlier evidence. ML on both sides. `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=4`, one process at a time.

Ten new datasets per route (seeds 1 to 10, different from the original single seed). Fixtures are the earlier ones with the seed changed (`fixtures.jl`); phylo and spatial keep the fixed 64-tip tree and 8 x 8 grid and redraw z1, latent fields and counts (`make_data_ps.R`).

## Routes

| Route | Model | Data size |
| --- | --- | --- |
| `poisson_animal` | Poisson `animal(1 + x \| g, A)`, `sd(coef(intercept)) ~ z0`, `sd(coef(x)) ~ z1` | 48 x 24 |
| `nb2_relmat` | NB2 `relmat(1 + x \| g, K)`, `sigma ~ 1`, two coef SDs | 48 x 24 |
| `gauss_ord` | Gaussian ordinary `(1 + x \| g)`, `sigma ~ 1`, two coef SDs, true rho 0.4 | 150 x 10 |
| `gauss_animal` | Gaussian `animal(1 + x \| g, A)`, `sigma ~ 1`, two coef SDs | 30 x 12 |
| `poisson_phylo` | Poisson `phylo(1 + x \| g)`, two coef SDs | 64 x 16 |
| `poisson_spatial` | Poisson `spatial(1 + x \| g)` (coordinate kernel), two coef SDs | 64 x 16 |
| `poisson_labelled` | Poisson `animal(1 + x \| p \| g, A)`, two coef SDs, estimated rho (true 0.5) | 48 x 24 |

**Substitution, please read.** The requested route "labelled-rho Poisson ordinary" does not exist in Julia at this commit. `drm(bf(y ~ x + (1 + x | p | g), sd(g, coef(intercept)) ~ z0, sd(g, coef(x)) ~ z1), Poisson())`, and the same with `(1 + x | g)`, throws "Poisson random-effect SD regression requires exactly one SD target" (`src/poisson.jl:462`). The only Poisson labelled-rho route is the structured one, so `poisson_labelled` uses `animal(1 + x | p | g, A)`, the Poisson route of `wave2-labelled-rho`. Poisson ordinary with two SD formulas has no Julia route to compare, so there is no multi-seed evidence for it.

## Results (Julia minus R; worst case over 10 seeds)

| Route | Both converged | Max coef diff (R-SE units) | Max coef diff (abs) | Max per-level SD rel. diff | Max abs log-lik diff | Max abs rho diff | Max SE rel. diff |
| --- | --- | --- | --- | --- | --- | --- | --- |
| poisson_animal | 10/10 | 6.2e-7 (s3) | 1.1e-7 | 1.2e-7 | 8.1e-9 (s2) | n/a | 2.5e-6 |
| nb2_relmat | 10/10 | 9.5e-7 (s2) | 1.3e-7 | 2.4e-7 | 1.1e-9 (s3) | n/a | 2.2e-6 |
| gauss_ord | 10/10 | 6.8e-10 (s6) | 3.4e-11 | 6.2e-11 | 1.9e-10 (s9) | 4.3e-9 | 3.3e-7 |
| gauss_animal | 10/10 | 1.2e-9 (s3) | 1.7e-10 | 2.7e-10 | 9.1e-12 (s5) | n/a | 3.4e-7 |
| poisson_phylo | 10/10 | 2.7e-6 (s9) | 7.5e-7 | 1.3e-6 | 2.3e-9 (s2) | n/a | 4.3e-3 (s9) |
| poisson_spatial, 9 seeds (not s9) | 9/9 | 6.7e-7 (s8) | 5.8e-7 | 1.1e-6 | 3.4e-9 (s3) | n/a | 3.8e-6 |
| **poisson_spatial, seed 9** | 1/1 | 5.9e-4 | **2.94** | **0.96** | 1.0e-8 | n/a | Inf |
| poisson_labelled | 10/10 | 8.0e-7 (s3) | 1.5e-7 | 2.6e-7 | 4.4e-10 (s8) | 6.3e-8 | 4.3e-6 |

All 70 fits converged in both languages (R convergence code 0, positive-definite Hessian in R for all 70). `summary.csv` has the same table in machine form; `raw_per_seed.csv` has the 70 per-seed rows; `raw_per_parameter.csv` has every parameter. "SD rel. diff" is the maximum over groups and both coefficient fields of |SD_julia - SD_R| / SD_R, with SD = exp(b0 + b1 z) evaluated from each fit's SD-formula coefficients at the observed z values. "R-SE units" divides the coefficient difference by R's standard error.

## The one disagreement: Poisson spatial, seed 9

Fixed effects, intercept-SD coefficients and log-likelihood agree as in every other seed (all coefficient differences under 4e-8 for parameters 1 to 4, log-likelihood difference 1.0e-8, Julia higher). The two slope-SD coefficients differ: Julia -14.49 and -0.448, R -11.55 and -0.148. Both fits are at the boundary where the slope-coefficient SD tends to zero: the implied per-level slope SD is 3e-7 to 8e-7 in Julia and 8e-6 to 1e-5 in R, a difference of about 1e-5 in absolute terms. The likelihood is flat along that direction, so the coefficient is not identified; R reports an SE of about 5000 for it and Julia reports 1.8 and Inf for the two slope-SD coefficients. This is a flat boundary optimum reached at slightly different points, not two different local maxima (the log-likelihoods agree to 1e-8), and it is why the relative SD difference (0.96) and the absolute coefficient difference (2.94) are large while the SE-unit difference (5.9e-4) is small. I did not rerun the seed from other starting values or widen any tolerance. The `compare.R` triage flag (non-convergence, > 1e-3 R-SE, or log-lik difference > 1e-6) did not trigger on this seed, because R's SE is huge; it was found by reading the per-parameter table. The other six routes and nine of ten spatial seeds have no seed near a boundary (no coefficient below -6 anywhere else).

## Other notes

- Poisson phylo SE differences reach 4.3e-3 (seeds 9, 7, 1, 5 are above 3e-4). This is the same finite-difference Hessian step effect on the weakly identified slope-SD block described in `wave2-phylo-spatial-q2/README.md`; estimates and log-likelihoods agree to 3e-6 R-SE units and 2.3e-9.
- Rho: `gauss_ord` compares Julia's unit-lower-triangular theta converted to rho against R's tanh(eta_cor_mu); `poisson_labelled` compares Julia's `atanh_rho` with R's `eta_cor_phylo` (same scale, included in the coefficient difference) and rho = 0.999999 tanh(.) on both sides.
- Time: Julia fits take 0 to 1 s each after the first call in a process (the first fit costs 12 to 29 s of compilation); R fits take 0.1 to 1.2 s. Whole study about 3 minutes of compute.

## Not covered

Coverage, recovery, REML, other kernels or tree shapes, other families (NB2 and Gaussian phylo/spatial, Gamma), and starting-value sensitivity. Only the optimum found by each default fit is compared.

## Rerun

From this directory, with `DRMTMB_LIB` pointing to a drmTMB library: `Rscript make_data_ps.R 1 10`; then for each route `julia --project=<DRModels test env> julia_run.jl <route>` and `Rscript r_run.R <route>`; then `Rscript compare.R`. Routes are listed at the top of `julia_run.jl`. `run.log` is the log of the run reported here.

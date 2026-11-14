# Wave 2: labelled (correlated) structured q2 with two coefficient SD formulas, R versus Julia

Reader: whoever decides whether the labelled structured q2 rows can move from "Julia refuses" to "agrees". This page does not change any verdict.

## What R supports (checked first)

Native drmTMB 0.8.1 (the `origin/main` install used by the earlier steps) fits all six target shapes: `animal(1 + x | p | g, A = A)` and `relmat(1 + x | p | g, K = K)` with `sd(g, level = "animal"|"relmat", dpar = "mu", coef = "(Intercept)") ~ z0` plus `sd(g, ..., coef = "x") ~ z1`, for `poisson()`, `nbinom2()` with `sigma ~ 1`, and `gaussian()` with `sigma ~ 1`. Each fit estimates `eta_cor_phylo`, and `rho = 0.999999 * tanh(eta_cor_phylo)`. In R's TMB source the unit-scale fields have prior N(0, R (x) C), and the per-group SDs multiply them (`src/drmTMB.cpp`, the `has_phylo_mu_q2_covariance` blocks).

R refuses some neighbouring shapes, shown in `probe.R`: Poisson labelled with only one SD formula; NB2 labelled with no SD formula; Gaussian labelled with no SD formula ("all-four bivariate Gaussian block"). Julia does not implement these either.

## Julia change

DRModels.jl branch `claude/labelled-rho-q2-20261107`, commit `c21d0a3b9`, based on `claude/q2-final-20261107`. The labelled form adds one parameter, `eta`, which is R's `eta_cor_phylo`. It sits in block `:recov` with the name `"g:atanh_rho"`. The Poisson and NB2 routes use a sparse Laplace with joint prior precision kron(R^-1, Q). The Gaussian route uses the exact dense marginal, which gains `rho (s0_g s1_h x_j + x_i s1_g s0_h) C[g, h]`. Test: `test/test_labelled_rho_q2_sd.jl` (95 passing assertions). It checks the fit against independent dense Laplace (counts) and MvNormal (Gaussian) oracles at the fitted theta, checks that `eta = 0` reproduces the unlabelled fit, and covers prediction, the bridge, a simulator variance check that depends on rho, and refusals.

## Agreement at the optimum (one dataset, G = 48, m = 24, n = 1152, true rho = 0.5, ML)

| Route | Params | Max abs diff | Max diff (R-SE units) | rho (R) | Log-lik diff (Julia minus R) |
| --- | --- | --- | --- | --- | --- |
| Poisson animal / relmat | 7 | 3.1e-8 | 2.3e-7 | 0.6071 | -4.2e-10 |
| NB2 animal / relmat | 8 | 1.1e-7 | 6.8e-7 | 0.6124 | -3.2e-9 |
| Gaussian animal / relmat | 8 | 8.8e-12 | 1.9e-10 | 0.6592 | 8.8e-11 |

The SE ratio (Julia/R) lies between 0.999997 and 1.0000004. Every fit converged in both languages. Animal and relmat give identical results because both use the same raw matrix (K = A).

Not covered: other seeds, REML, interval coverage, `Ainv` input on the labelled route, labelled intercept-only terms, and Gamma or Binomial labelled q2 (Julia still refuses these).

## Files and rerun

`fixture.jl` (data generator), then `julia_fit.jl`, which writes `data.csv`, `A.csv`, `A_ids.csv`, `julia_*.csv` and `julia_ll.csv`. It needs DRModels at the commit above. Next, `DRMTMB_LIB=<lib> Rscript r_fit.R`, which writes `r_*.csv`; run it from this directory. Last, `Rscript compare.R`, which writes `comparison_summary.csv`, `comparison_by_parameter.csv` and `compare.log`.

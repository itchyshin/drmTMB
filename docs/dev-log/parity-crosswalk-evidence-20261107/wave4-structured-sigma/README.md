# Wave 4: NB2 structured sigma, R versus Julia agreement

Reader: whoever decides whether Julia's NB2 / Gamma structured-sigma routes may be called "agrees with native drmTMB". Agreement at the maximum-likelihood optimum only; not coverage, calibration or recovery. No verdict or matrix file was changed.

Julia: DRModels.jl branch `claude/nb2-gamma-structured-sigma-20261108` (from `claude/labelled-ordinary-poisson-nb2-20261108`, tip 04581709d). Native R: drmTMB 0.8.1 (temporary library of the earlier evidence). ML on both sides, `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=2`.

## What native drmTMB fits (decides what can be compared)

Probed first (Julia design note `DESIGN-structured-sigma.md` holds the verbatim refusals):

* **NB2 `sigma ~ 1 + P(1 + x | id)`, no SD formula: fits** (animal, relmat, phylo, spatial). This is the only structured-sigma shape R fits for NB2 or Gamma, so it is the only shape with an R comparator.
* **NB2 and Gamma structured sigma WITH an SD formula (`sd(id, level, dpar = "sigma") ~ z`): R refuses**, for every provider, and for NB2 `(1 | id)` on sigma. Gamma refuses every structured sigma term. Julia implements the SD-formula intercept as a **Julia-only** extension (oracle evidence only, in `test/test_nb2_gamma_structured_sigma.jl`); it has **no R agreement evidence by construction**.

## Design

NB2, 40 groups x 12 rows (480 rows), `y ~ x`, `sigma ~ 1 + P(1 + x | id)`. Truth: mu = exp(1 + 0.3 x); log sigma = -0.3 + 0.45 u1[g] + 0.35 x u2[g], u1, u2 ~ N(0, K) independent. K: animal AR(0.4) (`A`), relmat a tree correlation times 1.7 (`K`), phylo a random coalescent tree (`rcoal`, ultrametric), spatial the native fixed kernel on random coordinates. `r_run.R` generates the data (seeds 1-5 per route) and fits in R; `julia_run.jl` reads the same CSVs; `compare.R` writes `raw_per_seed.csv`, `raw_per_parameter.csv`, `summary.csv`. Parameter order is identical in both (`beta_mu` x2, `beta_sigma`, log SD intercept, log SD slope).

## Results (Julia minus R, 5 seeds per provider; worst case)

| Provider | Both converged | R pdHess | Max abs log-lik diff | Max abs coef diff | Max coef diff (R-SE units) | Max SE rel. diff |
| --- | --- | --- | --- | --- | --- | --- |
| animal | 5/5 | 5/5 | 3.0e-10 | 7.0e-10 | 3.2e-9 | 7.6e-7 |
| relmat | 5/5 | 5/5 | 2.1e-11 | 1.5e-9 | 5.2e-9 | 1.1e-6 |
| phylo | 5/5 | 5/5 | 5.2e-9 | 4.3 (seed 2, see below) | 5.6e-4 | 68 (seed 2) |
| spatial | 5/5 | 5/5 | 6.6e-9 | 4.8 (seed 2, see below) | 7.9e-4 | 126 (seed 2) |

## The two exceptions: phylo seed 2 and spatial seed 2 (boundary)

In both, the slope-field SD is at its lower boundary: R's log SD is -11.66 (phylo) and -11.57 (spatial), Julia's -15.99 and -16.41. The log-likelihoods agree to 5e-9 and 7e-9, every other coefficient agrees to 1e-7 or better, and the implied SDs are below 1e-5 in both languages; the likelihood is flat in that direction and the coefficient is not identified (R reports SE of 5e5 and 8e5 for it, and Julia warns that those standard errors are untrustworthy). The "SE rel. diff" for those two seeds is meaningless for the same reason. I did not rerun from other starts or widen anything. The other 18 fits have no log SD below -2.2.

## Reproduce

```
export DRMTMB_LIB=<drmTMB 0.8.1 library>
for r in animal relmat phylo spatial; do Rscript r_run.R $r 1 5; done
for r in animal relmat phylo spatial; do julia --project=<DRModels test env> julia_run.jl $r 1 5; done
Rscript compare.R
```

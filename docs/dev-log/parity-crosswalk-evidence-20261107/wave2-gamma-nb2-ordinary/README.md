# Wave 2: Gamma and NB2 two-field SD routes, R versus Julia

Reader: whoever decides the parity-matrix verdicts for PROPOSED-verdict-flips.md rows 7 to 10 (and, as a side effect, rows 15 and 20). This folder is evidence only; no verdict and no `tools/write-parity-matrix.R` line was changed.

## What was done

Native R first. `r_probe.R` (log: `r_probe.log`) fits every target shape on a small dataset with native drmTMB 0.8.1 (temporary library built from `origin/main` today). R fits all of them except one: Gamma ordinary correlated `(1 + x | g)` with SD formulas is refused ("Only independent Gamma `mu` random intercepts and slopes ..."). Julia keeps that refusal.

Julia: DRModels.jl branch `claude/gamma-nb2-ordinary-q2-20261107` (commits `f378e038b`, `002a0df8d`; based on `claude/q2-final-20261107` `f4b30ee26`; pushed, no PR, not merged). One new file, `src/twofield_sd_laplace.jl`: a TMB-style Laplace for two latent mean fields, each with its own SD formula, `sigma ~ 1`, raw (never rescaled) kernels, optionally one cross-field correlation on the atanh scale. Gamma and NB2 dispatch to it before their existing single-target routes. Test: `test/test_gamma_nb2_twofield_sd.jl` (12 shape cases plus a refusal set, 118 assertions, about 40 s). Each case checks the fitted log-likelihood against an independent dense Laplace written without DRModels internals (original latent scale, Distributions.jl densities) to 1e-5, and checks that emulated bugs (reversed SD vector of either field, permuted kernel, rho set to 0) move that oracle by more than 0.1.

Agreement: `julia_fit.jl` regenerates one dataset per shape from the test fixtures and fits Julia; `r_fit.R` fits native R on the same CSV and kernel; `compare.R` compares the optimum. Paths inside the scripts point at this session's scratchpad. Data and kernels are not stored (regenerate with `julia_fit.jl`). ML on both sides.

## Results (one dataset and seed per shape)

| Shape (R syntax) | Family | Params | Max abs diff | Max diff (R-SE units) | Log-lik diff (Julia minus R) |
| --- | --- | --- | --- | --- | --- |
| `(1 \| g) + (0 + x \| g)`, `sd(g, coef = "(Intercept)")`, `sd(g, coef = "x")` | NB2 | 7 | 6.3e-8 | 3.9e-7 | 1.7e-11 |
| same | Gamma | 7 | 8.5e-8 | 5.1e-7 | 2.5e-11 |
| `(1 \| g) + (1 \| h)`, `sd(g)`, `sd(h)` | Gamma | 7 | 3.2e-8 | 9.1e-7 | -3.2e-11 |
| same | NB2 | 7 | 1.5e-7 | 7.1e-7 | 5.4e-11 |
| `(1 \| g) + relmat(1 \| p, K)`, `sd(g)`, `sd(p, level = "relmat")` | Gamma | 7 | 1.3e-7 | 1.3e-6 | 1.4e-11 |
| same | NB2 | 7 | 1.4e-7 | 3.5e-7 | -6.0e-12 |
| `(1 \| g) + animal(1 \| p, A)`, `sd(g)`, `sd(p, level = "animal")` | Gamma | 7 | 1.3e-7 | 1.3e-6 | 1.4e-11 |
| `relmat(1 + x \| g, K)`, two `coef` SDs (independent) | Gamma | 7 | 1.2e-7 | 8.2e-7 | 4.8e-12 |
| `animal(1 + x \| p \| g, A)`, two `coef` SDs, rho | Gamma | 8 | 7.4e-7 | 3.9e-6 | 1.8e-11 |
| `relmat(1 + x \| p \| g, K)`, two `coef` SDs, rho | Gamma | 8 | 7.4e-7 | 3.9e-6 | 1.8e-11 |
| `animal(1 + x \| p \| g, A)`, two `coef` SDs, rho | NB2 | 8 | 6.0e-7 | 2.1e-6 | 6.9e-11 |
| `(1 + x \| g)`, two `coef` SDs, rho | NB2 | 8 | 7.4e-8 | 5.8e-7 | -6.5e-10 |

All 24 fits report convergence. SE ratio (Julia/R) lies in 0.9999967 to 1.0000007 over every parameter. Julia's `atanh_rho` equals R's `eta_cor_mu` / `eta_cor_phylo` directly (no conversion). The animal and relmat rows with the same kernel are identical by construction (same data and raw kernel). Per-parameter tables: `<shape>/comparison.csv`; overview: `summary.csv`.

## Mapping to PROPOSED-verdict-flips.md rows

- Row 10 (Gamma and NB2 same-group intercept + slope, `coef` SDs): both families now fit and agree. NB2 ordinary correlated `(1 + x | g)` also agrees; Gamma correlated is refused on both sides.
- Row 7 (Gamma crossed and ordinary + relmat intercept SDs): both fragments fit and agree.
- Row 9 (Gamma ordinary + animal/phylo/spatial intercept SDs): animal fragment only. Phylo and spatial beside an ordinary term are NOT implemented in Julia (refused) and have no evidence here.
- Row 8 (Gamma animal correlated q2): the labelled (rho-estimating) animal and relmat forms now fit and agree. Gamma relmat q2 (independent) is new in Julia too.
- Side effects, not in this lane's rows: NB2 crossed, NB2 ordinary + relmat, NB2 labelled animal q2 (rows 15 and 20 mention labelled NB2 forms). A separate wave2-labelled-rho lane works on labelled Poisson/NB2/Gaussian forms in another Julia branch; merging both will conflict in the NB2 SD dispatch and needs one owner.

## Not shown

Other seeds, REML, interval coverage, recovery. Bridge (R calling Julia) was not exercised: native-only evidence. Post-fit methods on the new fits (`predict`, `simulate`, `residuals`, `profile`, bootstrap) were not tested and may refuse or misbehave. One-SD variants (only one of the two fields gets a formula; native R admits some) stay refused in Julia. Phylo and spatial providers on these two-field routes are not implemented.

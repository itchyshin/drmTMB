# Wave 4 post-fit: conditional quantile residuals and `Ainv`, R versus Julia

Reader: whoever decides whether Julia's random-effect SD-regression routes may be called "agrees with native drmTMB" for `residuals(type = "quantile")` and for `Ainv` input. Agreement at the maximum-likelihood optimum and at the conditional modes; not coverage or calibration. No verdict or matrix file was changed.

Julia: DRModels.jl branch `claude/postfit-cond-residuals-20261108` (from `claude/labelled-ordinary-poisson-nb2-20261108`, tip 04581709d). Native R: drmTMB 0.8.1 (temporary library of the earlier evidence). ML on both sides, `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=2`.

## What native drmTMB does (item 1)

`drm_quantile_residuals()` evaluates `F_i` through `fitted_distribution()`, which reads `predict_parameters(newdata = NULL)`: the fitted-row parameters. For a fit with random effects these **include the conditional modes** at the fitted parameters. Evidence: on the wave-3 ordinary `(1 + x | g)` Poisson fit, `predict(fit, dpar = "mu")` differs from `exp(X beta)` by up to 21.5, and the residuals have SD 0.976, not the 1.2 that the population level gives. So native residuals are conditional on the Laplace modes, not marginal and not population level. (The header comment of `R/adequacy.R` and the `newdata` paragraph of `fitted_distribution()` say "fixed-effect, population-level"; that is true for `newdata`, not for the fitted rows. I did not edit R.)

Julia used the population level (random effects set to 0) on every random-effect SD-regression route, so its residuals were over-dispersed (SD 1.07-3.27 on the test fixtures). Julia now records the per-row link-scale mode contribution at `theta_hat` (`scales[:cond_eta_re]`) on the q2 / q3 / q4, phylo / spatial q2, labelled, Gamma / NB2 two-field and Gaussian structured routes and uses it in the residuals. The joint mean + sigma routes already stored the conditional mean and conditional `sigma`; they are covered by the Julia test but needed no change.

## Design

`data/data.csv`, `data/A.csv` come from `make_data.jl` (the Julia test fixture `tf_case`: 40 animals x 14 rows, labelled `animal(1 + x | p | g)` with coefficient SD formulas, truth rho = 0.5; 560 rows; Poisson counts from a separate seeded draw). `data/wave3_data_2026110801.csv` is the wave-3 ordinary data (1280 rows). `r_postfit.R` and `julia_postfit.jl` fit the same models and write the same per-row columns (conditional mean, sigma, PIT bounds `lo = F(y-)`, `hi = F(y)`, residual); `compare.R` writes `comparison.csv`.

Fits: labelled `animal(1 + x | p | g)` for Poisson, NB2, Gamma and Gaussian, each from `A` and from `Ainv`; ordinary unlabelled `(1 + x | g)` for Poisson and NB2 (native drmTMB refuses the labelled ordinary form, as in wave 3).

## Results (Julia versus R)

See `comparison.csv`. Worst case over the ten fits:

| Quantity | Worst case |
| --- | --- |
| absolute log-likelihood difference | 6.0e-10 |
| conditional mean, relative | 2.2e-7 |
| sigma, absolute | 2.0e-8 |
| PIT bounds `lo`, `hi`, absolute | 8.2e-8 |
| deterministic residuals (Gamma, Gaussian), absolute | 1.6e-7 |
| count rows whose Julia `Phi(r)` lies in the R interval `[lo, hi]` | 100% (all six count fits) |

Count residuals are randomized, so the two generators differ and the SD of the residuals differs between languages only through the draw (for example NB2 0.941 R, 0.961 Julia); the interval check is the comparison. The `A` and `Ainv` fits give identical numbers in each language.

## What this does not show

One dataset per shape (the Poisson / NB2 / Gamma / Gaussian labelled fits share one design). Not run here against R: the phylo / spatial q2, the two-field crossed / relmat shapes, Gaussian q3 / q4 and the joint mean + sigma routes; Julia checks those against an independent dense computation only (`test/test_postfit_conditional_residuals.jl`, agreement 1e-8 or better). R does not fit several of these shapes (Gamma ordinary correlated, structured sigma with an SD formula), so no R comparator exists for them.

## `Ainv` (item 2)

Native drmTMB fits `animal(1 + x | p | id, Ainv = Ainv)` and the unlabelled form for Poisson, NB2, Gamma and Gaussian, and the fit equals the `A = solve(Ainv)` fit (log-likelihoods -914.5529, -1069.666, -713.644, -471.1828; identical for `A` and `Ainv`). Julia accepted `Ainv` for Poisson and NB2 but ended in a `MethodError` for Gamma and Gaussian. Julia now converts `Ainv` to the labelled covariance for those two families (rows in first-seen order of the animal group, as for Poisson / NB2) and matches R to 6e-10 in log-likelihood. Not added: the `Ainv` keyword on `simulate` / `bootstrap_result` for Gamma and Gaussian (pass `A = inv(Ainv)` there), and a precision keyword for `relmat` (R's `relmat(…, Q = Q)`).

## Reproduce

From the DRModels.jl worktree: `julia --project=test <this dir>/make_data.jl <this dir>/data`; then in this directory `DRMTMB_LIB=<lib> Rscript r_postfit.R`, `julia --project=<DRModels test env> julia_postfit.jl`, `Rscript compare.R`.

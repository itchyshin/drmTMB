# Scale extension: R versus Julia agreement for eight more SD-regression routes, on the line-search-fix tip

Reader: whoever decides whether the agreement shown in `../scale300/` and the 10-seed folders extends to Gaussian ordinary q3 and q4, to NB2 and Poisson on relmat, NB2 on animal and phylo, and Gaussian on relmat, and whether the Gaussian ordinary q2 line-search failures are gone. This is agreement of two implementations at the maximum-likelihood optimum. It is not a coverage, calibration or recovery claim. No verdict or matrix file was changed and no Julia source was edited. Nothing was merged and no PR was opened.

## What was run

* 1,200 pairs of fits on Totoro, one thread per worker (`OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`), 55 concurrent workers (cap 60). R-native (drmTMB 0.8.1, the private library of `~/drm_campaign_20261108/Rlib`, `origin/main` `6fc0910ed`) and Julia-native (DRModels 0.8.1, `git archive` of `origin/claude/wave4-merge-20261108`, tip `e5ae24539`, which includes the line-search fix `_optimize_with_fallback`) were run separately, ML on both sides. No `engine = "julia"`. Julia 1.10.12, fresh environment (`Pkg.develop` of the archive plus Distributions and DelimitedFiles; resolved manifest `manifest_julia1.10_totoro.toml`).
* Data: Julia-generated fixtures are written to files by the Julia run (`julia_run.jl`); the NB2 phylo datasets are generated in R first (`make_data_nb2phylo.R`); R reads the same files. Comparison is offline (`compare.R`).
* Working directory on Totoro: `~/drm_ext_20261108` (raw per-seed fits and datasets stay there, about 25 MB, not committed). `~/drm_campaign_20261108` was only read (Rlib, Julia depot copied).

| route | model | data | seeds | fixture |
|---|---|---|---|---|
| `gauss_q3` | Gaussian `y ~ x + z + (1 + x + z \| id)`, `sigma ~ 1`, one SD formula (`~ w`) per coefficient, unstructured correlation (3) | 150 x 10 | 100 | `fixtures_q34.jl` (as `multiseed2`, seeds `760000 + 30 + s`) |
| `gauss_q4` | same with `u`, 4 SD formulas, 6 correlations | 150 x 10 | 100 | same (`760000 + 40 + s`) |
| `gauss_ord` | Gaussian `(1 + x \| g)` q2, `sigma ~ 1`, SD formulas `z0`, `z1`, rho | 150 x 10 | 300 | `scale300` fixture, same seeds; datasets byte-identical to `scale300` (600 of 600 data files, gauss_ord and nb2_relmat, have the same md5) |
| `nb2_relmat` | NB2 `relmat(1 + x \| g)` intercept-slope, `sigma ~ 1`, SD formulas `z0`, `z1` | 48 x 24 | 300 | `scale300` fixture, same seeds (note below) |
| `poisson_relmat` | Poisson `relmat(1 + x \| g)`, same SD formulas | 48 x 24 | 100 | Poisson animal q2 fixture with `relmat`, seeds `780000 + s` |
| `nb2_animal` | NB2 `animal(1 + x \| g)`, `sigma ~ 1` | 48 x 24 | 100 | NB2 relmat fixture with `animal`, seeds `770000 + s` |
| `nb2_phylo` | NB2 `phylo(1 + x \| g)`, `sigma ~ 1`, NB2 sigma 0.6 | 64 x 16 | 100 | fixed 64-tip tree of `scale300`, new generator seed `2026111000 + s` |
| `gauss_relmat` | Gaussian `relmat(1 + x \| g)`, `sigma ~ 1` | 30 x 12 | 100 | Gaussian animal q2 fixture with `relmat`, seeds `790000 + s` |

Reading of the request. "NB2 relmat q2 ... with an intercept-slope relmat; reuse its fixture": the `scale300` NB2 relmat route already is an intercept-slope relmat, so I reran exactly that fixture (all 300 seeds, not 100, because it is cheap and covers seed 133) on the new tip. Its results are bit-identical to `scale300` for every seed on both sides (maximum absolute log-likelihood difference between this run and `scale300`: 0 for Julia and 0 for R). "Gaussian structured q2 relmat" is read as Gaussian `relmat(1 + x | g)` with two coefficient SDs and `sigma ~ 1` (the Gaussian animal fixture, relmat provider).

**Runtime.** Estimated before the full run: about 2 to 5 minutes wall on 55 workers (a 2-seed pilot of all eight routes took 38 s, almost all of it Julia compilation). Actual: **117 s** for data, Julia and R stages (Julia 96 s, R 20 s), plus 103 s for the diagnoses of the 9 flagged seeds and a few seconds of comparison. Far below the 3 hour line. Totoro carried load from others (load average about 24 at the start). Median Julia fit time after compilation: 0.02 s (gauss_ord) to 0.8 s (gauss_relmat); compilation 15 to 36 s per process. No processes of mine remain.

## Flag logic (audit-fixed, applied from the start)

A seed is flagged if any of: a side did not converge, errored or has no output; R Hessian not positive definite; max over coefficients of |Julia - R| / R-SE > 1e-3; max absolute coefficient difference > 1e-3; |log-lik difference| > 1e-6; max absolute per-level SD difference > 1e-3. Boundary flags (reported, not part of the flag): R or Julia correlation >= 0.99999 in absolute value, or any non-correlation coefficient < -6 on either side. Coefficients are compared by position after asserting the layout (below). For q3 and q4 the Cholesky correlation parameters (`theta_re_cov`) have the same parameterisation on both sides and are part of the coefficient comparison; for q2 ordinary (`eta_cor_mu` in R, theta in Julia) rho is compared on the correlation scale only (Julia `theta / sqrt(1 + theta^2)`, R `tanh(eta)`). R-SE units skip coefficients whose R standard error is not finite and positive (none occurred). Per-level SD is `exp(b0 + b1 z)` at each group's observed predictor value; "SD rel" divides by R's SD.

## Layout check

`layout_check.txt` prints, for seed 1 of each route, the Julia block names (the `sdtarget_<hex>` names decoded to `group|kind|dpar|coefficient|level`) next to the R parameter names, per index, next to the asserted values. The same assertion ran on every one of the 1,200 seeds before any difference was computed: R names equal the template, Julia within-block index equals the template, each Julia SD block decodes to the intended group, level (`iid`, `relmat`, `animal`, `phylo`), `mu` and coefficient, in the order `(Intercept)`, `x`, (`z`, `u`). Result: 0 of 1,200 seeds failed the layout assertion. The predictor of each SD formula (`w`, `z0`, `z1`) is not encoded in the block name, so it is not checked by this assertion; it is the same formula in both calls by construction, and a mismatch would show up as a large log-likelihood difference.

## Results (Julia minus R, `summary_distribution.csv`)

Medians, 99th percentiles and maxima are over seeds where both fits converged (absolute values). "R-SE" is the maximum over coefficients of |difference| / R-SE per seed.

| route | seeds | both conv. | R pdHess | coef diff R-SE: med / p99 / max | coef diff abs: med / p99 / max | SD rel: med / p99 / max | SD abs: med / p99 / max | ll diff: med / p99 / max | rho diff: p99 / max | seeds flagged |
|---|---|---|---|---|---|---|---|---|---|---|
| gauss_q3 | 100 | 100 | 100 | 4.3e-10 / 1.2e-09 / 1.2e-09 | 3.8e-11 / 1.2e-10 / 1.4e-10 | 4.8e-11 / 1.2e-10 / 1.7e-10 | 3.8e-11 / 1.5e-10 / 2.9e-10 | 8.7e-11 / 2.1e-10 / 2.2e-10 | 9.2e-11 / 9.8e-11 | 0 |
| gauss_q4 | 100 | 100 | 100 | 6.3e-10 / 1.3e-09 / 1.5e-09 | 7.4e-11 / 1.7e-10 / 1.7e-10 | 5.0e-11 / 1.1e-10 / 1.3e-10 | 4.5e-11 / 1.2e-10 / 1.5e-10 | 6.5e-11 / 2.1e-10 / 2.2e-10 | 1.1e-10 / 1.2e-10 | 0 |
| gauss_ord | 300 | 300 | 300 | 1.4e-10 / 7.4e-10 / 9.8e-10 | 8.3e-12 / 4.8e-11 / 6.4e-11 | 1.3e-11 / 7.2e-11 / 1.1e-10 | 9.0e-12 / 7.8e-11 / 1.1e-10 | 9.5e-11 / 2.0e-10 / 2.1e-10 | 5.5e-09 / 5.9e-09 | 0 |
| nb2_relmat | 300 | 300 | 300 | 7.5e-07 / 3.6e-06 / 4.6e-04 | 8.2e-08 / 1.5e-06 / 3.9 | 5.2e-08 / 2.9e-06 / 2.5e+03 | 2.0e-08 / 2.8e-07 / 1.4e-05 | 1.8e-10 / 6.7e-09 / 1.7e-06 | n/a | 2 |
| poisson_relmat | 100 | 100 | 100 | 1.5e-07 / 1.1e-06 / 2.1e-06 | 2.7e-08 / 3.2e-07 / 3.9e-07 | 3.5e-08 / 3.7e-07 / 5.7e-07 | 1.8e-08 / 1.6e-07 / 2.4e-07 | 3.1e-10 / 4.3e-09 / 6.9e-09 | n/a | 0 |
| nb2_animal | 100 | 100 | 100 | 7.4e-07 / 6.7e-06 / 4.7e-04 | 7.9e-08 / 3.8e-02 / 3.8 | 3.8e-08 / 2.2e+01 / 2.2e+03 | 2.0e-08 / 4.6e-07 / 4.7e-06 | 2.2e-10 / 1.8e-08 / 1.3e-06 | n/a | 1 |
| nb2_phylo | 100 | 99 | 100 | 6.3e-07 / 1.3e-02 / 0.65 | 2.2e-07 / 3.3 / 7.7 | 3.6e-07 / 2.6 / 79 | 5.1e-08 / 1.1e-03 / 5.3e-02 | 8.9e-11 / 2.3e-05 / 1.1e-03 | n/a | 5 (+ 1 non-converged, seed 7, counted among the 5) |
| gauss_relmat | 100 | 100 | 100 | 2.8e-10 / 2.8e-06 / 2.8e-04 | 4.1e-11 / 5.8e-02 / 5.8 | 5.0e-11 / 1.0e-02 / 1.0 | 2.6e-11 / 3.6e-10 / 1.6e-08 | 4.3e-12 / 7.8e-09 / 7.8e-07 | n/a | 1 |

(The p99 and max of the absolute and SD columns for nb2_animal, nb2_phylo and gauss_relmat come from the boundary seeds listed below.)

Standard errors: Julia returned non-finite standard errors for some parameters on 4 seeds, R on none (R reports very large finite SEs there): nb2_animal seed 63 (7 parameters), nb2_phylo seeds 7 (7), 19 (1) and 27 (2); the non-finite parameters are SD-formula coordinates of fields at the SD boundary (17 parameters in all). Every other seed has finite SEs on both sides. `per_seed.csv` has the per-seed counts.

Boundary seeds (flag-independent): nb2_relmat 133, 261; nb2_animal 63; nb2_phylo 7, 19, 27, 31, 55, 58; gauss_relmat 6. No seed has a correlation at the boundary (q3, q4, gauss_ord: none; the largest |rho| in R is far below 0.99999).

## Gaussian ordinary q2: the line-search fix works

All 300 seeds (the exact `scale300` datasets, md5-identical) converge in Julia and in R, with R pdHess on all 300. The 36 seeds that had no Julia result in `scale300` (24, 39, 40, 53, 62, 63, 66, 69, 82, 96, 105, 109, 112, 114, 144, 145, 149, 156, 171, 179, 180, 197, 201, 212, 243, 244, 253, 256, 269, 273, 279, 281, 282, 284, 291, 294) now all fit: maximum 5.4e-10 R-SE units and 2.1e-10 log-likelihood difference over those 36 (over all 300: 9.8e-10 R-SE, 6.4e-11 absolute coefficient, 5.9e-09 rho, 2.1e-10 log-likelihood). The 264 seeds that fitted before are bit-identical to the old tip (maximum |log-likelihood new minus old| = 0). Zero flagged seeds. Same-platform, same Julia version (1.10.12), same data, so the comparison is like for like.

## Non-converged seeds

| route | seed | Julia | R | note |
|---|---|---|---|---|
| nb2_phylo | 7 | converged | convergence code 1 ("singular convergence (7)"), R pdHess TRUE | both at the slope-SD boundary, see below |

No other fit of the 1,200 failed or reported non-convergence on either side; no Julia error occurred. (`nonconverged_seeds.csv`.)

## Every flagged seed, with diagnosis (`flagged_seeds.csv`, `diagnosis.csv`)

Diagnosis tool: `diagnose.R` (adapted from `scale300`): R's TMB objective at Julia's estimate, re-optimisation (`nlminb`) from Julia's estimate and from R's, and 40 jittered R starts (sd 0.7). Julia has no public restart option, so Julia-side restarts were not run. All 9 flagged seeds were diagnosed.

| route | seed | flag reasons | ll R / Julia | diagnosis |
|---|---|---|---|---|
| nb2_relmat | 133 | abs coef 3.91, ll 1.7e-6 | -1799.001923 / -1799.001921 | **Same optimum, boundary non-identification.** 42 of 44 evaluations within 1e-6 of the best, 1 distinct optimum. A slope-SD level is about 5e-11 (R) versus 1e-7 (Julia); abs SD difference 1.4e-5. Julia's own log-likelihood is 1.7e-6 above R's: R's objective at Julia's point is 3.3e-6 below Julia's reported value, so the two codes differ by that much in how they evaluate a factor with SD near 1e-7 (not traced); R's own best over its 44 evaluations equals R's default fit to 4e-9. Also flagged in `scale300`. |
| nb2_relmat | 261 | abs coef 2.75 | -1669.762891 / -1669.762890 | Same: 1 optimum, 44 of 44 within 1e-6, SD level about 5e-10 (R) versus 1e-7 (Julia), log-lik 4.6e-7. R-SE 3.5e-4. |
| nb2_animal | 63 | abs coef 3.84, ll 1.3e-6 | -1792.743511 / -1792.743509 | Same: 1 optimum, SD level 7e-11 versus 1.6e-7, Julia reports 7 non-finite SEs (SD on boundary), R finite and huge. R's objective at Julia's point is 2.9e-6 below Julia's reported value. |
| nb2_phylo | 7 | R non-converged, abs coef 13.7 | -1762.194856 / -1762.194856 | **Same optimum, both at the SD boundary.** SD-formula coefficients about -249 (Julia) and -235 (R), i.e. SD about 1e-100 or smaller; log-lik 2.5e-7. R reports convergence code 1 (singular convergence), Julia converged with 7 non-finite SEs. All 44 evaluations within 1e-6 of the best; 1 optimum. The nonconvergence is R's optimiser on a flat boundary, not a different maximum. |
| nb2_phylo | 19 | abs coef 3.24 | -1678.239111 / -1678.239111 | Same: 1 optimum, SD level 1e-5 (R) versus 1e-7, ll diff 8.6e-9, abs SD diff 2.7e-5, 1 Julia non-finite SE. |
| nb2_phylo | 27 | abs coef 2.55 | -1841.612603 / -1841.612603 | Same: 1 optimum, SD level 8e-6 versus 2e-7, ll diff 9.6e-9, abs SD 1.1e-5, 2 Julia non-finite SEs. |
| nb2_phylo | 58 | abs coef 2.19, ll 1.3e-6 | -1796.923297 / -1796.923296 | Same: 1 optimum (44 of 44 within 1e-6), SD level 3e-10 versus 2e-8; Julia 1.3e-6 above R, R's objective at Julia's point 1.5e-6 below Julia's reported value. |
| nb2_phylo | 55 | R-SE 0.65, abs coef 7.7, ll 1.1e-3, abs SD 5.3e-2 | -1637.420775 / -1637.421869 | **Julia stopped at a lower point; R's is higher by 1.1e-3.** R's objective at Julia's estimate reproduces Julia's reported value (-1637.421869385 against -1637.421869386), so it is the same likelihood. R's default fit and 33 of 44 evaluations reach -1637.420775; 3 distinct optima at 1e-4. R's re-optimisation from Julia's estimate does not move (gradient 2.3e-5 in R's objective), so Julia's point is at least a near-stationary point on a very flat slope-SD direction (R's slope-SD minimum 3.1e-3, Julia's 2.3e-6; slope-SD coefficients -4.4 and -1.4 in R, -12.1 and -0.9 in Julia, R SEs 12 and 7, Julia SEs 2.5e3 and 6.1e2). The deficit is 1.1e-3 log-lik. This is the only seed of the 1,200 where Julia's optimum is not as good as R's by more than 2e-6. |
| gauss_relmat | 6 | abs coef 5.80 | -251.481140 / -251.481139 | Same optimum, boundary: 44 of 44 within 1e-6, 1 optimum. Slope-SD level 3e-11 (R) versus 2e-16 (Julia), abs SD 1.6e-8, ll diff 7.8e-7 (Julia higher; R's objective at Julia's point is 7.8e-7 below Julia's reported value). R-SE units 2.8e-4. |

Summary of the nine: 8 are the same maximum with a boundary SD coordinate that the likelihood does not identify (large absolute coefficient difference of a log-SD, tiny R-SE difference, log-likelihood within 1.7e-6); 1 (nb2_phylo seed 55) is Julia stopping 1.1e-3 below a better point on a flat ridge; one of the 8 (nb2_phylo seed 7) additionally has R reporting non-convergence. At five of the boundary seeds (nb2_relmat 133, 261; nb2_animal 63; nb2_phylo 58; gauss_relmat 6) Julia's reported log-likelihood exceeds R's objective evaluated at the same point by 0.8e-6 to 3.3e-6; at nb2_phylo 7, 19 and 27 the two agree to 1.3e-7 or better. I did not trace the five.

Seeds with a boundary flag but no disagreement flag: nb2_phylo seed 31 (a coefficient below -6 on both sides, all differences below the thresholds).

## What this does not cover

* Julia-side restarts were not run; every diagnosis rests on R-side evaluation and re-optimisation. In this run no seed is attributed to R stopping at a worse maximum.
* The gap between Julia's reported log-likelihood and R's objective at Julia's point (0.8e-6 to 3.3e-6 at boundary seeds) was not traced.
* Only default fits (ML, default starts) at the optimum are compared. REML, other kernels, other sample sizes and starting-value sensitivity of Julia are not covered. One design per route.
* One platform and Julia version (Linux x86, Julia 1.10.12); no replicate on Julia 1.12.
* Datasets for q3 and q4 use the same generator and seed scheme as `multiseed2`, so seeds 1 to 10 are the same datasets as there (the 10-seed results are included in these 100).

## Files

`routes.R` (route table, shared), `fixtures_q34.jl`, `fixtures_scale300.jl` (copy of `../scale300/fixtures.jl`), `julia_run.jl`, `make_data_nb2phylo.R`, `r_run.R`, `run_ext.sh` (driver), `compare.R`, `diagnose.R`, `diag_run.sh`, `tree.nwk`, `coords.csv`; outputs `per_seed.csv` (1,200 rows), `per_parameter.csv` (every parameter, both sides), `summary_distribution.csv`, `nonconverged_seeds.csv`, `flagged_seeds.csv`, `diagnosis.csv`, `layout_check.txt`, `manifest_julia1.10_totoro.toml`, `logs/`.

Rerun on Totoro (after copying `DRM.jl` from `git archive e5ae24539` and `jenv`/`depot` as described above): `bash run_ext.sh $HOME/drm_ext_20261108/out 55 10; SC_OUT=$HOME/drm_ext_20261108/out Rscript compare.R; bash diag_run.sh`.

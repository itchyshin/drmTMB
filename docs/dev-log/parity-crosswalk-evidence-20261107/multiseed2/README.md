# Multi-seed R versus Julia agreement, second set of routes

Reader: whoever weighs whether the single-dataset agreement for the routes added after the first multi-seed study (`../multiseed/`) generalises across simulated datasets. This is agreement at the maximum-likelihood optimum only. It is not coverage, calibration or recovery. No tolerance was widened, no verdict or matrix file was changed, and no Julia source was edited.

Julia: DRModels.jl worktree `ms2-jl`, branch `claude/multiseed2-evidence-20261108`, from `origin/claude/labelled-ordinary-poisson-nb2-20261108` (tip `04581709d`). Native R: drmTMB 0.8.1 (the `origin/main` temporary library used by the earlier evidence). ML on both sides. `JULIA_NUM_THREADS=2`, `OPENBLAS_NUM_THREADS=1`, one process at a time. Whole study about 35 minutes (120 Julia fits, 1684 s including compilation; 120 R fits, 79 s); the estimate before starting was 20 to 60 minutes on the busy machine.

Ten new datasets per route (seeds 1 to 10), 12 routes, 120 comparisons, plus 10 refusal checks.

## Routes

| Route | Model (R syntax) | Data size | Fixture |
| --- | --- | --- | --- |
| `gauss_q3` | Gaussian `(1 + x + z \| id)`, `sigma ~ 1`, one SD formula (`~ w`) per coefficient, unstructured rho (3) | 150 x 10 | `fixtures_q34.jl`, `G-q3q4` generator |
| `gauss_q4` | same with `u` added, 4 coefficient SDs, 6 correlations | 150 x 10 | same |
| `gamma_same` | Gamma `(1 \| g) + (0 + x \| g)`, `sigma ~ 1`, `sd(g, coef = "(Intercept)") ~ w1`, `sd(g, coef = "x") ~ w2` | 40 x 10 | `tf_case` of `test_gamma_nb2_twofield_sd.jl` |
| `nb2_same` | same, NB2 | 40 x 10 | same |
| `nb2_corr` | NB2 `(1 + x \| g)`, two coefficient SDs, one correlation | 40 x 14 | same |
| `gauss_phylo` | Gaussian `phylo(1 + x \| id)`, `sigma ~ 1`, two coefficient SDs | 64 x 16 | `make_data_struct.R` (wave-2 generator, rho 0) |
| `gauss_spatial` | Gaussian `spatial(1 + x \| id)` (coordinate kernel), same SDs | 64 x 16 | same |
| `gauss_lphylo` | Gaussian `phylo(1 + x \| p \| id)`, labelled rho (true 0.5) | 64 x 16 | wave-3 generator |
| `gauss_lspatial` | Gaussian `spatial(1 + x \| p \| id)`, labelled rho | 64 x 16 | same |
| `gauss_joint` | Gaussian `y ~ x + (1 \| id)`, `sigma ~ 1 + (1 \| id)`, `sd(id) ~ w`, `sd(id, sigma) ~ z` (same group) | 30 ids, n 600 | `fixtures_joint.jl` |
| `nb2_joint` | same, NB2 | 30 ids, n 600 | same |
| `nb2_jcross` | NB2 same mean model, `sigma ~ 1 + (1 \| g)`, `sd(g, sigma) ~ z` (crossed) | 30 x 24, n 600 | same |

Choices to note. "Gamma ordinary two-field q2" is `gamma_same` (independent intercept and slope fields); the correlated Gamma `(1 + x | g)` is refused on both sides (below). "Joint mu+sigma SD" uses the same-group shape for Gaussian and NB2 (the shape with single-dataset evidence for both) and also the crossed shape for NB2; Gamma joint was not asked for (its crossed shape has a known two-maximum case in `wave2-joint-sigma`). The Gaussian phylo and spatial routes use the Gaussian response only. Phylo and spatial keep the fixed 64-tip height-2 tree and 8 x 8 grid and redraw z1, latent fields and noise.

## Where R refuses a shape

Gamma ordinary correlated `(1 + x | g)` with two SD formulas (`gamma_corr`, 10 seeds): R stops with "Only independent Gamma `mu` random intercepts and slopes are implemented in this slice", Julia stops with "Gamma random-effect SD regression requires exactly one SD target". Both refuse on all 10 seeds, so there is nothing to compare (outputs: `julia/gamma_corr_s*_ll.csv`, `r/gamma_corr_s*_ll.csv`). No other route was refused by either side.

## Results (Julia minus R; worst case over 10 seeds)

All 120 fits converged on both sides (R convergence code 0 and a positive-definite Hessian in R for all 120; Julia `converged = true` for all 120).

| Route | Max coef diff (R-SE units) | Max coef diff (abs) | Max per-level SD rel. diff | Max abs log-lik diff | Max abs rho diff | Max SE rel. diff |
| --- | --- | --- | --- | --- | --- | --- |
| gauss_q3 | 8.6e-10 (s9) | 8.8e-11 | 8.0e-11 (s2) | 2.1e-10 (s3) | 7.2e-11 | 3.3e-7 (s4) |
| gauss_q4 | 1.1e-9 (s10) | 1.5e-10 | 7.1e-11 (s9) | 1.5e-10 (s9) | 7.2e-11 | 3.2e-7 (s6) |
| gamma_same | 7.6e-7 (s7) | 2.0e-7 | 4.1e-7 (s5) | 5.1e-10 (s6) | n/a | 2.1e-6 (s5) |
| nb2_same | 6.3e-7 (s7) | 1.2e-6 | 2.6e-6 (s7) | 4.1e-11 (s6) | n/a | 2.5e-5 (s3) |
| nb2_corr | 1.1e-6 (s5) | 2.2e-7 | 5.1e-7 (s5) | 7.8e-11 (s6) | 1.9e-7 | 3.9e-6 (s8) |
| gauss_phylo | 6.9e-10 (s3) | 6.8e-11 | 1.2e-10 (s3) | 6.8e-11 (s10) | n/a | 3.3e-7 (s5) |
| gauss_spatial | 9.1e-10 (s6) | 1.3e-10 | 1.7e-10 (s5) | 6.6e-11 (s9) | n/a | 5.2e-7 (s9) |
| gauss_lphylo | 1.5e-9 (s6) | 2.8e-10 | 3.9e-10 (s6) | 7.0e-11 (s4) | 1.9e-10 | 3.3e-7 (s2) |
| gauss_lspatial, 9 seeds (not s2) | 1.8e-9 | 5.9e-10 | 4.5e-9 | 5.9e-9 is s2; others below 1e-10 | 1.7e-10 | 3.4e-7 |
| **gauss_lspatial, seed 2** | 9.9e-4 | **7.56** | 4.5e-9 | 5.9e-9 | 1.7e-10 | Inf |
| gauss_joint | 4.7e-7 (s7) | 5.7e-8 | 7.0e-8 (s1) | 3.6e-10 (s10) | n/a | 2.5e-5 (s10) |
| nb2_joint | 6.1e-7 (s6) | 3.2e-7 | 3.2e-7 (s6) | 3.4e-11 (s4) | n/a | 1.6e-6 (s8) |
| nb2_jcross | 5.5e-7 (s9) | 1.9e-5 | 3.7e-5 (s5) | 7.7e-10 (s8) | n/a | 2.7e-6 (s5) |

Per-seed rows: `raw_per_seed.csv`; every parameter: `raw_per_parameter.csv`; machine-readable table: `summary.csv`. "SD rel. diff" is the maximum over groups and coefficient fields of |SD_julia - SD_R| / SD_R with SD = exp(b0 + b1 z) from each fit's SD-formula coefficients at the observed predictor values. "rho diff" is the maximum over correlations of the difference between the two fits' correlations (unit-lower-triangular theta mapped to correlations for q3 and q4; `0.999999 tanh(eta)` for the labelled and `nb2_corr` routes). "R-SE units" divides the coefficient difference by R's standard error. Parameters are compared by position. `compare2.R` decodes each Julia block label (the hex `sdtarget_` names) and stops unless it matches R's parameter name at the same index and the SD target's group matches the route spec; all 120 fits pass. It cannot tell which coefficient (intercept or slope) an SD pair belongs to, because R's names carry no coefficient label; before 2026-11-08 the hex labels had been decoded by hand for seed 1 only.

## The one flagged seed: Gaussian labelled spatial, seed 2

Seven of the eight parameters agree to 4e-9 or better (mean, sigma and the four SD-formula coefficients), the log-likelihood differs by 5.9e-9 (Julia higher), and the per-level SDs agree to 4.5e-9. The correlation parameter `eta_cor` differs: Julia 19.15, R 11.59 (difference 7.56). That coordinate is on the atanh scale, and both fits sit at the correlation bound rho = 0.999999 (the labelled routes bound rho as `0.999999 tanh(eta)`): rho is 0.999999000 in Julia and 0.999998999828 in R, a difference of 1.7e-10. So both fits are at the rho = 1 boundary and the atanh coordinate is not identified there. R reports an SE of about 7600 for it; Julia reports Inf (with its "Hessian numerically singular" warning). The comparison script did not flag it on the R-SE criterion (9.9e-4, just under 1e-3), only on the absolute difference.

Diagnosis (`oracle_lspatial_s02.R`, `oracle_lspatial_s02.csv`, `oracle_lspatial_s02_rho_profile.csv`): an independent dense Gaussian marginal (1024 x 1024 covariance built from the grid kernel, both coefficient fields and the cross-field term, no package code) gives -824.685736753 at Julia's estimate (reported -824.685736753) and -824.685736756 at R's estimate (R reported -824.685736759). The profile in eta from the same oracle is flat to 1e-9 beyond eta about 11 (-824.685741 at eta 8, -824.685737 at eta 11.6 and 19.15), and it increases monotonically to the bound. Same likelihood, same rho at the bound, not a different local maximum. The other nine labelled spatial seeds have R eta_cor between 0.19 and 0.83 and agree to 1.8e-9 R-SE units. Labelled phylo and `nb2_corr` have no seed near the bound (R eta_cor 0.14 to 0.87).

## Other notes

- `nb2_same` and `gauss_joint` reach SE relative differences of 2.5e-5 and `nb2_jcross` a coefficient difference of 1.9e-5 (SD rel. diff 3.7e-5, seed 5, in R-SE units 5.5e-7): all well inside optimiser noise on weakly identified slope-SD or sigma-SD coefficients; log-likelihoods agree to 8e-10.
- Julia prints its "Hessian numerically singular, pseudo-inverse" warning for `gauss_lspatial` seed 2 and for one `nb2_jcross` seed (rcond 5e-9); the estimates there still agree with R to 1e-6 R-SE units.
- Time: Julia fits take 0 to 3 s after the first fit in a process (first fit 15 to 117 s of compilation under the load of this session); R fits take 0.2 to 1.7 s.

## Starting-value check: Poisson spatial q2, seed 9 of the first study

The one known disagreement of `../multiseed/` (Poisson `spatial(1 + x | g)`, two coefficient SDs, seed 9, flat slope-SD boundary) was refitted from ten start vectors on each side (`startprobe/starts.csv`; `julia_starts.csv`, `r_starts.csv` hold the results). Each row is a start; theta is (mean intercept, mean slope, intercept-SD intercept, intercept-SD z0, slope-SD intercept, slope-SD z1). R was driven through its fitted TMB objective (`fit$obj`) with `nlminb`; Julia through a copy of its fitter evaluated into the DRModels module at run time with a hook to overwrite the initial theta (the Julia source file is untouched; see `startprobe/julia_probe.jl`).

| Start | Julia log-lik | Julia slope-SD coefficients | R log-lik | R slope-SD coefficients |
| --- | --- | --- | --- | --- |
| default | -1627.030079530 | -14.49, -0.448 | -1627.030079540 | -11.55, -0.148 |
| S1 | -1627.030079530 | -17.55, -1.83 | -1627.030079696 | -10.15, -0.039 |
| S2 | -1627.030079530 | -13.80, 0.099 | -1627.030079763 | -9.99, -0.296 |
| S3 | **-1627.030045394** | -20.18, -16.79 | -1627.030079660 | -12.25, -3.13 |
| S4 | -1627.030079531 | -14.38, -1.63 | -1627.030079774 | -10.18, -0.808 |
| S5 | -1627.030079534 | -12.00, 0.0 | -1627.030079534 | -12.00, 0.0 |
| S6 | -1627.030079530 | -14.49, -0.448 | -1627.030079530 | -14.49, -0.448 |
| S7 | -1627.030079540 | -11.55, -0.148 | -1627.030079540 | -11.55, -0.148 |
| S8 | -1627.030079530 | -14.38, -0.133 | -1627.030079738 | -10.12, 0.225 |
| S9 | -1627.030079530 | -21.67, -7.27 | -1627.030079767 | -9.99, -0.338 |
| S10 (restart at Julia's S3 stopping point) | -1627.030045394 | stays | -1627.030045577 | stays |

Mean and intercept-SD coefficients are the same on every start and both sides to the digits shown (0.426, 0.098, -1.022, 0.417). The log-likelihood is the same to 3e-10 only within Julia's stops from the default, S1, S2, S4, S6, S8 and S9 starts (span 1e-9; Julia's S5 and S7 stops are 4e-9 and 1.0e-8 away). R's own stops spread about 2.4e-7 (-1627.030079534 to -1627.030079774), R and Julia differ by up to 2.4e-7 on the same start (S4), and by 1.8e-7 at S10 (R -1627.030045577, Julia -1627.030045394). All stops are within 3.4e-5 of each other. The one exception to the Julia agreement is the S3 start, where Julia stops at -1627.030045394 (3.4e-5 lower) with a slope SD of up to 0.034 at some groups, and where `nlminb` started at that point also stays (R objective -1627.030045577, max gradient 9e-4). So the likelihood is flat in the slope-SD direction; both optimisers can stop on the ridge, and Julia's stopping point on it is not a different maximum, but I have not shown it is the same maximum either: restarting either optimiser from there does not move it. The slope-SD coefficients are not identified (they wander over -9.99 to -21.7 and the implied slope SD stays below 1e-4 at nearly every group), which is exactly the first study's explanation: the two default fits differ in coefficients because the surface is flat, not in likelihood. Starts with Julia's default fit reproduce the earlier disagreement (-14.49 versus R's default -11.55) and every other start gives yet another pair of slope-SD coefficients, so the coefficient-level "disagreement" is a property of the boundary, not a Julia-versus-R difference.

## Not covered

Coverage, recovery, REML, other kernels or tree shapes, Gamma joint and Gamma correlated (refused), other families for the phylo, spatial and labelled routes (the earlier studies cover Poisson and NB2 on one dataset only), and starting-value sensitivity beyond the one probe above.

## Rerun

From this directory (paths in `run_all.sh` point at this session's scratchpad, edit `DRMJL`, `DRMTMB_LIB` and the `--project` path): `Rscript make_data_struct.R 1 10`; `./run_all.sh` (Julia then R for each route; log in `run.log`); `Rscript compare2.R`; `Rscript oracle_lspatial_s02.R`. Start probe: `cd startprobe`, `Rscript r_probe.R`, `julia --project=<test env> julia_probe.jl` (needs `../../multiseed/data/poisson_spatial_s09.csv`). `DRMJL` must point to a DRModels worktree, because the Gamma/NB2 fixture is read from `test/test_gamma_nb2_twofield_sd.jl`.

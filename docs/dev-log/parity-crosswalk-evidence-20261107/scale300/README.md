# Scale-300 R versus Julia agreement for the SD-regression routes

Reader: whoever decides whether the 10-seed agreement in `../multiseed/` and `../wave3-labelled-ordinary/` generalises. This is agreement of two implementations at the maximum-likelihood optimum. It is **not** a coverage, calibration or recovery claim; the Wald-coverage file is informational only. No verdict or matrix file was changed and no Julia source was edited. Nothing was pushed.

## What was run

* 300 datasets (seeds 1 to 300) per route, nine routes: Poisson animal q2, NB2 relmat q2, Gaussian ordinary q2, Gaussian animal q2, Poisson phylo q2, Poisson spatial q2, labelled-animal Poisson (`animal(1 + x | p | g, A)`), and labelled-ordinary Poisson and NB2 (Julia `(1 + x | p | g)` versus R unlabelled `(1 + x | g)`, because native R refuses the labelled form). Seeds 1 to 10 are the same datasets as the earlier folders. 2,700 pairs of fits.
* R-native (drmTMB 0.8.1, `origin/main` `6fc0910ed`, built with `--no-build-vignettes`, installed into a private library on Totoro; the shared 0.7.0 library was not touched) and Julia-native (DRModels 0.8.1, branch `claude/labelled-ordinary-poisson-nb2-20261108`, tip `04581709d`, shipped with `git archive`), run separately, one thread per worker (`OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`), 90 concurrent workers (cap 100; Totoro hard limit 150). No `engine = "julia"`. ML on both sides.
* Julia 1.10.12 via juliaup, fresh environment (`Pkg.develop` of the branch plus Distributions and DelimitedFiles; committed Manifest not used; the resolved manifest is `manifest_julia1.10_totoro.toml`). Optim 1.13.3, LineSearches 7.5.1 as on the Mac.
* Data: the five fixture routes are generated inside the Julia run (`fixtures.jl`, as in `multiseed`) and written to `data/`; R reads those files. Phylo, spatial and the two labelled-ordinary routes are generated in R (`make_data_ps.R`, `make_data_lord.R`) before either fit. Comparison is offline (`compare.R`).
* Reproduction before scaling (`pilot10_reproduction/`): seeds 1 to 10 of all routes through the same scripts. Julia log-likelihoods agree with the Mac numbers to 1.1e-9 (max over routes), R estimates to 1e-11 (R is deterministic), Julia coefficients to 4e-7 (optimiser tolerance; Julia 1.10/Linux versus 1.12/macOS), and the labelled-ordinary maxima (5.8e-6 R-SE) match `wave3`. The Poisson spatial seed 9 boundary case reproduced (Julia coefficients move by 0.84 on the flat boundary direction, as the earlier README describes).
* Runtime: **estimated about 5 minutes wall on 90 workers (pilot: 42 s for 10 seeds of all nine routes, dominated by Julia compilation of 12 to 30 s per process; far below the 3 hour line). Actual: 119 s wall** for the full 300 (R data, Julia, R, compare). A Julia 1.12.7 replicate took a further 126 s plus 36 s. No orphan processes remain.

## Results (Julia minus R, 300 seeds per route; `summary_distribution.csv`)

Differences are taken over seeds where both fits converged and returned a result. "R-SE units" divides each coefficient difference by R's SE (maximum over coefficients per seed); the distribution is over seeds. Per-level SD is exp(b0 + b1 z) from each fit's SD-formula coefficients, evaluated at the observed z values. Rho for the labelled routes is on the atanh scale in both fits and is included in the coefficient difference.

| route | seeds | both converged | R pdHess | coef diff / R-SE: median, p99, max | per-level SD rel diff: median, p99, max | abs ll diff: median, p99, max | abs rho diff: p99, max | seeds > 1e-3 R-SE | seeds ll diff > 1e-6 |
|---|---|---|---|---|---|---|---|---|---|
| poisson_animal | 300 | 300 | 300 | 1.7e-07 , 1.5e-06 , 1.7e-06 | 4.7e-08 , 6.5e-07 , 1.6e-06 | 2.8e-10 , 8.0e-09 , 1.2e-08 | n/a | 0 | 0 |
| nb2_relmat | 300 | 300 | 300 | 7.5e-07 , 3.6e-06 , 4.6e-04 | 5.2e-08 , 2.8e-06 , 2.5e+03 | 1.8e-10 , 6.7e-09 , 1.7e-06 | n/a | 0 | 1 |
| gauss_ord | 300 | 264 | 300 | 1.4e-10 , 7.4e-10 , 9.8e-10 | 1.4e-11 , 7.5e-11 , 1.1e-10 | 9.4e-11 , 2.0e-10 , 2.1e-10 | 5.5e-09, 5.9e-09 | 0 | 0 |
| gauss_animal | 300 | 300 | 300 | 2.2e-10 , 1.5e-09 , 2.0e-09 | 4.7e-11 , 4.8e-10 , 6.6e-10 | 4.5e-12 , 1.0e-11 , 1.1e-11 | n/a | 0 | 0 |
| poisson_phylo | 300 | 300 | 300 | 4.8e-07 , 8.5e-06 , 4.8e-04 | 2.1e-07 , 2.1e-04 , 1.5e+03 | 2.8e-10 , 4.2e-07 , 1.8e-06 | n/a | 0 | 1 |
| poisson_spatial | 300 | 300 | 297 | 5.0e-07 , 3.0e+00 , 1.2e+01 | 2.6e-07 , 1.5e+00 , 8.0e+00 | 2.1e-10 , 1.7e-01 , 1.0e+00 | n/a | 7 | 9 |
| poisson_labelled | 300 | 300 | 300 | 1.8e-07 , 1.8e-06 , 1.3e-04 | 3.8e-08 , 3.9e-07 , 2.6e-06 | 2.7e-10 , 3.9e-09 , 3.6e-08 | 1.2e-07, 3.0e-07 | 0 | 0 |
| lord_poisson | 300 | 300 | 300 | 3.5e-06 , 9.8e-06 , 2.0e-04 | 9.0e-08 , 1.3e-06 , 1.2e-05 | 3.4e-10 , 4.8e-09 , 1.5e-06 | 9.6e-07, 1.0e-06 | 0 | 1 |
| lord_nb2 | 300 | 298 | 300 | 2.9e-06 , 3.7e-04 , 5.5e-04 | 1.7e-07 , 2.2e-05 , 2.2e-04 | 1.2e-10 , 2.3e-06 , 6.3e-06 | 1.2e-06, 2.1e-06 | 0 | 12 |

All R fits returned convergence code 0; R had a positive-definite Hessian everywhere except 3 Poisson spatial seeds (seeds 20, 153, 253; 153 and 253 agree with Julia to under 1e-3 R-SE and were not flagged). `raw_per_seed.csv` has the 2,700 per-seed rows, `raw_per_parameter.csv` every parameter (estimates, SEs, differences, true values, coverage indicators), `flagged_seeds.csv` the 63 seeds that trip a triage flag (non-convergence or error, >1e-3 R-SE, or |log-lik diff| > 1e-6). Flags are for triage; no tolerance was applied to any verdict and none was widened.

**Headline.** Where both fits are at an interior optimum the two implementations agree to the optimiser tolerance: median differences are 1e-10 to 4e-6 R-SE units, and the 99th percentile stays at or below 1e-5 R-SE for poisson_animal, gauss_ord, gauss_animal, poisson_labelled and lord_poisson. The exceptions are all diagnosed below: boundary non-identification, R stopping at a lower local maximum, one Julia stop at a different local maximum, and Julia line-search failures.

## Every seed that disagrees, with diagnosis

Diagnosis tool: `diagnose.R` evaluates R's TMB objective at Julia's estimate (same likelihood), re-optimises from Julia's estimate and from R's, and runs 40 jittered R starts (`diagnosis.csv`). Julia has no public restart option and its source was not touched, so Julia-side restarts were not run; the R-side oracle is what supports each statement.

**Beyond 1e-3 R-SE units (7 seeds, all Poisson spatial).**

| seed | log-lik R / Julia | diagnosis |
|---|---|---|
| 88 | -1706.598 / -1706.567 | **R stopped at a lower local maximum.** R's polish from its own estimate does not move; the 40-start oracle and R's polish from Julia's estimate both reach Julia's value. 2 distinct optima. |
| 91 | -1895.386 / -1894.990 | Same: R lower by 0.40; Julia's point is the best of 4 distinct optima found. |
| 204 | -1695.538 / -1695.370 | Same: R lower by 0.17; 3 optima. |
| 211 | -1570.645 / -1570.393 | Same: R lower by 0.25; 2 optima. |
| 20 | -1645.4885 / -1645.4872 | R lower by 1.3e-3, R's Hessian not positive definite (gradient 2e-4), 5 optima; Julia's value is the best found. Near-flat region, R stopped early. |
| 147 | -1573.121 / -1574.140 | **Julia stopped at a lower, different local maximum.** R's point is best of 41 starts; R re-optimised from Julia's estimate does not move (gradient at Julia's point is about 3e-6), so Julia's point is a genuine stationary point, 1.02 log-lik lower. |
| 118 | -1775.35467 / -1775.35467 | Boundary non-identification: slope-SD per-level values 5.7e-6 to 1.1e-5 in R versus at most 2.9e-7 in Julia; log-lik difference 1.2e-8; R-SE units 1.1e-3 only because R's SE is huge. |

So in Poisson spatial, 5 of 300 datasets have R-native stopping short and 1 has Julia stopping at a worse optimum. This is a finding about optimiser robustness on this route, not about the likelihood: the likelihoods agree wherever evaluated (R's objective at Julia's estimate reproduces Julia's reported log-lik to about 1e-5 or better in all 27 diagnosed fits).

**Boundary non-identification (large absolute coefficient difference, tiny SE-unit difference, log-lik difference at most about 2e-6).** nb2_relmat seed 133, poisson_phylo seed 54, poisson_spatial seeds 157, 279, 282 (and 118 above). One SD coefficient is driven to a boundary where a per-level SD is about 1e-10 to 1e-7 (intercept SD at the z level in 133 and 54; slope SD at 2e-7 or smaller in 157, 279, 282). Both fits are at the same boundary at slightly different points (R: SD 7.8e-11 versus Julia 1.2e-7 in seed 54, and the like). These are the cases behind the p99 and max of the per-level SD relative difference (up to 2.5e3 for a quantity that is about zero). I did not widen anything; the SE-unit criterion does not flag them, the log-lik and SD columns do.

**Log-lik difference above 1e-6 with small coefficient difference (13 lord_nb2, 1 lord_poisson, 1 poisson_phylo, 1 nb2_relmat).** In every lord_poisson and lord_nb2 case the fitted correlation is at the boundary (R's rho is 1 to six decimals, R's SE of atanh(rho) is 4,100 to 5,800). Julia's log-likelihood is 1e-6 to 6e-6 below R's (Julia stopped slightly short on the flat ridge; R's gradient at Julia's point is up to 2e-3, and re-optimising from Julia's point moves it by at most 6e-6). Two of these are Julia non-converged flags (lord_nb2 seeds 232 and 276, with log-lik deficits 2.1e-6 and 1.7e-6). Cause: boundary non-identification of rho plus optimiser tolerance, not a different maximum. 15 of 600 labelled-ordinary fits have rho at the boundary.

**Julia line-search failure, Gaussian ordinary (36 of 300 seeds, no Julia result).** Julia 1.10.12 throws `AssertionError: isfinite(phi_c) && isfinite(dphi_c)` (`logs/julia110_gauss_ord_errors.txt`); R converges on all 36 with positive-definite Hessian. All 264 other seeds agree to 1e-9 R-SE units. The error is not specific to Julia 1.10: a second run on Julia 1.12.7 (`j112/`, different datasets for the five Julia-generated routes because the Julia 1.12.7 random stream differs from 1.10.12) had 26 of 300 Gaussian ordinary failures. On the Mac (Julia 1.12.6, macOS) seeds 24, 39 and 40 did fit (same data, identical md5). I did not trace the cause (platform or BLAS difference is a hypothesis, not tested). I did not modify Julia source. This is a robustness gap in Julia for the Gaussian ordinary SD-regression route and needs a Julia-side fix before the route can claim agreement on every seed.

## Julia 1.12.7 replicate (`j112/`)

Same scripts, Julia 1.12.7, own manifest (`depot112`). Phylo, spatial and labelled-ordinary data are identical to the main run; the five Julia-generated routes are new datasets. Results: no change in kind (Poisson spatial 6 seeds beyond 1e-3 R-SE, Gaussian ordinary 26 Julia errors, 13 lord_nb2 and 1 lord_poisson rho-boundary seeds, nb2_relmat none above the 1e-6 log-lik line). Summary in `j112/summary_distribution.csv`. R was re-run on the replicate's data (R results of the main run were not reused because the data differ).

## Wald coverage of the true values (informational, not the claim)

`coverage_informational.csv`: share of Wald 95 per cent intervals (estimate +/- 1.96 SE, SE finite and below 1000) containing the data-generating value, by parameter group and package. The two packages give the same coverage to about 0.005 wherever both have a usable SE, as expected from agreement. Values range 0.84 to 0.99 (Poisson spatial fixed effects 0.84, the lowest; rho on the boundary-prone labelled-ordinary routes 0.99; Gaussian animal and relmat fixed effects 0.91 to 0.92). Truth scale for sigma is log(sigma); the spatial and phylo truths are those of the generators and the spatial kernel is the generator's, so the spatial row may reflect a kernel mismatch rather than the package. I do not interpret these as calibration evidence (300 datasets, one design per route, and at most 600 to 1200 intervals per cell).

## Gaps

* Julia-side restarts and a dense oracle on the Julia side were not run (no public start option; no source edits). Diagnoses of "R stopped short" rest on R-side re-optimisation and R's objective evaluated at Julia's estimate.
* The Gaussian ordinary failures were not traced to a cause and no Julia fit exists for 36 seeds, so agreement for those datasets is untested.
* drmTMB was built from `origin/main` (0.8.1), not the Mac working tree (which is on 0.7.1 with other people's uncommitted changes).
* Totoro had load from others during the run (load average 15 to 58 at the end); timings are not benchmarks.
* Only the optimum of each default fit is compared; REML, other kernels, and starting-value sensitivity of Julia are not covered.

## Files

`run_campaign.sh` (driver; extended after the main run with the `JCH`, `JENV`, `JDEPOT`, `STAGES` variables, same stage logic), `setup_julia.sh`, `fixtures.jl`, `julia_run.jl`, `r_run.R`, `make_data_ps.R`, `make_data_lord.R`, `compare.R`, `diagnose.R`, `diag_run.sh`, `tree.nwk`, `coords.csv`, outputs listed above, `logs/`. Raw per-seed Julia and R fit files and datasets (about 130 MB) stay on Totoro in `~/drm_campaign_20261108/full300` and `full300_j112`, not committed.

Rerun from this directory on Totoro: `bash setup_julia.sh 1.10 jenv depot; bash run_campaign.sh $HOME/drm_campaign_20261108/full300 300 10 90; bash diag_run.sh`.

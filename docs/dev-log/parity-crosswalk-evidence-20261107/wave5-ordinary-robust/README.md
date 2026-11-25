# Wave 5: Gaussian ordinary q2 line-search failure, and Poisson spatial seed 147

Reader: whoever decides whether the Gaussian ordinary SD-regression route can claim agreement with native drmTMB on every simulated dataset. Julia branch `claude/ordinary-robust-linesearch-20261108` (commit `346968b2b`, on top of `04581709d`), pushed (later folded into PR #1266, tip `e5ae24539`). This is agreement of two implementations at the maximum-likelihood optimum, not a coverage claim.

## Root cause (36/300 seeds failing with `isfinite(phi_c) && isfinite(dphi_c)`)

Instrumenting the objective on a failing dataset (`logs/trace_nonfinite.txt`, seeds 24 and 39, Totoro Julia 1.10.12):

* The Gaussian ordinary q2 route is `_fit_gaussian_ordinary_q34_sd` (same code as q3/q4, q = 2). It runs L-BFGS with the default HagerZhang line search on an objective that is a sum over rows, so the gradient at the start has length of order 1e2 to 1e3, and the first L-BFGS step is the raw gradient (`InitialStatic`, step length 1).
* The first probe lands at log-sigma about -770 and SD coefficients of order 85. There `exp(-2 eta_sigma)` is about e^1540 and the group information matrix overflows: the code's non-PD check returns the 1e18 sentinel (finite value, zero AD gradient).
* The bisection then probes log-sigma about -386, then -193. At -193 the information matrix is finite but about 1e170 in size, so the Cholesky "succeeds" and the objective (or its AD gradient) is NaN. HagerZhang then hits `@assert isfinite(phi_c) && isfinite(dphi_c)` and the whole fit is lost.
* Whether a given dataset falls on the sentinel branch or on the NaN branch depends on floating-point detail (BLAS kernels), which is why the failing set differs between platforms and Julia versions although the data are identical: Totoro Linux/x86 1.10.12 36 of 300, 1.12.7 26 of 300 (different datasets, as the README of `../scale300` said); on the Mac (aarch64) the same data fit for seeds 24, 39, 40 but other seeds fail (below). There is no platform bug: it is a latent unguarded objective, exposed by chance.

## Fix

`_optimize_with_fallback` (already used by the binomial and beta-binomial SD routes) wraps the objective so that a probe with a non-finite value or non-finite AD gradient returns the 1e18 sentinel, only inside the optimiser, and retries with BackTracking if HagerZhang still asserts. It gained an `opts` keyword (default unchanged) so the route keeps its `x_abstol = NaN` option set. The reported log-likelihood, Hessian and convergence check still use the raw objective. Probes with a finite value and gradient are untouched, so fits that already worked follow exactly the same path.

Same unguarded pattern, same fix: the Gaussian structured animal/relmat q2 fitter (`_fit_structured_gaussian_q2_sd` in `gaussian_lss.jl`). q3/q4 are the same function as ordinary q2. Not changed: the REML-style structured LSS fitter at `gaussian_lss.jl` line 574 (different objective, no failure seen); not looked at further.

## 1. All 300 Gaussian ordinary seeds, both Julia versions, against R's stored estimates

Run on Totoro (60 single-thread workers, `OPENBLAS_NUM_THREADS=1`, native Julia, own directory `~/drm_fix_20261108`, no orphan processes; estimated minutes, actual about 2 minutes per batch of four configurations). Four configurations: the campaign datasets of the Julia 1.10.12 run (`d110`) and of the Julia 1.12.7 run (`d112`; the datasets differ), each fitted on Julia 1.10.12 and 1.12.7, each before and after the fix. R reference is the stored native drmTMB 0.8.1 fit for the same dataset (`../scale300/` raw files; fetched from Totoro `full300/r` and `full300_j112/r`). Coefficient difference in R-SE units is the maximum over the seven coefficients; rho is compared as `th/sqrt(1+th^2)` against `tanh(eta)` as in `compare.R`.

| Julia | dataset | failed before | failed after | converged after | max coef diff, R-SE units | max abs rho diff | max abs log-lik diff vs R | worst seeds |
|---|---|---|---|---|---|---|---|---|
| 1.10.12 | d110 | 36 | 0 | 300 | 9.8e-10 (seed 211) | 5.9e-09 (seed 118) | 2.1e-10 (seed 291) | 175, 267, 211 |
| 1.10.12 | d112 | 41 | 0 | 300 | 8.4e-10 (seed 7) | 6.6e-09 (seed 115) | 2.1e-10 (seed 299) | 216, 38, 7 |
| 1.12.7 | d110 | 33 | 0 | 300 | 9.8e-10 (seed 211) | 5.9e-09 (seed 118) | 2.1e-10 (seed 291) | 175, 267, 211 |
| 1.12.7 | d112 | 26 | 0 | 300 | 8.4e-10 (seed 7) | 6.6e-09 (seed 115) | 2.1e-10 (seed 299) | 216, 38, 7 |

Every seed (1200 fits) converges and agrees with R to optimiser tolerance; there is no remaining disagreement to diagnose (the largest difference in any quantity is 6.6e-9 in rho, and 1e-9 R-SE units in the coefficients). No tolerance was changed or applied. `agreement_per_seed.csv` has the 1200 rows; `baseline_failed_seeds.csv` lists the seeds that failed before the fix per configuration (the 36 and 26 of the original campaign are reproduced exactly; the 41 and 33 are the cross-version combinations).

Fits that already succeeded are bit-identical: over the 264 + 259 + 267 + 274 = 1064 previously successful fits, the maximum absolute log-likelihood difference between the unfixed and fixed source is exactly 0 (and the coefficient difference too; `agreement_per_seed.csv`, columns `abs_ll_fixed_minus_baseline`, `max_abs_par_fixed_minus_baseline`).

Sibling check: Gaussian animal (`gauss_animal`, 300 seeds, Julia 1.10.12 and 1.12.7, `ga_*` in the scripts): 0 failures before and after; all 600 fits bit-identical (log-likelihood and coefficients, difference exactly 0) between the unfixed and fixed source. There is no campaign failure for q3/q4 or relmat; their guard follows from sharing the fitter (q3/q4) or the same pattern (relmat/animal q2), and is covered by the existing tests below.

## 2. Regression tests (fail before, pass after)

`test/test_gaussian_ordinary_q2_linesearch.jl` (+ `test/fixtures/gaussian_ordinary_q2_linesearch/`, two campaign datasets, 63 KB each): (a) a toy objective that reproduces the failure mode platform-independently (finite sentinel region, then NaN region, raw gradient 141); the unguarded `Optim.optimize` throws `AssertionError`, `_optimize_with_fallback` reaches the minimum, and on a well-behaved objective guarded and unguarded runs coincide exactly; (b) seeds 179 and 244 of the campaign, fitted against stored native drmTMB 0.8.1 values (log-likelihood 1e-8, coefficients 1e-6 R-SE, rho 1e-7). Both datasets throw on the unguarded source on Totoro 1.10.12 and on the Mac under 1.10.12 and 1.12.6 (not on Totoro 1.12.7, where the failing set differs; see `baseline_failed_seeds.csv`).

* Before (source `04581709d`, fixture part only; the toy part errors earlier on the missing `opts` keyword): `AssertionError: isfinite(phi_c) && isfinite(dphi_c)` on Julia 1.12.6 and 1.10.12 (`logs/before_test.log`; the testset loop stops at seed 179, so 244 is shown failing by the baseline lists rather than by this log).
* After: all pass on Julia 1.12.6 and 1.10.12 (`logs/focused4_112.txt`, `logs/focused2_110.txt`).

`test/test_poisson_spatial_q2_second_start.jl` (+ `test/fixtures/poisson_spatial_q2_seed147/`, 30 KB): before, log-likelihood -1574.1400540 (`isapprox` to -1573.120983211433 fails) and coefficients 4.76 R-SE away; after, equal to R to 1e-6 and coefficients within 1e-5 R-SE (`logs/spatial_before_after.log`).

## 3. Existing tests rerun (Mac, Julia 1.12.6 and 1.10.12)

Passed on 1.12.6: `test_gaussian_ordinary_q2_sd`, `q3_q4_sd`, `test_gaussian_structured_q2_sd`, `test_q2_sd_simulate`, `test_q2_structured_vcov`, `test_betabinomial_sd_regression`, `test_poisson_animal_intercept_slope_sd`, `test_poisson_relmat_intercept_slope_sd`, `test_labelled_ordinary_q2_sd`, `test_labelled_rho_q2_sd`, `test_nb2_spatial_slope_sd_regression`, `test_spatial_coord_poisson`, `test_lss_group`, both new tests, and `test_skewnormal.jl` in the same process afterwards (each batch ends with it). On 1.10.12: the Gaussian files, `test_q2_sd_simulate`, `test_q2_structured_vcov`, both new tests and `test_skewnormal.jl`.

Failures that are **not** caused by this change (identical numbers on the unfixed source, same Julia 1.12.6 Mac; not touched): `test_binomial_animal_q2_sd.jl` (2 failures, 1 error: slope-SD recovery 0.587 and 0.584 against 0.45; bootstrap refit), `test_phylo_spatial_q2_sd.jl` ("phylo nb2" stderror not finite), `test_labelled_phylo_spatial_q2_sd.jl` (three failures: NB2 phylo rho, labelled spatial Poisson log-likelihood 600.956 against oracle 604.101 and rho). **Correction (2026-11-08, after triage):** these were not all pre-existing. `test_phylo_spatial_q2_sd` and `test_labelled_phylo_spatial_q2_sd` failed on Julia 1.12 only because their fixtures used `MersenneTwister` streams that differ between Julia 1.10 and 1.12 (datasets differ; verified by swapping datasets), plus one real latent bug (`scales[:cond_failed] = 1.0` into a `Dict{Symbol,Vector{Float64}}` threw `MethodError`); both are fixed on the wave-4 branch (#1266) with version-independent committed fixtures (`test/fixtures/q2_stable`). `test_binomial_animal_q2_sd.jl` fails on 1.12 on origin/main too (main has the file). The reconciled list is item 8 of `../PROPOSED-verdict-flips.md`.

## 4. Poisson spatial q2 seed 147

The default fit starts the SD coefficients at log 0.4 and log 0.25 and stops at a genuine stationary point 1.02 log-lik below the best (slope fixed effect 0.94 against 0.25). Starts with a larger intercept-SD (log 0.7 or log 1.0) reach the best optimum (-1573.12098 = R). Probe on all 300 spatial datasets from four starts (`logs/sp_probe_all.txt`, 1200 fits): the alternative starts reach a higher log-likelihood than the default on **only seed 147** (by 1.019); on 8 to 19 other seeds a single alternative start is worse than the default by up to 15 (so replacing the default start would regress). Best-of-two never reduces the log-likelihood.

Change: the spatial route (`kind === :spatial`, Poisson, labelled or not) optimises also from SD coefficients log 0.7 and keeps that result only if the objective improves by more than 1e-6. Result over the 300 campaign datasets (`spatial_second_start_per_seed.csv`, Julia 1.10.12): 299 bit-identical (log-likelihood and coefficients), seed 147 now -1573.12098 (diff to R -4e-10, coefficients 3.5e-7 R-SE). Cost: about double the fit time on the spatial route only. Limits: still a heuristic (a third mode could exist); NB2 spatial and the other structured routes were not given a second start and were not examined for the same issue. The seeds where R stopped short (88, 91, 204, 211) are R's issue and unchanged.

## Files

`agreement_per_seed.csv`, `baseline_failed_seeds.csv`, `spatial_second_start_per_seed.csv`, `scripts/` (`fit_ord.jl`, `runall.sh`, `analyse.py`, `fit_animal.jl`, `runall_animal.sh`, `fit_spatial.jl`, `runall_spatial.sh`, `sp_probe.jl` with a throwaway start-override hook that is not in the shipped source, `trace1.jl`), `logs/`. Raw per-seed fits stay on Totoro in `~/drm_fix_20261108` and the Mac scratchpad.

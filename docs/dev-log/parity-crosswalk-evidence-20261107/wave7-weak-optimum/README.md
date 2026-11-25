# Wave 7: three cases where Julia stopped at a worse optimum than native R (structured q2 Laplace fitters)

Reader: whoever decides whether the structured intercept-and-slope (q2) rows may say "Julia reaches the same maximum as native R" for NB2 phylo/animal/relmat and Binomial phylo/spatial/animal. This is agreement of two implementations at a maximum-likelihood optimum, plus a robustness fix. It is not a coverage, calibration or recovery claim. Nothing was merged, no PR was opened, nothing was pushed to main.

Julia branch: `claude/weak-optimum-20261108` (DRModels.jl, from `origin/claude/binomial-phylo-spatial-q2-20261108`, base tip `759e58e4f`; fix commit `d780fd460`). R reference: drmTMB 0.8.1 (private library), ML. Julia 1.10.12 (Mac Studio aarch64 for traces and the weak-probe family; Totoro x86-64 Linux for the 500-fit bit-identity check). Estimates before running: every run here took seconds to a few minutes (the Totoro 500-fit stage 51 s base and 56 s fix on 30 workers, one thread each); nothing approached the 3 hour line; no process of mine remains on either machine.

## Summary

| case | before | after | verdict |
|---|---|---|---|
| (a) NB2 phylo q2, scale_ext seed 55 | Julia -1637.42186939 (converged, slope-SD ridge at the boundary) vs R -1637.42077453, gap 1.09e-3 | -1637.42077453, gap 2.0e-11 (Mac and Totoro) | fixed |
| (b) Binomial phylo/spatial q2 weak probe (64 tips, 16 rows per tip, slope SD 0.33-0.49) | the original probe data was not retained (below). On a rebuilt family of 80 datasets, 2 are 0.0154 (phylo 5) and 0.0076 (spatial 28) below R, 3 fits unconverged | those two are within 1.6e-7 of R; 0 unconverged | fixed on the rebuilt family; the original dataset itself was not re-run |
| (c) Binomial animal q2, `test_stored_loglik_at_optimum` dataset on Julia 1.10 | -263.18497551, `converged = false`, 41 iterations | -263.18497616, `converged = true` | fixed (status); the boundary optimum itself was right |

Regression tests: `test/test_q2_weak_optimum.jl` (selection rule on a toy objective, start builder, case a, case c). No committed regression test for (b): the two datasets are ~35 KB each and live here under `data/`; the family is checked by the scripts in `scripts/case_b/`. Say so rather than imply otherwise.

## What was found (mechanism, with traces)

### Common mechanism for (a) and (b): two stationary points, the default start slides to the boundary one

With a weakly identified slope SD, the Laplace log-likelihood in the slope-SD coefficients has a flat ridge running to the boundary (SD to 0) and a separate interior stationary point that is slightly higher. L-BFGS from the single default start (SDs 0.4 and 0.25 or 0.3, `z1` coefficient 0) walks down the ridge, the gradient becomes tiny, the fit reports convergence, and the point is a genuine stationary point of the same likelihood.

Checks that it is the same likelihood and a real second optimum:
* (a) `scale_ext/diagnosis.csv` (R side): R's TMB objective at Julia's estimate is -1637.42186938546 (equal to Julia's reported value), R re-optimised from Julia's estimate stays (parameter move 0), and 33 of 44 jittered R starts reach the better value.
* (b) `scripts/case_b/case_b_ms.jl` and `results/case_b_r_objective_at_julia_estimate.log`: Julia's objective at R's estimate equals R's reported log-likelihood to 1e-8 (phylo 5: -644.72641569 against R -644.7264156910; spatial 28: -589.90139921 against -589.9013992083), and re-optimising from R's estimate stays (`gmax/n` 4e-7 and 7e-7).
* (a) trace (`scripts/case_a/case_a_trace.jl`): the slope-SD intercept coefficient slides from -1.4 to -12.5 over 56 iterations while the objective gain per step falls from 1.7e-3 to 1e-8 and `|g|` to 1e-5. The interior optimum (drmTMB coefficients -4.363 and -1.417) is reached from 3 of 6 start sets (SD pairs 0.7/0.7, 0.2/0.1, 0.4/0.05) and not from the other 3 (0.4/0.25 the default, 0.4/0.5, 1.0/1.0) (`scripts/case_a/case_a_ms.jl`).
* (b) starts with a constant slope SD (all of 8 tried, including 0.2/0.1, 0.7/0.7, 0.4/0.05, 0.1/0.03) end on the boundary ridge for phylo 5 and spatial 28. Starts whose slope SD varies strongly with `z1` (z1 coefficient of magnitude 2, intercept -1.5 or -3) reach R's optimum (`scripts/case_b/case_b_grid.jl`: phylo 5, starts (-1.5, -2) and (-3, -2); spatial 28, starts (-1.5, -2) and (-3, +2); the sign that works depends on the dataset).

### (c): inner-solve failure leaking the 1e18 sentinel into the gradient, then noise at rho = -1

Reproduced (`scripts/case_c/case_c.jl`, Julia 1.10.12): `ll = -263.18497551`, `converged = false`, 41 iterations. Trace (`case_c_trace.jl`): the slope-SD intercept coefficient (-9.0), its `z1` coefficient (-7.9) and atanh(rho) (-10.0, rho = -1 + 4e-9) all run to the boundary, then Optim stops with "line search failed" and `|g| = 2.8e20`. Probe (`case_c_probe.jl`): the `+h` finite-difference stencil on the slope `z1` coefficient returned 1e18, the repo's failed-inner-solve sentinel; every other stencil value is finite. Cause (`case_c_probe3.jl`): with rho near -1 the joint prior precision has entries 1.3e8 (condition number about 5e8), the inner Newton solve from a cold start takes steps of 1.5e-5, 7.7e-6, 5.8e-6 and then no trial lowers the objective (floating-point floor), and `accepted || return ..., false` turned that into a failure. The step size, the stencil and the cold versus warm start (`last_b`) decide whether a given probe fails, which is why only some stencils did.

After fixing that, the sentinel is gone but the fit is still unconverged (`gmax/n = 8.9e-6` against the 1e-6 test): the objective itself is noisy at about 3e-7 in this region (`case_c_noise.jl`, a line scan with cold starts; the `logdet` of a matrix of condition number 5e8 is accurate to about 5e-8 per term). L-BFGS restarts from the final point do not help (`case_c_rs.jl`, five restarts, `gmax/n` stays 6.8e-6 to 8.9e-6). The optimum is real: four starts reach -263.18498 to within 1e-6 (one reaches -263.9244, a worse stationary point, and one stops at -263.1855 unconverged; `case_c_ms.jl`), so the slope SD has collapsed to 0 in these data and the objective there is flat, not mis-evaluated. Honest reading: this was a convergence-status failure at a correct boundary optimum, not a worse optimum than R (there is no R value for this dataset; the "-243.95 on Julia 1.12" in the earlier note is a different dataset because the test fixture uses `MersenneTwister`, whose stream differs between Julia 1.10 and 1.12).

## What was changed (small, in three places)

1. `src/sparse_laplace_glmm.jl`: `_q2_boundary_restarts` and `_q2_alt_theta` (shared helper). Only when the first fit ends near the boundary (a fitted group SD below 0.05) or fails the outer gradient test, re-run L-BFGS from six alternative starts (constant SDs 0.2/0.1 and 0.7/0.7; slope SDs rising or falling by e^4 across the slope-SD predictor at two levels, four starts) and keep an alternative only on a clear objective gain (same convergence status: more than 1e-5 lower; alternative converged and incumbent not: no more than 1e-5 higher; alternative unconverged and incumbent converged: more than 1e-3 lower). A fit whose first optimum is kept is returned with the warm-start buffer exactly as the first run left it.
2. `src/negbinomial.jl` (`_fit_nb2_animal_intercept_slope_laplace`) and `src/binomial_sd_regression.jl` (`_fit_binomial_animal_q2_laplace`): one call to the helper before the final evaluation. NB2 serves animal, relmat, phylo and spatial; Binomial serves animal, phylo and spatial. The Poisson fitter was not touched (no Poisson failure was reported; its spatial route already has its own second start).
3. `src/binomial_sd_regression.jl` (`_binomial_animal_q2_mode`): a failed line search at a negligible Newton decrement (`0.5 * grad' * step <= 1e-9 * (1 + |f|)`) is convergence at the noise floor, not failure. This only turns a previous failure into a success.

Discarded alternatives, with reasons: bounding rho as `0.999999 * tanh` like the count routes (changes the parameterisation and every correlated Binomial fit, simulators and predict code read `tanh(theta)`); using one-sided differences when a stencil hits the sentinel (the one-sided error exceeds the 1e-6 gradient test on a flat valley); an unconditional multi-start (3 to 7 times the cost on every fit for no gain on interior fits).

## Before and after

### (a) NB2 phylo, scale_ext (`scripts/totoro/`, `results/totoro_nb2_base_vs_fix.csv`)

Totoro, Julia 1.10.12, the unchanged `scale_ext/julia_run.jl` on the same datasets (`~/drm_ext_20261108/out/data`), base source `759e58e4f` and fix source `d780fd460`, 30 workers, one thread each, run separately from R:

| route | seeds | log-lik bit-identical (string equal) | changed | unconverged base / fix |
|---|---|---|---|---|
| nb2_phylo | 100 | 99 | seed 55 | 0 / 0 |
| nb2_animal | 100 | 100 | none | 0 / 0 |
| nb2_relmat | 300 | 300 | none | 0 / 0 |

Seed 55: -1637.42186939 to -1637.42077453; R -1637.42077453 (difference 2.0e-11). The base run reproduces the campaign Julia log-likelihoods (tip `e5ae24539`) to 5e-12 on all 500 fits. Seeds still more than 1e-6 from R after the fix: nb2_animal 63, nb2_phylo 58, nb2_relmat 133, all boundary seeds listed in `scale_ext/README.md`, Julia at least as high as R in each; unchanged by this work. Mac (Julia 1.10.12 aarch64) on the 100 nb2_phylo datasets (`results/nb2_phylo_mac_*.csv`): 98 identical, seed 55 as above, seed 7 moves by 3.2e-6 towards R (and becomes converged); seed 7 is the data set with the slope SD at e^-240.

The trigger fires on about a quarter of the nb2_phylo seeds (a fitted group SD under 0.05; 26 of 100 harness fits). Cost: Totoro, all 500 fits, 1,052 s of summed fit time (including 30 s compilation per process) to 1,196 s (+14%); Mac, 100 nb2_phylo fits, 61 s to 180 s (the fix run shared the machine with a second Julia job).

### (b) Binomial phylo and spatial, rebuilt weak-probe family (`scripts/case_b/`, `results/case_b_weak_probe_base_vs_fix.csv`)

The original probe dataset (`refusal-probe/mk.R` earlier version, R -641.18394, Julia -641.29367) was overwritten; `mk.R` was edited to 30 rows per tip afterwards and a search over the plausible earlier settings did not reproduce -641.18394 (`wave6` README, honest gap). So this is a rebuilt family with the same shape: 64 tips, 16 Bernoulli rows per tip, beta (0.3, 0.5), intercept SD `0.9 exp(0.4 z0)`, slope SD `exp(log 0.4 - 0.2 z1)` (0.33 to 0.49), 40 datasets per kernel (`make_data.R`, `set.seed(20261200 + s)`), logit, ML, drmTMB 0.8.1 against Julia base and fix. All 80 R fits ran; R's Hessian is not positive definite on two (phylo 20, spatial 32), flagged in the CSV (`R_pd`).

| | base | fix |
|---|---|---|
| datasets more than 1e-3 below R | 2 (phylo 5: -0.0154; spatial 28: -0.0076) | 0 |
| datasets unconverged | 3 (phylo 5, phylo 32, spatial 19) | 0 |
| largest |Julia - R| among datasets within 1e-3 | 2.8e-6 | 1.6e-6 |
| datasets where Julia is more than 1e-3 above R | 3 (spatial 6, 10, 32) | 4 (adds spatial 29) |
| fix worse than base by more than 1e-6 | n/a | none |
| bit-identical to base | | 61 of 80 |

The datasets where Julia is above R are R's own local optima: R's objective at Julia's estimate equals Julia's log-likelihood (spatial 6: -616.25974206, spatial 10: -690.46114883, spatial 32: -487.19863005, spatial 29: -674.81857356; `results/case_b_r_objective_at_julia_estimate.log`) and R re-optimised from there stays. Spatial 29 is new with the fix: the heterogeneous start found an optimum 1.27 higher than both base Julia and R's default. This is a better fit, but it is also a new disagreement with native R in the other direction, which any parity claim must state.

Of the 19 datasets that differ from base, 15 differ by at most 4e-7 (boundary fits where the inner-solve change of item 3 alters a few probes: same optimum to the objective's noise); 4 differ by more: phylo 5, spatial 28 and spatial 29 (the cases above) and phylo 32 (+2.7e-6, base unconverged, fix converged).

Cost: summed Julia fit time over the 80 datasets 66 s to 202 s (about 3x), because every boundary fit runs up to six extra starts and most of this family sits at the boundary by design. Interior fits do not pay.

### (c) Binomial animal q2 (`scripts/case_c/`, `test/test_q2_weak_optimum.jl`)

| | log-lik | converged | iterations |
|---|---|---|---|
| base | -263.18497551 | false | 41 |
| inner-solve change only | -263.18497521 | false | 39 |
| fix (both changes) | -263.18497616 | true | 49 |

The three values agree to 1e-6, the objective noise at this boundary. The fixture is committed (`test/fixtures/weak_optimum/binomial_animal_q2_boundary*.tsv`, produced on Julia 1.10.12), so the test does not depend on the version's random stream.

## Tests

Julia 1.10.12 on the Mac, against the fix commit (`results/focused_tests_julia1.10.12_mac.log`; the logs of the first batch show `rc=1` for three files that failed only because the scratch environment lacked ForwardDiff and SpecialFunctions; they were re-run in the second batch):

| file | result |
|---|---|
| `test_q2_weak_optimum` (new) | pass |
| `test_binomial_animal_q2_sd` | pass |
| `test_binomial_phylo_spatial_q2_sd` | pass |
| `test_phylo_spatial_q2_sd` (NB2, Poisson, Gaussian phylo/spatial q2) | pass |
| `test_labelled_phylo_spatial_q2_sd` | pass |
| `test_nb2_animal_intercept_slope_sd` | pass |
| `test_nb2_relmat_intercept_slope_sd` | pass |
| `test_stored_loglik_at_optimum` | pass |
| `test_binomial_animal_slope_iid_sd_regression` | 14 pass, 1 error: `dense_binomial_animal_slope_iid_laplace did not converge`, raised by the test file's own dense oracle (line 43), not by package code; this file is on the earlier wave-1 list of files that fail identically on origin/main (`PROPOSED-verdict-flips.md`, item 8). Not re-run on the base source, so "pre-existing" rests on that list and on where the error is raised. |

The new test file fails on the base source for (a) (log-likelihood -1637.42186939 against the required R value) and (c) (`converged` false); the toy-objective testset cannot run on base (the helper does not exist). The (a) and (c) base values come from the runs reported above, not from running the test file on base (the file aborts on its first testset there). The full suite was not run.

## Not verified, unresolved

* (b): the exact original probe dataset. The rebuilt family reproduces the signature (boundary stop 0.0076 to 0.015 below R) twice in 80 datasets, not its numbers.
* Julia 1.12 was not run for any of this work. The Totoro 1.10.12 run is the only Linux evidence.
* Poisson structured q2 was not changed and not re-run; if a Poisson ridge failure exists it is untreated.
* No SE comparison was made after the change. The restarts change the reported optimum materially (more than 1e-5) for 4 of the 180 datasets here (nb2_phylo 55; Binomial phylo 5, spatial 28, spatial 29, the last moving away from R), so their SEs changed with them. SEs for fits whose first optimum is kept are computed as before. Only log-likelihoods were compared in this wave (the NB2 Mac harness ran with `se = false`; the Binomial runs computed SEs but they were not compared).
* `converged` for boundary fits still rests on the gradient test, which is noise-limited near rho = +-1 (item (c)); a fit can still end unconverged at a correct boundary optimum if none of the six restarts passes the test.
* The two weak-probe datasets where R's Hessian is not positive definite (phylo 20, spatial 32) were not excluded; the comparison is on log-likelihood only.

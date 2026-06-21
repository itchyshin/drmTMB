# AVONET phylogenetic Gaussian algorithm scout

This report times the current Julia route for a real AVONET/Hackett Gaussian phylogenetic mean model with 100 tree tips. It is a direct DRM.jl benchmark, not the R bridge timing table.

## Data and model

- AVONET CSV: `/Users/z3437171/Dropbox/Github Local/pigauto/avonet/AVONET3_BirdTree.csv`
- Hackett tree: `/var/folders/7x/ytfpq14s0v18frbm9v_w9f4c0000gq/T//RtmpZch3Eb/avonet-hackett-100-species-61f41e3ebeaa.tre`
- Tree tips: 100; total all-node tree states: 199; internal nodes: 99
- AVONET input rows: 9993; skipped incomplete rows: 0
- Exact zero-length tree branches rewritten to `1e-8` before parsing: 0
- Model: `log(Mass) ~ z(Hand-Wing.Index) + z(Beak.Length_Culmen) + phylo(1 | species)`, `sigma ~ 1`
- CPU policy: Julia threads = 4, BLAS threads = 1, Julia 1.10.0

## Timings

| route | g_tol | reps | median_s | min_s | converged | logLik | delta_from_best | beta_hand_wing | beta_beak | sigma | sd_phylo | finite_vcov | nll_for_profile |
|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---|---|
| auto_sparse_lbfgs | 1.000e-04 | 1 | 0.036 | 0.036 | yes | -72.689265 | 0.000e+00 | -0.084608 | 0.509540 | 0.000060 | 0.122183 | no | yes |

Reference row for coefficient deltas is the highest-logLik row (`g_tol = 1.000e-04`).

## Inference pipeline status

| target | current status | implication |
|---|---|---|
| Fixed-effect Wald SEs | Sparse L-BFGS stores the profiled sparse-GLS fixed-effect covariance block | Fixed-effect Wald intervals can be read from the `:mu` block; scale and variance-component Wald rows remain deliberately unset in this first slice. |
| Random-effect / variance-component profile CIs | Sparse L-BFGS attaches the full sparse objective closure | `profile_result(fit; parm = :resd)` is the high-value CI target; it is now mechanically possible and should be benchmarked next. |
| Parametric bootstrap | `bootstrap_result(fit; ...)` can reuse a fitted object and Gaussian refits now accept `algorithm` / `g_tol` controls | Bootstrap is the natural Julia speed-payoff path because refits are independent and threadable; use the benchmark below to check whether the advantage appears at the requested B. |

## Bootstrap benchmark

| B | mode | workers | algorithm | g_tol | ok | used | failed | elapsed_s | sec_per_used | total_time_s | message |
|---:|---|---:|---|---:|---|---:|---:|---:|---:|---:|---|
| 2 | serial | 1 | auto_sparse_lbfgs | 1.000e-04 | yes | 2 | 0 | 0.090 | 0.045 | 0.515 | bootstrap refits used explicit Gaussian algorithm/g_tol controls |
| 2 | threaded | 2 | auto_sparse_lbfgs | 1.000e-04 | yes | 2 | 0 | 0.066 | 0.033 | 0.066 | bootstrap refits used explicit Gaussian algorithm/g_tol controls |

Serial/threaded bootstrap speedup on the simulated-refit phase: 1.36x.

## Profile benchmark

| parm | mode | workers | ok | attempted | used | failed | elapsed_s | total_time_s | lower | upper | autodiff | message |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| resd | serial | 1 | yes | 1 | 1 | 0 | 0.691 | 0.698 | -2.234699 | -1.956926 | stored | profile_result completed |
| resd | threaded | 2 | yes | 1 | 1 | 0 | 0.099 | 0.099 | -2.234699 | -1.956926 | stored | profile_result completed |

Serial/threaded profile speedup on the endpoint phase: 6.99x.

## Reading

The single-fit sparse EM route and the sparse L-BFGS route both use the all-node tree representation, so the algorithm question is no longer dense tips versus sparse nodes. The current default for this cell is sparse profiled L-BFGS with exact Takahashi trace gradients and an attached objective for profile/bootstrap workflows. EM remains available as an explicit comparator and can be very fast at loose tolerance, but it does not carry the profile objective or covariance surface in this slice.

For applied users, the largest Julia advantage is likely the repeated-refit pipeline: profile likelihood or bootstrap confidence intervals for random-effect and variance-component targets. Fixed-effect Wald intervals should be cheap once information is available, but they are not where the dramatic speedup should be sold.

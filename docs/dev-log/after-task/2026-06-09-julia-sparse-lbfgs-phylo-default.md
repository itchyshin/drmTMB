# After-task: Julia phylo bridge Sparse L-BFGS default refresh

Date: 2026-06-09

## Summary

Refreshed the experimental `engine = "julia"` phylogenetic bridge after DRM.jl
promoted the Gaussian `phylo(1 | species, tree = tree)` mean cell to the
all-node sparse L-BFGS route. The R bridge now reports partial covariance
honestly: the mean fixed-effect covariance block can be finite, while residual
scale and variance-component covariance entries remain unavailable.

## Evidence

The fresh AVONET/Hackett bridge smoke wrote
`docs/dev-log/benchmarks/julia-bridge-phylo-gaussian-sparse-lbfgs-2026-06-09.csv`.
Warm-session rows were:

```text
n      tmb_s    julia_s   speedup   logLik_diff   tmb_conv   julia_conv   julia_uncertainty
100    1.162    0.126     9.22      5.07e-06      0          0            partial: mu
1000   2.555    0.430     5.94      1.01e-08      0          0            partial: mu
9993   61.113   17.222    3.55      1.16e-03      1          0            partial: mu
```

The direct DRM.jl AVONET/Hackett scout is faster than the R bridge because it
does not pay JuliaCall marshalling or R object reconstruction costs. Its current
default Sparse L-BFGS row was about `2.62 s`, converged cleanly, and attached the
sparse objective needed for future profile work.

## Interpretation

The old question was whether EM should be the default. The current answer is no:
loose EM is still a useful point-estimate comparator, but Sparse L-BFGS is the
better default because it gives the best smoke likelihood, a cleaner convergence
state, a mean fixed-effect covariance block, and a profile-ready objective.

The bridge still needs release-grade timing with cold/warm columns, memory
metadata, repeated-observation-per-species fixtures, and separate bridge
marshalling timing before this becomes a public performance claim.

# Fisher review — R3.1 exact marginal diagnostic

## Verdict

**No-go for G15.** R3.1 shows a material Laplace contribution alongside, not
instead of, the alpha--amplitude ridge observed in R2 and R3.

At the interior point, native Laplace is 0.4065 negative-log-likelihood units
below 9-node quadrature; the remaining 7-to-9 refinement is 0.0220. At the
ridge point, the discrepancy is 0.0735 with a 0.000136 refinement. The first
value is not an exact numerical error estimate, but is materially larger than
its retained refinement. The second is resolved at this precision.

The narrow comparison is structurally valid: both OU rates and both field SDs
are mapped fixed in the native objective; its optimized intercepts are used by
an independent six-tip stationary-OU quadrature. Its three-tip size cannot
measure error in the 128-tip R2 fits or allocate the failed recovery chiefly
to Laplace rather than likelihood geometry.

## Next decision-bearing diagnostic

Propose R3.2, only after approval: time a converged exact small-tree
*relative-profile* grid, increase/interrogate quadrature beyond nine nodes at
the interior point, and test whether Laplace changes profile ordering or
flatness across rate and amplitude. Agreement would leave the ridge as the
primary explanation; disagreement requires an estimator repair or a bounded
approximation claim before alpha recovery is reconsidered.

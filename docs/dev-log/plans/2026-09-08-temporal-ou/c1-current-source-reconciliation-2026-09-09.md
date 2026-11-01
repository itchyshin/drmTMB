# C1 AR1 current-source reconciliation

The historical AR1 C1 pilot was run at source `eafb56a`. Its seed
`2026091002` returned a non-positive-definite Hessian and an objective below
the later independent dense marginal calculation. That evidence could not be
carried forward as a current-source likelihood result.

The later AR1 transition calculation uses an algebraically equivalent but
numerically stable transition SD. At current source, a five-repeat replay of
seed `2026091002` is deterministic: residual SD `0.000224`, persistence
`0.378`, positive-definite Hessian, and finite covariance. Its objective
`618.883549080730` agrees with the independent dense marginal objective
`618.883549144532` at the boundary grid to about `6e-8`. A full five-seed
current-source recheck of `2026091001`--`2026091005` has 5/5 finite covariance
and Wald interval sets. The historical non-PD result was therefore numerical,
not an alternative lower ML solution.

This repair does not remove the inferential boundary. In a disjoint
current-source batch, seed `2026091101` selects residual SD `0.000338`, has
unavailable covariance and a non-positive-definite Hessian, and has persistence
`0.189`, far from the AR1 correlation boundary. Its independent dense marginal
profile is flat from residual SD `1e-7` through `1e-4` (difference below
`6e-9`) and rises by `0.00575` at residual SD `0.1`. The free dense fits settle
between `0.000322` and `0.000380`, all about `6e-8` above the boundary grid.
This is a real residual-variance boundary in the stated C1 model.

The two current-source five-seed batches have 9 available interval sets among
10. That bounded result is not a coverage estimate and cannot decide whether
the proposed 1,000-replicate campaign would meet its 0.99 availability target.
It does show that current full-Hessian Wald inference needs a revised,
explicitly authorized boundary policy before it can be qualified for OU.

Evidence is retained in
`simulation-artifacts/2026-09-09-temporal-ar1-c1-current-source-recheck/` and
`simulation-artifacts/2026-09-09-temporal-ar1-c1-current-boundary/`.

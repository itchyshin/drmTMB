# Arc 1 `mc-0438` feasibility stop

This is an Arc 1 target-level feasibility probe, not a capability promotion.

`mc-0438` is the ordinary ML/Laplace `poisson()` location route with exactly
one pair-level `phylo_interaction(1 | plant:pollinator)` intercept.  Its direct
target is `sd:mu:phylo_interaction(1 | plant:pollinator)` on the positive SD
scale.  The live source at execution was
`c8e04258d9d550384b037b1e2a91734c22aaaab5`.

The two retained attempts use 64 pair-level random-effect groups (`8 * 8`) at
8 and 20 observations per pair. Both converge, but both profile receipts have
`profile_boundary = TRUE` and nonfinite endpoints, so neither produces the
required finite two-sided interval. These feasibility fits deliberately use
`se = FALSE`; Hessian diagnostics were not requested and `pdHess` is therefore
recorded as unavailable rather than interpreted as a rung-specific failure.
The nonfinite intervals alone stop Totoro replication, a profile-ready
expansion, and any `interval_feasible` ledger transition.

The denominator is intentionally the number of pair-level latent effects,
`n_plant * n_pollinator`, rather than either marginal clade count.  This makes
the design explicit without pretending that a successful pair-level profile
has been demonstrated.

The old Lane-B receipts cannot be reused: their adapter/source SHA predates
the reconciled `origin/main` head.  The source-bound receipts in this directory
are the retained failure record for the current head.

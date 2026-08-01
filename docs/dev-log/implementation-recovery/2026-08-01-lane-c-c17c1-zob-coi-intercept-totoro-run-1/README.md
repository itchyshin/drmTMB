# C17-C1 Totoro recovery run 1: retained runner-order blocker

Source commit: `26f6dc05d7ddb24a38a94fa36c13e3255c30133e`.

This authenticated 12-fit run evaluated the frozen `M = 16, 32, 64` ladder
and seeds `2026081701:2026081704` for the exact complete-response ML model

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))
```

All twelve fits returned convergence code zero, `pdHess = TRUE`, gradients at
or below `0.01`, interior SD estimates, and mode correlations above `0.45`.
At `M = 64`, every fixed-effect, log-`sigma`, relative-SD, and boundary-only
`lme4::glmer()` comparator gate passed. The largest comparator difference was
`1.30e-05`.

The predeclared verdict is nevertheless **`BLOCKED_POINT_RECOVERY`** because
seed `2026081702` had only one observed zero in one group, below the required
minimum of two; the other three M=64 attempts passed the support gate.

Post-run inspection found a deterministic runner defect rather than an
estimator failure: `factor(paste0("g", 1:M))` silently ordered group levels
lexicographically (`g1`, `g10`, ...), so frozen random effects were assigned in
a different order from the intended sequential group definition. Run 1 is
retained unchanged. The repaired runner declares `levels = paste0("g", 1:M)`
before generating data, still generates exactly once per `(M, seed)`, performs
no support-conditioned resampling, and requires an independently authenticated
run 2 before any promotion.

This run is neither interval nor coverage evidence and changes no ledger row.

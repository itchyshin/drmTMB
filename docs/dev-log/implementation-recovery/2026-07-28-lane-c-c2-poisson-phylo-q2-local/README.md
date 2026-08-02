# Lane C C2 local point-recovery receipt

This receipt is for exactly one internal route:

```r
count ~ x + phylo(1 + x | p | species, tree = tree)
```

with ordinary `poisson()`. It is neither interval nor coverage evidence and it
does not alter the capability ledger or dashboard.

## Frozen fixture

- Three planned local attempts, seeds `2026072811:2026072813`, with a 64-tip
  balanced ultrametric tree and eight observations per tip.
- `x` is centred within species and globally scaled. The joint field is
  `t(chol(K)) %*% Z %*% chol(Sigma)` with `tau = (0.60, 0.50)`, `rho = 0.50`,
  fixed effects `(1.00, 0.35)`, and Poisson responses on the log-mean scale.
- `raw-attempts.tsv` retains each valid fit, its source and runner identity,
  software versions, DGP/tree digests, warnings, diagnostics, estimates, and
  elapsed time. `iid-dgp-control.tsv` is a separate `K = I` DGP control, not a
  fourth estimator attempt.
- `initial-runner-error/` preserves the first invalid invocation, which used
  `tree = sim$tree` rather than the required named formula object. The runner
  was corrected before the planned model fits were launched; the DGP, seeds,
  tolerances, and rule were unchanged.
- `SOURCE-MANIFEST.sha256` binds the exact candidate R, C++, test, and runner
  sources used by the retained run.

## Predeclared decision rule

`PASS_POINT_RECOVERY_LOCAL` requires all three planned attempts to fit without
error with `convergence == 0`, `pdHess == TRUE`, finite non-boundary estimates,
`abs(rho_hat) < 0.95`, mean fixed-effect error at most 0.20, mean SD relative
error at most 40%, and mean correlation error at most 0.25. Any other result
is `BLOCKED_LOCAL_FIXTURE`; attempts are never silently replaced or omitted.

## Result

The three retained fits and the separate IID DGP control passed. This is local
technical point-recovery evidence for C0-07 only. It does not support spatial,
animal, relmat, zero-inflated, ordinary-RE, q4, interval, profile, bootstrap,
coverage, association, or public-capability claims.

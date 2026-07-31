# Lane C C1 local point-recovery receipt

This receipt is for exactly one internal route:

```r
count ~ x + phylo(1 + x | p | species, tree = tree)
```

with ordinary `nbinom2()` and fixed-effect `sigma ~ 1`. It is neither an
interval nor coverage result, and it does not alter the capability ledger or
dashboard.

## Frozen fixture

- Three planned and retained local attempts, seeds `2026072801:2026072803`.
- A fixed balanced 64-tip ultrametric tree, eight observations per tip, and a
  predictor centred within species then globally scaled.
- The joint phylogenetic field is drawn from
  `t(chol(K)) %*% Z %*% chol(Sigma)`, with `tau = (0.60, 0.50)` and
  `rho = 0.50`; NB2 `sigma = 0.50`; fixed effects `(1.00, 0.35)`.
- `raw-attempts.tsv` retains every attempt, including source base SHA, DGP and
  reporting scales, warnings, convergence, Hessian, outer-gradient, boundary,
  estimates, and elapsed time. The `-dirty` source suffix correctly records
  that the C1 code was tested before its scoped commit was created.
- `SOURCE-MANIFEST.sha256` independently binds the exact R, C++, focused-test,
  and runner content used for the candidate; this closes the otherwise
  insufficient base-SHA-plus-dirty provenance.
- `iid-dgp-control.tsv` is a separate deterministic `K = I` control of the
  same joint `Sigma` draw. It passed and is explicitly not a fourth estimator
  attempt or part of the three-attempt recovery denominator.

## Predeclared decision rule

`PASS_POINT_RECOVERY_LOCAL` requires all three attempts retained, fit without
error, `convergence == 0`, `pdHess == TRUE`, finite non-boundary estimates,
`abs(rho_hat) < 0.95`, and three-attempt mean deviations no greater than 0.20
for each fixed effect, 40% relative error for `sigma` and both `tau`s, and
0.25 absolute error for `rho`. Any other result is
`BLOCKED_LOCAL_FIXTURE`; attempts are never replaced or omitted.

## Result

All three attempts passed the fit-quality conditions and the retained means
meet the frozen rule (`summary.tsv`: `PASS_POINT_RECOVERY_LOCAL`). This is
technical local point-recovery evidence for C0-04 only. It does **not** support
the four other count-q2 candidates or any interval, profile, bootstrap,
coverage, association, or public-capability claim.

# Fixed-kappa mesh/SPDE field-scale recovery gate

## Decision

**BLOCKED_POINT_RECOVERY_GATE.** The mesh/SPDE implementation remains a
fixed-kappa, Gaussian-`mu`, intercept-only **local-fit** capability.  This
receipt does not support a `point_fit_recovery` claim.  In particular, it does
not support intervals, coverage, a projected marginal-SD interpretation, or
range inference.

## Frozen estimand and gate

The fitted parameter is the raw GMRF field scale `s` in
`omega ~ N(0, s^2 Q(kappa)^-1)`, with `kappa = 5e-5` fixed and
`s_truth = 1e-4`.  Before execution, the V2 runner required, at every sample
size, all 50 attempts to converge with `pdHess = TRUE`, absolute relative bias
at most 0.15, and log-scale RMSE at most 0.30.  The complete runner receipt is
in `simulation-artifacts/2026-08-02-mesh-spde-field-scale-recovery-v2/`.

## Totoro result

The 150-attempt Totoro receipt is complete (`run_status = COMPLETE`), records
the source SHA, runner checksum, host, platform, R version, fixed parameters,
and append-per-attempt policy.  All fits converged with `pdHess = TRUE` and no
retained error.  The `n = 64` rung nevertheless failed the frozen RMSE gate:

| n | usable | relative bias | log-scale RMSE | rung decision |
| ---: | ---: | ---: | ---: | --- |
| 64 | 50/50 | -0.0899 | 1.5490 | fail |
| 128 | 50/50 | -0.0077 | 0.1608 | pass |
| 256 | 50/50 | -0.0192 | 0.1249 | pass |

One `n = 64` fitted scale was `2.08e-09` (seed `2026180325`) despite a clean
optimizer status and Hessian, which is sufficient to make the unconditional
log-scale recovery result fail.  It must not be dropped after the fact.

## Independent controls

The test suite includes an independently calculated dense Gaussian marginal
likelihood for `V = sigma^2 I + s^2 A Q^-1 A^T`; it agrees with the TMB
objective in the mesh contract test.  A separate fixed-domain, paired
mesh-resolution control retained 50 data seeds and 100 fits (coarse and fine
meshes).  Every fit converged with `pdHess = TRUE`; the maximum absolute paired
log-scale difference was 0.04409.  Its raw receipt is in
`simulation-artifacts/2026-08-02-mesh-spde-resolution-sensitivity/`.  That
control rules out an obvious coarse-versus-fine mesh discrepancy in this
setting, but it does not repair the failed `n = 64` recovery rung.

## Next gate

Keep the public article and capability boundary at local fit.  A new,
predeclared recovery-design decision is required before another campaign:
either justify a narrower deployment domain that excludes `n = 64`, or change
the estimator/model design and rerun an independent multi-seed ladder.  Neither
action is authorized by this receipt.

# Fixed-kappa mesh field-scale recovery V3 adjudication

## Decision

**PASS_POINT_RECOVERY_GATE.** The exact univariate Gaussian `mu` mesh
intercept earns `point_fit_recovery` for the two tested fixed-domain designs at
`n = 128` and `n = 256`. The retained `n = 64` V2 failure remains the lower
tested boundary. This decision does not claim a universal `n >= 128` floor.

## Model and estimand

The fitted model is

\[
y = X\beta + A_{st}\omega + \epsilon, \qquad
\omega \sim N\{0, s^2 Q(\kappa_0)^{-1}\}, \qquad
\epsilon \sim N(0, \sigma^2 I).
\]

The estimand is the raw GMRF covariance-scale multiplier `s`, with fixed
`kappa = 5e-5`, `s_truth = 1e-4`, residual `sigma = 0.25`, locations uniform
in a 100-km square, and the frozen mesh recipe. It is not a fitted range or a
uniform projected marginal standard deviation.

## Confirmatory Totoro result

The current-source receipt at
`simulation-artifacts/2026-08-02-mesh-spde-field-scale-recovery-v3/` records
100 fresh attempts from clean source
`1e48e8d80a7267354ae7b5a58adfec2dd67b2a21`.

| n | usable | relative bias (95% MC interval) | log-scale RMSE (95% MC upper bound) | decision |
| ---: | ---: | ---: | ---: | --- |
| 128 | 50/50 | -0.0301 (-0.0657, 0.0056) | 0.1444 (0.1799) | pass |
| 256 | 50/50 | -0.0096 (-0.0375, 0.0182) | 0.1009 (0.1173) | pass |

All 100 fits had convergence code zero, `pdHess = TRUE`, a finite positive
field-scale estimate, a finite objective, maximum absolute gradient below
`1e-3`, no warning, and no near-zero estimate. Estimates ranged from
`6.50e-5` to `1.22e-4`; maximum gradients ranged from `1.27e-12` to
`2.56e-4`. The bias intervals remain within the frozen `[-0.15, 0.15]` gate,
and both RMSE upper bounds remain below 0.30.

## Authentication and review

The receipt stores the source SHA, runner/helper/design SHA-256 values, key
source blobs and SHA-256 values, compiled DLL checksum, dependency versions,
raw/summary/gate checksums, and hashes of the retained V2 receipt. Design and
raw files contain the same 100 `(n_site, replicate, seed)` rows. The heartbeat
contains 100 paired `STARTED`/`COMPLETE` records.

Curie independently reproduced the hashes, row alignment, diagnostics, bias,
and RMSE summaries and returned GO. Fisher returned PROMOTE for this exact
`point_fit_recovery` claim. The first proposed V3 ledger at source
`50770c579` is inadmissible because its smoke reused two promotion seeds; that
launch was stopped, the entire ledger was excluded, and the valid campaign
used a wholly fresh replacement ledger.

## Boundary retained

V2 retained its cleanly optimized near-zero `n = 64` estimate and failed its
predeclared log-RMSE gate. V3 does not erase that result. The package may claim
point-estimate recovery only for the exact tested `n = 128` and `n = 256`
designs. Field-scale intervals, coverage, projected marginal-SD intervals,
range estimation, other `kappa` values, mesh slopes, non-Gaussian or bivariate
mesh models, anisotropy, barriers, replicated fields, and spatiotemporal
fields remain unearned.


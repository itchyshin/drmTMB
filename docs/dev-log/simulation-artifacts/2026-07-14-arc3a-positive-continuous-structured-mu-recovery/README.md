# Arc 3a positive-continuous structured-`mu` recovery

## Final Arc 3a disposition

This directory preserves the primary 6,000-fit campaign and its mixed frozen
verdict. It must not be rewritten as a three-cell PASS. A separate fresh
2,400-fit phylogenetic addendum used a predeclared design-conditioned GLS
oracle and structured-field projection gates; both phylogenetic routes passed.
Together, the two studies support all three new Arc 3a cells at
`point_fit_recovery`. See
`../2026-07-14-arc3a-phylo-recovery-addendum/README.md`.

## Result

The frozen Totoro certification completed all 6,000 scheduled fits: 400
replicates for each of five fit routes at `M = 16, 32, 64`. All 6,000 fits
returned, converged with optimizer code zero, supported analysis, and had a
positive-definite Hessian. No attempt was replaced or removed.

The certification verdict is mixed and the frozen gates are retained:

- lognormal × `relmat()` passes and reaches `point_fit_recovery` for both
  equivalent `K` and `Q = solve(K)` representations;
- the existing Gamma × `relmat()` comparator passes and remains
  `point_fit_recovery`;
- Gamma × `phylo()` and lognormal × `phylo()` remain `implemented` because
  their final fixed-intercept RMSEs, `0.1930` and `0.1934`, exceed the
  predeclared `0.12` threshold;
- no interval, coverage, inference-ready, or supported claim follows.

All other final-rung scalar targets pass their frozen bias and RMSE gates. At
`M = 64`, slope RMSE is about `0.010`, residual-scale coefficient RMSE about
`0.020`, and structured-SD RMSE `0.0471` for Gamma-phylo and `0.0481` for
lognormal-phylo. Median conditional-field correlations are about `0.986`.

## Why the phylogenetic intercept gate holds

The phylogenetic intercept result is sampling geometry, not an implementation
or optimization defect. For a balanced tree with `M = 2^L` tips, unit branch
increments, and package normalization to unit root-to-tip height,

\[
\operatorname{Var}(\bar b)
=
\tau^2\frac{1-1/M}{\log_2 M}.
\]

With `tau = 0.5`, `sigma = 0.35`, and 20 observations per tip, the known-
covariance fixed-intercept scale is approximately

\[
\operatorname{SD}(\hat\beta_0)
=
\sqrt{0.25\frac{1-1/M}{\log_2 M}+
      \frac{0.35^2}{20M}}.
\]

This gives `0.2429`, `0.2205`, and `0.2028` for `M = 16, 32, 64`, closely
matching the observed Gamma RMSEs `0.2368`, `0.2208`, `0.1930` and lognormal
RMSEs `0.2525`, `0.2152`, `0.1934`. The field mean therefore shrinks only as
`tau / sqrt(log2(M))`; the predeclared `0.12` threshold cannot be reached at
the tested ladder even with known covariance and negligible observation
noise. The correct action is to preserve the HOLD rather than weaken the gate
after seeing the result.

Source-level review found no double scaling, covariance-orientation error,
family mismatch, extractor error, or optimization pathology. K/Q parity also
passes all 1,200 paired replicates with zero tolerance failures; maximum
absolute discrepancies are `2.81e-10` for the objective, `6.43e-7` for fixed
effects, `4.51e-7` for the structured SD, and `6.71e-7` for the field.

## Provenance and files

The package and runner were installed from source commit
`0ef41a6904372de1790a63ecbf233758221d52ff`. A later one-line summarizer fix at
`5f324a6876c1c2665598774a2717e8ee06524f4b` disabled accidental names on a
logical vector; it did not alter the runner, raw fits, thresholds, or
statistics. The frozen runner SHA-256 is
`9ea11858676db1b205fce3bcdb426b937b6f6d22d022f4d7f0a6f8909a8630b3`.

The retained raw 6,000-row table remains local on Totoro at
`/home/snakagaw/drmtmb_work/arc3a-0ef41a69/runs/certification-0ef41a69-w40`.
Its SHA-256 is
`b303aab6781770e14be096b69c95b5da0e803f703cf3321baa91750a6465dcd3`.
Raw simulation output is not a GitHub Actions artifact. This directory stores
only compact, reviewable summaries:

- `summary-manifest.txt`: source, host, denominators, seeds, hashes, and R
  session;
- `failure-stage-counts.tsv`: every attempted fit by route and rung;
- `route-rung-summary.tsv`: convergence, Hessian, boundary, scale, field, and
  timing diagnostics;
- `target-recovery-summary.tsv`: scalar truth, bias, RMSE, MCSE, quantiles,
  attempted denominator, and conditional denominator;
- `kq-parity-summary.tsv`: paired `K`/`Q` representation checks;
- `route-decisions.tsv` and `cell-decisions.tsv`: frozen gate results.

## Scope boundary

This evidence covers native TMB, univariate ML, pure-`mu`, unlabelled q1
Gamma/lognormal structured intercepts for the exact phylogenetic and
relatedness geometries above. It does not cover slopes, labels/q2+, structured
`sigma`, joint `mu`/`sigma`, simultaneous providers, spatial/animal,
bivariate responses, REML, intervals, coverage, supported status, or Julia.

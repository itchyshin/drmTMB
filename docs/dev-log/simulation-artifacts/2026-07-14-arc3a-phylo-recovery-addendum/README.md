# Arc 3a phylogenetic recovery addendum

## Certified result

The fresh, predeclared phylogeny-only addendum completed 2,400/2,400 scheduled
fits: Gamma × `phylo()` and lognormal × `phylo()`, 400 replicates at each of
`M = 16, 32, 64`. Every fit returned, converged with optimizer code zero,
supported analysis, and had a positive-definite Hessian. There were no
boundary, gross-sigma, or other failure-stage events.

Both routes pass every retained recovery gate and the new design-adjusted
intercept oracle gate. The fail-closed combiner also authenticated the
immutable primary campaign's combined raw hash, Gamma-relatedness comparator,
and lognormal K/Q parity decisions before allowing either PASS. Therefore:

- Gamma × `phylo()` reaches `point_fit_recovery`;
- lognormal × `phylo()` reaches `point_fit_recovery`;
- lognormal × `relmat()` retains the primary campaign's
  `point_fit_recovery` decision; and
- Gamma × `relmat()` remains the unchanged positive comparator.

This completes the Arc 3a recovery goal for the three new cells without
relaxing or rewriting the original 6,000-fit decision. The original universal
`beta0` RMSE cap remains a documented HOLD for the balanced-tree primary
campaign; the addendum used fresh seeds and an independently predeclared
provider-geometry criterion.

## Intercept oracle result

For each replicate, the combiner reconstructed the realized `x`, tree field,
and the known-truth covariance. It evaluated the exact design-conditioned GLS
variance

\[
s_{0,M,r}^2
=
\left[
  \left(X_r^\top V_r^{-1}X_r\right)^{-1}
\right]_{00},
\qquad
V_r=\tau^2 Z_r C_M Z_r^\top+\sigma^2 I,
\]

plus the exact structured-field contribution to the fitted intercept. The
observed/design-oracle RMSE ratios are:

| Route | M=16 | M=32 | M=64 |
| --- | ---: | ---: | ---: |
| Gamma-phylo | 1.0013 | 0.9893 | 1.0294 |
| lognormal-phylo | 1.0085 | 0.9063 | 1.0225 |

All are inside the frozen `[0.80, 1.20]` band. Correlations between intercept
error and the exact structured projection range from `0.9969` to `0.9989`;
after subtracting that projection, residual RMSE ranges from `0.00986` to
`0.01939`, below the frozen `0.05` defect threshold. Final-rung intercept bias
is `0.00626` for Gamma and `0.00514` for lognormal. Every non-intercept bias,
RMSE, information-response, MCSE, and conditional-field gate also passes.

## Provenance

The runner and summarizer came from clean source commit
`d00da03713bcd0ace3dfcb236d7dd392ace27df2`. Its package-engine trees are
byte-identical to the primary implementation source `0ef41a69`:

- `R/`: `84e4d7111a3514f119e5386d9299044aa78a36b7`;
- `src/`: `5e385ee36b910f907c807c5d5c3767b34e22a373`.

The raw 2,400-row combined table remains local on Totoro at
`/home/snakagaw/drmtmb_work/arc3a-d00da037-runs/certification-w40-v2/summary/arc3a-phylo-addendum-combined-raw.tsv`.
Its SHA-256 is
`f4c3a0da9089cffd51a1703d2d2ba6526da5ca84db8ac26d9022926e6032d9cd`.
Raw output is not a GitHub Actions artifact.

The summary manifest records all compact hashes, the 40-worker count, R
4.5.3, Ubuntu 24.04.4, summary seed `2026071437`, exactly 2,000 bootstrap
resamples, and the four authenticated primary hashes. The predeclared plan and
runner record the fresh master seed `2026071431`.

## Scope boundary

This evidence covers native TMB, univariate ML, pure-`mu`, unlabelled q1
Gamma/lognormal phylogenetic intercepts over the exact balanced-tree DGP and
discrete information ladder above. It does not cover slopes, labels/q2+,
structured `sigma`, joint `mu`/`sigma`, simultaneous providers,
spatial/animal, bivariate responses, REML, intervals, coverage,
inference-ready, supported status, or Julia.

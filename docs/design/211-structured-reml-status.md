# Structured REML Status

## Purpose

This note records the native exact-Gaussian REML boundary for structured
random effects. It separates the implemented R/TMB routes from ML support,
non-Gaussian Laplace fits, direct DRM.jl evidence, R-to-Julia bridge evidence,
and HSquared/AI-REML terminology. The machine-readable authority is
`docs/dev-log/dashboard/estimator-surface-conformance.tsv` together with the
REML-specific scope boards under `docs/dev-log/dashboard/`.

## Arc 1a mean-side provider routes

For a univariate Gaussian response, native `REML = TRUE` now admits a pure
mean-side `spatial()`, `animal()`, or `relmat()` term when the structured shape
is either an unlabelled intercept or an independent intercept plus one numeric
slope. The residual scale must be constant: `sigma ~ 1`, with no ordinary or
structured sigma random effect. For example:

```r
bf(y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1)
bf(y ~ x + animal(1 + x | id, A = A), sigma ~ 1)
bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1)
```

For provider covariance matrix \(K_h\), the admitted one-slope model is

\[
y = X\beta + Zb_0 + D_x Zb_1 + \varepsilon,
\qquad
b_j \sim N(0, s_j^2 K_h),
\qquad
\varepsilon \sim N(0, \sigma^2 I),
\]

with independent \(b_0\) and \(b_1\). The fitted structured SD scale is
\(s_j\), so the latent-field covariance is \(s_j^2 K_h\). Node \(i\) has
marginal SD \(s_j\sqrt{K_{h,ii}}\), which equals \(s_j\) only when that
diagonal entry is one.

The implementation is checked against an independent dense restricted-
likelihood oracle and deterministic representation-parity fixtures. The Arc 1a
Totoro campaign used spatial coordinates, animal `A`, and relmat `K`.
`animal(Ainv = ...)`, pedigree input, and `relmat(Q = ...)` parity is
deterministic-fixture evidence, not a broad multi-seed claim.

Fresh Noether, Fisher, and Pat D-43 reviews support
`inference_ready_with_caveats` for exactly these discrete domains:

- `spatial()`: `n_each=20`, `M={8,16,32}`;
- `animal()`: `n_each=20`, the fixed `M=8` pedigree;
- `relmat()`: `n_each=20`, `M={8,16,32}`.

All represented profile targets passed the pre-specified small-sample coverage
floors, but coverage is not nominal-exact. Upper-tail miss asymmetry and
zero-lower-bound slope profiles remain material caveats. The evidence therefore
does not support continuous `M >= ...` claims or the `supported` tier.

## Arc 1b bivariate q2 location routes

Arc 1b-S1 admits one matching labelled fixed-covariance spatial q2
location-intercept block in bivariate Gaussian `mu1` and `mu2`. Arc 1b-S2R adds
one parallel supplied-relatedness cell:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
    mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  family = biv_gaussian(),
  data = data,
  REML = TRUE
)
```

Both endpoints must use the same label, group, supplied named covariance
matrix, and group-level ordering. Residual `sigma1`, `sigma2`, and `rho12` are
constant; response pairs are complete; weights are one; and the model has no
known `meta_V()` covariance, direct-SD formula, `corpair()` regression, or
additional random-effect layer. The route reuses drmTMB's existing native-TMB
exact-Gaussian REML engine and known-covariance structured prior.

The independent dense restricted-likelihood oracle agrees with the TMB
objective at the fitted optimum and two displaced parameter vectors. The
predeclared Totoro campaign retained 2,400 unique attempts; all 2,400 converged
with `pdHess = TRUE`, and every bias and RMSE gate passed. This evidence supports
only the two endpoint ledger rows at `point_fit_recovery`. It does not promote
intervals, coverage, `inference_ready_with_caveats`, or `supported` status.
The retained denominator, gates, matrix digests, and hashes are recorded in
`docs/dev-log/simulation-artifacts/2026-07-15-arc1b-s2r-relmat-q2-reml/README.md`.

The S2R cell does not admit `relmat(..., Q = Q)`, `animal()`, unlabelled,
unmatched, or differently ordered blocks, slopes, q4+, scale-side structure,
extra random effects, incomplete pairs, non-unit weights, non-Gaussian
families, or AI-REML. The spatial and supplied-`K` cells are separate exact
admissions; neither creates provider-wide bivariate REML support.

## Excluded routes

Arc 1a does not admit slope-only terms, factor slopes, labelled covariance
blocks, multiple slopes, `sigma ~ x`, sigma random effects, matched structured
`mu+sigma` terms, `phylo_interaction()`, bivariate routes beyond the separate
Arc 1b exact q2 cells, non-Gaussian families, estimated spatial range, sparse
fixed effects, response aggregation, engaged missing-data engines, or
direct-SD formulas. Fixed-effect profile
intervals are unavailable under REML because the mean coefficients are in the
integrated parameter block; use an ML fit when fixed-effect profiles are
required.

Other native REML routes, including existing phylogenetic and scale-side
routes, retain their row-specific evidence and boundaries. Arc 1a does not
borrow their claims, and they do not widen Arc 1a.

The pre-existing phylogenetic native REML routes include q1 mean-side with
retained interval evidence, sigma-only and matched univariate q2 point-fit
evidence, bivariate mean-side q2 point-fit evidence, and block-diagonal or
dense q4 recovery evidence. None of the latter rows inherits the q1 mean-side
interval tier, and none is HSquared AI-REML.

## Vocabulary boundary

Native REML here means the exact Gaussian restricted likelihood evaluated by
drmTMB's native TMB engine. It is not HSquared AI-REML. Direct DRM.jl evidence
and R-to-Julia bridge tests remain route-specific evidence; neither creates a
general bridge support claim.

This note does not promote native q4 beyond its row-specific recovery tier,
non-Gaussian REML, public optimizer controls, nominal-exact coverage, or
`supported` status.

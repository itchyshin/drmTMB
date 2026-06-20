# rho12 ~ x recovery coverage figure (Confidence Eye; Florence-approved)

**Date:** 2026-06-20 · **Author:** Ada (autonomous, pushes held) · **Gate:** Florence (approve, v5)

A coverage figure for the lead-novelty predictor-dependent residual correlation
`rho12 ~ x`, built from the already-verified 500-replicate recovery artifact
(`docs/dev-log/simulation-artifacts/2026-06-20-rho12-predictor-recovery/`, no
refit). It promotes the matrix "Bivariate residual correlation rho12" **visual**
cell and the `drmTMB-rho12-predictors-lead-novelty` finish-board visual cell to
covered.

## Figure

`rho12-recovery-coverage-eye-v5.png` (script `plot-rho12-recovery.R`, shared eye
helper `../_coverage-eye-helper.R`).

- Maintainer-requested **Confidence Eye** grammar: each cell's empirical Wald
  coverage is a vertical compatibility lens whose half-width follows the quadratic
  log-likelihood profile (widest at the coverage estimate, tapering to zero at
  +/- 1.96 cell MCSE), with a hollow point marker (circle = rho12 intercept,
  triangle = rho12 slope).
- Solid line = nominal 0.95; pale band = 0.93-0.97 reference region (not a
  pass/fail threshold). The eye is Monte-Carlo uncertainty on the coverage
  estimate, NOT model uncertainty.
- 4 cells: n in {300, 600} x {rho12 intercept, rho12 slope}. Coverage 0.920-0.964.

## Honest cell

The rho12 slope at n=300 sits at the lower band edge (coverage 0.920) with a wide
eye; it recovers to 0.956 at n=600. `ylim` is set to c(0.88, 1.0) so the full eye
is shown (un-clipped) -- a Florence v4->v5 fix.

## Grammar note

Per `docs/design/39-visualization-grammar.md`, simulation coverage plots default
to dots + MCSE bars + a target line, and use Confidence Eyes only "for a specific
reason". The maintainer's explicit request is that reason; the eye semantics
(MC compatibility interval for the coverage estimate) are stated in the figure.

## Florence review cycle

v3 (eye) -> v4 (subtitle fit) -> v5: fixed the n=300 slope eye clipping (expanded
ylim) and the legend key (hollow markers via show.legend=FALSE on the polygon).
Approved at v5.

## Boundary

Coverage display of already-verified fixed-effect rho12 ~ x recovery; native TMB,
complete data. Not a calibration proof. Random-effect rho12, profile/bootstrap
intervals, and the Julia bridge are separate cells.

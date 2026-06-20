# Non-Gaussian fixed-effect recovery coverage figure (Confidence Eye; Florence-approved)

**Date:** 2026-06-20 · **Author:** Ada (autonomous, pushes held) · **Gate:** Florence (approve, v3)

A coverage figure for non-Gaussian fixed-effect mu recovery across the six
implemented one-response families, built from the already-verified 500-replicate
recovery artifact
(`docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-fe-recovery-calibration/`,
no refit). It promotes the matrix "Non-Gaussian models" **visual** cell to covered.

## Figure

`nongaussian-recovery-coverage-eye-v3.png` (script `plot-nongaussian-recovery.R`,
shared eye helper `../_coverage-eye-helper.R`).

- Maintainer-requested **Confidence Eye** grammar (vertical compatibility lens =
  +/- 1.96 cell MCSE on the coverage estimate; hollow circle = mu intercept,
  triangle = mu slope), faceted by family (poisson, nbinom2, Gamma, lognormal,
  beta, student).
- Solid line = nominal 0.95; pale band = 0.93-0.97 reference region (not a
  pass/fail threshold). The eye is MC uncertainty on coverage, not model uncertainty.
- 24 cells: 6 families x n in {300, 600} x {intercept, slope}. Coverage 0.926-0.970.

## Honest cell

The student n=300 mu:x cell sits just below the band (coverage 0.926) and recovers
to 0.952 at n=600; its eye is fully visible (not clipped) within ylim c(0.90, 1.0).
This is the same off-cell that holds the non-Gaussian Wald cell at partial.

## Grammar note

Coverage plots use Confidence Eyes only "for a specific reason"
(`docs/design/39-visualization-grammar.md`); the maintainer's request is that
reason. Eye semantics are stated in the figure.

## Florence review

v1 (bars) -> eye-v2 -> eye-v3 (legend key fix). Approved at eye-v3.

## Boundary

Coverage display of already-verified fixed-effect mu recovery; native TMB, complete
data, six one-response families. Not a calibration proof. The Wald cell stays
partial (student small-n); random/structured effects, profile/bootstrap, and the
Julia bridge are separate cells.

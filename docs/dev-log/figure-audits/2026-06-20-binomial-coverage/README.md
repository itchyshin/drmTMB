# Binomial fixed-effect interval-coverage figure (Florence-approved)

**Date:** 2026-06-20 · **Author:** Ada (autonomous, pushes held) · **Gate:** Florence (approve)

A publication-grade coverage figure for the binomial fixed-effect family, built
from **already-banked, already-verified** 500-replicate calibration artifacts (no
refit). It is the evidence that promotes the matrix "Bernoulli/binomial response
family" **visual** cell `planned -> covered`.

## Figure

`binomial-coverage-eye-v5.png` (rendered by `plot-binomial-coverage-eye.R`, shared
eye helper `../_coverage-eye-helper.R`). The original error-bar version
(`binomial-coverage-wald-profile-v3.png`, committed 3f47503c) was superseded by
the maintainer-requested **Confidence Eye** grammar for figure-family consistency.

- Each cell's empirical coverage is a vertical **Confidence Eye**: a pale
  compatibility lens whose half-width follows the quadratic log-likelihood profile
  (widest at the coverage estimate, tapering to zero at +/- 1.96 cell MCSE), with a
  hollow point marker (circle = Intercept, triangle = Slope x; redundant
  colour+shape).
- Solid line = nominal 0.95; pale band = 0.93-0.97 **reference region (not a
  pass/fail threshold)**. The eye is Monte-Carlo uncertainty on coverage, not model
  uncertainty.
- Facets: columns = interval method (Wald | Profile); rows = response encoding
  (0/1 binary | cbind()).

## Data sources (no refit)

- Wald: `docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration/tables/binomial-fe-wald-coverage.csv`
  (12 cells, coverage 0.946-0.964).
- Profile: `docs/dev-log/simulation-artifacts/2026-06-20-binomial-fe-profile-calibration/tables/profile-coverage-summary.csv`
  (8 cells, coverage 0.930-0.972).
- Design grid (from `inst/sim/dgp/sim_dgp_binomial_fixed_effect.R`):
  encoding {binary, cbind} x n {240, 480} x trials-per-obs {8, 20} (cbind). The
  Wald cell IDs (1-6) and the profile sample sizes are related but distinct design
  grids and are not point-for-point comparable across the method columns.

## Florence review cycle

- **v2 -> revise**: x-axis label asymmetry (Wald "cell N" vs Profile "n = X")
  hurt comparability; colour was the sole coefficient discriminator; MCSE/band
  framing could mildly mislead.
- **v3 -> approve**: added redundant shape encoding (circle/triangle); caption now
  states the distinct design grids and non-comparability; subtitle says
  "cell-specific MCSE"; band labelled a reference region, not a threshold; title
  softened to "clusters around the nominal 0.95"; "no refit" added. The one weak
  cell (Profile / cbind / Slope / n=240, coverage 0.930, lower bar ~0.908) is shown
  honestly and unclipped.
- **eye-v5 -> approve** (2026-06-20, later): rebuilt with the maintainer-requested
  Confidence Eye grammar (shared helper) for figure-family consistency with the
  rho12 and non-Gaussian coverage figures; same data, same honest weak cell, legend
  key shows hollow markers. The error-bar v3 is superseded (preserved in git
  history at commit 3f47503c).

Not changed, with reasons: full relabel of Wald cells by `n` (the artifact CSVs
carry no reliable cell_id->n map; resolved via caption instead) and dpi (144 is
appropriate for audit/widget evidence, not a manuscript figure).

## Alt-text (Florence-supplied)

Dot-and-errorbar plot of empirical 95% interval coverage for binomial
fixed-effect models. Columns: Wald (six cells, design grid encoding x n x
trials-per-obs) and Profile (two cells, n in 240 and 480). Rows: 0/1 binary and
cbind() response encoding. Points are hollow circles (Intercept, blue) or hollow
triangles (Slope, orange), with error bars showing +/- 1.96 cell-specific Monte
Carlo standard errors. A solid line marks the nominal 0.95 target; a grey band
marks the 0.93-0.97 reference region. Almost all point estimates fall within the
band; one cell (Profile / cbind / Slope / n=240) sits at the lower band edge with
a wide error bar.

## Boundary

Visualises already-verified fixed-effect interval coverage (Wald + profile),
native TMB, complete data. It is a coverage display, not a calibration proof, and
does not extend to random/structured effects, bivariate/mixed responses, the Julia
bridge, or headline coverage. Promotes the binomial **visual** cell only.

# After-task report: Gaussian spatial q2 with coefficient SDs (batch 19)

Date: 2026-11-01. Lane: predictor-dependent random-effect SD regression.

## What was asked

Admit `spatial(1 + x | id, coords = coords)` and its labelled form
`spatial(1 + x | p | id, coords = coords)` for Gaussian models with one
`sd(id, level = "spatial", coef = ...)` formula per coefficient, if the
existing Gaussian q2 C++ branch can serve it without a new engine layer.

## What changed

The C++ branch needed no change. The Gaussian R builder admitted only
`animal`, `relmat` and `phylo` at three places, and `spatial` was missing from
each. Adding it makes the existing precision-based branch serve the coordinate
kernel (exponential, range equal to the median positive distance, diagonal
1 + 1e-6).

1. `R/drmTMB.R`, `allow_labelled_mu_q2_sd` in the univariate structured-term
   loop: lets the labelled intercept-plus-slope block through when SD formulas
   are present.
2. `R/drmTMB.R`, `allow_gaussian_structured_q2_sd`: admits two-coefficient
   spatial blocks and passes `allow_multiple_coefficients` to the parser.
3. `R/drmTMB.R`, `make_tmb_data()`: sets `has_sd_phylo_coef_model` and the
   per-row coefficient SD map for Gaussian spatial.

Item 3 matters most. With items 1 and 2 only, the unlabelled fit ran but the
template used the single-coefficient SD map, so the model was silently wrong
(a constant-SD spatial fit differed from the plain spatial fit by 0.17 in log
likelihood). The labelled fit stopped with a C++ error. The new tests caught
both.

## Tests

New file `tests/testthat/test-gaussian-spatial-q2-sd.R` (52 expectations):

* exact Gaussian marginal oracle, built independently from irregular
  coordinates, at the fitted parameters (1e-6 relative) and an independent
  dense L-BFGS-B optimum (1e-5 relative), for the unlabelled and labelled
  blocks, with coordinate rows and data rows shuffled;
* emulated-bug sensitivity (wrong kernel range, Gaussian instead of
  exponential kernel, coordinates read by position, swapped SD formulas,
  shared SD, missing slope loading, dropped or sign-flipped correlation), each
  moving the oracle NLL by more than 1e-3;
* constant-SD equivalence with the existing spatial q2 fit (1e-5);
* conditional simulation is reproducible; marginal simulation matches the
  dense covariance (variances within 25 percent, covariance pattern correlation
  above 0.9, 4000 draws);
* refusal checks with message patterns (one SD formula, duplicate coefficient,
  unknown selector, sigma endpoint, level mismatch, three coefficients,
  slope-only block, residual-scale spatial beside a q2 mu block).

Limits: the spatial kernel has a diagonal of 1 + 1e-6, so the non-unit-diagonal
check used for animal and relmat does not apply. No recovery or calibration
claim is made; an earlier sign check on a fitted SD slope was dropped for that
reason (24 sites did not recover it).

## Stale refusal pins

* `tests/testthat/test-gaussian-structured-q2-sd.R` (lines about 405-418) pins
  Gaussian spatial q2 as refused. That file carries evidence receipts, so it
  was not edited. It now fails on that one expectation and the coordinator must
  swap it (for example to a three-coefficient or sigma-endpoint spatial route)
  and refresh its receipts.
* `tests/testthat/test-phylo-gaussian.R` (not receipted) held a second pin on
  the same route. It was changed to a single SD formula with `coef = "x"`,
  which is still refused with the "requires one SD formula for each
  coefficient" message.

## Not covered

Docs and vignettes (`predictor-dependent-random-sd.Rmd`,
`implementation-map.Rmd`) and the evidence tables were not updated. No Julia
parity, mesh spatial, or REML route was examined. The evidence census needs a
row for the new test file.

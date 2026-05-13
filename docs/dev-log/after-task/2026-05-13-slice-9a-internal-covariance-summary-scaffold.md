# After Task: Slice 9A Internal Covariance-Summary Scaffold

## Goal

Start Slice 9 by adding a stable internal table for transformed random-effect
variance and covariance point estimates, without adding public interval support
yet.

## Implemented

`R/methods.R` now includes `random_effect_covariance_summaries()`, an internal
registry-backed helper. It walks fitted covariance-block registry pairs, matches
each pair to its two fitted random-effect SDs, and reports the correlation,
both variances, and the covariance:

```text
covariance = correlation * from_sd * to_sd
variance = sd^2
```

The table keeps the same identifying fields used by `corpairs()` so future
interval columns can join back to the same pair meaning. It also records the
fitted random-effect scale. Mean effects use the identity scale, while scale
effects use the `log(sigma)` scale.

`tests/testthat/test-covariance-block-registry.R` now checks this helper on the
hidden q=4 endpoint scaffold. The test covers all six fitted-like endpoint
pairs, a fully dormant q4 registry, and a mixed registry where only one pair is
fitted.

## Team Roles

Ada integrated the slice. Emmy checked the internal table shape. Gauss checked
that the covariance formula stays on the fitted random-effect scale. Curie kept
the tests focused on deterministic point estimates. Rose's boundary is that
this remains internal infrastructure, not public q4 or interval support.

## Scope Boundary

This is not interval support and not a public extractor. It does not add
uncertainty columns, residual `rho12` covariance summaries, or ordinary fitted
q4 support. For `sigma`, `sigma1`, and `sigma2`, the variance/covariance is for
random effects on `log(sigma)`, not residual variance itself.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-9a-internal-covariance-summary-scaffold.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 170 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|corpairs")'`: passed with 218 expectations, 0
  failures, 0 warnings, and 0 skips.
- `air format R/methods.R tests/testthat/test-covariance-block-registry.R
  ROADMAP.md docs/design/28-double-hierarchical-endpoint.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-9a-internal-covariance-summary-scaffold.md`:
  passed.
- `git diff --check`: passed.

## Next Actions

1. Add Slice 9B: attach direct profile-interval rows to this internal
   covariance summary table without using Wald intervals for nonlinear derived
   quantities.

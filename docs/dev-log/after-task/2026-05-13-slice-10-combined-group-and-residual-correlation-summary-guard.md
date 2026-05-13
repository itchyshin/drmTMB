# After Task: Slice 10 Combined Group And Residual Correlation Summary Guard

## Goal

Close the original Slice 10 target efficiently by strengthening the existing
combined bivariate regression. The model already fits separate `mu1`/`mu2` and
`sigma1`/`sigma2` group-level covariance blocks with predictor-dependent
residual `rho12 ~ x`; this slice checks that the new Slice 9 summary surface
reports that combined state correctly.

## Implemented

`tests/testthat/test-biv-gaussian.R` now checks that
`summary(fit)$covariance` contains exactly two group-level covariance rows for
the combined bivariate model: one `mean-mean` row for the `pm` block and one
`scale-scale` row for the `ps` block. The test checks the row classes, block
labels, distributional parameters, fitted scales, covariance point estimates,
and `covariance_conf.status`.

The same test now explicitly checks that residual `rho12` is absent from
`summary(fit)$covariance`, while `corpairs()` still reports it as a separate
residual row.

## Team Roles

Ada treated this as an integration guard rather than a duplicate feature.
Boole checked that the existing public syntax remains separate block labels,
`pm` and `ps`. Noether checked that summary covariance rows stay on the fitted
random-effect scale. Curie owns the focused regression test. Rose guarded the
claim: this is still pairwise public support, not a full q4 shared block.

## Scope Boundary

This slice does not add new formula grammar, TMB likelihood code, q > 2 public
support, or derived covariance intervals. It closes the already implemented
combined pairwise bivariate path against the newer `summary()` covariance
reporting surface.

## Files Changed

- `tests/testthat/test-biv-gaussian.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-10-combined-group-and-residual-correlation-summary-guard.md`

## Checks Run

- `air format tests/testthat/test-biv-gaussian.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-10-combined-group-and-residual-correlation-summary-guard.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|summary|corpairs")'`:
  passed with 638 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Next Actions

1. Run focused bivariate and summary/corpairs checks.
2. Commit and push this Slice 10 guard.
3. Move to the phylogenetic q4 state planning slice once the CI boundary is
   still green.

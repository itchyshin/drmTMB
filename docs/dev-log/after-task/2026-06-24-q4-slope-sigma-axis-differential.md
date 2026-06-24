# After Task: Q4 Slope Sigma-Axis Differential

## Goal

Test whether the q4 all-four one-slope Hessian blocker can be isolated by
contrasting the all-four baseline with reduced `mu1+mu2` and `sigma1+sigma2`
structured intercept-plus-slope axes, without promoting interval reliability,
coverage, REML, AI-REML, broad bridge support, public support, or broader q8
support.

## Current Result

The differential sidecar was regenerated after the endpoint-aware q>2 routing
slice opened the exact structured `mu1+mu2` intercept-plus-one-slope q4 location
cell. The sidecar now records 24 rows: two deterministic variants, four
structured providers, and three model axes (`all_four_slope`, `mu_axis_only`,
and `sigma_axis_only`).

- The all-four rows still reproduce Hessian-blocked lower-bound sigma geometry:
  all eight converged with `pdHess = FALSE`, nonfinite `sdr$cov.fixed`, and all
  four sigma-endpoint direct SD targets at the lower bound.
- The `mu_axis_only` rows now fit for `phylo()`, fixed-covariance `spatial()`,
  A-matrix `animal()`, and K-matrix `relmat()` with four direct SD targets,
  `pdHess = TRUE`, and finite positive `sdr$cov.fixed`. These are exact
  diagnostic native point-fit/extractor q4 location cells.
- The `sigma_axis_only` rows remain fit errors because partial
  location-scale structured blocks require matching labelled terms in `mu1`,
  `mu2`, `sigma1`, and `sigma2`.

## Implemented

The differential evidence lives in:

- `tools/run-structured-re-q4-slope-sigma-axis-differential.R`
- `docs/dev-log/dashboard/structured-re-q4-slope-sigma-axis-differential.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-sigma-axis-differential/structured-re-q4-slope-sigma-axis-differential-results.tsv`

The regenerated sidecar is now also reflected in:

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## Mathematical Contract

The all-four rows inherit the existing bivariate Gaussian q8-shaped model:
labelled structured random effects in `mu1`, `mu2`, `sigma1`, and `sigma2`,
each with an intercept and one `x` slope.

The `mu_axis_only` rows are exact q4 location cells with four members:
`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, and `mu2:x`. They do not include
structured scale endpoints.

The `sigma_axis_only` rows are deliberate unsupported-neighbour probes, not a
runtime support claim. They keep the partial location-scale guard visible.

## Checks Run

- `Rscript --vanilla tools/run-structured-re-q4-slope-sigma-axis-differential.R`
  passed and rewrote the differential artifact and dashboard sidecar.
- `air format R/drmTMB.R src/drmTMB.cpp tests/testthat/test-phylo-gaussian.R tests/testthat/test-spatial-gaussian.R tests/testthat/test-animal-relmat-gaussian.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 2,981 assertions.
- `python3 tools/validate-mission-control.py` passed and reported 24 structured
  RE q4 slope sigma-axis differential rows and 77 structured RE q-series cells.
- `git diff --check` passed.

## Tests Of The Tests

The conversion-contract test now requires the exact 2-variant by 4-provider by
3-axis cross-product, the all-four Hessian-blocked baseline, fitted
`mu_axis_only` rows with `pdHess = TRUE` and finite positive `cov.fixed`,
fit-error `sigma_axis_only` rows with the partial location-scale guard, linked
q-series support-cell boundaries, and diagnostic-only claim language. The
Python validator mirrors those checks for mission-control drift detection.

## Consistency Audit

The dashboard README and q-series completion map now state that the
`mu1+mu2` partial q4 location neighbours are legal diagnostic runtime cells, but
that the `sigma1+sigma2` partial location-scale neighbours remain unsupported.
The support-cell ledger records the four exact `mu1+mu2` q4 rows separately from
the slope-only q2 rows and the all-four q8-shaped rows.

## GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on. This slice records local
runtime and dashboard evidence and does not change public user support.

## What Did Not Go Smoothly

The first version of this differential was a pure guard differential: both
partial axes were fit errors. The endpoint-aware runtime slice deliberately
changed the `mu_axis_only` half of that evidence. That is the correct direction,
but it exposed stale q-series, dashboard, validator, and after-task language,
which all had to be reconciled against the regenerated sidecar.

## Team Learning

For q-series work, neighbouring cells must be probed as exact cells, not
inferred. The slope-only q2 location cell, the intercept-plus-slope q4 location
cell, and the all-four q8-shaped location-scale cell have different grammar,
runtime, extractor, and inference gates.

## Known Limitations

This is diagnostic native point-fit/extractor evidence for exact partial q4
location cells only. It does not implement partial location-scale structured
blocks, admit coverage denominators, claim q4 interval reliability, claim q4
interval coverage, promote q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared
AI-REML, non-Gaussian REML, broad bridge support, public optimizer controls,
DRAC execution, SR150 coverage readiness, or an Ayumi-facing reply.

## Next Actions

Add deterministic same-target fixture evidence for the exact `mu1+mu2`
intercept-plus-slope q4 location cells, then decide whether to open the
remaining partial location-scale `sigma1+sigma2` neighbour or continue to q4
location interval diagnostics.

# After Task: Q4 Slope Hessian Geometry Audit

## Goal

Explain why the q4 all-four one-slope direct-SD interval lane remains blocked
after the interval-stability probe, without promoting interval reliability,
coverage, REML, AI-REML, broad bridge support, public support, or broader q8
support.

## Implemented

Added `tools/run-structured-re-q4-slope-hessian-geometry.R` and the paired
dashboard/artifact TSVs:

- `docs/dev-log/dashboard/structured-re-q4-slope-hessian-geometry.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-hessian-geometry/structured-re-q4-slope-hessian-geometry-results.tsv`

The sidecar records one row for each `strong` / `more_levels` variant crossed
with `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`.

## Mathematical Contract

The diagnostic keeps the same bivariate Gaussian q4 all-four one-slope cells as
the preceding stability probe: labelled structured random effects in
`mu1`, `mu2`, `sigma1`, and `sigma2`, each with an intercept and one `x` slope.
It does not change the likelihood, formula grammar, estimator, or covariance
parameterization. It records fitted-geometry diagnostics only:
`pdHess`, selected optimizer, `sdr$gradient.fixed`, `sdr$cov.fixed`, raw TMB
Hessian availability, direct-SD lower-bound counts, and derived-correlation
extremeness.

## Files Changed

- `tools/run-structured-re-q4-slope-hessian-geometry.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q4-slope-hessian-geometry.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-hessian-geometry/structured-re-q4-slope-hessian-geometry-results.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-24-q4-slope-hessian-geometry.md`

## Checks Run

- `Rscript --vanilla tools/run-structured-re-q4-slope-hessian-geometry.R`
  passed and wrote the geometry artifact and dashboard sidecar. The run reported
  7 fallback optimizer warnings.
- A TSV summary check reported 8 geometry rows, all with
  `n_sigma_direct_sd_at_lower_bound = 4`, `cov_fixed_status = nonfinite`, and
  geometry status split between 7 fallback-selected rows and 1 nonfallback row.
- `Rscript --vanilla tools/run-structured-re-q4-slope-interval-stability-probe.R`
  was rerun after the first geometry-script draft inherited the stability
  script output paths; the stability sidecar was restored to 64 rows and the
  artifact to 128 method rows.
- `air format tools/run-structured-re-q4-slope-hessian-geometry.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 2873 assertions.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 8 structured
  RE q4 slope Hessian-geometry rows.
- `git diff --check` passed.
- The q4-slope overclaim scan for unsupported interval, coverage, REML,
  AI-REML, and supported-status wording returned no hits.

## Tests Of The Tests

The conversion-contract test now requires the exact 2-variant by 4-provider
geometry cross-product, the nonfinite covariance status, lower-bound sigma SD
counts, raw-Hessian unavailable message, fallback pattern, q-series support-cell
boundary, and diagnostic-only claim language. The Python validator mirrors those
checks for mission-control drift detection.

## Consistency Audit

The dashboard README and q-series completion map now state that this diagnostic
localizes the current q4 all-four one-slope interval blocker to sigma-endpoint
lower-bound geometry plus covariance/Hessian failure. They keep interval
reliability, coverage, q4 REML, AI-REML, broad bridge support, public support,
and broader q8 support unpromoted.

## GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on. This slice records local
diagnostic evidence and does not change public user support.

## What Did Not Go Smoothly

The first script draft loaded helper definitions from the interval-stability
probe and inherited its output paths, which clobbered the stability TSVs with
geometry rows. The stability probe was rerun immediately, restoring the 64-row
dashboard sidecar and 128-row artifact. The geometry script now resets its
artifact/status paths after helper loading.

## Team Learning

Helper reuse across executable evidence scripts needs an explicit output-path
reset when the donor script defines global paths. For future scripts, define
helper-only sources or isolate reusable functions before assigning output
locations.

## Known Limitations

This is diagnostic negative evidence. It does not admit coverage denominators,
claim q4 interval reliability, claim q4 interval coverage, promote q4 REML,
native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML, broad
bridge support, public optimizer controls, DRAC execution, SR150 coverage
readiness, or an Ayumi-facing reply.

## Next Actions

Separate sigma-endpoint lower-bound geometry from covariance/Hessian failure
before denominator accounting. A focused differential diagnostic should compare
the current all-four q4 slope design with a sigma-axis-reduced or fixed-sigma
variant before any calibrated coverage work.

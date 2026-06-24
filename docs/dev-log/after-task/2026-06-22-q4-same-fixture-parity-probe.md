# Q4 Same-Fixture Parity Probe

## Goal

Probe the next q4 parity blocker with one same-data native R/TMB versus
R-via-Julia comparison, then record the result without promoting q4 bridge
support.

## What Changed

- Added `phase18_structured_re_q4_same_fixture_parity_probe()` in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R`.
- Added
  `docs/dev-log/dashboard/structured-re-q4-same-fixture-parity-probe.tsv`.
- Added fixture and dashboard contract tests so the probe remains negative
  evidence unless a future row supplies native convergence, direct DRM.jl point
  export, and same-fixture tolerance evidence.

## Probe Result

A live local probe fit the same 30-tip, 3-observation-per-tip q4 phylogenetic
location-scale dataset with native R/TMB and the R-via-Julia bridge. Native
TMB reported false convergence (`code 1`), while the R-via-Julia fit converged.
The log likelihoods were close, but derived q4 `corpairs()` differed beyond the
predeclared correlation tolerance:

- native convergence: `FALSE`
- R-via-Julia convergence: `TRUE`
- absolute log-likelihood delta: `0.0006700136`
- maximum absolute q4 `corpairs()` delta: `0.3958341`
- predeclared q4 correlation tolerance: `max_abs_delta <= 0.05`

## Boundary

This is blocker evidence only. It does not promote q4 parity, q4 REML,
HSquared AI-REML, R-via-Julia q4 bridge support, direct DRM.jl same-fixture
export support, interval reliability, or interval coverage.

The next gate is a calibrated same-fixture native/direct/bridge probe where
native TMB converges, direct DRM.jl's q4 point-matrix export is compared on the
same data, and all rows are compared against the predeclared q4 tolerance
policy.

## Follow-Up In Same Tranche

DRM.jl now adds a `q4_point_export` payload for bridge fits carrying
`fit.ranef.Sigma_a`, with the raw `Sigma_a` matrix, per-axis SDs, and the
derived correlation matrix. A later calibrated probe also fixed the q4
log-Cholesky coefficient-label order used by the R wrapper. The focused Julia
contract test now passes 36 assertions. This removes the missing-export and
wrapper-reconstruction sub-blockers, but it does not by itself accept q4 parity:
native-vs-Julia logLik remains outside the predeclared tolerance in the
calibrated probe.

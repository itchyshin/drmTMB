# After-task report: homogeneous Toeplitz redesign brief

## 1. Goal

Turn the proved free-Toeplitz residual/process covariance ridge into an explicit,
identified implementation decision before any inferential calibration or campaign
continues.

## 2. Implemented

`T3-8-REDESIGN-DECISION.md` gives two full likelihood contracts, data-admission
requirements, interpretation boundaries, and consequences. The P2 plan now
states that the existing direct provider is a non-public prototype; the Unlazy
ledger adds manual gate T3-7b before its former calibration gate.

## 3a. Decisions and Rejected Alternatives

The brief recommends a marginal Toeplitz covariance for ordinary panel CSV data,
where its one SD is explicitly total variation. A replicated latent-process route
is available only when each series--occasion has independently replicated
measurements. Fixing a nugget, hiding Hessian diagnostics, or widening a campaign
was rejected because none adds the missing information.

## 4. Files Touched

`docs/dev-log/plans/2026-09-10-temporal-homtoep/T3-8-REDESIGN-DECISION.md`,
`PLAN.md`, `unlazy/GATES.md`, `docs/dev-log/check-log.md`, and this report.

## 5. Checks Run

- T3-7 reverified the source-fingerprinted pilot outputs.
- T3-7a reverified the independent exact covariance and likelihood identity.
- `git diff --check` passed for the decision-record changes.

## 6. Tests of the Tests

The decision brief is anchored to T3-7a's dense, independent covariance and NLL
test. It also records the separate cross-package source-map result that flexible
Toeplitz comparisons in glmmTMB disable free residual dispersion.

## 7a. Issue Ledger

No external issue was opened or changed. T3-7b remains a local manual gate,
awaiting the model-semantics choice; it is not a campaign authorization.

## 8. Consistency Audit

The pilot, exact-ridge test, plan correction, gate sequence, and brief all
separate the direct prototype from either identifiable replacement. AR1 and OU
retain their distinct temporal-process plus residual-noise interpretation.

## 9. What Did Not Go Smoothly

The initial P2 plan treated a positive-definite Toeplitz correlation map as
sufficient for the requested variance decomposition. The pilot and exact
transformation showed that positive definiteness does not establish component
identification.

## 10. Known Residuals

The user must select M or R at T3-7b. No redesigned provider, profile or Wald
interval, recovery/campaign evidence, rendered reader workflow, or release
claim has been produced for Toeplitz.

## 11. Team Learning

Covariance validity and inferential identifiability are separate acceptance
conditions. A flexible covariance provider must document which variance
components the observation grain can distinguish before public API work begins.

## 12. Cross-Product Coverage

This work covers the design boundary for direct Gaussian free Toeplitz covariance
with one observation per series--occasion. It does NOT cover the selected
replacement implementation, replicated data admission, REML, Julia, missing
data, ordinary intercepts, phylogenetic or spatial structures, calibration,
campaigns, forecasting, or newdata prediction.

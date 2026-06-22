# Structured Random-Effect Inference Status

## Purpose

This note banks the SR061-SR070 inference tranche for the structured
random-effect balance arc. It is a status note, not a new coverage claim.

The useful distinction is:

- point fits and extractors can be available;
- Wald intervals are usable only when the fit-specific Hessian supports them;
- profile and bootstrap routes are target-specific;
- coverage is unevaluated unless a replicated known-truth grid says otherwise.

## Wald Status

For fitted Gaussian structured rows, Wald intervals inherit the usual
`sdreport()` and Hessian contract. A clean `pdHess = TRUE` fit can expose fixed
effects and direct transformed targets, but `pdHess = FALSE`, an active
log-`sigma` clamp, a collapsed structured SD, a boundary correlation, or a large
gradient keeps Wald intervals diagnostic.

The existing boundary ledger separates those cases:
`docs/dev-log/dashboard/ayumi-boundary-status-ledger.tsv` records false Hessian,
clamp-active, collapsed-axis, near-boundary residual-correlation, and profile
failure rows.

## Profile Status

Profile target availability is not coverage. The current ledgers show this
split explicitly:

- `docs/dev-log/dashboard/phylo-profile-loglik-status.tsv` records finite
  log-likelihood and direct profile-target readiness for selected
  phylogenetic rows.
- `docs/dev-log/dashboard/phylo-q2-q4-target-map.tsv` separates bivariate q2,
  q2-plus-q2, and q4 target identities.
- `docs/dev-log/dashboard/phylo-extractor-status.tsv` keeps
  `corpairs()`, `summary()$covariance`, and `profile_targets()` status separate.

Full q4 correlations remain derived interval-unavailable unless a row-specific
nonlinear or bootstrap route proves otherwise. q4 SD rows can be direct targets
while q4 correlations remain unavailable.

## Bootstrap Status

`docs/dev-log/dashboard/bootstrap-refit-accounting.tsv` records requested,
successful, and failed bootstrap refits. It is accounting evidence. It is not a
calibrated uncertainty study.

The current table includes small native-TMB univariate and q4 bookkeeping rows,
plus an experimental direct-Julia q4 row. The 30-tip q4 row is plumbing only,
and the 100-tip q4 rows returned failed refits. Those rows should guide the next
diagnostic, not an applied interval claim.

## Coverage Status

Coverage reliability remains the open gap for this structured balance arc.

The existing Ayumi inference ledger records `coverage_status = not_evaluated`
or stronger negative caveats for the relevant cells. Direct DRM.jl bootstrap
evidence also records severe scale-axis SD undercoverage at nominal 90% for the
q4 bootstrap study. That is a reason to keep q1, q2, and q4 coverage pilots
separate from calibrated coverage validation.

SR064-SR066 are now banked as labelled pilot rows by
`docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/`.
That artifact records target identities, fit status, Hessian status, interval
availability, finite-interval coverage, and MCSE. The result is deliberately
diagnostic: q1 had three converged positive-Hessian fits with one finite target
interval covering the truth; q2 produced fit rows but no positive-Hessian fits
and no finite intervals; q4 produced fit rows but no converged fits, no
positive-Hessian fits, and no finite intervals. This banks the
coverage-accounting pipeline, not interval reliability.

## Diagnostic Rows

`check_drm()` and summary rows should expose:

- route: `phylo`, `spatial`, `animal`, `relmat`, or `phylo_interaction`;
- dimension: q1, q2, q2-plus-q2, or q4;
- endpoint: location, scale, matched mean-scale, or all-four;
- fit status: converged, diagnostic, nonconverged, or rejected;
- inference status: Wald, profile, bootstrap, coverage, or unavailable.

This is already partly present through the q2/q4 extractor and boundary
ledgers. The next implementation step is to make those rows less phylo-specific
where spatial, animal, and `relmat()` evidence is already fitted.

## Decision

SR061-SR070 are banked as inference-status and diagnostic-surface rows.
SR064-SR066 are banked only as small labelled pilot-accounting rows. No
interval coverage reliability, q4 REML, non-Gaussian REML, AI-REML, R bridge
promotion, or Ayumi-scale interval claim is added.

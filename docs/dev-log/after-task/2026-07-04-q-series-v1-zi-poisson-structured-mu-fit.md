# After Task: Q-Series v1 Zero-Inflated Poisson Structured-Mu Fit

## 1. Goal

Move the cheapest remaining basic-distribution row,
`qseries_count_mu_zeroinflated_poisson_structured_rejected`, into the v1.0
practical surface as local fit-only evidence for fixed-covariance spatial
`mu` with fixed zero inflation. Keep all interval, coverage,
`inference_ready`, `supported`, q2/q4, REML, AI-REML, bridge, and public-support
claims out of scope.

## 2. Implemented

`drm_build_poisson_spec()` now permits `spatial(1 | site, coords = coords)` in
the Poisson `mu` formula when a fixed-effect `zi ~ 1` formula is present. The
exception is provider-scoped to `spatial`, so other structured providers with
fixed zero inflation still hit the existing zero-inflated structured-effect
boundary.

The local first-four smoke now includes
`count_struct_mu_fit_zi_poisson_spatial`, which checks a finite
zero-inflated Poisson fit with convergence 0, visible `spatial_mu` random
effects, and direct spatial `mu` SD extraction. The support cell, non-Gaussian
audit, v1 readiness reset, v1 release ledger, release status, preflight report,
and candidate queue were regenerated or updated to match.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only the spatial Poisson structured `mu` route with fixed `zi ~ 1`.
- Keep structured `zi` plus structured `mu` closed.
- Keep zero-inflated NB2 structured `mu` closed because the NB2 TMB route does
  not yet carry structured effects.
- Treat the row as local fit-only evidence, not a retained-denominator recovery
  row.

Rejected alternatives:

- Do not unlock phylo, animal, relmat, or phylo-interaction zero-inflated
  Poisson structured `mu` routes in this slice.
- Do not run Totoro or DRAC; no denominator, coverage, or host provenance is
  needed for this local gate.
- Do not promote intervals, coverage, `inference_ready`, `supported`, REML,
  AI-REML, q2/q4, bridge, or public-support wording.

## 3b. Mathematical Contract

The admitted local row is:

```text
y_i ~ zero-inflated Poisson(mu_i, pi)
log(mu_i) = X_i beta + u_site[i]
logit(pi) = gamma_0
u ~ N(0, sigma_spatial^2 C)
```

This establishes that the existing Poisson structured-effect machinery can
route a spatial structured `mu` contribution through the zero-inflated Poisson
objective with direct SD extraction. It does not establish interval reliability,
coverage, retained-denominator recovery, broad provider support, or structured
zero-inflation support.

## 4. Files Touched

- `R/drmTMB.R`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`
- `tests/testthat/test-count-structured-mu.R`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-count-structured-mu-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv`
- `docs/dev-log/release-audits/q-series-v1-release-status.md`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- R parse check for the changed R, smoke, and focused test files: passed.
- Python byte-compile for Mission Control and Q-Series v1 tools: passed.
- `tools/qseries-v1-first-four-rejection-smoke.R`: passed.
- `devtools::test(filter = 'count-structured-mu')`: passed.
- `devtools::test(filter = 'poisson-mean')`: passed and preserves the
  non-spatial zero-inflated structured-`mu` boundary.
- `devtools::test(filter = 'nongaussian-structured-boundary')`: passed.
- `devtools::test(filter = 'structured-re-conversion-contracts')`: passed.
- `tools/validate-mission-control.py`: passed.
- `tools/qseries_v1_release_check.py --summary --check-report
  --check-candidates`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-04-q-series-v1-zi-poisson-structured-mu-fit.md')"`:
  passed.
- `git diff --check`: passed.

## 6. Tests of the Tests

The first `count-structured-mu` run caught that the ordinary count helper was
too broad for a zero-inflated model: its prediction and `check_drm()` assertions
assumed the ordinary Poisson/NB2 diagnostic shape. I replaced that with a
zero-inflated-specific shape check that still verifies convergence, pdHess,
structured type, direct SD target identity, random-effect visibility, and finite
`mu`/`zi` predictions.

The same test also caught a stale NB2 neighboring-route expectation. The actual
closed route now fails at the joint structured `mu` plus structured `sigma`
gate, so the test now checks the observed `cannot be combined` boundary.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. This was a focused local branch
checkpoint in the drmTMB Q-Series v1 practical-surface lane.

## 8. Consistency Audit

Rose audit: the moved row is no longer present in the count-structured-`mu`
rejection contract. Mission Control reports 104 Q-Series cells, 8 exact
`inference_ready` rows, 0 structured `supported` rows, 37 non-Gaussian audit
rows, and 5 active count-structured-`mu` rejection rows.

Fisher audit: coverage remains unauthorized. The row is `point_fit` with
`coverage_status = planned`, not an interval or coverage claim.

Grace audit: the release checker and Mission Control agree on 85/104 practical
v1.0 rows, 29/37 basic-distribution recovery rows, and 19 post-v1.0 rows.

## 9. What Did Not Go Smoothly

The first implementation flag was too broad and would have admitted all Poisson
structured `mu` providers with fixed zero inflation. The scope was tightened to
`spatial` before validation, preserving the existing phylo guard in
`test-poisson-mean.R`.

## 10. Known Residuals

The row is local fit-only. It still needs a retained recovery fixture before it
can be called recovery-grid evidence, and it needs separate interval and
coverage design before any `inference_ready` or support claim. NB2
zero-inflated structured `mu`, structured `zi` combined with structured `mu`,
labelled q2 count `mu`, structured-plus-ordinary count `mu`, and simultaneous
structured providers remain post-v1 design work.

## 11. Team Learning

Provider-scoped exceptions are safer than family-level switches for Q-Series
triage. A small local fit can move the v1.0 practical surface efficiently, but
the support cell and validator must name exactly which provider and endpoint
moved so the rest of the family does not inherit the claim.

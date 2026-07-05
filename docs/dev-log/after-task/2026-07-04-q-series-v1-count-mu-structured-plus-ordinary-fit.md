# Q-Series v1 count mu structured-plus-ordinary fit-only row

## 1. Goal

Admit one economical Q-Series v1 row only if the implementation already works:
ordinary Poisson `mu` with fixed-covariance spatial `spatial(1 | site,
coords = coords)` plus an ordinary `(1 | id)` `mu` random effect. Keep the row
local fit-only, with no interval, coverage, bridge, `inference_ready`,
`supported`, REML, AI-REML, q2/q4, or public-support claim.

## 2. Implemented

- Added a provider-scoped allowance in `validate_count_structured_mu_term()` so
  ordinary Poisson spatial structured `mu` can be combined with ordinary `mu`
  random effects.
- Added a separate deterministic fixture with distinct site and ordinary-group
  levels, avoiding the confounded `site == id` case.
- Added tests for convergence, positive-definite Hessian, ordinary and spatial
  random-effect extraction, both `sdpars$mu` labels, the direct spatial SD
  profile target, finite positive predictions, and `check_drm()` diagnostics.
- Added the row to the source-tree Q-Series v1 smoke as `expected_fit`.
- Moved `qseries_count_mu_structured_plus_ordinary_rejected` to local
  `point_fit` / `extractor_ready` / `planned` coverage status in Mission
  Control.
- Regenerated the Q-Series v1 release ledger, status report, preflight report,
  and next-candidate queue.

## 3a. Decisions and Rejected Alternatives

- Allowed only `poisson()` plus `spatial()` for this combined-dependence slice.
  NB2, zero-inflated plus ordinary random effects, labelled covariance,
  simultaneous structured providers, and non-canonical count `mu` terms remain
  closed.
- Used local source-tree fit evidence only. No retained denominator, host
  compute, top-up, coverage grid, or interval promotion was added.
- Removed unrelated roxygen-generated man-page link churn after running
  `devtools::document()` because no roxygen source changed.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-count-structured-mu.R`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/validate-mission-control.py`
- `tools/qseries_v1_claim_guard.py`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-count-structured-mu-rejection-contract.tsv`
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

- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "devtools::document()"`
- R parse check for `R/drmTMB.R`, the smoke runner, and the focused tests.
- `python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'count-structured-mu', reporter = 'summary')"`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary', reporter = 'summary')"`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `python3 tools/qseries_v1_claim_guard.py --summary`
- `git diff --check`

## 6. Tests of the Tests

The first count-structured `mu` rerun failed because the formula used
`coords = sim_plus_ordinary$coords`, which violates the parser contract that
`coords` must name an object. The test now binds `coords_plus_ordinary` before
calling `bf()`, exercising the public formula path instead of bypassing parser
rules. The conversion-contract test initially failed on the old
non-Gaussian audit state counts; it now asserts 6 rejected and 12 point-only
rows.

## 7a. Issue Ledger

- No GitHub issue was opened or closed in this slice.
- The support-cell movement is local fit-only and remains a v1 release-planning
  accounting change, not a support or inference promotion.

## 8. Consistency Audit

- Mission Control still reports 104 Q-Series cells.
- Exact `inference_ready` rows remain 8/104.
- Structured `supported` rows remain 0/104.
- q4 coverage-authorized rows remain 0.
- Practical v1.0 row surface is now 86/104 (82.7%).
- Basic-distribution recovery is now 30/37 (81.1%).
- Post-v1.0 validation/design is now 18/104 (17.3%).
- The count-structured `mu` rejection contract now has four rows.

## 9. What Did Not Go Smoothly

Two small guardrails caught useful mistakes. First, formula parsing rejected a
`$` expression for `coords`, which forced the test to use the public documented
syntax. Second, the conversion-contract test caught the old non-Gaussian audit
state count, confirming that the dashboard accounting changed exactly one row.

## 10. Known Residuals

- This row has no retained-denominator evidence.
- Interval and coverage status remain unsupported/planned.
- No bridge parity, q2/q4 covariance, labelled covariance, simultaneous
  structured provider, NB2, zero-inflated plus ordinary, or public support claim
  is made.
- The first four post-v1 review gates remain ordinal phylo `mu`,
  truncated-NB2 relmat `hu`, labelled spatial count `mu`, and simultaneous
  structured count `mu`.

## 11. Team Learning

The cheapest useful v1 move is often to test the exact parser boundary first,
then bank only the row that already has a clean lower-engine path. Keeping site
and ordinary grouping distinct matters for Hessian quality and avoids banking a
confounded near-boundary fit.

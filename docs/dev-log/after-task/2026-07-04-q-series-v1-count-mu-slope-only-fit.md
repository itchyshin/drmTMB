# Q-Series v1 count mu slope-only fit-only row

## 1. Goal

Admit one economical Q-Series v1 row only if the implementation already works:
ordinary Poisson `mu` with fixed-covariance spatial `spatial(0 + x | site,
coords = coords)`. Keep the row local fit-only, with no interval, coverage,
bridge, `inference_ready`, `supported`, REML, AI-REML, q2/q4, NB2, zero
inflation, or public-support claim.

## 2. Implemented

- Added a provider- and family-scoped allowance in
  `validate_count_structured_mu_term()` for ordinary Poisson fixed-covariance
  spatial slope-only structured `mu`.
- Added a deterministic slope-only fixture and fit checks for convergence,
  positive-definite Hessian, `spatial_mu` extraction, the direct spatial slope
  SD profile target, finite positive predictions, and `check_drm()` diagnostics.
- Kept NB2 slope-only closed with a negative-control test.
- Added the row to the source-tree Q-Series v1 smoke as `expected_fit`.
- Moved `qseries_count_mu_noncanonical_term_rejected` to local `point_fit` /
  `extractor_ready` / `planned` coverage status in Mission Control.
- Regenerated the Q-Series v1 release ledger, status report, preflight report,
  and next-candidate queue.

## 3a. Decisions and Rejected Alternatives

- Allowed only `poisson()` plus fixed-covariance `spatial()` for this slope-only
  slice. NB2, labelled q2 covariance, simultaneous structured providers,
  multiple slopes, zero-inflated NB2, and structured zero-inflation remain
  closed.
- Used local source-tree fit evidence only. No retained denominator, host
  compute, top-up, coverage grid, or interval promotion was added.
- Did not move the zero-inflated NB2 candidate after a probe showed that the
  current NB2 zero-inflation branch can return convergence while dropping the
  structured `mu` random effect from the optimized fit.

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

- `python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`
- R parse check for `R/drmTMB.R`, the smoke runner, and the focused tests.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'count-structured-mu')"`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary')"`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `python3 tools/qseries_v1_claim_guard.py --summary`

## 6. Tests of the Tests

The non-Gaussian boundary test initially asserted `sdr$pdHess` on a fast
`se = FALSE` fit, where no `sdr` object is created. The stronger
count-structured fixture now carries the `pdHess` assertion; the source-tree
smoke remains a fast fit-shape check. The conversion-contract test also caught
that the generated preflight report had been written with Mission Control
skipped; regenerating after a full validator pass restored `Mission Control:
ok`.

## 7a. Issue Ledger

- No GitHub issue was opened or closed in this slice.
- The support-cell movement is local fit-only and remains a v1 release-planning
  accounting change, not a support or inference promotion.

## 8. Consistency Audit

- Mission Control still reports 104 Q-Series cells.
- Exact `inference_ready` rows remain 8/104.
- Structured `supported` rows remain 0/104.
- q4 coverage-authorized rows remain 0.
- Practical v1.0 row surface is now 87/104 (83.7%).
- Basic-distribution recovery is now 31/37 (83.8%).
- Post-v1.0 validation/design is now 17/104 (16.3%).
- The count-structured `mu` rejection contract now has three rows.

## 9. What Did Not Go Smoothly

The zero-inflated NB2 probe was a useful false lead: convergence alone was not
enough, because the fit shape showed no structured `mu` random effect and no
direct structured `mu` SD. That row stayed closed. The generated preflight
report also had to be rewritten after the full Mission Control check because a
temporary `--skip-mission-control` run left stale text.

## 10. Known Residuals

- This row has no retained-denominator evidence.
- Interval and coverage status remain unsupported/planned.
- No bridge parity, q2/q4 covariance, labelled covariance, multiple-slope,
  simultaneous structured provider, NB2, zero-inflated NB2, structured
  zero-inflation, or public support claim is made.
- The first four post-v1 review gates remain ordinal phylo `mu`,
  truncated-NB2 relmat `hu`, labelled spatial count `mu`, and simultaneous
  structured count `mu`.

## 11. Team Learning

For v1 acceleration, fit-shape checks matter as much as convergence. A cheap
local fit can bank a real implementation row only when random-effect extraction,
SD extraction, and profile-target identity all match the intended formula cell.

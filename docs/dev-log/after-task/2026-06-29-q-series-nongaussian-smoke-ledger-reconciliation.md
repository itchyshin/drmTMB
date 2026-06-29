# Q-Series non-Gaussian smoke ledger reconciliation

## 1. Goal

Make the non-Gaussian Q-Series audit ledger agree with the smoke evidence
already shown in the mission-control widget, without promoting any support-cell
row.

## 2. Implemented

This promotes exactly no support cell under no interval channel with no
denominator-policy change and does not claim non-Gaussian intervals, coverage,
q2/q4 count covariance, REML, AI-REML, bridge support, `supported`, q4/q8, or
public support.

Updated `structured-re-nongaussian-status-audit.tsv` so the ten exact
non-Gaussian q1 count `mu` intercept-style cells now carry
`widget_state = non_gaussian_intercept_recovery_smoke`:

- two `phylo_interaction()` Poisson/NB2 rows;
- two phylo Poisson/NB2 intercept rows;
- six spatial/animal/relmat Poisson/NB2 intercept rows.

The linked support-cell rows still have `fit_status = point_fit`,
`interval_status = unsupported`, and `coverage_status = planned`.

Updated `tools/validate-mission-control.py` so the main non-Gaussian audit
expects the 10 / 8 / 18 / 1 split across intercept smoke, recovery-only,
rejected, and planned rows. The validator now derives the ten intercept-smoke
cells from the three smoke sidecars and rejects audit rows that drift back to
point-only wording.

Added a focused testthat guard that reads the main non-Gaussian audit plus the
three smoke sidecars and checks that the same ten cells are smoke-only,
unsupported for intervals, planned for coverage, and `do_not_promote`.

Updated the dashboard README wording and bumped the mission-control build
marker to `r80`.

## 3a. Decisions and Rejected Alternatives

I did not change `structured-re-q-series-support-cells.tsv`. The support-cell
table remains the row identity and status source of truth; this tranche only
reconciles the audit ledger used for dashboard row-state display.

I did not collapse the smoke sidecars into the main non-Gaussian audit. The
sidecars keep the richer artifact-level counts, while the audit ledger keeps
one row per non-Gaussian support cell.

I did not turn local smoke into recovery-only evidence. The smoke rows have
four condition-replicates or four replicate seeds and no interval denominator;
the 80-rep recovery-only rung remains separate and only applies to the count
one-slope rows.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-nongaussian-smoke-ledger-reconciliation.md`

## 5. Checks Run

- `python3 tools/validate-mission-control.py`: passed with
  `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test(filter = "structured-re-conversion-contracts")'`: 6288 PASS /
  0 FAIL.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-nongaussian-smoke-ledger-reconciliation.md')"`:
  after-task structure check passed.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test()'`: 19667 PASS / 0 FAIL / 17 warnings / 43 skips.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::check()'`: 0 errors / 0 warnings / 0 notes.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'pkgdown::check_pkgdown()'`: no problems found.

## 6. Tests of the Tests

The new test would fail if any of the ten smoke-sidecar cell ids in the main
non-Gaussian audit were labelled `non_gaussian_point_only`, if their interval
status changed from `unsupported`, if coverage changed from `planned`, or if
the audit no longer cited local recovery-smoke sidecar evidence.

The Python validator independently checks the same class of drift before the
dashboard is treated as valid.

## 7a. Issue Ledger

- The ten intercept-style count rows have local smoke evidence only; they still
  need replicated recovery grids with MCSE and a boundary ledger before any
  recovery claim.
- `qseries_spatial_nbinom2_q1_mu_intercept` remains marked with
  lower-boundary warnings through its smoke sidecar.

No GitHub issue was opened. This is a PR #685 dashboard-source reconciliation.

## 8. Consistency Audit

The Q-Series board still has 104 support cells and exactly five interval plus
coverage `inference_ready` rows. No non-Gaussian row is
`inference_ready`, no q4/q8 row is inference-ready, and no structured row is
`supported`.

The adjacent README wording now describes the non-Gaussian audit split as
intercept smoke, recovery-only, rejected, and planned rows. Historical
check-log entries that were true when written were left intact.

## 9. What Did Not Go Smoothly

The dashboard was already visually correct because later smoke sidecars
overlaid the main non-Gaussian audit rows. The stale wording was hidden unless
one read the audit TSV directly, which is exactly why this needed a validator
and test guard rather than another visual-only tweak.

The first focused R test failed because `table()` preserved a dimension
attribute while the expected vector did not. Converting the table slice to
plain integers made the guard compare the counts instead of the table shape.

## 10. Known Residuals

This tranche does not execute new simulations. Non-Gaussian count intercept
rows remain local-smoke only, the one-slope rows remain recovery-only, and all
non-Gaussian interval and coverage routes remain unsupported.

## 11. Team Learning

When the widget overlays sidecars, keep the base audit ledger semantically
aligned with the overlay. Otherwise the top board can look correct while the
source table quietly says something weaker or stale.

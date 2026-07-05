# After Task: Q-Series v1 Ordinal Phylo Mu Fit

## 1. Goal

Move `qseries_ordinal_mu_phylo_rejected` into the Q-Series v1.0 practical
surface as a narrow local fit-only row for cumulative-logit ordinal `mu` with
one phylogenetic q1 intercept. Keep all interval, coverage, `inference_ready`,
`supported`, q2/q4, REML, AI-REML, bridge, and public-support claims out of
scope.

## 2. Implemented

`drm_build_cumulative_logit_spec()` now admits only the exact row-specific route
`bf(score ~ x + phylo(1 | species, tree = tree))`. The builder validates that
the structured term is phylogenetic, unlabelled q1, and intercept-only before
passing the existing sparse precision inputs into the ordinal TMB data path.

The cumulative-logit objective now adds the phylogenetic `mu` latent field and
Gaussian precision prior before computing ordered category probabilities. The
fitted ordinal location SD is exposed through `sdpars$mu`, `ranef("phylo_mu")`,
and a direct `profile_targets()` row. The first-four local smoke now records
`nongaussian_struct_fit_ordinal_mu_phylo` as `expected_fit`, and the Q-Series
release artifacts now account for 89/104 practical v1.0 rows.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only `phylo(1 | species, tree = tree)` in the ordinal `mu` predictor.
- Keep the row as local fit-only/extractor evidence with no retained
  denominator, recovery denominator, or coverage authorization.
- Keep the existing structured SD reporting channel as `log_sd_phylo`, because
  neighbouring non-Gaussian structured rows share that direct target name.
- Update README, NEWS, ROADMAP, the completion map, and dashboard README so the
  exception is visible without becoming broad ordinal mixed-model support.

Rejected alternatives:

- Do not unlock ordinary ordinal `(1 | id)`, ordinal slopes, labelled ordinal
  covariance, multiple structured providers, ordinal scale/discrimination
  formulas, bivariate ordinal models, or mixed-response ordinal models.
- Do not run Totoro, DRAC, or a local retained-denominator smoke; this row has
  no denominator and no host-provenance claim.
- Do not promote intervals, coverage, `inference_ready`, `supported`, REML,
  AI-REML, q2/q4, bridge, or public-support wording.

## 3b. Mathematical Contract

The admitted local row is:

```text
Pr(y_i <= k) = logistic(theta_k - eta_i)
eta_i = X_i beta + u_species[i]
u ~ N(0, sigma_phylo^2 K_phylo)
theta_1 < theta_2 < ... < theta_{K-1}
```

This establishes that the ordinal likelihood can route one phylogenetic
structured `mu` intercept through the existing sparse precision machinery and
expose the fitted SD. It does not establish interval reliability, coverage,
retained-denominator recovery, broad ordinal random-effect support, or
scale/discrimination support.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-cumulative-logit.R`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_claim_guard.py`
- `tools/qseries_v1_release_check.py`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv`
- `docs/dev-log/release-audits/q-series-v1-release-status.md`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv`
- `docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv`
- `docs/dev-log/release-audits/q-series-v1-90pct-review-packet.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-candidate-design-contract.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-candidate-debug-fixture-contract.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py
  tools/qseries_v1_release_check.py tools/qseries_v1_claim_guard.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `python3 tools/qseries_v1_release_check.py --write-report
  --write-candidates --summary`: passed with practical v1.0 surface 89/104
  (85.6%), basic-distribution recovery 33/37 (89.2%), exact `inference_ready`
  8/104, `supported` authority 0/104, and post-v1 15/104.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/qseries_v1_release_check.py --summary --check-report
  --check-candidates`: passed with the same row accounting.
- `R_PROFILE_USER=/dev/null /Library/Frameworks/R.framework/Resources/bin/Rscript
  --no-init-file tools/qseries-v1-first-four-rejection-smoke.R --output
  /tmp/qseries-v1-first-four-ordinal.tsv`: passed with 18 local rows and
  `expected_fit`/`expected_rejection` statuses.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file -e
  "Sys.setenv(NOT_CRAN='true', OMP_NUM_THREADS='1',
  OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1');
  devtools::test(filter = 'cumulative-logit', reporter = 'summary')"`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file -e
  "Sys.setenv(NOT_CRAN='true', OMP_NUM_THREADS='1',
  OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1');
  devtools::test(filter = 'nongaussian-structured-boundary', reporter =
  'summary')"`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file -e
  "Sys.setenv(NOT_CRAN='true', OMP_NUM_THREADS='1',
  OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1');
  devtools::test(filter = 'structured-re-conversion-contracts', reporter =
  'summary')"`: passed.
- Stale wording scan:
  `rg -n 'three row-specific local|three Q-Series v1\\.0 rows|84\\.6|88/104|16/104|15\\.4|17 post-v1\\.0|current seven rows|ordinal/phylo `mu`|cumulative_logit\\(\\).*phylo\\(\\).*rejection|cumulative_logit\\(\\) `mu` with `phylo\\(\\)' README.md NEWS.md ROADMAP.md docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md docs/dev-log/release-audits/q-series-v1-preflight-report.md tests/testthat/test-structured-re-conversion-contracts.R`:
  passed, with only unrelated `15.43` fixture strings.
- GitHub issue search for `qseries_ordinal_mu_phylo_rejected` and for
  `ordinal phylo mu Q-Series`: both returned zero hits.
- `git diff --check`: passed.

## 6. Tests of the Tests

The new cumulative-logit test checks the positive path by requiring convergence,
positive-Hessian status, `q = 1`, visible `sdpars$mu`, visible
`ranef("phylo_mu")`, finite ordinal `mu` predictions, ordered cutpoints, and a
direct profile target.

The same test file checks two negative paths: ordinal phylogenetic slopes and
labelled q terms still fail with row-specific messages. The conversion-contract
test first failed on three stale expectations, which confirmed it was checking
the dashboard audit counts and the generated first-four design contract rather
than only parsing static files. Updating those expectations made the test pass
against the regenerated artifacts.

## 7a. Issue Ledger

`gh` is not installed in this local environment. Public GitHub search for the
exact support-cell id `qseries_ordinal_mu_phylo_rejected` returned zero issue
hits. Public GitHub search for `ordinal phylo mu Q-Series` in `itchyshin/drmTMB`
also returned zero issue hits. No issue was opened, commented on, or closed.

## 8. Consistency Audit

Rose audit: the moved row is no longer present in the
non-Gaussian structured-family rejection contract. Mission Control reports 104
Q-Series cells, 8 exact `inference_ready` rows, 0 structured `supported` rows,
37 non-Gaussian audit rows, and 1 active structured-family rejection row.

Fisher audit: coverage remains unauthorized. The row is `point_fit` with
`coverage_status = planned`, not an interval or coverage claim.

Gauss audit: the TMB branch adds the same sparse structured-field prior and
direct SD reporting used by neighbouring structured rows, scoped to
`model_type == 13` for cumulative-logit ordinal fits.

Noether audit: the symbolic contract, formula grammar, and TMB implementation
all route a single phylogenetic field into ordinal `mu`, while cutpoints remain
ordered and scale/discrimination formulas remain closed.

Grace audit: the validator, generated release artifacts, focused tests, claim
guard, and stale wording scans agree on 89/104 practical rows, 33/37
basic-distribution recovery rows, 15/104 post-v1 rows, and no new support or
coverage promotion.

## 9. What Did Not Go Smoothly

The implementation itself was narrow, but the release-audit artifacts shifted
the generated first-four queue after ordinal moved into the practical surface.
The conversion-contract test caught that the fourth first-four design row is
`planned`, not `unsupported`, and that the non-Gaussian audit state counts now
have three rejected rows and fifteen point-only rows.

## 10. Known Residuals

- No retained-denominator recovery was run.
- No coverage, interval, `inference_ready`, or `supported` status was added.
- Ordinary ordinal `(1 | id)`, ordinal slopes, labelled ordinal covariance,
  multiple structured providers, ordinal scale/discrimination formulas,
  bivariate ordinal models, mixed-response ordinal models, REML, AI-REML,
  bridge support, and public support remain closed.
- Q-Series v1.0 is still not complete: the practical surface is 89/104
  (85.6%), exact `inference_ready` is 8/104, and `supported` authority is
  0/104.

## 11. Team Learning

Kim's economy rule held: this was a local fit-only practical-surface move, not
a compute tranche. The cheap safe path was to admit the exact ordinal phylo row,
regenerate the release ledger, and let Rose/Fisher/Grace boundaries block any
status inflation before considering the next 90% rows.

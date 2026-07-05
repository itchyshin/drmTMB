# After Task: Q-Series v1 Truncated-NB2 Relmat Hurdle Hu Fit

## 1. Goal

Move `qseries_truncnbinom2_hu_relmat_rejected` into the Q-Series v1.0
practical surface as a narrow local fit-only row for `truncated_nbinom2()`
hurdle `hu` with one relmat q1 intercept. Keep all denominator, interval,
coverage, `inference_ready`, `supported`, q2/q4, REML, AI-REML, bridge, and
public-support claims out of scope.

## 2. Implemented

`drm_build_truncated_nbinom2_spec()` now admits only the exact row-specific
route:

```r
bf(y ~ x, sigma ~ 1, hu ~ relmat(1 | id, Q = Q))
```

The builder validates that the structured hurdle term is relmat, unlabelled
q1, and intercept-only before passing the sparse precision inputs to the
hurdle NB2 TMB path. The hurdle objective now routes the structured field into
the `hu` linear predictor and reports the fitted structured SD through
`sdpars$hu` and `ranef("relmat_hu")`.

The first-four local smoke now records
`nongaussian_struct_fit_truncnbinom2_hu_relmat` as `expected_fit`, the retired
non-Gaussian structured-family rejection contract is header-only, and the
Q-Series release artifacts now account for 90/104 practical v1.0 rows.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only `hu ~ relmat(1 | id, Q = Q)` for `truncated_nbinom2()`.
- Keep the row as local fit-only/extractor evidence with no retained
  denominator, recovery denominator, or coverage authorization.
- Reuse the existing sparse structured-field machinery and direct SD reporting
  path, with the relmat term marked as the `hu` distributional parameter.
- Update README, NEWS, ROADMAP, known limitations, the completion map, and
  dashboard README so the exception is visible without becoming broad hurdle
  structured-effect support.

Rejected alternatives:

- Do not unlock hurdle structured slopes, labelled covariance, q2/q4 terms,
  multiple structured providers, count-side structured terms for this family,
  location-scale blocks, or bridge support.
- Do not run Totoro, DRAC, or a local retained-denominator smoke; this row has
  no denominator and no host-provenance claim.
- Do not promote intervals, coverage, `inference_ready`, `supported`, REML,
  AI-REML, q2/q4, derived correlations, bridge support, or public-support
  wording.

## 3b. Mathematical Contract

The admitted local row is:

```text
Pr(y_i = 0) = logistic(eta_hu_i)
eta_hu_i = Z_i u
u ~ N(0, sigma_relmat_hu^2 K_relmat)
y_i | y_i > 0 ~ NB2+(mu_i, phi)
log(mu_i) = X_i beta
log(phi_i) = W_i gamma
```

This establishes that the hurdle probability can route one relmat structured
q1 intercept through the existing sparse precision machinery and expose the
fitted SD. It does not establish interval reliability, coverage,
retained-denominator recovery, broad hurdle random-effect support,
location-scale support, or bridge support.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
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
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py
  tools/qseries_v1_release_check.py tools/qseries_v1_claim_guard.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `python3 tools/qseries_v1_release_check.py --summary --check-report
  --check-candidates`: passed with practical v1.0 surface 90/104 (86.5%),
  basic-distribution recovery 34/37 (91.9%), exact `inference_ready` 8/104,
  `supported` authority 0/104, and post-v1 14/104.
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
- `R_PROFILE_USER=/dev/null
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file
  tools/qseries-v1-first-four-rejection-smoke.R --output
  /tmp/qseries-v1-first-four-trunc-hu.tsv`: passed.

## 6. Tests of the Tests

The new focused test checks the positive path by requiring convergence,
`model_type = "hurdle_nbinom2"`, a visible `relmat_hu` random-effect block,
and a relmat structured SD under `sdpars$hu`.

The same test file checks two negative paths: hurdle relmat slopes and labelled
q terms still fail with row-specific messages. The conversion-contract suite
first failed on one stale expected audit count, which confirmed it was checking
the non-Gaussian dashboard buckets after the row moved from rejected to
point-only. Updating the expected split to 2 rejected and 16 point-only made the
test pass against the regenerated artifacts.

## 7a. Issue Ledger

No GitHub issue was opened, commented on, or closed in this slice. The change
is a narrow local v1 recovery row and does not create a public support claim.

## 8. Consistency Audit

Rose audit: the moved row is no longer present in the non-Gaussian
structured-family rejection contract. Mission Control reports 104 Q-Series
cells, 8 exact `inference_ready` rows, 0 structured `supported` rows, 37
non-Gaussian audit rows, and 0 non-Gaussian structured-family rejection rows.

Fisher audit: coverage remains unauthorized. The row is `point_fit` with
`coverage_status = planned`, not an interval or coverage claim.

Gauss audit: the TMB hurdle branch adds the sparse relmat field to the `hu`
linear predictor before evaluating the hurdle NB2 likelihood and adds the same
Gaussian precision prior used by neighbouring structured rows.

Noether audit: the formula, dpar metadata, TMB routing, and extractor key all
identify the admitted structured target as relmat `hu`, not count `mu`.

Grace audit: the validator, generated release artifacts, focused tests, claim
guard, and smoke runner agree on 90/104 practical rows, 34/37
basic-distribution recovery rows, 14/104 post-v1 rows, and no new support,
coverage, or denominator promotion.

## 9. What Did Not Go Smoothly

The first focused conversion-contract rerun failed on one stale expected
non-Gaussian audit bucket count. The regenerated dashboard had correctly moved
the row from rejected to point-only, but the test still expected the old 3/15
split. Updating the expectation to 2 rejected and 16 point-only made the test
match the current artifacts.

## 10. Known Residuals

- Hurdle structured effects remain limited to this exact
  `truncated_nbinom2()` relmat q1 `hu` gate.
- No denominator, profile, Wald, bootstrap, or coverage evidence exists for
  this row.
- q2/q4 hurdle covariance, labelled covariance, slopes, multiple structured
  providers, count-side structured fields for this family, bridge transport,
  and public support remain post-v1 or separate-design work.

## 11. Team Learning

Ada kept the slice scoped to one generated candidate row instead of broadening
the hurdle family. Rose and Fisher kept the status as fit-only with coverage
unauthorized. Gauss and Noether caught the important implementation detail: the
structured term must carry `dpars = "hu"` before the shared relmat builder runs,
otherwise the extractor key and SD bucket would drift back toward `mu`.

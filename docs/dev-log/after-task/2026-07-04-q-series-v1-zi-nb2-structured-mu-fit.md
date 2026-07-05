# After Task: Q-Series v1 Zero-Inflated NB2 Structured-Mu Fit

## 1. Goal

Move `qseries_count_mu_zeroinflated_nbinom2_structured_rejected` into the
Q-Series v1.0 practical surface as a narrow local fit-only row for fixed-`zi`
zero-inflated NB2 with a coordinate-spatial structured `mu` intercept. Keep all
interval, coverage, `inference_ready`, `supported`, q2/q4, REML, AI-REML,
bridge, and public-support claims out of scope.

## 2. Implemented

`drm_build_nbinom2_spec()` now permits the exact row-specific route
`bf(count ~ x + spatial(1 | site, coords = coords), sigma ~ 1, zi ~ 1)`. The
zero-inflated NB2 TMB data path now carries the existing structured-`mu`
precision inputs, and the `zi_nbinom2` objective adds the spatial `mu` field,
Gaussian precision prior, and direct `log_sd_phylo` reporting.

The extractors now expose the fitted row through `sdpars$mu`,
`ranef("spatial_mu")`, and `profile_targets()`. The first-four local smoke
adds `count_struct_mu_fit_zi_nbinom2_spatial`, and the Q-Series sidecars and
release reports now account for 88/104 practical v1.0 rows.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only fixed-covariance `spatial(1 | site, coords = coords)` in `mu` for
  zero-inflated NB2 with fixed `zi ~ 1`.
- Keep the row as local fit-only/extractor evidence with no denominator,
  retained-denominator recovery, or coverage authorization.
- Keep the existing direct-SD naming path as `log_sd_phylo` because current
  structured count routes share that internal profile-target channel.
- Synchronize public status wording so the exception is visible without
  becoming broad zero-inflated NB2 structured support.

Rejected alternatives:

- Do not unlock phylo, animal, relmat, or phylo-interaction zero-inflated NB2
  structured `mu` routes in this slice.
- Do not unlock zero-inflated NB2 structured slopes, labels, simultaneous
  providers, structured `zi`, structured `sigma`, or joint count covariance.
- Do not run Totoro or DRAC; this row has no denominator and no host-provenance
  claim.
- Do not promote intervals, coverage, `inference_ready`, `supported`, REML,
  AI-REML, q2/q4, bridge, or public-support wording.

## 3b. Mathematical Contract

The admitted local row is:

```text
y_i ~ zero-inflated NB2(mu_i, sigma, pi)
log(mu_i) = X_i beta + u_site[i]
log(sigma_i) = alpha_0
logit(pi_i) = gamma_0
u ~ N(0, sigma_spatial^2 Q^{-1})
```

This establishes that the zero-inflated NB2 likelihood can route one
coordinate-spatial structured `mu` intercept through the existing sparse
precision machinery and expose the fitted SD. It does not establish interval
reliability, coverage, retained-denominator recovery, broad provider support,
structured zero-inflation support, or structured overdispersion support.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-count-structured-mu.R`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-count-structured-mu-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv`
- `docs/dev-log/release-audits/q-series-v1-release-status.md`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv`
- `docs/dev-log/release-audits/q-series-v1-90pct-review-packet.tsv`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py
  tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py
  tools/qseries_v1_claim_guard.py tools/qseries-tranche-scaffold.py`: passed.
- Extracted dashboard JavaScript from `docs/dev-log/dashboard/index.html` and
  ran bundled `node --check`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e
  "devtools::document()"`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e
  "devtools::test(filter = 'count-structured-mu')"`: passed, 354 tests.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e
  "devtools::test(filter = 'nongaussian-structured-boundary')"`: passed, 69
  tests.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file
  tools/qseries-v1-first-four-rejection-smoke.R`: passed.
- `python3 tools/qseries_v1_release_ledger.py --write --write-status
  --summary`: passed with practical v1.0 row surface 88/104, Gaussian core
  56/67, basic-distribution recovery 32/37, exact `inference_ready` 8/104,
  `supported` 0/104, and post-v1 16/104.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/qseries_v1_release_check.py --write-report --write-candidates
  --summary`: passed with `rows_to_90=6`, `candidate_review_rows=16`, and
  `ninety_review_packet_rows=6`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/qseries_v1_release_check.py --summary --check-report
  --check-candidates`: passed with the same row accounting.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`, 104
  Q-Series cells, 8 inference-evidence summary rows, 2 count structured-`mu`
  rejection rows, and 37 non-Gaussian audit rows.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e
  "devtools::test(filter = 'structured-re-conversion-contracts')"`: passed,
  22,279 tests.
- `python3 tools/qseries_v1_claim_guard.py --summary`: passed after public
  prose sync.

## 6. Tests of the Tests

The focused `count-structured-mu` test checks the positive path by requiring
convergence, positive-Hessian status, the `spatial` structured type, `q = 1`,
visible `sdpars$mu`, visible `ranef("spatial_mu")`, a direct
`profile_targets()` row, finite predictions, and positive overdispersion.

The same file checks a failure path: zero-inflated NB2 spatial structured `mu`
slopes still fail at the intercept gate. During implementation, this test
exposed that `split_tmb_sdpars()` and `split_tmb_random_effects()` did not yet
include `zi_nbinom2`, so the fit could run but the extractor contract was not
complete. Adding the model type to those extractor allowlists made the test
pass for the intended reason.

## 7a. Issue Ledger

`gh` is not installed in this local environment, so issue inspection used the
public GitHub search API instead. Search for the exact support-cell id
`qseries_count_mu_zeroinflated_nbinom2_structured_rejected` returned zero issue
hits. Search for `"zero-inflated NB2" "structured mu"` returned one broad old
tutorial gate, `itchyshin/drmTMB#57`, which is not a direct row-level task for
this checkpoint. No issue was opened, commented on, or closed.

## 8. Consistency Audit

Rose audit: the moved row is no longer present in the
count-structured-`mu` rejection contract. Mission Control reports 104 Q-Series
cells, 8 exact `inference_ready` rows, 0 structured `supported` rows, 37
non-Gaussian audit rows, and 2 active count-structured-`mu` rejection rows.

Fisher audit: coverage remains unauthorized. The row is `point_fit` with
`coverage_status = planned`, not an interval or coverage claim.

Gauss audit: the TMB branch adds the same sparse structured-field prior and
direct SD reporting used by neighbouring count structured `mu` routes, scoped
to `model_type == 9` for zero-inflated NB2.

Noether audit: the symbolic contract, formula grammar, and TMB implementation
all route a single spatial field into `log(mu)`, while fixed `zi` and fixed
`sigma` remain ordinary fixed-effect predictors.

Grace audit: the validator, generated release artifacts, focused tests, claim
guard, and stale wording scans agree on 88/104 practical rows, 32/37
basic-distribution recovery rows, 16/104 post-v1 rows, and no new support or
coverage promotion.

Stale wording scans covered README, ROADMAP, NEWS, known limitations, formula
grammar, and the formula vignette. The scan first found old wording that said
zero-inflated NB2 structured routes were fully planned; those locations now
name the exact fixed-`zi` spatial `mu` exception and keep all broader
zero-inflated NB2 structured routes closed. A follow-up scan found no remaining
old "two gates" or broad zero-inflated structured-effect contradictions.

## 9. What Did Not Go Smoothly

The fit path was cheaper than the audit path. The first implementation made the
TMB objective run but did not expose `sdpars$mu` or `spatial_mu` random effects
because the zero-inflated NB2 model type was missing from extractor allowlists.
The prose cleanup was also broader than expected: README, ROADMAP, NEWS,
known limitations, formula grammar, and the vignette all needed row-specific
wording to avoid stale planned/support contradictions.

The local GitHub CLI was unavailable, so issue inspection needed a public API
fallback. That is fine for this public repo checkpoint, but it is a reminder
not to assume every GitHub surface is available just because browser auth is
working.

`devtools::document()` also produced unrelated Rd link-normalization churn under
the local roxygen toolchain. Because no roxygen source changed, that generated
noise was left out of the commit to keep the slice focused.

## 10. Known Residuals

- No retained-denominator recovery was run.
- No coverage, interval, `inference_ready`, or `supported` status was added.
- Zero-inflated NB2 structured slopes, labelled q2/q4 count covariance,
  simultaneous structured providers, structured `zi`, structured `sigma`, REML,
  AI-REML, bridge support, and public support remain closed.
- Q-Series v1.0 is still not complete: the practical surface is 88/104
  (84.6%), exact `inference_ready` is 8/104, and `supported` authority is
  0/104.

## 11. Team Learning

For cheap v1.0 speedups, a fit-only row is not done when the optimizer returns.
The extractor contract, dashboard accounting, release guard, public wording,
and stale-limitations inventory have to move together. Kim's economy rule held:
we used local deterministic evidence only and did not spend Totoro or DRAC
compute on a row that still has no denominator claim.

# After Task: Q-Series v1 Poisson Labelled-Scalar Spatial Mu Fit

## 1. Goal

Move `qseries_count_mu_labelled_q2_rejected` into the Q-Series v1.0
practical surface as a narrow local fit-only row for `poisson()` count `mu`
with one labelled scalar spatial intercept:

```r
bf(count ~ x + spatial(1 | p | site, coords = coords))
```

Keep all denominator, interval, coverage, `inference_ready`, `supported`,
q2/q4 covariance, labelled slopes, simultaneous providers, REML, AI-REML,
bridge, and public-support claims out of scope.

## 2. Implemented

`drm_build_poisson_spec()` now admits only the exact row-specific
labelled-scalar route for spatial count `mu`. The validator treats the
covariance label as a scalar block tag only when all of these conditions hold:
the family is Poisson, the structured provider is `spatial`, the term is
intercept-only, there is no zero-inflation term, and the structured field stays
q1.

The fitted route reports the existing spatial q1 SD through `sdpars$mu`, the
conditional field through `ranef("spatial_mu")`, and a direct SD target through
`profile_targets()`. The first-four local smoke now records the row as
`expected_fit`, the count structured-`mu` rejection contract keeps only the
simultaneous-provider rejection, and the Q-Series release artifacts now account
for 91/104 practical v1.0 rows.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only `spatial(1 | p | site, coords = coords)` for ordinary
  `poisson()` count `mu`.
- Treat `p` as a scalar covariance-block label, not as evidence for q2/q4
  covariance.
- Keep the row as local fit-only/extractor evidence with no retained
  denominator, recovery denominator, or coverage authorization.
- Update README, NEWS, known limitations, the completion map, dashboard README,
  Mission Control sidecars, release packets, and focused tests so the row
  movement is visible without inflating status.

Rejected alternatives:

- Do not unlock labelled spatial slopes, simultaneous structured providers,
  labelled NB2 count routes, zero-inflated labelled count routes, or correlated
  count covariance.
- Do not run Totoro, DRAC, or a local retained-denominator smoke; this row has
  no denominator and no host-provenance claim.
- Do not promote intervals, coverage, `inference_ready`, `supported`, REML,
  AI-REML, q2/q4, bridge support, or public-support wording.

## 3b. Mathematical Contract

The admitted local row is:

```text
y_i ~ Poisson(mu_i)
log(mu_i) = X_i beta + Z_i u
u ~ N(0, sigma_spatial_mu^2 K_spatial)
```

The label in `spatial(1 | p | site, coords = coords)` names the scalar
structured block and leaves the latent field one-dimensional. This establishes
that the labelled scalar form can route through the existing spatial q1
count-`mu` machinery and expose the fitted SD. It does not establish
correlated q2/q4 covariance, interval reliability, coverage, retained
denominator recovery, bridge support, or public support.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-count-structured-mu.R`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-count-structured-mu-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
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
  --check-candidates`: passed with practical v1.0 surface 91/104 (87.5%),
  basic-distribution recovery 35/37 (94.6%), exact `inference_ready` 8/104,
  `supported` authority 0/104, and post-v1 13/104.
- `python3 tools/qseries_v1_claim_guard.py --summary`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file -e
  "Sys.setenv(NOT_CRAN='true', OMP_NUM_THREADS='1',
  OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1');
  devtools::test(filter = 'count-structured-mu', reporter = 'summary')"`:
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
- `R_PROFILE_USER=/dev/null
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file
  tools/qseries-v1-first-four-rejection-smoke.R --output
  /tmp/qseries-v1-first-four-labelled-scalar.tsv`: passed and wrote 18
  result rows plus the header.

## 6. Tests of the Tests

The focused count structured-`mu` test checks the positive path by requiring
optimizer convergence, `pdHess`, `model_type = "poisson"`, `type = "spatial"`,
`q = 1`, `covariance_label = "p"`, `covariance_mode = "scalar"`, a visible
`spatial_mu` random-effect block, and a direct profile target for
`sd:mu:spatial(1 | p | site)`.

The same test file keeps neighbouring gates closed: labelled spatial slopes
still fail with the unlabelled-q1 message, and other count structured routes
retain their previous boundary checks. The conversion-contract suite first
failed on one stale first-four debug-contract failure-stage ordering, which
confirmed it was checking the regenerated candidate queue. Updating the
expected order to simultaneous-provider, planned one-slope boundary, animal
q2-plus sigma, and relmat q2-plus sigma made the test pass.

## 7a. Issue Ledger

No GitHub issue was opened, commented on, or closed in this slice. The change
is a narrow local v1 recovery row and does not create a public support claim.

## 8. Consistency Audit

Rose audit: the moved row is no longer present in the count structured-`mu`
rejection contract. Mission Control reports 104 Q-Series cells, 8 exact
`inference_ready` rows, 0 structured `supported` rows, 37 non-Gaussian audit
rows, and 1 count structured-`mu` rejection row.

Fisher audit: coverage remains unauthorized. The row is `point_fit` with
`coverage_status = planned`, not an interval or coverage claim.

Gauss audit: the implementation reuses the existing Poisson spatial q1
Laplace route and changes only the formula gate that previously rejected the
scalar label. There is no new covariance parameterization.

Noether audit: the formula, row status, extractor names, and profile target
all describe one scalar spatial `mu` SD. They do not describe q2/q4 latent
correlations.

Grace audit: the validator, generated release artifacts, focused tests, claim
guard, and smoke runner agree on 91/104 practical rows, 35/37
basic-distribution recovery rows, 13/104 post-v1 rows, and no new support,
coverage, or denominator promotion.

## 9. What Did Not Go Smoothly

The first release preflight rerun failed because a NEWS sentence tied the new
labelled-scalar route too closely to Q-Series v1.0 wording. The claim guard
treated that as potential release-authority inflation. Rewording the sentence
to describe only the labelled-scalar spatial count route made the intended
local fit-only boundary clear.

The first conversion-contract rerun failed on one stale first-four
debug-contract failure-stage order. The generated artifacts were correct after
the labelled-scalar row moved out of the queue; the test still expected the
old row ordering.

## 10. Known Residuals

- Labelled count support remains limited to this exact ordinary-Poisson
  spatial q1 scalar-label gate.
- No denominator, profile interval, Wald interval, bootstrap, or coverage
  evidence exists for this row.
- q2/q4 count covariance, labelled slopes, simultaneous structured providers,
  NB2 labelled routes, zero-inflated labelled routes, bridge transport, and
  public support remain post-v1 or separate-design work.

## 11. Team Learning

Ada kept the slice scoped to one generated candidate row. Rose and Fisher kept
the status as fit-only with coverage unauthorized. Gauss and Noether clarified
that a labelled scalar tag is not a covariance expansion. Grace's claim guard
caught the one wording slip before it could harden into release prose.

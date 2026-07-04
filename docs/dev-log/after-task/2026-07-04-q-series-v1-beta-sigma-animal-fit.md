# After Task: Q-Series v1 Beta Sigma Animal Local Fit-Only Recovery

## 1. Goal

Move the narrow `beta()` `sigma` animal intercept row from unsupported
post-v1.0 design work to local fit-only recovery for the v1.0
basic-distribution surface, without opening interval, coverage, bridge, q2/q4,
REML, AI-REML, `inference_ready`, `supported`, or public-support claims.

## 2. Implemented

`drm_build_beta_ls_spec()` now accepts exactly one structured beta scale route:
`sigma ~ animal(1 | id, pedigree = ped)` or the existing known-covariance
equivalent using `A` or `Ainv`. The beta builder strips the structured term
from the fixed scale formula, stamps the structured endpoint as `sigma`, routes
the latent field contribution into the beta scale predictor, and reports the
direct animal structured SD through `sdpars$sigma`.

The first-four smoke remains a local gate smoke. It now expects local fits for
beta animal `mu`, Gamma relmat `mu`, Student spatial `mu`, and beta animal
`sigma`, while ordinal phylo `mu` remains an expected pre-optimization
rejection.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only the beta `sigma` animal intercept route as local fit-only recovery.
- Keep beta `sigma` structured slopes, labelled covariance, q2/q4,
  zero-one beta, bridge, REML, AI-REML, intervals, and coverage deferred.
- Relabel the current generated review packet as the post-75% next-four packet
  because this slice reaches 78/104 practical rows.

Rejected alternatives:

- Do not treat the beta sigma animal fit as a retained denominator.
- Do not move the row to `inference_ready` or `supported`.
- Do not broaden the row into beta location-scale block support or public
  structured-covariance support.

## 3b. Mathematical Contract

The admitted local fit-only route is:

```text
y_i ~ beta(mu_i, phi_i)
logit(mu_i) = X_i beta
log(sigma_i) = Z_i gamma + u_id[i]
u ~ N(0, sigma_animal^2 A)
```

The route uses the existing beta scale-to-precision mapping. This is point-fit
evidence only. It does not establish retained denominators, Wald/profile
intervals, coverage, `inference_ready`, `supported`, REML, AI-REML, q2/q4
behavior, bridge behavior, beta structured slopes, simultaneous beta
location-scale support, or zero-one beta support.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_release_check.py`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/release-audits/q-series-v1-release-status.md`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv`
- `docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-candidate-design-contract.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-candidate-debug-fixture-contract.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "invisible(parse('R/drmTMB.R')); invisible(parse('tools/qseries-v1-first-four-rejection-smoke.R')); invisible(parse('tests/testthat/test-nongaussian-structured-boundary.R')); invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R')); cat('parse_ok\n')"`
- `python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "pkgbuild::compile_dll(debug = FALSE, quiet = TRUE); cat('compile_dll_ok\n')"`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary', reporter = 'summary')"`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`

## 6. Tests of the Tests

The first `nongaussian-structured-boundary` rerun failed because the test still
expected the beta sigma animal intercept route to reject. The corrected test
now checks the intercept route as a fit-only row and keeps a beta sigma animal
slope as the fail-closed case. The conversion-contract test passed after the
non-Gaussian status counts moved to 18 recovery-only, 0 caveat, 14 rejected, 1
planned, and 4 point-only rows.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. This was local v1.0 Q-Series
implementation, dashboard, and validation work on the active branch.

## 8. Consistency Audit

Rose boundary: this slice changes one local fit-only support cell and no
interval/coverage/support status. The Q-Series board still has 104 support
cells, 8 exact `inference_ready` anchors, 0 `supported` authority rows, 0 q4
coverage-authorized rows, and no non-Gaussian interval/coverage promotion.

Fisher boundary: the beta animal sigma smoke is not a retained denominator. It
is a deterministic local fit check with no profile, Wald, coverage, MCSE, or
admission interpretation.

Grace boundary: Mission Control and the generated v1 release checker both pass
after regenerating the release ledger, release status, preflight report, and
candidate-review artifacts.

## 9. What Did Not Go Smoothly

The first local smoke implementation routed the fitted beta animal scale SD to
the `mu` endpoint because the structured term still carried the default `mu`
endpoint label. Stamping the structured beta sigma term with `dpars = "sigma"`
and making the random-effect key endpoint-aware fixed the extractor and support
cell evidence.

The boundary test also had one stale rejection expectation after the route was
admitted. It now asserts the correct fail-closed slope boundary.

## 10. Known Residuals

The row remains local fit-only recovery evidence. It is not interval-ready,
coverage-ready, `inference_ready`, `supported`, bridge-supported, q2/q4,
REML/AI-REML, a beta location-scale block, zero-one beta support, or public
support. The current post-75% next-four review packet starts with ordinal `mu`
phylo plus NB2 `sigma` one-slope animal, phylo, and relmat rows, all still
design-only.

## 11. Team Learning

Endpoint labels are part of the evidence boundary. When a structured
non-Gaussian route is admitted for a non-`mu` endpoint, the parser, TMB
contribution, extractor key, support-cell row, and smoke expectation must all
name the endpoint consistently.

## Next Actions

Stop at this clean 75% practical-surface checkpoint unless the next explicit
task is to review the post-75% next-four packet. Any further row movement still
needs row-specific recovery evidence plus Rose/Fisher/Grace review, and still
authorizes no coverage, `inference_ready`, `supported`, REML, AI-REML, q4/q8,
or public-support claim.

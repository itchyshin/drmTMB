# After Task: Q-Series v1 Beta Mu Animal Local-Debug Fixture Contract

## Goal

Add the fail-closed local-debug fixture contract for the first Q-Series v1.0
post-v1 design candidate, `qseries_beta_mu_animal_rejected`.

## Implemented

`tools/qseries_v1_release_check.py` now generates and checks
`docs/dev-log/release-audits/q-series-v1-beta-mu-animal-debug-fixture-contract.tsv`
as part of the existing candidate bundle. The generated preflight report has a
first-candidate local-debug fixture section, and the focused
conversion-contract test checks the new TSV and report wording.

## Mathematical Contract

The fixture contract does not add or run a model. It links the prior beta
animal design target, `y_i ~ beta(mu_i, phi)`,
`logit(mu_i) = X_i beta + u_id[i]`, `u ~ N(0, sigma_animal^2 A)`, and
`phi = 1 / sigma^2`, to the current observed rejection
`Structured non-Gaussian paths` at the pre-optimization formula gate.

## Files Changed

- `tools/qseries_v1_release_check.py`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-beta-mu-animal-debug-fixture-contract.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py tools/validate-mission-control.py`
- `python3 tools/qseries_v1_release_check.py --summary --write-report --write-candidates`
- `python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`

## Tests Of The Tests

The focused conversion-contract test failed once because the generated TSV had
the debug fixture claim boundary but the generated Markdown preflight report did
not expose that boundary. After adding the report sentence, the same focused
test passed with `DONE`.

## Consistency Audit

This slice changes no R API, formula grammar, likelihood, TMB code, object
shape, support-cell status, README claim, NEWS claim, or known-limitations
claim. The beta `mu` animal row remains `basic_distribution_post_v1_design`
with unsupported fit, interval, and coverage status.

## GitHub Issue Maintenance

No GitHub issue was opened or commented on. This is a local release-prep
fixture contract under the existing Q-Series v1.0 reset.

## What Did Not Go Smoothly

The first focused R test run caught a human-facing report gap: the TSV had the
right claim boundary, but the Markdown report did not state it. The fix was to
make the generated report carry the same no-implementation/no-coverage boundary
as the TSV.

## Team Learning

The v1.0 speedup tooling should make stop rules visible in both machine-readable
TSV artifacts and human-readable reports. A generated TSV alone is too easy to
miss during review.

## Known Limitations

The debug fixture contract is not implementation evidence, recovery evidence,
interval evidence, coverage evidence, `inference_ready`, `supported`, REML,
AI-REML, bridge, or public-support authority. It authorizes no local fit, host
compute, denominator row, support-cell edit, or release claim.

## Next Actions

Use this contract to review whether a future local debug fixture runner is worth
writing for beta `mu` animal. If that runner is written, keep it local-only and
fail-closed until Rose/Fisher/Grace approve a separate status movement.

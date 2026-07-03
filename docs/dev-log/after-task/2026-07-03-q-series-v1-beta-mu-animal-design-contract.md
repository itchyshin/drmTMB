# After Task: Q-Series v1 Beta Mu Animal Design Contract

## Goal

Create the first row-specific design/recovery contract from the generated 75%
review packet, starting with `qseries_beta_mu_animal_rejected`.

## Implemented

`tools/qseries_v1_release_check.py` now generates and checks
`docs/dev-log/release-audits/q-series-v1-beta-mu-animal-design-contract.tsv`.
The generated preflight report includes a first-candidate design-contract
section, and the focused conversion-contract test checks the new TSV.

## Mathematical Contract

The contract records the proposed model shape only:
`y_i ~ beta(mu_i, phi)`, `logit(mu_i) = X_i beta + u_id[i]`,
`u ~ N(0, sigma_animal^2 A)`, and `phi = 1 / sigma^2`. This is a design target
for review, not fitted or validated evidence.

## Files Changed

- `tools/qseries_v1_release_check.py`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-beta-mu-animal-design-contract.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py tools/validate-mission-control.py`
- `python3 tools/qseries_v1_release_check.py --summary --write-report --write-candidates`
- `python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py | tail -n 1`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`

## Tests Of The Tests

The focused conversion-contract test reads the generated TSV, checks the exact
schema, requires the `qseries_beta_mu_animal_rejected` cell, checks the symbolic
model terms, requires strict `(0, 1)` response support, and asserts
`no_compute_authorized`, `coverage_not_authorized`, and `do_not_promote`.

## Consistency Audit

This slice changes no R API, formula grammar, likelihood, TMB code, package
object, support-cell status, README claim, NEWS claim, or known-limitations
claim. The beta/animal row remains `basic_distribution_post_v1_design` with
unsupported fit, interval, and coverage status.

## GitHub Issue Maintenance

No GitHub issue was opened or commented on. This is a local release-prep design
contract for the existing Q-Series v1.0 reset.

## What Did Not Go Smoothly

The useful boundary was narrower than "start beta animal implementation". The
honest movement was to write the model, DGP, failure, and validator contract
first, because the current support cell has exact rejection evidence rather
than a runnable route.

## Team Learning

The v1.0 campaign gets faster when each candidate row has an explicit
pre-code contract. That lets Kim choose the next slice cheaply while Rose keeps
the distinction between design, recovery evidence, and status movement intact.

## Known Limitations

The contract is not implementation evidence, recovery evidence, interval
evidence, coverage evidence, `inference_ready`, `supported`, REML, AI-REML,
bridge, or public-support authority. It authorizes no local fit, host compute,
or denominator.

## Next Actions

Review the beta `mu` animal design contract. If it passes review, the next
slice can write a fail-closed local debug fixture contract; do not edit the
support cell or run compute from this design contract alone.

# After Task: Q-Series v1 First-Four Contract Bundle

## Goal

Generalize the Q-Series v1.0 75% review packet from one beta `mu` animal
contract into generated design and local-debug contracts for all four first
candidate rows.

## Implemented

`tools/qseries_v1_release_check.py` now generates and checks
`docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv` and
`docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv`.
The generated preflight report has 75% first-four design and local-debug
fixture sections, and the focused conversion-contract test validates both new
TSVs.

## Mathematical Contract

The bundle records four design targets only:

- beta `mu` animal: beta response on `(0, 1)` with a logit location predictor
  and animal known-covariance random effect.
- Gamma `mu` relmat: positive response with a log location predictor and relmat
  known-covariance random effect.
- ordinal `mu` phylo: ordered response with a cumulative-logit location shift
  and phylogenetic known-covariance random effect.
- Student `mu` spatial: real-valued response with a location predictor and
  spatial known-covariance random effect.

Each row keeps the current observed rejection,
`Structured non-Gaussian paths`, as the expected current failure.

## Files Changed

- `tools/qseries_v1_release_check.py`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py tools/validate-mission-control.py`
- `python3 tools/qseries_v1_release_check.py --summary --write-report --write-candidates`
- `python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`

## Tests Of The Tests

The focused conversion-contract test reads both first-four TSVs, checks exact
schemas, requires all four expected cell IDs, checks current unsupported
statuses, verifies row-specific model/DGP text, and asserts
`no_compute_authorized`, `coverage_not_authorized`, and `do_not_promote` for
every row. It also checks that the generated preflight report exposes the new
first-four sections.

## Consistency Audit

This slice changes no R API, formula grammar, likelihood, TMB code, object
shape, support-cell status, README claim, NEWS claim, or known-limitations
claim. The practical v1.0 row surface remains 74/104 (71.2%).

## GitHub Issue Maintenance

No GitHub issue was opened or commented on. This is a local release-prep
contract bundle under the existing Q-Series v1.0 reset.

## What Did Not Go Smoothly

The main design choice was keeping the beta-specific artifacts while adding the
first-four bundle. That avoids breaking existing review anchors while making the
75% review packet complete.

## Team Learning

The next Q-Series v1.0 moves should be generated in small bundles where the
candidate packet, design contract, debug fixture contract, preflight report, and
focused test all agree. That is faster than hand-maintaining one-off TSVs and
safer than letting a debug fixture become status evidence.

## Known Limitations

The first-four contract bundle is not implementation evidence, recovery
evidence, interval evidence, coverage evidence, `inference_ready`, `supported`,
REML, AI-REML, bridge, or public-support authority. It authorizes no code,
local fit, host compute, denominator row, support-cell edit, or release claim.

## Next Actions

Review the four contract rows with Rose/Fisher/Grace. If they approve, the next
slice can choose one local-only fail-closed debug runner to write; keep status
movement separate from that runner.

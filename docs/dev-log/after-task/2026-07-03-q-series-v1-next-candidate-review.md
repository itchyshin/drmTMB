# After Task: Q-Series v1 Next-Candidate Review

## Goal

Make the Q-Series v1.0 preflight identify which post-v1 rows should be reviewed
first if the team wants to move from the current 71.2% practical row surface
toward 75% or 80%, without promoting any row.

## Implemented

`tools/qseries_v1_release_check.py` now generates
`docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv` from the
104-row release ledger. The generated preflight report includes the top ten
candidate-review rows, and the one-line CLI summary reports that 30 post-v1
candidate-review rows remain.

## Mathematical Contract

The practical surface stays 74/104 rows. Reaching 75% requires 78/104 rows, so
the generated queue marks the first four rows as
`first_four_to_review_for_75_percent`. Reaching 80% requires 84/104 rows, so
the next six rows are marked `additional_six_to_review_for_80_percent`. The
remaining 20 rows stay in `later_post_v1_review_queue`.

## Files Changed

- `tools/qseries_v1_release_check.py`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv`
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

The focused conversion-contract test now checks the generated TSV schema, 30
candidate rows, exact 4/6/20 target-band split, exact first four candidate cell
IDs, and all-row `coverage_not_authorized` plus `do_not_promote` decisions. It
also runs the preflight with `--check-candidates`, so a stale generated TSV
fails inside the test.

## Consistency Audit

The candidate queue is review-only. Every row keeps a claim boundary that says
the row is not a support-cell edit, `inference_ready`, `supported`, coverage,
q4/q8, REML, AI-REML, bridge, or public-support evidence. No public API,
formula grammar, likelihood code, package object, README claim, NEWS release
claim, support-cell status, or host denominator changed.

## GitHub Issue Maintenance

No GitHub issue was opened or commented on. This is local release-prep tooling
for the existing Q-Series v1.0 status reset.

## What Did Not Go Smoothly

The first deterministic ranking treated specialized count-design rows as equal
to simple q1 location-family gaps. I added a small complexity sort so the first
four review rows are beta, Gamma, ordinal, and Student q1 location-family design
gaps before the more specialized count rows.

## Team Learning

Generated candidate queues are a better fit than hand-written recommendations
for this campaign. They let Kim push speed and economy while Rose can still
audit that every row remains blocked from status movement until evidence exists.

## Known Limitations

The queue is not implementation evidence. Moving any candidate into the
practical v1.0 surface still requires row-specific implementation or recovery
evidence plus review. The queue authorizes no compute, no coverage job, no
promotion, no `inference_ready`, no `supported`, and no public support.

## Next Actions

Use the first four candidate rows only as review targets if the next campaign
slice aims for 75%. The cheapest honest next move is to write a row-specific
design/recovery contract for one candidate family, then decide whether any
implementation work is appropriate before touching status.

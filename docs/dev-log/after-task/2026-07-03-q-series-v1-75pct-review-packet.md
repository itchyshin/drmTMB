# After Task: Q-Series v1 75 Percent Review Packet

## Goal

Turn the generated 75% candidate band into a concrete review packet so the next
Q-Series v1.0 slice can start from exact row-level requirements instead of
manually interpreting the candidate queue.

## Implemented

`tools/qseries_v1_release_check.py` now writes and checks
`docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv` whenever the
candidate artifacts are generated or checked. The preflight report now includes
the same four-row packet as a design/recovery checklist.

## Mathematical Contract

The practical v1.0 row surface remains 74/104. A 75% surface requires 78/104
rows, so the packet contains exactly the first four generated review rows:
`qseries_beta_mu_animal_rejected`, `qseries_gamma_mu_relmat_rejected`,
`qseries_ordinal_mu_phylo_rejected`, and
`qseries_student_mu_spatial_rejected`.

## Files Changed

- `tools/qseries_v1_release_check.py`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv`
- `docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv`
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

The focused conversion-contract test now reads the 75% packet TSV, checks its
schema, requires exactly four rows, requires the packet row IDs to match the
first four candidate-review rows, and asserts `no_compute_authorized`,
`coverage_not_authorized`, and `do_not_promote` for every packet row.

## Consistency Audit

The packet is a design/recovery checklist only. It authorizes no code change,
compute, denominator, coverage job, support-cell edit, `inference_ready`,
`supported`, q4/q8, REML, AI-REML, bridge, or public-support claim. No R API,
formula grammar, likelihood, package object, README release claim, NEWS release
claim, or support-cell status changed.

## GitHub Issue Maintenance

No GitHub issue was opened or commented on. This is a local release-prep
artifact that makes the next candidate review cheaper.

## What Did Not Go Smoothly

The main design choice was whether to add another standalone command. I kept
the packet under `--write-candidates` and `--check-candidates` so the routine
preflight remains a single command and agents cannot forget the packet drift
check.

## Team Learning

For the v1.0 reset, the next speed gain is not raw compute; it is removing
manual interpretation between the row ledger and the next decision. A generated
packet gives Kim a short path to 75% while keeping Rose's no-claim boundary
visible on every row.

## Known Limitations

The packet is not implementation or recovery evidence. Each row still needs a
row-specific design/recovery contract, and any later status movement would need
separate evidence and Rose/Fisher/Grace review.

## Next Actions

Start with `qseries_beta_mu_animal_rejected` if the next slice aims for 75%.
Write a row-specific beta q1 `mu` animal design/recovery contract first; do not
run compute or edit support-cell status from this packet alone.

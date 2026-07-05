# After Task: Q-Series v1 90 percent review packet

## 1. Goal

Make the next Q-Series v1.0 decision faster by turning the current
`rows_to_90=7` counter into a generated review packet, without changing any
support-cell status, compute authorization, coverage claim, or public-support
claim.

## 2. Implemented

`tools/qseries_v1_release_check.py` now derives the number of rows needed for
the 90 percent practical-surface target from the current ledger accounting and
writes `docs/dev-log/release-audits/q-series-v1-90pct-review-packet.tsv`.

The packet lists the first seven current candidate rows:
`qseries_ordinal_mu_phylo_rejected`,
`qseries_truncnbinom2_hu_relmat_rejected`,
`qseries_count_mu_labelled_q2_rejected`,
`qseries_count_mu_simultaneous_structured_types_rejected`,
`qseries_count_mu_zeroinflated_nbinom2_structured_rejected`,
`qseries_nongaussian_structured_slope_neighbors_planned`, and
`qseries_animal_q2_plus_q2_sigma_rejected`.

Every row remains a review contract only, with no compute authorized, no
coverage authorized, and no promotion authorized. Rose/Fisher/Grace remain the
blocking review group before any code, compute, or support-cell edit.

## 3a. Decisions and Rejected Alternatives

- Generated the packet from the existing candidate queue instead of creating a
  hand-maintained list.
- Kept the packet bound to the current `rows_to_90` counter so it will fail
  validator checks if the generated artifact drifts.
- Did not promote q4, q6, q8, non-Gaussian interval, bridge, REML, AI-REML,
  `inference_ready`, or `supported` status.
- Did not run Totoro, DRAC, or local simulation compute. This slice is decision
  hygiene, not evidence generation.

## 4. Files Touched

- `tools/qseries_v1_release_check.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/release-audits/q-series-v1-90pct-review-packet.tsv`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --write-report --write-candidates --summary`: passed with `mission_control=ok`, practical v1 surface 87/104, `rows_to_90=7`, and `ninety_review_packet_rows=7`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`: passed with practical v1 surface 87/104, exact `inference_ready` 8/104, `supported` 0/104, and post-v1 rows 17/104.
- `python3 -m py_compile tools/qseries_v1_release_check.py tools/validate-mission-control.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py tools/qseries-tranche-scaffold.py`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts')"`: passed with 22,280 tests, no failures, warnings, or skips.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-04-q-series-v1-90pct-review-packet.md')"`: passed with `after-task structure check passed`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused conversion-contract test now reads the generated 90 percent packet,
checks that it has exactly seven rows, checks the current seven cell IDs in
order, and asserts the no-compute, no-coverage, no-promotion, and no-claim
boundaries. It also checks the generated preflight report names the packet and
the current `rows_to_90` counter.

## 7a. Issue Ledger

No GitHub issue was opened or closed. This is local release-prep tooling for
the active Q-Series v1.0 readiness campaign, and it changes no user-facing
package behaviour. I attempted a targeted issue sweep with
`gh issue list -R itchyshin/drmTMB --search "Q-Series v1 90 percent review packet" --limit 5`,
but this shell does not currently have the `gh` command installed.

## 8. Consistency Audit

- Mission Control still reports 104 Q-Series cells.
- Practical v1.0 row surface remains 87/104 (83.7%).
- Basic-distribution recovery remains 31/37 (83.8%).
- Exact `inference_ready` rows remain 8/104.
- Structured `supported` authority remains 0/104.
- q4 coverage-authorized rows remain 0.
- Post-v1.0 validation/design remains 17/104.

## 9. What Did Not Go Smoothly

A temporary `--skip-mission-control --check-report` run reported that the
checked-in report differed from the generated report. That was expected once
the canonical report had been regenerated with full Mission Control enabled,
because the report records whether Mission Control was skipped or passed. The
canonical validation command is the full non-skip
`tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
run.

## 10. Known Residuals

The packet is not implementation evidence. The seven rows still need
row-specific design, DGP/extractor expectation, local debug or explicit
rejection evidence, and Rose/Fisher/Grace review before any status movement.
No retained denominator, coverage grid, public documentation claim, bridge
claim, q4/q8 claim, REML claim, AI-REML claim, `inference_ready`, or
`supported` status is added.

## 11. Team Learning

The fastest honest path to 90 percent is not more blanket compute. It is a
generated row-specific review queue that forces the next decision to name the
minimum evidence needed before any code, compute, or support-cell edit.

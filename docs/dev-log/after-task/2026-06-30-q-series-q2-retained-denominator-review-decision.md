# After Task: Q-Series q2 Retained-Denominator Review Decision

## Goal

Turn the five-row q2 retained-denominator review synthesis into an explicit
Fisher/Rose/Grace decision layer for the widget: no top-up, no status edit, and
no support-cell promotion until a row-specific repair contract exists.

## Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-review-decision.tsv`
and the generator
`tools/summarize-structured-re-q2-retained-denominator-review-decision.R`.
The new decision table records five blocked decisions over the imported
Rorqual SR150 q2 retained-denominator evidence, including min coverage, max
MCSE, denominator/finiteness/miss signals, blocker targets, and the next gate.

The support-cell table, Gaussian low-q status audit, row-selection table, and
closure triage now point the affected q2 rows at the decision layer. This makes
the widget say what the evidence actually says: the rows were tried, but
top-up and promotion are blocked.

## Mathematical Contract

No likelihood, formula grammar, parameterization, estimator, interval equation,
or correction changed. This is a status/evidence contract only. The decision
layer keeps q2 intercept targets separate from q2 slope evidence, q2-plus-q2
evidence, sigma evidence, q4/q8, non-Gaussian rows, REML, and AI-REML.

## Files Changed

- `tools/summarize-structured-re-q2-retained-denominator-review-decision.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-review-decision.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv`
- `docs/dev-log/check-log.md`

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-review-decision.R --overwrite=true`
- `python3 -m py_compile tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-q2-retained-denominator-review-decision.R"))'`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R"))'`
- Scoped `git diff --check` over the validator, focused test, decision
  summarizer, decision TSV, and synced dashboard TSVs.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
  passed with `mission_control_ok`, including five q2 retained-denominator
  review-decision rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`
  passed with 9859 PASS / 0 FAIL / 0 WARN / 0 SKIP.

Full `devtools::test()`, `devtools::check()`, and `pkgdown::check_pkgdown()`
were not rerun for this narrow dashboard/status contract update.

## Tests Of The Tests

Mission-control now validates the decision TSV directly: exact fields, five
exact cell IDs, exact Fisher/Rose/Grace decision statuses, exact min coverage
and max MCSE values, links back to the synthesis and pregrid source tables,
support-cell status `point_fit/planned/planned`, blocker-target text, and the
cluster stop rule.

The focused conversion-contract test now checks that support cells, the low-q
audit, and row-selection rows point at the decision table, not the older
synthesis table. The first test run failed on stale wording expectations
(`Totoro/Nibi/Rorqual/Trillium`, `149/150 pdHess`, and provider-specific
undercoverage text); those assertions were narrowed to stable invariants before
the passing run.

## Consistency Audit

Stale-string scans:

```sh
rg -n "q2_review_status|q2_review_evidence|sr150_pregrid_imported_review_required|No new compute before Fisher/Rose/Grace review|Rorqual source evidence is imported" tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py
rg -n "structured-re-q2-retained-denominator-review-synthesis.tsv" tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv
```

Remaining synthesis references are source/input references for the decision
table, not widget-facing gate links for the five affected support cells.

## GitHub Issue Maintenance

No GitHub issue or PR body was updated in this step. This was a local
dashboard/validator/test synchronization over already-imported evidence.

## What Did Not Go Smoothly

The first focused test run exposed six assertion mismatches. They were useful:
the test had inherited old exact wording from the synthesis layer and was too
strict about phrases that are not common to all providers. The assertions now
check the decision-layer invariant and leave provider-specific blocker details
to the direct decision-table checks.

## Team Learning

Rose's status guard needs two layers for this lane: synthesis of raw target
evidence, then a decision table that says whether compute or promotion is
allowed. Fisher's answer for these five rows is currently "no top-up until
repair," and Grace's answer is "no Totoro/DRAC/Trillium use until the repair
contract exists and the host root/source are ready."

## Known Limitations

- No Q-Series row was promoted.
- All five affected support cells remain `point_fit/planned/planned`.
- The q2 intercept and q2-plus-q2 evidence remains blocked by interval-shape,
  finite-interval, direct-correlation, or `pdHess` defects.
- Trillium is reachable in the host-access ledger, but has no qseries run root
  or source root yet, so it is not a usable compute target for this lane.
- Totoro, Nibi, Rorqual, Trillium, FIIA, and other DRAC jobs remain blocked for
  these cells until a row-specific repair contract exists.

## Next Actions

Write the q2 repair contracts before any more compute for these five cells.
Only after Fisher/Rose/Grace accept exact targets, seed ranges, interval
channel, denominator policy, finite-interval policy, one-sided miss policy, and
artifact retention should Totoro or DRAC be used for small retained-denominator
smokes or top-up campaigns.

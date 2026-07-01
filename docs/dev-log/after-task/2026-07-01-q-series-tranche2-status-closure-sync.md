# After Task: Q-Series Tranche 2 Status Closure Sync

## Goal

Close the stale wording found during Fisher/Rose review of Gaussian low-q
Tranche 2 without promoting any Q-Series support cell.

## Implemented

I updated the current dashboard status surfaces so q2 retained-denominator rows
no longer read as eligible for a fresh SR150 pregrid or host top-up. The
dashboard now says the Rorqual SR150 pregrid and Totoro existing-route repair
smoke are review-only historical evidence. All five affected q2 rows remain
`point_fit/planned/planned`; host escalation is blocked until Fisher/Rose/Grace
accept a named q2 interval-repair route and it passes a small host-separated
no-promotion smoke.

Fisher's review found no remaining Gaussian structured low-q q1/q2 row that can
be promoted now. Rose found no accidental promotion in the support-cell table,
but did find stale q2 wording in the dashboard README and row-selection
`allowed_hosts` field. This patch fixes that drift.

The q2 repair-smoke dashboard overlay is now idempotent: it writes one
canonical low-q queue state instead of appending the same warning on every
regeneration. The conversion-contract test and mission-control validator both
check that the q2 repair-smoke readiness, precondition, and stop-rule phrases
appear exactly once.

## Mathematical Contract

No likelihood, estimand, formula grammar, interval implementation, or
simulation result changed. This is a status-ledger and prose synchronization:
q2 intercept and q2-plus-q2 retained-denominator evidence remains diagnostic
only, and the support-cell statuses remain unchanged.

## Files Changed

- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche2-status-closure-sync.md`

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-gaussian-lowq-row-selection.R")); invisible(parse("tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R"))'`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`: passed and wrote 20 Gaussian low-q row-selection rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R --dispatch=docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv --output=docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-review.tsv --sync-dashboard=true --overwrite=true`: passed and synced q2 repair-smoke review gates.
- `rg -n "eligible for an SR150 pregrid|no denominator evidence is imported|Nibi primary for SR150 retained-denominator pregrid|Rorqual is confirmation or overflow|q2 retained-denominator pregrid.*ready|Run only the q2 intercept target rows marked|Run only q2-plus-q2 target rows marked" docs/dev-log/dashboard/README.md docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R || true`: no matches.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series cells, 8 Q-Series inference-evidence summary rows, 20 Gaussian low-q row-selection rows, and 5 q2 repair-smoke review rows.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 10239 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## Tests Of The Tests

The stale-phrase scan directly targeted Rose's findings: old pregrid-eligible
wording, old "no denominator evidence imported" wording, and the old Nibi/Rorqual
host-permission phrase. The focused conversion-contract test then rechecked the
generated status ledgers, support-cell contracts, q2 no-promotion guardrails, and
widget-facing TSV expectations after regeneration.

I also added a regression tripwire for a generator drift found during closeout:
the low-q queue row must contain the q2 repair-smoke readiness phrase,
precondition phrase, and stop-rule phrase exactly once. This guards against
future dashboard syncs accumulating repeated claims in generated TSV prose.

## Consistency Audit

Current evidence says exactly eight structured low-q rows are
`inference_ready`, and no structured row is `supported`. The q2 retained-
denominator rows point at either the direct-SD endpoint blocker or the
repair-smoke review, and their row-selection `allowed_hosts` fields now say no
current host escalation. The dashboard README now matches the TSV: q2
retained-denominator pregrid and repair-smoke evidence is historical
diagnostic evidence, not permission to spend Totoro, Nibi, Rorqual, Trillium, or
DRAC time.

I did not rewrite historical after-task notes that were true when written.
This report supersedes them for current Tranche 2 closure wording.

## GitHub Issue Maintenance

No GitHub issue or PR comment was changed. This was a local status-ledger
consistency fix after Fisher/Rose review. Existing q2 future-method issue
tracking remains the place for a new interval-repair route.

## What Did Not Go Smoothly

The generated row-selection table had two sources of truth: the base low-q
generator and the q2 repair-smoke review overlay. A visible TSV edit would have
been fragile, so I patched both generator paths and regenerated them as a pair.
The first closeout pass also exposed that the q2 queue overlay was appending
instead of replacing warning prose; I fixed the generator and added the
idempotence checks before committing.

## Team Learning

When a route advances from "pregrid ready" to "review-only blocker", host
permission fields must be treated as scientific claims. The next audit should
scan not only `next_gate` and `claim_boundary`, but also `allowed_hosts`, because
that field can accidentally invite invalid compute.

## Known Limitations

This does not create a new q2 interval-repair route and does not promote any q2,
q1 sigma, q1 matched `mu+sigma`, q1 `mu` one-slope, q4/q8, non-Gaussian, REML,
AI-REML, or public-support claim. It also does not make the bounded
direct-correlation sidecar an accepted repair route; that remains future design
work.

## Next Actions

Treat Tranche 2 as no-promotion blocker-complete for the current evidence
routes. The next scientific work is design-first: animal q1 `mu` needs a new
A-matrix direct-SD interval route or explicit blocker decision; animal/relmat
q1 `sigma` need sigma-specific interval hardening; q2 retained-denominator rows
need a named interval-repair route before any small smoke or host escalation.

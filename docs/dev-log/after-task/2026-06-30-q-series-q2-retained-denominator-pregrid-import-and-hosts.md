# After Task: Q-Series q2 Retained-Denominator Pregrid Import And Host Ledger

## Goal

Import the completed Rorqual SR150 q2 retained-denominator pregrid as
review-only evidence, update host-access truth for Totoro and Trillium, and
avoid any Q-Series support-cell promotion.

## Implemented

The dashboard now has a 17-row no-promotion sidecar at
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-pregrid-results.tsv`.
The sidecar records retained denominator, Rorqual provenance, finite-interval
rates, lower/upper misses, MCSE, and review-only statuses for the exact 17
predeclared q2 retained-denominator targets.

The host-access ledger now has six rows. Totoro is recorded as reachable through
interactive ControlMaster access with staged private-library smoke readiness.
Trillium is recorded as reachable at `tri-login03`, but not yet usable for this
Q-Series lane because the checked `drmtmb-qseries` root is missing.

## Mathematical Contract

No model equation, likelihood, interval formula, or estimand changed. The
implemented contract is evidence accounting: all attempted SR150 rows are
retained in denominators, failures/nonfinite intervals remain visible, and
`MCSE <= 0.01` remains a top-up target rather than an SR150 pass claim.

## Files Changed

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-pregrid-results.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-host-access-recheck.tsv`
- `tools/summarize-structured-re-q2-retained-denominator-pregrid.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `ssh -o BatchMode=yes -o ConnectTimeout=5 trillium hostname`: reached
  `tri-login03`.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 trillium 'hostname; ...'`:
  project area exists; checked qseries/source roots are missing.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-pregrid.R --overwrite=true`
- `python3 -m py_compile tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse("tools/summarize-structured-re-q2-retained-denominator-pregrid.R")'`
- `git diff --check -- tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R tools/summarize-structured-re-q2-retained-denominator-pregrid.R docs/dev-log/dashboard/structured-re-q-series-host-access-recheck.tsv docs/dev-log/dashboard/structured-re-q2-retained-denominator-pregrid-results.tsv`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`

Result: `mission_control_ok`; focused test passed 9788 / 0 / 0 / 0.

## Tests Of The Tests

The Python validator and focused R test now both require the exact 17-result
target set, the exact no-promotion decision, the four expected result-status
buckets, local artifact path resolution, Rorqual provenance, and the six-row
host-access ledger. The first mission-control run failed because q2-plus rows
lacked SLURM provenance; the summarizer fallback was added and the sidecar was
regenerated from artifacts.

## Consistency Audit

Stale-claim scan:

```sh
rg -n "supported|inference_ready|REML|AI-REML|public support|promotes exactly no|Trillium|Totoro|Rorqual SR150" \
  docs/dev-log/dashboard/structured-re-q-series-host-access-recheck.tsv \
  docs/dev-log/dashboard/structured-re-q2-retained-denominator-pregrid-results.tsv \
  tools/summarize-structured-re-q2-retained-denominator-pregrid.R \
  tools/validate-mission-control.py \
  tests/testthat/test-structured-re-conversion-contracts.R
```

The new dashboard rows keep forbidden phrases inside explicit no-claim
boundaries. No support-cell TSV row was promoted by this task.

## GitHub Issue Maintenance

No GitHub issue or PR comment was changed. This is a local evidence-import and
host-ledger sync inside the existing Q-Series branch.

## What Did Not Go Smoothly

The q2-plus source summary omitted `slurm_cluster_name`, `run_root`,
`metadata_dir`, and `log_dir`, even though the imported Rorqual metadata
contained them. Mission-control caught that mismatch before closeout. The
summarizer now backfills those fields from `_rorqual-metadata/shard_*` run logs.

## Team Learning

Grace/Rose rule: imported cluster artifacts need a second provenance path when
source summaries are heterogeneous across runners. Curie/Fisher rule: SR150
pregrids are screening evidence only when MCSE remains above 0.01 or pdHess /
finite-interval flags remain.

## Known Limitations

- No Q-Series row is promoted.
- Ten rows are only top-up candidates because MCSE remains above 0.01.
- Five q2-plus rows need convergence/`pdHess` review.
- The spatial q2-intercept correlation row needs profile-finiteness review.
- The animal q2-intercept correlation row needs Wald-finiteness review.
- Totoro is staged for bounded smoke / worker use, not denominator promotion.
- Trillium is reachable but needs a qseries run root before use.
- FIIA remains unresolved by alias/access.

## Next Actions

Fisher/Rose/Grace should review the 17 SR150 rows before any top-up or
status-table edit. If Trillium is useful, stage a qseries run root there before
submitting smoke work. Totoro can be used for capped single-thread workers with
the same artifact contract and explicit cleanup.

# After Task: Q-Series q2 Retained-Denominator Review Synthesis

## Goal

Make the imported Rorqual SR150 q2 retained-denominator evidence visible in
the Q-Series widget as row-level review evidence without promoting any support
cell.

## Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-review-synthesis.tsv`,
a five-row cell-level synthesis over the 17 imported target-level pregrid rows.
The synthesis records exact review states for phylo, spatial, animal, relmat,
and phylo q2-plus-q2 cells, then links the affected support, Gaussian low-q
audit, and row-selection rows to that synthesis.

This promotes exactly no Q-Series row. The five linked support cells remain
`point_fit/planned/planned`.

## Mathematical Contract

No likelihood, formula grammar, parameterization, or interval equation changed.
This is an evidence-contract update only. The synthesis keeps endpoint SD and
direct-correlation targets separate, keeps q2-plus within-block targets separate
from the held sigma1/sigma2 correlation and cross-block correlations, and
records that Fisher/Rose/Grace review is required before any top-up, repair, or
status edit.

## Files Changed

- `tools/summarize-structured-re-q2-retained-denominator-review.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-review-synthesis.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/check-log.md`

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-review.R --overwrite=true`
- `python3 -m py_compile tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'parse("tools/summarize-structured-re-q2-retained-denominator-review.R")'`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'parse("tests/testthat/test-structured-re-conversion-contracts.R")'`
- Scoped `git diff --check` over the validator, focused test, synthesis
  generator, synthesis TSV, and synced dashboard TSVs.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
  passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`
  passed with 9812 PASS / 0 FAIL / 0 WARN / 0 SKIP.

Full `devtools::test()`, `devtools::check()`, and `pkgdown::check_pkgdown()`
were not rerun for this narrow dashboard contract update.

## Tests Of The Tests

The new focused checks compare the five synthesis rows back to the imported
17-row target-level pregrid table, require exact per-cell review states, require
`do_not_promote`, and require the linked support cells to stay
`point_fit/planned/planned`.

Mission control initially failed because the row-selection audit text did not
include the review-state field and because one guard expected the phrase
`no interval_status` while the synthesis says `does not claim interval_status`.
Those failures were corrected before the passing run.

## Consistency Audit

Stale-string scan:

```sh
rg -n "q2_retained_denominator_design_ready|nibi_retained_denominator_pregrid_ready|structured-re-q2-intercept-nibi-smoke.tsv|q2_retained_denominator_design_ready_with_profile_blocker|q2_plus_sr150_pregrid_ready_except" tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv
```

Remaining hits refer to the original Nibi smoke artifact and its own contract
tests, not the five SR150-reviewed widget rows.

## GitHub Issue Maintenance

No GitHub issue or PR body was updated in this step. This was a local
dashboard/validator synchronization over already-imported evidence.

## What Did Not Go Smoothly

The first validator patch inserted extra row-selection text into the neighboring
special-target string concatenation and briefly caused a Python syntax error.
The syntax check caught it before the focused R test ran.

## Team Learning

Rose's guard should treat imported target-level simulation output and
cell-level support status as separate layers. The synthesis layer is the right
place to make "tried but review-required" visible without letting that evidence
look like `inference_ready`.

## Known Limitations

- The q2 intercept and q2-plus-q2 rows are not promoted.
- Spatial q2 direct-correlation profile finiteness, animal q2 direct-correlation
  Wald finiteness, q2-plus 149/150 `pdHess`, and MCSE/top-up decisions remain
  open review items.
- Totoro, Nibi, Rorqual, Trillium, and other DRAC runs remain blocked for
  these cells until Fisher/Rose/Grace choose exact targets, seeds, interval
  channel, denominator policy, finite-interval policy, and one-sided miss
  policy.

## Next Actions

Fisher/Rose/Grace should review the five synthesis rows and decide whether each
cell needs an exact-target top-up, a repair/blocker note, or no further compute.
Only after that review should any Totoro/DRAC campaign be staged for these q2
cells.

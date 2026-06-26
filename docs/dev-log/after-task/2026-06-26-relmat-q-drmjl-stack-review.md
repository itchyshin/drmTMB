## 1. Goal

Record the final local review decision for the active DRM.jl q2/q4 draft stack
before using it to plan drmTMB relmat `Q` bridge work. The target reader is the
next R package contributor deciding whether exact `Q` transport can be coded.

## 2. Implemented

- Added a generated five-row dashboard sidecar,
  `docs/dev-log/dashboard/structured-re-relmat-q-drmjl-stack-review.tsv`.
- Added `phase18_structured_re_relmat_q_drmjl_stack_review()` and the writer
  script `tools/run-structured-re-relmat-q-drmjl-stack-review.R`.
- Wired the new sidecar into `tools/validate-mission-control.py`, including
  exact PR heads, PR URLs, local assertion counts, draft/CLEAN state, and
  conservative claim-boundary checks.
- Added a dashboard contract test for the new sidecar.
- Updated the q-series completion map, dashboard README, and check log.

## 3a. Decisions and Rejected Alternatives

The sidecar is a review ledger, not a runtime support ledger. I kept DRM.jl
#297, #298, #299, #300, and drmTMB #666 as separate rows because each row has a
different dependency role. Combining them into one relmat `Q` support row would
overstate the evidence: the upstream stack is reviewed and green, but it is
still draft and unmerged.

I did not implement R-side exact `Q` transport in this slice. That code should
wait until the upstream DRM.jl stack is accepted and the R payload contract can
be matched against a stable provider API.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-relmat-q-drmjl-stack-review.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-relmat-q-drmjl-stack-review.tsv`
- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-relmat-q-drmjl-stack-review.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-relmat-q-drmjl-stack-review.R`
  passed and wrote 5 rows.
- `Rscript --vanilla -e 'source("inst/sim/R/sim_structured_re_bridge_fixtures.R"); x <- phase18_structured_re_relmat_q_drmjl_stack_review(); stopifnot(nrow(x) == 5L, identical(x$dependency_ref, c("DRM.jl#297", "DRM.jl#298", "DRM.jl#299", "DRM.jl#300", "drmTMB#666")), all(grepl("^[0-9a-f]{40}$", x$head_oid)), all(x$merge_state_status == "CLEAN_DRAFT"), all(grepl("not", x$downstream_permission)), all(grepl("broad bridge support", x$claim_boundary)), all(grepl("coverage", x$claim_boundary)), all(grepl("AI-REML", x$claim_boundary)))'`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 5 relmat `Q`
  DRM.jl stack-review rows.
- `devtools::test()` and direct `testthat::test_file()` could not run in this
  app R library because `devtools` and `testthat` are unavailable.
- `air format inst/sim/R/sim_structured_re_bridge_fixtures.R tools/run-structured-re-relmat-q-drmjl-stack-review.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `git diff --check` passed.
- `Rscript --vanilla -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-relmat-q-drmjl-stack-review.md')"`
  passed.

## 6. Tests of the Tests

The mission-control validator now fails closed if the stack-review sidecar
loses a row, changes a reviewed PR head, points to the wrong PR URL, changes
the local assertion count, drops the draft/CLEAN state, or removes boundary
phrases such as `q4 REML`, `q4 AI-REML`, `HSquared AI-REML`,
`non-Gaussian REML`, `broad bridge support`, `coverage`, or `public support`.
The testthat contract mirrors the row IDs, assertion counts, and blocked
downstream-permission rule, but could not be executed locally because
`testthat` is unavailable in this app R library.

## 7a. Issue Ledger

- Fixed: the exact-head review state for DRM.jl #297, #298, #299, and #300 is
  now banked beside drmTMB #666.
- Fixed: the next merge/retarget order is explicit: #297, then #298, then
  #299, then #300, then downstream exact `Q` transport after review.
- Deferred: exact relmat `Q` payload transport remains blocked until the
  upstream DRM.jl stack is accepted and the R-side contract is implemented.

## 8. Consistency Audit

The new sidecar agrees with the existing relmat `Q` provider-readiness sidecar:
DRM.jl #299 and #300 remain draft-green dependencies, not R-via-Julia relmat
`Q` transport. It also keeps DRM.jl #297/#298 in the dependency order so the
stack cannot be retargeted out of sequence.

## 9. What Did Not Go Smoothly

The first full mission-control run rejected two review-scope strings: one used
capitalized `Exact`, and one omitted `exact`. I updated the generated strings
instead of weakening the validator, then regenerated the TSV.

## 10. Known Residuals

The review ledger is static. If any of DRM.jl #297, #298, #299, #300, or drmTMB
#666 are rebased, merged, retargeted, or rechecked, the sidecar must be
regenerated from current evidence. No q4 interval reliability, q4 coverage, q4
REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML,
broad bridge support, public support, SR150 readiness, DRAC/Totoro execution,
or Ayumi-facing reply is claimed.

## 11. Team Learning

When a stacked upstream dependency is reviewed but still draft, bank a separate
review-decision row. That lets the team move efficiently on merge order and
next-slice planning without turning draft upstream evidence into downstream
support.

# After Task: Q-Series Tranche 9 q2 Retained-Denominator Repair-Route Review

## 1. Goal

Bank a no-compute Tranche 9 review for the blocked q2 retained-denominator cells before spending host time. The task was to decide whether the existing `bounded_tmbprofile_direct_correlation_sidecar` was enough to authorize a small repair smoke or top-up.

## 2. Implemented

- Added a seven-row Mission Control sidecar, `structured-re-q2-retained-denominator-tranche9-repair-route-review.tsv`, covering four q2 intercept provider rows, one q2-plus hold row, one route summary, and one tranche summary.
- Recorded that the existing direct-correlation sidecar is a named candidate for `cor_mu1_mu2_intercept`, but rejected it as a complete cell-level repair because endpoint direct-SD blockers remain.
- Kept the phylo q2-plus-q2 row held because it still needs a route for the `pdHess`, endpoint-SD, direct `mu1`/`mu2` correlation, and held `sigma1`/`sigma2` correlation blockers.
- Added Fisher, Rose, Noether, and Grace member-board rows with blocking review stances.
- Updated Mission Control rendering, dashboard version `r203`, validator guards, focused conversion-contract tests, dashboard README wording, completion-map wording, and the check-log.

## 3a. Decisions and Rejected Alternatives

- Rejected using `bounded_tmbprofile_direct_correlation_sidecar` as a whole-cell q2 repair route. It can only address the direct correlation target and does not repair endpoint direct-SD undercoverage or provider-specific finiteness blockers.
- Rejected a q2 small smoke or SR475/SR1000 top-up from the partial route. Fisher blocks the compute claim, Rose blocks status movement, Noether blocks target-identity shortcuts, and Grace blocks host spend until the route scope matches the blockers.
- Kept q2-plus separate from q2 intercept. The q2-plus row has an additional `pdHess` and held sigma-correlation blocker and cannot inherit the q2 direct-correlation candidate.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche9-repair-route-review.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche9-q2-retained-denominator-repair-route-review.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- `python3 - <<'PY' ...`: passed; confirmed the Tranche 9 sidecar has eight lines including its header and 23 columns on every row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`: passed after fixing the new f-string error message.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}' docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js && node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series support cells, 8 Q-Series inference-evidence summary rows, 5 q2 retained-denominator repair-smoke review rows, and 7 q2 retained-denominator Tranche 9 repair-route rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`: passed after tightening the new test's scope-count and member-discussion reads.
- `rg -n "Tranche 9.*(coverage result|coverage_evaluable|inference_ready|supported|smoke authorized|top-up authorized|host top-up)|q2.*Tranche 9.*(inference_ready|supported|coverage_status|interval_status)" ... -g '!structured-re-q2-retained-denominator-tranche9-repair-route-review.tsv'`: no off-ledger stale-claim hits.
- `rg -n "tranche9.*(coverage_authorized|promote|submitted|executed|inference_ready|supported)|q2.*partial_route.*(coverage_authorized|promote|submitted|executed)" ...`: expected hits only in the Tranche 9 sidecar no-claim text and the focused test's `do_not_promote` assertion.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche9-q2-retained-denominator-repair-route-review.md')"`: passed.
- `git diff --check`: passed.
- `sh tools/start-mission-control.sh --background && curl -fsS http://127.0.0.1:8765/version.txt && curl -fsS http://127.0.0.1:8765/structured-re-q2-retained-denominator-tranche9-repair-route-review.tsv | wc -l`: passed; served dashboard returned `r203` and the Tranche 9 sidecar served with eight lines including its header.

## 6. Tests of the Tests

The focused conversion-contract test initially failed on two test-fixture assumptions: comparing `table()` output with attributes intact, and reading member-discussion rows before defining the `discussions` fixture. The Mission Control validator also initially failed on a malformed f-string and on using `member` instead of the real `member_id` field. Those failures show the new validator and focused tests were executing the new route-review path rather than silently passing.

The final focused test now verifies the Tranche 9 schema, exact row count, route-scope counts, no-coverage/no-promotion decisions, reviewer list, evidence paths, partial-route rejection for all four target rows, q2-plus hold semantics, and the Fisher/Rose/Noether/Grace member-board rows.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This was a repository-local evidence and Mission Control tranche, not a public API or behavior change. The route-review result remains tied to the existing q2 retained-denominator evidence sidecars and should inform the next named q2 route or target-split decision before any issue-level claim is made.

## 8. Consistency Audit

- Rose: no status claim moved; every Tranche 9 row keeps `coverage_not_authorized` and `do_not_promote`.
- Fisher: no smoke or top-up is authorized from a partial direct-correlation route.
- Noether: direct-correlation repair is not treated as endpoint direct-SD repair, and q2-plus does not inherit q2 intercept evidence.
- Grace: host spend stays blocked until route scope, provenance, and denominator policy match the target blockers.
- Dashboard and docs were scanned for off-ledger Tranche 9 coverage, support, `inference_ready`, and execution wording; no positive status claim was found outside the deliberate no-claim guard text.

## 9. What Did Not Go Smoothly

The validator edit had two small but useful mistakes: an f-string literal-brace error and the wrong member-discussion field name. The focused R test also needed a sharper fixture read and attribute-free scope-count comparison. These were cheap failures, and they helped tighten the contract before closure.

## 10. Known Residuals

Tranche 9 does not provide a complete q2 retained-denominator repair route. The next q2 move needs either a combined endpoint direct-SD plus direct-correlation route or an explicit target-split decision, reviewed by Fisher, Rose, Noether, and Grace before any small smoke. The q4 relmat SR150 host-pack execution gate also remains closed until explicit Rose/Fisher/Grace approval.

## 11. Team Learning

A named route is not sufficient unless its estimand scope matches every blocker in the cell, or the tranche explicitly target-splits the cell. For q2 retained-denominator work, direct-correlation repair must not be allowed to smuggle endpoint direct-SD undercoverage into a compute gate.

# After Task: Q-Series Tranche 10 q2 Retained-Denominator Target-Split Design

## 1. Goal

Advance the Q-Series completion campaign after Tranche 9 by banking the q2 retained-denominator target split without spending compute or moving any support status.

## 2. Implemented

- Added `structured-re-q2-retained-denominator-tranche10-target-split-design.tsv`, an eight-row Mission Control sidecar.
- Split the four q2 intercept blocked cells into direct `cor_mu1_mu2_intercept` and endpoint direct-SD `sd_mu2_intercept` components.
- Kept the phylo q2-plus-q2 row outside the q2 intercept split because its `pdHess`, endpoint-SD, direct `mu1`/`mu2` correlation, and held `sigma1`/`sigma2` correlation blockers need a separate route.
- Added Fisher, Rose, Noether, and Grace member-board rows.
- Updated Mission Control rendering, dashboard version `r204`, validator guards, focused conversion-contract tests, dashboard README wording, completion-map wording, and the check-log.

## 3a. Decisions and Rejected Alternatives

- Accepted target splitting as a design ledger, not as compute approval. Tranche 10 says what must be separated before a smoke, but it does not define an executable smoke command.
- Rejected pooling direct-correlation and endpoint-SD evidence. Noether blocks any route that lets one estimand repair the other by wording alone.
- Rejected including q2-plus in the q2 intercept split. Its blocker set is larger and includes the held `sigma1`/`sigma2` correlation path.
- Rejected status movement from the design ledger. Every row remains `no_smoke_in_tranche10`, `coverage_not_authorized`, and `do_not_promote`.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche10-target-split-design.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche10-q2-retained-denominator-target-split-design.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- `python3 - <<'PY' ...`: passed; confirmed the Tranche 10 sidecar has nine lines including its header and 27 columns on every row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`: passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}' docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js && node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series support cells, 8 Q-Series inference-evidence summary rows, 7 q2 retained-denominator Tranche 9 repair-route rows, 8 q2 retained-denominator Tranche 10 target-split rows, and 56 member discussion rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`: passed.
- `rg -n "Tranche 10.*(coverage result|coverage_evaluable|inference_ready|supported|smoke authorized|top-up authorized|host top-up)|q2.*Tranche 10.*(inference_ready|supported|coverage_status|interval_status)" ... -g '!structured-re-q2-retained-denominator-tranche10-target-split-design.tsv'`: no off-ledger stale-claim hits.
- `rg -n "Tranche 10.*(coverage_authorized|promote|submitted|executed|inference_ready|supported)|tranche10.*(coverage_authorized|submitted|executed)|tranche10.*(coverage_status[[:space:]]+inference_ready|promotion_decision[[:space:]]+promote)" ... -g '!structured-re-q2-retained-denominator-tranche10-target-split-design.tsv'`: no off-ledger positive authorization/status hits.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche10-q2-retained-denominator-target-split-design.md')"`: passed.
- `git diff --check`: passed.
- `sh tools/start-mission-control.sh --background && curl -fsS http://127.0.0.1:8765/version.txt && curl -fsS http://127.0.0.1:8765/structured-re-q2-retained-denominator-tranche10-target-split-design.tsv | wc -l`: passed; served dashboard returned `r204` and the Tranche 10 sidecar served with nine lines including its header.

## 6. Tests of the Tests

The new validator block checks the exact Tranche 10 row IDs, schema, scope counts, source references, linked support-cell statuses, no-compute/no-coverage/no-promotion decisions, component identity split, q2-plus hold semantics, claim-boundary wording, and Fisher/Rose/Noether/Grace board rows.

The focused R test independently reads the sidecar, verifies the same row count and target split, checks source paths, and confirms the member-board rows. It also replaces an older partial-match member-board read with explicit `member_id`, which makes the test less permissive.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This tranche is a local Mission Control design gate and does not change public API, formula grammar, fitted behavior, documentation promises, or package status.

## 8. Consistency Audit

- Rose: the design ledger cannot be read as interval status, coverage status, `inference_ready`, or support.
- Fisher: no smoke or top-up is authorized before a Tranche 11 executable contract names the component denominators and gates.
- Noether: direct-SD, direct-correlation, and q2-plus sigma-correlation targets remain identity-separated.
- Grace: no host spend follows from Tranche 10 because source, seed, host, run-root, and artifact policy are not executable yet.
- Dashboard README, completion map, Mission Control rendering, validator output, and focused tests now all name Tranche 10 as design-only.

## 9. What Did Not Go Smoothly

The main risk was over-writing the target-split as if it were a smoke authorization. Keeping `no_smoke_in_tranche10` as a required field in every row made that boundary explicit.

## 10. Known Residuals

Tranche 10 does not define the executable q2 smoke contract. The next q2 move is Tranche 11: either a combined endpoint-SD plus direct-correlation small-smoke contract, a component target-split smoke contract, or a separate q2-plus route design, all reviewed by Fisher, Rose, Noether, and Grace before compute.

The q4 relmat SR150 host-pack execution gate remains closed until explicit Rose/Fisher/Grace approval.

## 11. Team Learning

Target splitting is useful only when it is treated as an identity ledger first and a compute contract later. The team should not let a split design row imply denominator adequacy, host readiness, or support-cell movement.

# After Task: Q-Series Tranche 11 q2 Direct-Correlation Smoke Contract

## 1. Goal

Advance the q2 retained-denominator lane from the Tranche 10 target split into an executable-but-not-executed direct-correlation smoke contract, while preserving all no-compute and no-status gates.

## 2. Implemented

- Added `structured-re-q2-retained-denominator-tranche11-direct-correlation-smoke-contract.tsv`, an eight-row Mission Control sidecar.
- Banked four exact future command rows for the q2 intercept direct `cor_mu1_mu2_intercept` component, one per provider.
- Added `tools/run-q2-retained-denominator-tranche11-direct-correlation-smoke.sh`, a fail-closed helper that refuses to run unless `DRMTMB_Q2_TRANCHE11_EXECUTION_APPROVED=rose_fisher_noether_grace` is set.
- Kept endpoint direct-SD and q2-plus-q2 rows held because no endpoint-SD interval-shape route or q2-plus route is available yet.
- Added Fisher, Rose, Noether, and Grace member-board rows.
- Updated Mission Control rendering, dashboard version `r205`, validator guards, focused conversion-contract tests, dashboard README wording, completion-map wording, and the check-log.

## 3a. Decisions and Rejected Alternatives

- Accepted a direct-correlation component smoke contract because the existing q2 intercept runner can target `cor_mu1_mu2_intercept` and pass the bounded `tmbprofile` repair channel.
- Rejected treating the direct-correlation command as whole-cell q2 repair. Endpoint direct-SD blockers remain, and q2-plus has a separate blocker set.
- Rejected execution in this tranche. The command contract is banked for later explicit Fisher/Rose/Noether/Grace approval.
- Rejected any support-cell status edit, coverage wording, or top-up authorization from command availability.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche11-direct-correlation-smoke-contract.tsv`
- `tools/run-q2-retained-denominator-tranche11-direct-correlation-smoke.sh`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche11-q2-direct-correlation-smoke-contract.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- `python3 - <<'PY' ...`: passed; confirmed the Tranche 11 sidecar has nine lines including its header and 33 columns on every row.
- `bash -n tools/run-q2-retained-denominator-tranche11-direct-correlation-smoke.sh`: passed.
- `sh tools/run-q2-retained-denominator-tranche11-direct-correlation-smoke.sh`: passed as a fail-closed probe; it exited 64 with the expected missing-approval message.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`: passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}' docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js && node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series support cells, 8 Q-Series inference-evidence summary rows, 8 q2 retained-denominator Tranche 10 target-split rows, 8 q2 retained-denominator Tranche 11 direct-correlation smoke-contract rows, and 60 member discussion rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`: passed after fixing a numeric-versus-character test expectation for `n_rep`.
- `rg -n "Tranche 11.*(coverage result|coverage_evaluable|inference_ready|supported|smoke executed|smoke result|top-up authorized|host job submitted)|q2.*Tranche 11.*(inference_ready|supported|coverage_status|interval_status)" ... -g '!structured-re-q2-retained-denominator-tranche11-direct-correlation-smoke-contract.tsv'`: no off-ledger stale-claim hits.
- `rg -n "tranche11.*(coverage_authorized|submitted_imported|completed_imported|coverage_status[[:space:]]+inference_ready|promotion_decision[[:space:]]+promote|status_edit)|direct-correlation smoke.*(executed|submitted|coverage_authorized|promote|inference_ready|supported)" ... -g '!structured-re-q2-retained-denominator-tranche11-direct-correlation-smoke-contract.tsv'`: no off-ledger positive authorization/status hits.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche11-q2-direct-correlation-smoke-contract.md')"`: passed.
- `sh tools/start-mission-control.sh --background && curl -fsS http://127.0.0.1:8765/version.txt && curl -fsS http://127.0.0.1:8765/structured-re-q2-retained-denominator-tranche11-direct-correlation-smoke-contract.tsv | wc -l`: passed; served dashboard returned `r205` and the Tranche 11 sidecar served with nine lines including its header.

## 6. Tests of the Tests

The focused R test initially failed because the new TSV `n_rep` field was parsed as integer while the test expected the string `"32"`. That failure confirms the new Tranche 11 test block was being exercised. The fixed test now checks the sidecar schema, row count, scope counts, direct-correlation component rows, no-execution decisions, hold rows, source paths, helper content, and Fisher/Rose/Noether/Grace member-board rows.

The helper was also probed directly without the approval variable and failed closed with exit 64, proving the execution guard is active.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This tranche is a local command-contract gate and does not change public API, formula grammar, fitted behavior, examples, package documentation promises, or public status.

## 8. Consistency Audit

- Rose: command availability is not reported as an executed smoke, interval status, coverage status, `inference_ready`, or support.
- Fisher: the direct-correlation smoke is component evidence only and cannot clear endpoint-SD blockers or authorize top-up.
- Noether: direct correlation, endpoint direct-SD, and q2-plus sigma-correlation estimands remain separated.
- Grace: the helper requires explicit approval and records one-host retained-denominator provenance expectations before execution.
- Dashboard README, completion map, check-log, Mission Control rendering, validator, and focused tests now all describe Tranche 11 as command-contract only.

## 9. What Did Not Go Smoothly

The R test needed one adjustment because `read.delim()` inferred `n_rep` as numeric. The first focused test failure was useful because it showed the new assertions were live and sensitive to the sidecar schema.

## 10. Known Residuals

No Tranche 11 smoke was executed. The endpoint-SD component still needs an interval-shape route before any endpoint-SD smoke. The q2-plus-q2 row still needs a separate route for `pdHess`, endpoint-SD, direct `mu1`/`mu2` correlation, and held `sigma1`/`sigma2` correlation blockers.

The q4 relmat SR150 host-pack execution gate remains closed until explicit Rose/Fisher/Grace approval.

## 11. Team Learning

Executable commands are evidence only after execution and review. A command contract should be treated as a reproducibility artifact plus approval gate, not as smoke evidence, denominator adequacy, or support-cell progress.

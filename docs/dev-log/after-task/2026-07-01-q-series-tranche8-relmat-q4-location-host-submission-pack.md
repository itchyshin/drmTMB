# After Task: Q-Series Tranche 8 Relmat Q4 Location Host Submission Pack

## 1. Goal

Bank the relmat-only q4 location host submission pack after Tranche 7 approved
the SR150 pregrid contract, without executing Totoro commands, submitting DRAC
jobs, importing results, or moving any support-cell status.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q4-location-tranche8-relmat-host-submission-pack.tsv`,
a six-row host-pack ledger for the exact relmat q4 location direct-SD targets.
The four target rows map to shards 13-16, SR150, `n_each = 20`, `bootstrap = 0`,
and seed starts 980000, 981000, 982000, and 983000.

The pack records exact Totoro/control-master commands, exact DRAC fallback
commands, source SHA and dirty-state capture, host-label policy, expected output
paths, expected log paths, and the next gate. It also adds the fail-closed
Totoro wrapper `tools/run-q4-location-relmat-pregrid-totoro.sh` and the
relmat-only DRAC fallback script `tools/slurm/q4-location-relmat-pregrid.sbatch`.
Both helpers require
`DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace` before they run.

Mission Control now serves the host-pack sidecar at dashboard version `r202`;
the validator and focused conversion-contract test enforce the schema, no-run
state, no-coverage state, and Rose/Fisher/Grace blocking-review rows.

## 3a. Decisions and Rejected Alternatives

The host pack uses a new relmat-only DRAC sbatch file instead of the existing
all-provider SR475 q4 coverage sbatch. That keeps the fallback command aligned
with Tranche 7's exact scope: relmat only, shards 13-16, SR150 screen only.

The Totoro wrapper defaults to dry-run and refuses execution unless the explicit
Rose/Fisher/Grace approval environment variable is present. This tranche
rejected direct execution, all-provider reruns, host denominator pooling, result
import, support-cell movement, q4 REML, REML, AI-REML, q8, derived-correlation
interval claims, and any public-support claim.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-tranche8-relmat-host-submission-pack.tsv`
- `tools/run-q4-location-relmat-pregrid-totoro.sh`
- `tools/slurm/q4-location-relmat-pregrid.sbatch`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche8-relmat-q4-location-host-submission-pack.md`

## 5. Checks Run

- `wc -l docs/dev-log/dashboard/structured-re-q4-location-tranche8-relmat-host-submission-pack.tsv`:
  confirmed seven lines including the header.
- `rg -n "Tranche 8.*(coverage result|coverage_evaluable|inference_ready|supported|submitted|executed)|q4 relmat.*(coverage result|inference_ready|supported)"
  docs/dev-log/dashboard docs/design/218-structured-q-series-completion-map.md
  docs/dev-log/check-log.md
  tests/testthat/test-structured-re-conversion-contracts.R
  -g '!structured-re-q4-location-tranche8-relmat-host-submission-pack.tsv'`:
  found only the intended Rose member-board warning that the pack must not be
  mistaken for launched coverage.
- `rg -n "submitted_imported|completed_imported|coverage_evaluable[[:space:]]+TRUE|coverage_status[[:space:]]+inference_ready|authority_status[[:space:]]+supported|q4.*relmat.*supported|q4.*relmat.*inference_ready"
  docs/dev-log/dashboard docs/design/218-structured-q-series-completion-map.md
  docs/dev-log/check-log.md
  tests/testthat/test-structured-re-conversion-contracts.R
  tools/run-q4-location-relmat-pregrid-totoro.sh
  tools/slurm/q4-location-relmat-pregrid.sbatch`: historical dashboard and
  Tranche 5-7 guardrail hits only; no Tranche 8 positive status claim was used
  as evidence.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `bash -n tools/run-q4-location-relmat-pregrid-totoro.sh`: passed.
- `bash -n tools/slurm/q4-location-relmat-pregrid.sbatch`: passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}'
  docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js &&
  node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 8 Q-Series inference-evidence summary
  rows, and 6 q4 location Tranche 8 relmat-host-pack rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'`: passed.
- `python3 - <<'PY' ...`: confirmed all six Tranche 8 rows remain
  `pack_banked_not_submitted`,
  `do_not_execute_until_rose_fisher_grace_explicit_approval`,
  `coverage_not_authorized`, and `do_not_promote`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche8-relmat-q4-location-host-submission-pack.md')"`:
  passed.
- `git diff --check`: passed.
- `sh tools/start-mission-control.sh --background && curl ...`: Mission Control
  was already listening at `http://127.0.0.1:8765/`; `version.txt` returned
  `r202`, and the Tranche 8 host-pack sidecar served with seven lines including
  its header.

## 6. Tests of the Tests

The new focused test checks the Tranche 8 sidecar schema, row counts, exact
source links to Tranche 7, shard and seed assignments, Totoro and DRAC command
tokens, no-coverage and no-promotion decisions, claim-boundary text, fail-closed
approval gates in both helper scripts, and Rose/Fisher/Grace member-board rows.
It exercises a boundary/failure path by requiring the helper scripts to refuse
execution without `DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace` and by
checking that no host-pack row can masquerade as a submitted or completed
coverage artifact.

## 7a. Issue Ledger

No GitHub issue action was taken. This tranche is a local Mission Control
submission pack and does not change public APIs, formula grammar, likelihoods,
pkgdown, README, NEWS, or package support status.

## 8. Consistency Audit

Rose: the host pack is not a tier/status claim; every row remains
`coverage_not_authorized` and `do_not_promote`.

Fisher: SR150 remains a pregrid screen only. No MCSE-controlled coverage result
exists, and no coverage decision can be made from this pack.

Grace: both host routes are fail-closed and require source SHA, dirty-state,
host label, session information, output paths, and logs before any imported
result can be reviewed.

Gauss: the pack routes through the existing q4 location coverage-grid runner and
does not alter the runner's fit, Hessian, interval, warning, or denominator
logic.

Noether: the scope remains the four relmat q4 location direct-SD targets only;
there is no derived-correlation interval, q8 target, REML, or AI-REML claim.

## 9. What Did Not Go Smoothly

The broad positive-status scan was too noisy because it intentionally searched
the whole dashboard neighborhood and matched older completed/imported sidecars
plus guardrail text. I kept it as a historical-neighborhood scan and added a
tighter row-level fail-closed assertion for the Tranche 8 sidecar.

## 10. Known Residuals

- No Tranche 8 Totoro command has been executed.
- No Tranche 8 DRAC job has been submitted.
- No Tranche 8 result has been imported.
- No q4 support-cell status changed.
- The next gate is a fresh checkpoint plus explicit Rose/Fisher/Grace execution
  approval before spending Totoro or DRAC compute.

## 11. Team Learning

For compute-adjacent Q-Series work, bank the runnable host command as a
reviewable artifact before running it. The command itself needs provenance,
scope limits, and fail-closed approval gates, because a clean command can still
be an overclaim if it is mistaken for evidence.

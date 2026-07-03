# After Task: Q-Series Tranche 87 q1 Mu One-Slope Spatial DRAC SLURM-Packet Blocker

## 1. Goal

Bank the q1 `mu` one-slope spatial DRAC execution route as a SLURM-safe packet
before any compute is allowed. The tranche should correct the planned direct
wrapper execution route, record the Rorqual staging gap, and preserve the
current support-cell boundary.

The implemented claim is narrow: Tranche 87 is packet/provenance evidence only.
It submits no `sbatch`, runs no R command or `Rscript`, fits no model, creates
no retained denominator, and changes no Q-Series support-cell status.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche87-spatial-drac-slurm-packet.tsv`
with eight decision rows. The rows import the T86 approval boundary, add a
local fail-closed Rorqual sbatch packet, record local runner/wrapper/packet
hashes, record a no-model Rorqual preflight, and state that the remote T85
runner and wrapper are missing.

Mission Control now renders the T87 table and summary card in build `r281`.
The q1 `mu` one-slope queue now points at T87 as primary evidence and names
Tranche 88 as the next gate: a remote staging proof for the exact T85 runner,
T85 wrapper, and T87 sbatch packet before any later sbatch submission is
considered.

## 3a. Decisions and Rejected Alternatives

T87 rejects direct wrapper execution over SSH because the reviewed wrapper calls
`Rscript`, which would risk model work on a login node. The accepted route is a
fail-closed SLURM packet that refuses unless `SLURM_CLUSTER_NAME=rorqual` and
`SLURM_JOB_ID` are set, checks the exact T85 runner/wrapper hashes, and
preserves `DRMTMB_Q1MU_SLOPE_T77_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace`.

Rejected alternatives: run the T85 wrapper from a login shell, stage files and
submit `sbatch` in the same tranche, count packet rows as denominators, pool
Totoro and DRAC evidence, start coverage/top-up work, or promote any q1 `mu`,
q1 `sigma`, q2, q4, q8, REML, AI-REML, bridge, public-support, coverage,
`inference_ready`, or `supported` claim from T87.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche87-spatial-drac-slurm-packet.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche87-spatial-drac-slurm-packet-rorqual/`
- `tools/slurm/q1-mu-slope-spatial-t87-rorqual-smoke.sbatch`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-q-series-tranche87-q1-mu-one-slope-spatial-drac-slurm-packet.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
  passed.
- Extracted dashboard JavaScript from `docs/dev-log/dashboard/index.html` and
  ran `node --check /tmp/drmtmb-mission-control-index-r281.js`; passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py` passed and reported 8 T87 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test(filter = "structured-re-conversion-contracts", reporter =
  "summary")'` passed.
- Support-cell invariant scan reported `104 96 8 0 0 0 0`: 104 Q-Series
  cells, 96 structured cells, 8 interval+coverage `inference_ready` rows, 0
  `supported` authority rows, 0 structured `supported` rows, 0 q4
  `inference_ready` coverage rows, and 0 q4 coverage-authorized rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-02-q-series-tranche87-q1-mu-one-slope-spatial-drac-slurm-packet.md')"`
  passed.
- Served Mission Control probe at `http://127.0.0.1:8768/` reported version
  `r281`, the T87 card, loader, and table present, and 9 T87 TSV lines.
- Recovery checkpoint written:
  `docs/dev-log/recovery-checkpoints/2026-07-02-181027-codex-checkpoint.md`.
- After adding the checkpoint path, the after-task structure checker passed
  again.
- `git diff --check` passed.
- Removed the generated `tools/__pycache__/` directory and confirmed no
  `tools/**/__pycache__` directories remain.

## 6. Tests of the Tests

The focused conversion-contract test reads the T87 sidecar, checks all eight
decision IDs, verifies the SC427 Rose/Fisher/Gauss/Noether/Grace blocking
review, confirms that every evidence URL resolves, checks the SLURM packet
guard text and hashes, checks the Rorqual preflight output, and verifies that
the linked support cell remains `point_fit/planned/planned`.

This is a boundary test: if T87 rows are counted as retained denominators, if
T87 submits `sbatch`, if the login-node guard is removed, or if the support
cell moves, the test should fail.

## 7a. Issue Ledger

No GitHub issue or PR comment was updated. T87 is an internal Mission Control
packet/blocker on the active Q-Series branch, and the next action is a remote
staging proof rather than a public claim.

## 8. Consistency Audit

Rose audit result: no T87 row is fit evidence, interval evidence,
retained-denominator evidence, admission evidence, coverage evidence,
`inference_ready`, or `supported`. Every T87 row keeps
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`.

Fisher/Gauss/Noether/Grace boundary: no model replicate exists in T87, so no
retained denominator or retained-rate admission threshold can be evaluated; no
Hessian/Wald/profile taxonomy can move beyond `not_observed`; direct-SD target
identity remains `sd_mu_intercept` and `sd_mu_x`; host provenance remains
separate and does not pool Totoro, DRAC, local, Nibi, Rorqual, Fir, or
Trillium evidence.

No public API, `R/`, `src/`, formula grammar, pkgdown reference page, README,
NEWS, or support-cell status changed.

## 9. What Did Not Go Smoothly

The previously approved T87 direct-command shape was not safe for DRAC because
the wrapper calls `Rscript` directly. The Rorqual preflight also showed that
the exact T83 source/run-root paths exist, but the remote T85 runner and wrapper
are missing. T87 therefore stops as a packet/blocker instead of a smoke
execution tranche.

## 10. Known Residuals

T87 does not stage the T85 runner or wrapper on Rorqual, does not submit
`sbatch`, does not run a module load, R command, `Rscript`,
`devtools::load_all()`, smoke command, model fit, interval, retained-denominator
scan, coverage job, or support-cell status edit.

The next tranche is T88 only: copy the exact T85 runner, T85 wrapper, and T87
sbatch packet to the exact T83 Rorqual source/run-root paths; chmod the wrapper
and packet; verify remote SHA-256 hashes; run bash syntax and manifest-only
no-R proof; import remote stdout, stderr, exit code, host provenance, and
hashes; then checkpoint and stop before any sbatch submission or status
movement.

## 11. Team Learning

Cluster execution gates should separate staging, packet validation, and job
submission. That one-extra-gate discipline is cheaper than debugging an
accidental login-node command or a denominator whose host provenance is unclear.

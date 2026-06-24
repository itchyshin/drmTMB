# q4 derived-correlation DRAC dispatch pack

Date: 2026-06-23

Goal:

- Turn the r57 DRAC/totoro shard plan and r62 local MCSE pre-grid evidence into
  a dry-run dispatch pack that can be reviewed before any cluster compute is
  submitted.

Result:

- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/write-calibrated-grid-delta-drac-dispatch-pack.R`.
- Generated
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv`.
- Generated
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-drac-dispatch-pack/`.
- The pack contains an eight-task DRAC SLURM array template for shards 1-8, a
  DRAC worker script that runs forced compute then no-force resume passes in
  private shard roots, a separate shard-9 `totoro` worker, an aggregate-afterok
  script that waits for all nine shard manifests and uses
  `--compute-rate-mcse=true`, and a README.
- The generated pack keeps the account as `def-pi-placeholder`, marks scheduler
  and compute status as dry-run/not-submitted, records no GPU dependency, and
  keeps the storage policy as project-backed private shard roots with no login
  node compute.
- Updated mission-control widget, validator, focused R contract test, dashboard
  README, status JSON, sweep JSON, executable-evidence ledger, and build marker
  `r63`.

Checks:

- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/write-calibrated-grid-delta-drac-dispatch-pack.R`
  passed and regenerated the dispatch pack.
- `sh -n` passed for the generated DRAC array, DRAC worker, `totoro` worker, and
  aggregate scripts.
- `air format tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/write-calibrated-grid-delta-drac-dispatch-pack.R`
  passed.
- `python3 -m json.tool docs/dev-log/dashboard/status.json` passed.
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json` passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed; removed
  `tools/__pycache__`.
- `python3 tools/validate-mission-control.py` passed with eight r63 DRAC
  dispatch-pack dashboard rows and 62 executable-evidence rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1457 assertions.
- `sh -n tools/start-mission-control.sh` passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed validation and found the dashboard listening at
  `http://127.0.0.1:8765/`.
- Direct Python `urllib` fetches passed for `version.txt`, `status.json`,
  `sweep.json`, and
  `structured-re-q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv`; the
  live build marker was `r63`.
- `Rscript tools/codex-checkpoint.R --goal "r63 q4 derived-correlation DRAC/totoro dispatch pack" --next "Use the r63 dry-run dispatch pack only after selecting a DRAC account/host and login path; keep DRAC compute unsubmitted until all private-shard, compute/resume, and aggregate-afterok scripts are reviewed. SR150 remains blocked until coverage-evaluable denominator and calibrated coverage MCSE evidence exists."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-101603-codex-checkpoint.md`.
- `git diff --check` passed in
  `/Users/z3437171/Dropbox/Github Local/drmTMB`.
- `git diff --check` passed in
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

Boundary:

- This is q4 derived-correlation DRAC/totoro dispatch safety evidence only. It
  does not submit a DRAC job, run new compute, unblock SR150, or promote q4
  interval reliability, interval coverage, q4 REML, native-TMB q4 REML,
  HSquared AI-REML, non-Gaussian AI-REML, broad bridge support, DRAC readiness,
  a commit, a PR, or an Ayumi-facing reply.

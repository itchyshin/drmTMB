# Q4 Derived-Correlation Delta Grid Totoro Pilot

## 1. Goal

Bank r56 as the first totoro-backed CPU-only pilot for the q4
derived-correlation delta-grid resumable runner, using a larger seed-scale grid
than r55 while keeping SR150 blocked until calibrated ADEMP evidence exists.

## 2. Implemented

- Primed and verified SSH access to `totoro` through the shared ControlMaster
  socket.
- Confirmed `totoro` exposes 384 CPUs to the login environment.
- Installed missing user-library R dependencies needed for this artifact:
  `TMB` and `ape`.
- Synced a scratch copy of the current drmTMB worktree to
  `/home/snakagaw/codex-runs/drmTMB-r56/`.
- Ran the resumable q4 derived-correlation delta-grid runner on `totoro` with
  8 seeds crossed with scale levels `0.35`, `0.50`, and `0.65`.
- Ran a second no-force pass and confirmed all 24 per-cell outputs were skipped
  rather than recomputed.
- Pulled only the r56 simulation artifacts back to the local mission-control
  checkout.
- Updated the mission-control sidecar, dashboard feeds, validator, focused R
  dashboard contract test, dashboard README, widget build marker, and executable
  evidence ledger for r56.

## 3a. Decisions and Rejected Alternatives

The r56 pilot used `totoro` before DRAC because the r55 local pilot proved the
runner's basic skip behavior, but the project still needed a remote CPU
environment check before spending scheduler effort on calibrated ADEMP arrays.

The runner stayed sequential for this pilot. That choice keeps the current
manifest and run-log semantics simple. The DRAC step should parallelize at the
job-array layer or through a race-safe shard/aggregate runner rather than by
allowing multiple processes to write one run log.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke/`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-totoro-pilot.md`
- `docs/dev-log/recovery-checkpoints/2026-06-23-073825-codex-checkpoint.md`

## 5. Checks Run

- `ssh -o BatchMode=yes -o ControlPath=~/.ssh/cm-%r@%h:%p totoro 'hostname; whoami; getconf _NPROCESSORS_ONLN; pwd'`
  passed and reported `totoro`, user `snakagaw`, and 384 CPUs.
- `Rscript --vanilla -e 'install.packages("TMB", repos = "https://cloud.r-project.org", Ncpus = 4)'`
  passed on `totoro`.
- `Rscript --vanilla -e 'install.packages("ape", repos = "https://cloud.r-project.org", Ncpus = 4)'`
  passed on `totoro`.
- `rsync -a --delete --exclude='.git/' --exclude='.Rproj.user/' ... ./ totoro:~/codex-runs/drmTMB-r56/`
  passed.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R --n-rep=8 --sd-scales=0.35,0.50,0.65 --cell-limit=24 --run-label=r56_totoro_compute --force=true --reset-output=true --reset-log=true --allow-large=true`
  passed on `totoro` and wrote 24 per-cell TSV outputs.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R --n-rep=8 --sd-scales=0.35,0.50,0.65 --cell-limit=24 --run-label=r56_totoro_resume --force=false --allow-large=true`
  passed on `totoro` and recorded 24 `skipped_existing` actions.
- `air format tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`,
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`, and
  `sh -n tools/start-mission-control.sh` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1049 assertions.
- `python3 -m py_compile tools/validate-mission-control.py && python3 tools/validate-mission-control.py`
  passed with 8 q4 derived-correlation delta-grid resumable-smoke rows and 55
  executable-evidence rows.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed and served build `r56`.
- Direct Python `urllib` fetches passed for `version.txt`, `status.json`,
  `sweep.json`, the r56 resumable-smoke sidecar, the manifest, the run log, and
  one per-cell TSV.
- `Rscript tools/codex-checkpoint.R --goal "r56 q4 derived-correlation delta-grid totoro pilot" --next "Prepare DRAC job-array or shard/aggregate plan for calibrated ADEMP grid; keep SR150 blocked until MCSE-calibrated denominator evidence exists."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-073825-codex-checkpoint.md`.
- Final `git diff --check` passed in both active worktrees:
  `/Users/z3437171/Dropbox/Github Local/drmTMB` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## 6. Tests of the Tests

The focused R test and mission-control validator now require 24 explicit
seed-scale cells, 24 computed actions, 24 skipped actions, 144 retained
denominator rows, 142 finite delta rows, 48 warning rows, 30 failure-class
denominator rows, 27 boundary-clamped rows, and the r56 totoro compute/resume
run-label sequence. They also verify that the two unavailable delta rows remain
in the denominator instead of being silently dropped.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence under SR150. Ayumi-facing work remains out of scope.

## 8. Consistency Audit

The r56 dashboard wording keeps this as remote resumability pilot evidence only.
It does not promote q4 interval reliability, interval coverage, q4 REML,
native-TMB q4 REML, HSquared AI-REML, non-Gaussian AI-REML, broad bridge
support, public optimizer control, SR150 unblocking, a commit, a PR, or an
Ayumi reply.

## 9. What Did Not Go Smoothly

The first remote run failed because the synced scratch copy included local
compiled objects (`src/drmTMB.o`, `src/init.o`, and `src/drmTMB.so`). Linux
rejected the copied shared object with `invalid ELF header`. Removing those
remote scratch binaries let `devtools::load_all()` rebuild natively on totoro.

The next remote run failed because `ape` was not installed. `TMB` was also
missing initially. Both are now installed in the `snakagaw` R 4.5 user library
on totoro.

Julia is not on `PATH` on totoro, but this r56 R-runner slice did not require
Julia. Install Julia only when a Julia-backed step needs it.

## 10. Known Residuals

This is still pilot evidence. It proves that the resumable runner works on
totoro with a 24-cell CPU-only grid and preserves denominator accounting across
warning, pdHess=false, unavailable-interval, and boundary-clamped rows. It does
not estimate calibrated coverage or unblock SR150.

## 11. Team Learning

Grace should exclude local compiled package artifacts when syncing scratch
copies to Linux compute machines. Curie should scale the next rung through
DRAC job arrays or a shard/aggregate runner so multiple jobs do not race on one
run log.

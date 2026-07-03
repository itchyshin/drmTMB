# After Task: Q-Series Tranche 34 q4 relmat Host Preflight

## 1. Goal

Check whether the Tranche 8 q4 relmat location pregrid pack can be executed on
Totoro or DRAC, without spending compute or converting host reachability into a
coverage, admission, or support claim.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q4-location-tranche34-relmat-host-preflight.tsv`
as a six-row Mission Control sidecar. The rows cover the four relmat q4
location direct-SD targets plus provider and tranche summaries.

Mission Control build `r228` now loads and renders the Tranche 34 sidecar. The
validator, focused conversion-contract test, dashboard README, completion map,
and member discussion board now enforce the same boundary: Totoro is reachable,
but execution is blocked until source checkout and helper-script provenance are
clean.

Remote preflight observations:

- Local source SHA: `56add7f0`; local tree: `dirty`.
- Totoro ControlMaster socket:
  `/Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22`, present.
- Remote probe: `remote_host=totoro`, `remote_user=snakagaw`,
  `remote_date=2026-07-01T18:06:29-06:00`.
- Remote R: `/usr/bin/Rscript`, `Rscript (R) version 4.5.3 (2026-03-11)`.
- Remote path: `/home/snakagaw/codex/drmTMB` exists.
- Git probe from that path: `git_dir=/home/snakagaw/.git`,
  `top=/home/snakagaw`, `branch=main`,
  `head=fatal: ambiguous argument 'HEAD'...`, and
  `short=fatal: Needed a single revision`.
- Required files on Totoro: coverage runner present but untracked,
  `tools/run-q4-location-relmat-pregrid-totoro.sh` missing, and
  `tools/slurm/q4-location-relmat-pregrid.sbatch` missing.

## 3a. Decisions and Rejected Alternatives

The accepted decision is
`block_execution_until_source_checkout_and_helpers_are_synced`. Tranche 34 runs
no Totoro job, submits no DRAC job, creates no coverage-evaluable denominator,
and moves no support-cell status.

Rejected executing from the reachable Totoro path. Grace blocks it because the
remote path is not a verified run checkout for this tranche, `HEAD` is not
usable, and Tranche 8 helper scripts are absent. Fisher blocks any denominator
from unverifiable source provenance. Rose blocks any tier, status, or public
claim based only on host reachability.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-tranche34-relmat-host-preflight.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche34-q4-relmat-host-preflight.md`

## 5. Checks Run

- Tranche 34 TSV shape check: 7 lines including header, 31 columns.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r228.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 6 Tranche 34 relmat-host-preflight
  rows, and 168 member-discussion rows.
- Focused `devtools::test(filter = "structured-re-conversion-contracts",
  reporter = "summary")`: passed with `DONE` and exit code 0.
- Invariant scan: 104 support cells, 8 interval `inference_ready`, 8 coverage
  `inference_ready`, 0 structured rows with any `supported` status, 0 q4
  coverage-authorized rows, and all 6 Tranche 34 rows set to
  `no_compute_in_tranche34`, `coverage_not_authorized`, and
  `do_not_promote`.
- Served dashboard probe on `http://127.0.0.1:8766`: `version.txt` returned
  `r228`, the Tranche 34 sidecar served with 7 lines and 31 columns, and
  `index.html` contained the Tranche 34 render label and sidecar load.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche34-q4-relmat-host-preflight.md')"`:
  passed with `after-task structure check passed`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused R test reads the Tranche 34 sidecar directly and checks schema,
row IDs, scopes, target mapping back to Tranche 8 host-pack rows, the Totoro
source-provenance blocker fields, `no_compute_in_tranche34`, unchanged q4
relmat support-cell status, and the Rose/Fisher/Grace member-board rows.

The Python validator independently checks row counts, required columns, exact
common blocker values, claim-boundary phrases, next-gate phrases, Tranche 8
source-pack identities, unchanged support-cell status, and the SC378 reviewer
discussion entries.

## 7a. Issue Ledger

No new GitHub issue was opened. I did not run a public issue search for this
closeout because Tranche 34 is an internal Mission Control provenance gate, not
a user-facing API, formula, package behavior, or documentation feature.

## 8. Consistency Audit

The q4 relmat location support cell remains `point_fit/planned/planned`.
Mission Control still reports 104 Q-Series support cells, 8 interval-ready rows,
8 coverage-ready rows, 0 structured rows with any `supported` status, and 0 q4
coverage-authorized rows.

Public APIs, formula grammar, `R/`, `src/`, pkgdown, README, NEWS, and
support-cell statuses were not changed.

## 9. What Did Not Go Smoothly

The first validator rerun failed because the exact-string guard for the older q4
admission renderer sequence had not been updated to include the new Tranche 34
argument. The dashboard itself already loaded the older q4 admission sidecars;
the validator guard was stale. I updated the guard and reran validation before
accepting the tranche.

## 10. Known Residuals

Q4 relmat pregrid compute remains blocked. The next tranche must either
synchronize or stage a clean Totoro run source, or choose a verified DRAC
fallback checkout, then rerun the host preflight. A fresh checkpoint and
Rose/Fisher/Grace approval are required before any q4 relmat pregrid execution.

The full Q-Series completion campaign remains active.

## 11. Team Learning

Grace kept host reachability separate from executable provenance. Fisher kept an
unverifiable source checkout from becoming a denominator. Rose kept the status
boundary honest: no execution, no coverage, no admission, no support.

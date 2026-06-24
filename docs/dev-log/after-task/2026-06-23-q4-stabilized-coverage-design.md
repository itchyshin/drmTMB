# Q4 Stabilized Coverage Design

## Goal

Convert the r43 stabilized q4 direct-profile evidence into a calibrated
coverage-design gate without promoting interval reliability or coverage.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-coverage-design.tsv`.
- The design records that direct q4 SD profile intervals are now finite for all
  four profile-eligible stabilized denominator rows.
- The design keeps the three `pdHess = false` rows, one gradient-warning row,
  and two duplicate-`x` profile warnings in scope for any future denominator.
- The design separates direct q4 SD profiles from derived q4 correlation
  intervals, bootstrap refit accounting, route-specific bridge status, and MCSE
  reporting.
- The design preserves the planned calibrated replicate count of 500 rows before
  coverage wording.

## Boundary

This is q4 stabilized coverage-design evidence only. It does not promote q4
interval reliability, interval coverage, q4 REML, HSquared AI-REML,
profile/bootstrap coverage, broad bridge support, a public optimizer control, a
commit, a PR, or an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 623 assertions.
- `python3 tools/validate-mission-control.py` passed with 8 q4 stabilized
  coverage-design rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r44` and
  `structured-re-q4-stabilized-coverage-design.tsv` from
  `http://127.0.0.1:8765/`.

## Next Gate

Create a calibrated q4 grid runner/report that keeps successful, failed,
warning, unavailable, and unattempted rows in denominator accounting and reports
MCSE before any interval-coverage wording.

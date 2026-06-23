# Q4 Stabilized Eligible Profile Extension

## Goal

Profile all four direct q4 SD axes for the three stabilized denominator rows
that were profile-eligible but not yet attempted.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-eligible-profile.tsv`.
- Added companion artifact rows in
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-eligible-profile-results.tsv`.
- The three newly attempted denominator rows were seed `202606902`, scale
  `0.35`; seed `202606903`, scale `0.35`; and seed `202606904`, scale `0.50`.
- All twelve direct q4 SD profile rows returned finite ordered endpoints,
  `conf.status = profile`, `profile.boundary = false`, and
  `profile.message = ok`.
- The profile run emitted two `regularize.values()` duplicate-`x` warnings, so
  the sidecar keeps warning context visible instead of treating the run as
  promotion-grade interval evidence.
- Updated
  `docs/dev-log/dashboard/structured-re-q4-stabilized-profile-denominator-status.tsv`
  so all four profile-eligible denominator rows are now attempted and finite,
  while three `pdHess = false` rows and one gradient-warning row remain in the
  denominator.

## Boundary

This is eligible-denominator direct-SD profile evidence only. It does not
promote q4 interval reliability, interval coverage, q4 REML, HSquared AI-REML,
profile/bootstrap coverage, broad bridge support, a public optimizer control, a
commit, a PR, or an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 611 assertions.
- `python3 tools/validate-mission-control.py` passed with 12 q4 stabilized
  eligible-profile rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r43`,
  `structured-re-q4-stabilized-eligible-profile.tsv`, and
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-eligible-profile-results.tsv`
  from `http://127.0.0.1:8765/`.

## Next Gate

Design the next calibrated profile/coverage grid so `pdHess = false`,
gradient-warning, profile-warning, and finite-profile rows all remain in the
denominator with MCSE before any coverage wording.

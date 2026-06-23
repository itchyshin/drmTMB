# Q4 Stabilized Profile Smoke

## Goal

Check whether the stabilized q4 fixture that produced finite Wald direct-SD
intervals can also evaluate a single direct-SD profile interval.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-profile-smoke.tsv`.
- Added companion artifact row
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-profile-smoke-results.tsv`.
- The scale `0.50`, seed `202606902` stabilized row had optimizer convergence,
  `pdHess = TRUE`, and max fixed-gradient `0.0009231771`.
- `profile_targets()` marked the four direct q4 SD targets profile-ready and
  the six derived q4 correlations not profile-ready.
- A fast `TMB::tmbprofile` interval for
  `sd:mu:sigma1:phylo(1 | p | species)` returned finite endpoints
  (`0.2956858`, `0.7575208`), `conf.status = profile`,
  `profile.boundary = false`, and `profile.message = ok`.
- Updated the mission-control widget so the profile smoke renders beside the
  stabilized denominator extension.
- Added validator and test coverage for the single smoke row, finite ordered
  endpoints, profile status, profile boundary, evidence path, and claim
  boundaries.

## Boundary

This is one q4 direct-SD profile smoke only. It does not promote q4 interval
reliability, interval coverage, q4 REML, HSquared AI-REML, profile/bootstrap
coverage, broad bridge support, a public optimizer control, a commit, a PR, or
an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 567 assertions.
- `python3 tools/validate-mission-control.py` passed with 1 q4 stabilized
  profile-smoke row.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r40`,
  `structured-re-q4-stabilized-profile-smoke.tsv`, and
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-profile-smoke-results.tsv`
  from `http://127.0.0.1:8765/`.

## Next Gate

Replicate profile intervals across all four direct q4 SD axes and denominator
rows before any calibrated coverage wording.

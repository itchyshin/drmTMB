# Q4 Stabilized All-Direct Profile Smoke

## Goal

Check whether the same stabilized q4 row used for the single-target profile
smoke can evaluate finite profile intervals for all four direct q4 SD axes.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-all-direct-profile.tsv`.
- Added companion artifact rows in
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-all-direct-profile-results.tsv`.
- The scale `0.50`, seed `202606902` stabilized row had optimizer convergence,
  `pdHess = TRUE`, and max fixed-gradient `0.0009231771`.
- Fast `TMB::tmbprofile` intervals returned finite ordered endpoints for all
  four direct q4 SD targets:
  `sd:mu:mu1:phylo(1 | p | species)`,
  `sd:mu:mu2:phylo(1 | p | species)`,
  `sd:mu:sigma1:phylo(1 | p | species)`, and
  `sd:mu:sigma2:phylo(1 | p | species)`.
- All four rows returned `conf.status = profile`,
  `profile.boundary = false`, and `profile.message = ok`.
- Updated the mission-control widget so the all-direct profile smoke renders
  beside the single-target profile smoke.
- Added validator and test coverage for row count, axis coverage, profile
  status, finite ordered endpoints, evidence paths, and claim boundaries.

## Boundary

This is one-row q4 direct-SD profile smoke evidence only. It does not promote
q4 interval reliability, interval coverage, q4 REML, HSquared AI-REML,
profile/bootstrap coverage, broad bridge support, a public optimizer control, a
commit, a PR, or an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 583 assertions.
- `python3 tools/validate-mission-control.py` passed with 4 q4 stabilized
  all-direct profile rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r41`,
  `structured-re-q4-stabilized-all-direct-profile.tsv`, and
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-all-direct-profile-results.tsv`
  from `http://127.0.0.1:8765/`.

## Next Gate

Replicate all-four profile intervals across denominator rows and add
profile-failure denominators before any calibrated coverage wording.

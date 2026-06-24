# Q4 Stabilized Profile Denominator Status

## Goal

Turn the stabilized q4 preflight and denominator-extension rows into an
explicit profile-denominator ledger before running larger profile or coverage
work.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-profile-denominator-status.tsv`.
- The denominator map has eight stabilized q4 rows: four scale `0.35` rows and
  four scale `0.50` rows.
- Five rows have `pdHess = TRUE` and finite Wald direct-SD status.
- One `pdHess = TRUE` row is held out of profile eligibility because
  `max_gradient = 0.0048295879`.
- One row, scale `0.50` and seed `202606902`, has all four direct profile
  intervals banked as finite.
- Three rows are profile-eligible but not yet profiled.
- Three rows remain blocked by singular convergence and `pdHess = false`.

## Boundary

This is denominator-accounting evidence only. It does not promote q4 interval
reliability, interval coverage, q4 REML, HSquared AI-REML, profile/bootstrap
coverage, broad bridge support, a public optimizer control, a commit, a PR, or
an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 597 assertions.
- `python3 tools/validate-mission-control.py` passed with 8 q4 stabilized
  profile-denominator rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r42` and
  `structured-re-q4-stabilized-profile-denominator-status.tsv` from
  `http://127.0.0.1:8765/`.

## Next Gate

Profile all four direct q4 SD axes for the three eligible unprofiled rows,
resolve or retain the gradient-warning row explicitly, and keep every failed or
unprofiled row in the denominator before any coverage wording.

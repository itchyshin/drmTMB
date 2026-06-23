# Q4 Stabilized Denominator Extension

## Goal

Extend the compact q4 stabilized preflight from row-level positive evidence into
scale-wise denominator evidence before any profile/bootstrap or coverage work.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-denominator-extension.tsv`.
- Added companion artifact rows in
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-denominator-extension-results.tsv`.
- Across four seeds at scale `0.35`, all four fits returned, two converged with
  `pdHess = TRUE`, and two had 4/4 finite Wald direct-SD interval rows.
- Across four seeds at scale `0.50`, all four fits returned, three converged
  with `pdHess = TRUE`, and three had 4/4 finite Wald direct-SD interval rows.
- The scale `0.50`, seed `202606903` row had `pdHess = TRUE` and finite Wald
  rows but also `max_gradient = 0.0048295879`, so the sidecar keeps one
  gradient-warning row in the denominator.
- Updated the mission-control widget so the denominator extension renders next
  to the q4 stabilized preflight.
- Added validator and test coverage for the two scale rows, denominator counts,
  gradient-warning count, evidence path, and claim boundaries.

## Boundary

This is q4 stabilized denominator-preflight evidence only. It does not promote
q4 interval reliability, interval coverage, q4 REML, HSquared AI-REML,
profile/bootstrap intervals, broad bridge support, a public optimizer control,
a commit, a PR, or an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 553 assertions.
- `python3 tools/validate-mission-control.py` passed with 2 q4 stabilized
  denominator-extension rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r39`,
  `structured-re-q4-stabilized-denominator-extension.tsv`, and
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-denominator-extension-results.tsv`
  from `http://127.0.0.1:8765/`.

## Next Gate

Predeclare the stabilized q4 seed grid and denominator writer, then evaluate
profile/bootstrap availability separately from Wald finite-interval status.

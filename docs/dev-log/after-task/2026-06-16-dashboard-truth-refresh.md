# After Task: Dashboard Truth Refresh After Binomial Evidence

## Goal

Keep the mission-control finish board truthful after the non-Ayumi merge stack:
`#585`, `#587`, `#588`, and `#589` are on `origin/main`, while binomial
interval calibration, Julia bridge promotion, release readiness, and numerical
guard sensitivity remain unfinished.

## Implemented

Updated `docs/dev-log/dashboard/status.json` and
`docs/dev-log/dashboard/sweep.json` so the live board no longer describes the
binomial evidence lane as a staged branch. The board now records `#588` as
merged evidence, keeps fixed-effect binomial interval calibration planned, and
keeps release readiness planned. The `#544` bridge-gate row now points to the
merged capability comparison / docs-drift-guard after-task note rather than
describing a pending PR.

Added a new Evidence Gates row,
`drmTMB-numerical-guard-sensitivity`, for Hao Qin's numerical-guard concern.
The row deliberately marks documentation as covered and simulation as planned:
the guard audit note exists, but no sensitivity simulation has been run yet.

## Mathematical Contract

No likelihood, parameterization, or formula grammar changed. The dashboard
continues to separate fixed-effect `stats::binomial(link = "logit")` GLM
parity from unclaimed binomial interval calibration, random effects, structured
effects, bivariate or mixed responses, and Julia bridge support.

## Files Changed

- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-dashboard-truth-refresh.md`

## Checks Run

```sh
python3 tools/validate-mission-control.py
node -e 'JSON.parse(require("fs").readFileSync("docs/dev-log/dashboard/status.json","utf8")); JSON.parse(require("fs").readFileSync("docs/dev-log/dashboard/sweep.json","utf8")); console.log("json_ok")'
sh tools/start-mission-control.sh --background
git diff --check
```

Browser checks against `http://127.0.0.1:8765/`:

- desktop render showed all six finish-board sections, 11 finish cards, the
  guard-sensitivity row, merged binomial evidence text, release-readiness text,
  and dirty/detached repo truth;
- mobile render at 390 by 844 showed the same board sections and guard row with
  no horizontal overflow.

## Tests Of The Tests

The mission-control validator checks the JSON schema, canonical team names,
finish-board lanes, evidence requirements for covered/banked rows,
`version.txt` versus the HTML `BUILD` constant, and the Julia gate/capability
TSV contracts. The browser check verifies the rendered page, not only the JSON.

## Consistency Audit

The refreshed board now says:

- `#588` is merged, not staged;
- `#589` adds documentation and numerical-guard audit visibility;
- numerical-guard sensitivity is an explicit Evidence Gates item, not an
  invisible caveat;
- release readiness remains planned;
- DRM.jl binomial claim alignment remains owner-held and deferred, with no
  Codex DRM.jl code changes.

## GitHub Issue Maintenance

Issue breadcrumbs posted:

- `drmTMB#577`:
  https://github.com/itchyshin/drmTMB/issues/577#issuecomment-4724259204
- `drmTMB#59`:
  https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4724259200
- `drmTMB#569`:
  https://github.com/itchyshin/drmTMB/issues/569#issuecomment-4724259211

## What Did Not Go Smoothly

The first JSON edit normalized inline arrays and created needless diff churn.
I rewrote the update from the checked-in JSON with targeted replacements so the
final PR shows the real state changes.

## Team Learning

Rose's dashboard rule should be automatic after every evidence PR: if a branch
description says "stages" after a merge, the board is lying softly. Fixing that
small drift early keeps later release decisions from inheriting stale truth.

## Known Limitations

No package code changed, so R package tests were not rerun for this slice.
`pkgdown::check_pkgdown()` remains outside this slice and has a known
Claude-owned penalty/MAP navigation blocker. The guard-sensitivity row is a
tracking row only; it does not implement the big simulation lane.

## Next Actions

Use the refreshed dashboard as the checkpoint for the next non-Ayumi slice:
release/comparator readiness should promote only the `stats::glm()` binomial
parity evidence that is already banked, while leaving interval calibration and
guard-sensitivity claims planned until simulations produce MCSE-backed
evidence.

# After Task: Ayumi Phylo Balance Research Plan

## 1. Goal

Research the parked Ayumi phylo-balance concern and create a 100-slice plan for
the next Ayumi-facing arc without drafting or posting a reply.

## 2. Implemented

Added `docs/design/197-ayumi-phylo-balance-research-100-slices.md`, which
summarizes the accessible evidence and gives a balance-first 100-slice plan.

## 3a. Decisions and Rejected Alternatives

The direct Ayumi issue was not readable from this session, so the plan records
that limitation instead of guessing the issue text. The plan is kept separate
from the current `finish-100-slices.tsv` ledger because it is the next arc, not
a replacement for the active finish run.

## 4. Files Touched

- `docs/design/197-ayumi-phylo-balance-research-100-slices.md`
- `docs/dev-log/after-task/2026-06-22-ayumi-phylo-balance-research-plan.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```sh
tools/validate-mission-control.py
git diff --check
```

Both checks passed after adding the plan note. Dashboard JSON also parsed with
`python3 -m json.tool`.

## 6. Tests of the Tests

This is a planning/research slice. Its guardrail is source triangulation:
local balance tables, code/test evidence, internal GitHub trackers, and the
public tutorial are named explicitly so the next agent can verify each claim.

## 7a. Issue Ledger

Read or attempted:

- `Ayumi-495/LS_ecogeographical-rules#2`: inaccessible here by GitHub app and
  public web request.
- `itchyshin/drmTMB#555`: q4 status/speed/bridge harness.
- `itchyshin/drmTMB#570`: beak sigma-phylo native failure.
- `itchyshin/DRM.jl#291`: q4 Gaussian REML speed and robustness.
- `itchyshin/DRM.jl#293`: Julia ML `-Inf` point-fit ladder.

No issue was edited or commented on.

## 8. Consistency Audit

The plan keeps native ML, native REML, R-to-Julia bridge, direct DRM.jl,
profile/bootstrap inference, MAP/penalized fits, and Ayumi reply drafting as
separate waves.

## 9. What Did Not Go Smoothly

The Ayumi issue itself returned 404 through both available live paths, so the
plan is evidence-backed but not a fresh read of the private thread.

## 10. Known Residuals

Before any Ayumi reply, a session with access to the issue thread should read
the latest comments directly and compare them with this plan.

## 11. Team Learning

The balance question should be answered by estimator and route, not by a single
binary implemented/not-implemented label.

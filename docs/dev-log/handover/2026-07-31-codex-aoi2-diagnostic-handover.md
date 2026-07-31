# Session Handoff: AOI-2 pre-prediction diagnostics

Meta: 2026-07-31 · from Codex · Association lane · AOI-2 HOLD

## Critical Context

AOI-1's fixed-effect Bernoulli x ordinary-NB2 association formula and
`newdata` point-prediction implementation is already merged. AOI-2's retained
3,000-attempt point-recovery campaign is **HOLD_NO_POINT_RECOVERY_CLAIM**:
14 of 15 formula-by-sample-size cells fail the frozen 95% interior-fit
availability criterion. Do not translate small conditional-on-available bias
into a programme claim.

AOI-2D0–D2 adds internal diagnostic retention only. It does not begin AOI-3,
change public APIs/docs/ledgers, relax `boundary_unresolved` prediction, or
authorize any remote computation.

## What Was Accomplished

- `62fac72a3` retained the AOI-2 point-recovery consolidation HOLD receipt.
- `be9126f38` captures association diagnostics before prediction in the AOI-2
  runner and adds focused tests.
- `72c97adc7` corrects diagnostic row-status serialization.
- `8db19b67b` retains three exact-seed local replay artifacts and the internal
  diagnostic receipt.

The pre-prediction payload records nonexclusive unresolved flags: hard cap,
non-finite likelihood, optimizer convergence, multistart disagreement, weak
curvature, score failure, and NB2 endpoint failure; it also records optimizer,
multistart, score/curvature, integration, and response details.

## Current Working State

- Working: the committed runner and focused tests.
- In progress: none.
- Held: AOI-2 point-recovery claim; uncertainty/calibration and AOI-3.
- Protected: Lane B `sd()` clamp/profile work and every foreign association
  branch. Do not edit or merge them from this lane.

## Key Decisions and Rationale

The generic old `Cannot predict from a boundary-unresolved association fit.`
record did not retain the fitted association result because prediction occurred
first. The new runner copies diagnostics before that fail-closed prediction
call. It deliberately does not infer a single cause: unresolved conditions are
nonexclusive.

Three retained-seed local replays exercise the observed outer statuses:
`mixed/n=360/r=1` is interior, `numeric_interaction/n=360/r=7` is
near-boundary, and `transformation/n=360/r=6` is boundary-unresolved. The
last has a score-failure flag only among the recorded unresolved flags. That
is a one-seed observation, not an explanation of all 708 unavailable attempts.

## Landing State

The completed Association-lane commits are pushed through `9366c68e2`.
They remain **CARRIED-OVER** rather than merged: this branch must remain
segregated from foreign Lane-B and association work, and the AOI-2 HOLD has no
owner-approved landing/PR path.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/aoi2-drac-recovery` through `9366c68e2` | yes | yes | none | CARRIED-OVER — resume on this checkout; do not merge without owner routing |

Other unpushed branches reported by the gate are foreign and must not be
cleaned, rebased, or included in this lane.

## Files Created / Modified

- `R/associate-pairs.R`
- `tools/run-aoi2-bernoulli-nb2-recovery.R`
- `tests/testthat/test-aoi2-diagnostic-payload.R`
- `tests/testthat/test-aoi2-recovery-dispatch.R`
- `docs/dev-log/after-task/2026-07-31-aoi2-point-recovery-consolidation-hold.md`
- `docs/dev-log/after-task/2026-07-31-aoi2d0-d2-preprediction-diagnostic-receipt.md`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi2d0-local-replays-r2/`
- this handover

## Next Immediate Steps

1. Run lane preflight and inspect this branch against current `main` before
   taking ownership.
2. Treat AOI-2's point-only result as held; read both after-task receipts.
3. Do not launch a replay campaign, alter public surfaces, or start AOI-3
   unless the owner explicitly authorizes a separately frozen diagnostic or
   uncertainty design.
4. If authorization arrives, freeze the diagnostic sample and its analysis
   contract before replaying; report nonexclusive trigger flags and retain all
   attempts. A later uncertainty study remains a separate AOI-3 gate.

## Blockers / Open Questions

The live blocker is scientific, not technical: 14 of 15 AOI-2 cells fail
interior-fit availability. The existing data cannot identify trigger
prevalence because they predate payload retention. Owner direction is needed
before a broader diagnostic replay or any repair design.

## Gotchas and Failed Approaches

- Never infer that all 708 unavailable results share the sampled score-failure
  flag.
- Do not count near-boundary fits as AOI-2 usable interior fits.
- Do not overwrite, pool away, or rerun the retained r3/r4 campaign roots.
- Do not expose sandwich internals through `vcov()`, `confint()`, profiles, or
  standard errors; AOI-3 has not started.

## Mission Control

| Scope | Branch / evidence | State | Next leverage |
| --- | --- | --- | --- |
| AOI-1 formula/newdata | merged before this lane | point-only implementation | preserve API boundary |
| AOI-2 recovery | r3+r4 3,000 retained attempts | HOLD | separate diagnostic design if authorized |
| AOI-2D0–D2 | `be9126f38`, `72c97adc7`, `8db19b67b` | internal retention complete | no public inference action |
| AOI-3 | none | not begun | requires separate approval and calibration contract |

## How to Resume

From the drmTMB checkout, start a new Codex task and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-31-codex-aoi2-diagnostic-handover.md,
docs/dev-log/after-task/2026-07-31-aoi2-point-recovery-consolidation-hold.md,
and docs/dev-log/after-task/2026-07-31-aoi2d0-d2-preprediction-diagnostic-receipt.md.
Run tools/lane_preflight.sh, preserve the AOI-2 HOLD and Lane-B split, then execute only an owner-authorized next step.
```

# Session Handoff: AOI-2D3 completed diagnostic replay

Meta: 2026-07-31 · from Codex · Association lane · AOI-2 HOLD

## Critical Context

AOI-1's Bernoulli x ordinary-NB2 fixed-effect association formula and
`newdata` point-prediction route are merged, point-only. The original AOI-2
3,000-attempt point-recovery campaign remains
**HOLD_NO_POINT_RECOVERY_CLAIM**: 14 of 15 formula-by-sample-size cells fail
the frozen 95% interior-fit availability criterion. Nothing in D3 changes that
result, starts AOI-3, or exposes uncertainty.

## What Was Accomplished

The owner-authorized local D3 replay completed the immutable 113-key
stratified sample (71 original boundary-unresolved, 30 interior, 12
near-boundary) over all five fixed-effect formula classes and n = 360, 720,
1440. All 113 dispatches exited zero and carry the sole replay source SHA
`e9375dbed4243e1e9d9f17b36a7236b29db55685`.

The analyzer output is
`docs/dev-log/simulation-artifacts/2026-07-31-aoi2d3-diagnostic-analysis/`.
It explicitly says `INTERNAL_AOI2_DIAGNOSTIC_ONLY`. The claim review receipt
is `docs/dev-log/after-task/2026-07-31-aoi2d3-diagnostic-claim-review.md`.

## Current Working State

- Complete: valid D3 replay, integrity check, trigger summary, and internal
  claim review.
- Held: AOI-2 point-recovery claim, all uncertainty, and AOI-3.
- Protected: Lane B `sd()`/profile work, Arc D, all foreign association lanes,
  public APIs/docs/ledgers, and public capability claims.

## Key Decisions and Rationale

D3 is descriptive, stratified, and diagnostic only. Of the sampled original
boundary-unresolved rows, 66/71 replayed boundary-unresolved and all 66 had a
score-failure flag; five replayed interior. All 30 sampled interior rows
replayed interior. The sampled near-boundary rows replayed 11 near-boundary
and one boundary-unresolved. Flags are nonexclusive; these counts do not
identify a universal cause or a population prevalence.

Never use the status differences to correct the original campaign. Never pool
the 113 diagnostic rows with the original 3,000 attempts. The original 708
unavailable results remain unreclassified. The earlier invalid mixed-SHA local
attempt is retained separately and excluded from all valid D3 analysis.

## Landing State

The D3 files are completed locally on `codex/aoi2-drac-recovery`. They need a
scoped commit/push only; do not merge or create a PR without owner routing.

## Files Created / Modified

- `docs/dev-log/simulation-artifacts/2026-07-31-aoi2d3-local-replays/`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi2d3-diagnostic-analysis/`
- `docs/dev-log/after-task/2026-07-31-aoi2d3-diagnostic-claim-review.md`
- this handover

## Checks

- `tools/summarize-aoi2-diagnostic-replays.R` completed against the immutable
  manifest and valid replay root.
- Dispatch: 113 rows, zero nonzero exits, one source SHA.
- `check-after-task.R` passed for the D3 receipt.
- Focused AOI-2 payload/dispatch/association tests passed.

## Next Immediate Step

Keep the AOI-2 HOLD. The next possible work is an owner decision about whether
the internal diagnostics support a separately designed point-estimation route.
AOI-3 remains forbidden unless separately authorized for local smoke and then,
only if that passes, the preregistered DRAC full-refit uncertainty campaign.

## How to Resume

```text
Rehydrate from docs/dev-log/handover/2026-07-31-codex-aoi2d3-diagnostic-handover.md,
docs/dev-log/after-task/2026-07-31-aoi2d3-diagnostic-claim-review.md, and
docs/dev-log/after-task/2026-07-31-aoi2-point-recovery-consolidation-hold.md.
Run lane preflight, preserve the AOI-2 HOLD and Lane-B split, and take only an
explicitly owner-authorized next action. Do not begin AOI-3 or change public
surfaces.
```

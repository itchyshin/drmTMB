# Plan vs actual: R-Julia parity re-pin to DRModels `da8b3f871`, 2026-09-24

Reader: Shinichi, and whoever runs the next re-pin. This file reconciles the
approved ultra-plan against what actually happened, recording material
deviations only. It does not review implementation quality and does not
escalate; readers should treat a "drift" tag as a flag for someone else to
look at, not a verdict.

## Provenance

| | |
|---|---|
| plan | `/Users/z3437171/.claude/plans/eventual-rolling-dove.md` |
| after-task | `docs/dev-log/after-task/2026-09-24-parity-repin-da8b3f871.md` |
| lane | `claude/r-julia-parity-20260924`, worktree `~/local-scratch/lanes/drmTMB-r-julia-parity-20260924` |
| drmTMB base | `54df129fe` |
| DRModels pin | `da8b3f8711beb5ef3186b890544c2e7850c7f194` (#808) |

The headline deliverable landed as planned: one pin, `da8b3f871`, now names
all three pin-bearing generated docs, the `source-pins.json` `repins[]`
entry, and the tip-identity receipt; the four pin-independent generators
produced zero diff; the acceptance ledger passed 8/8 on reverify. The rows
below record where the path to that outcome departed from the plan.

## Deviations

| axis | planned | actual | tag | owner |
|---|---|---|---|---|
| scope | S0: one detached DRModels worktree, at the new pin only | S2's baseline regen at the old pin needed a second detached worktree, `~/local-scratch/lanes/DRModels-pin-d2102ab73`, not named in the plan | adaptive | Ada |
| scope | S0: widen the lease once, to all output paths | Lease was widened twice; the second claim replaced the path list rather than extending it, so the union of both claims had to be re-claimed by hand | drift | Ada |
| scope | S6: update the OWED markers in `coordination-board.md` and `active-lane-split.md`, on this branch's own lines | Not edited: those OWED lines exist only on the unmerged handover branch, not on `main` or this branch; the after-task records that this PR supersedes them instead | adaptive | Ada |
| evidence/verification | S1: rehydrate `test-julia-module-compat.R` "live" | Reported 8 pass, 0 fail, but ran 0 live-engine tests; the test is mock-driven regardless of environment, so "live" was not an available outcome | unclear | Gauss |
| evidence/verification | S4: Haiku scout produces a normalised (SHA-stripped) two-pass diff with GREEN/UNCITED/join-mismatch counts | First pass did not strip SHAs: it reported drmTMB-side line-number reindexing as substantive and the DRModels-side raw count (271 lines) instead of the corrected 4/47/0; the orchestrator re-measured before the count was used anywhere | drift | Gauss |
| model routing | D-151: planning runs on Fable; D-280 (Fable-vs-Opus trial) named as a comparison to run | Shinichi deferred the D-280 trial to a later plan, but the session, including its own plan, ran on Opus 5.5, not Fable | drift | Ada |
| model routing | S7: dispatched as a Haiku scout slice | Orchestrator ran `gate-check --reverify` directly, judging it a deterministic script needing no separate agent | adaptive | Ada |
| model routing | Fan-out budget: 5 new children (Haiku x2, Sonnet x2, Opus x1) within a ceiling of 6 | 6 children used: the planned 5 plus one Sonnet Rose plan-review before execution, added under ultra-plan Phase 2, filling the budget to its cap | adaptive | Ada |
| safety gates | S5: receipt FAIL means stop and report as a DRModels finding, never force | First attempt failed on environment (no `Manifest.toml` in the fresh worktree; juliaup default channel 1.10.0 vs the receipt's 1.13.0), not on numerics; this was read as outside the "receipt FAIL" stop condition and repaired (Manifest copied, `JULIA_HOME` pointed at 1.13.0), then rerun to PASS | unclear | Ada |
| safety gates | Acceptance ledger G3/G4/G5 written in S0, expected to pass on first reverify | All three failed on first run: G3 (byte-stable) tripped on the drmTMB HEAD-stamp line that changes after every commit; G4 (zero skips) tripped on the pre-existing #1184 skip; G5 hit the checker's 120s default timeout. G3 and G4 were wording faults in the gate; G5 was a runner timeout. None was a fault in the regenerated artefacts. Corrected with NOTE lines and a 900s rerun to 8/8; Rose's output review then found the first G3 fix too weak (it dropped bullet lines) and G6 matching text instead of exit status; both re-corrected, G3 red control added, 8/8 again | drift | Gauss |
| public claims | ESTIMATE ~55 min wall-clock | Actual ran longer (Dropbox worktree checkout took several minutes; ultra-plan phases and two review rounds added time); no exact figure is recorded | adaptive | Rose |
| handoff state | S9: remove the DRModels pin worktree | Kept the new-pin worktree (`DRModels-pin-da8b3f871`) because the receipt records it as its source path, following the same precedent as the 2026-09-20 receipt; the old-pin worktree (`DRModels-pin-d2102ab73`) is left pending removal | adaptive | Ada |
| handoff state | Slice table: S9 depends on S8 (Rose's review) | S8 returned NOT READY: 1 blocking finding (the after-task's "three families" and "MISMATCH already everywhere" claims were false against `main`) and 5 fixes (a fourth pin `aee371cc9` on the join; misquoted `julia_manifest_source`; weak G3 filter; missing G5 note; 13 refreshed drmTMB citations hidden by "0 lines"). All applied before commit | adaptive | Rose |

## Summary

The re-pin delivered exactly what the plan headlined: one SHA across every
pin-bearing artefact, a measured and reproducible drmTMB-side/DRModels-side
diff, and a clean 8/8 gate reverify. Most deviations were adaptive
corrections made as the plan met a worktree, lease, and gate state it had
not fully anticipated; the closest items to drift are the uncorrected Haiku
scout counts (caught before use), the gate faults in S7 (two wording, one
timeout), a false "already true" claim in the first after-task draft (caught
by Rose), the
lease double-claim, and running this session's own planning on Opus 5.5
rather than Fable per D-151. One item is open at handoff: the old-pin
worktree awaits removal.

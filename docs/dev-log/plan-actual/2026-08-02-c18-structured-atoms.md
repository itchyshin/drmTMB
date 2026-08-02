# Plan vs actual — C18 structured zero-one-beta atom effects

Reconciler: Melissa · 2026-08-02 · lane `claude/c18-structured-atoms-plan`
Plan: `~/.claude/plans/peaceful-wobbling-clock.md` (rev 2, approved)
Baseline `origin/main@83055ec58` · lane head `90d1abe1d`

Material deviations only, along the six axes. Cosmetic differences are not recorded.

## Outcome against the plan

| | planned | actual |
| --- | --- | --- |
| cells promoted | 8 | **7** |
| census | 338 / 350 / 9 | **337 / 350 / 10** |
| total rows | 697 | 697 |
| spatial | deferred (untouched) | deferred **and refused in code** |

## Scope

**D1 · Seven cells promoted, not eight — ADAPTIVE.** `mc-0615` (coi × relmat) scored 3/4;
seed 2026080624 collapsed the variance component to the boundary (`tau_hat` 0.0006 against 0.55).
The gate produced `BLOCKED_LOCAL_FIXTURE` and the cell stayed `not_implemented`. Re-running with
other seeds would very likely have produced a pass and was explicitly not done. The census follows
from this, so **D2 (census 337/350/10) is the same deviation, not a second one.**

**D3 · Spatial went from "deferred" to "refused in code" — ADAPTIVE, forced by review.**
The plan fenced spatial by *not implementing* it. In fact `docs/design/248` §8 listed spatial as
in-scope, so the implementation slice built it, and `zoi ~ spatial(...)` became fittable with zero
recovery evidence while `drm_reject_phase1_terms` told users spatial was "Implemented" for the
atoms. The design document and the owner's decision had diverged, and the code followed the
document. Restored to a refusal; §8 now records the deferral as superseding its own earlier listing.
**Generalisable: a design doc can silently outrank a spoken decision when nobody reconciles them.**

**D4 · An unplanned repair round — ADAPTIVE.** The plan had S9 (panel) → S10 (promote). The panel
returned NOT-DONE from two of three reviewers, so a repair slice ran between them. Planned-for in
spirit (the panel exists to be able to block) but absent from the slice table.

## Evidence and verification

**D5 · S4.5 ran twice — ADAPTIVE.** Planned once, after the implementation slice. The F3
missing-response guard lives inside `drm_build_zero_one_beta_spec`, one of the spans hashed into the
pinned model-15 fingerprint, so the repair round invalidated the receipts a second time and the
compatibility campaign was re-run. Both times `mc-0568`/`mc-0569`/`mc-0576` passed 4/4.

**D6 · A third gate was added mid-flight — ADAPTIVE.** Rev 1 of the plan verified with
`capability_ledger.py --check` and `devtools::test`. Rose's plan review caught that CI also runs
`python3 -m unittest tools/tests/test_capability_ledger.py`, which the plan did not. It failed
exactly as predicted once the source files were edited. Without that review it would have failed in
CI, late.

**D7 · Conformance anchors drifted — recurrence, not new.** The full suite returned 43146/1; the one
failure was `reml_gate_sd_phylo_plus_sigma_phylo` citing `R/drmTMB.R:12989` after the line moved to
13166. This is the A1 lesson already in the do-not-repeat ledger. All 37 rows were audited, not just
the failing one, because the test enforces detail strings only on `expected == "error"` rows. Seven
enforced, one drifted. Final: 43147 / 0.

## Model routing

**D8 · S4.5 re-tiered Haiku → Sonnet — ADAPTIVE, recorded before dispatch.** The plan called it a
mechanical hash refresh. Reading `check_c17_c14_current_source_compatibility()` showed the bridge is
accepted only when the three promoted ordinary routes still pass, i.e. it runs a real campaign and
interprets its result.

**D9 · Ceiling budget honoured.** One Opus child across the whole lane (Rose, on the completion
panel), which is where the load-bearing verdict sat. Everything else Sonnet, with Haiku on the
mechanical sweeps and Fable on the symbolic derivation.

## Safety gates

No gate was skipped or weakened. The separation filter (Decision 4b) was added to the C16 bar and
did the decisive work: on the 28,800-fit campaign the C16 criteria alone passed 73/720 `coi` cells
while only 4/720 also had zero separated groups. `git add -A` was never used. No campaign ran on
GitHub Actions.

## Public claims

All seven promoted cells carry exact claim boundaries: point-fit recovery only, explicitly not
profile-, interval-, coverage- or inference-ready. Verified live that
`confint(method = "profile")` still errors. Lane B, missing-data, and mesh/SPDE were not touched.

## Orchestrator errors worth carrying forward — DRIFT, mine

These are recorded because each cost real time and each was caught by someone other than me.

1. **A correct derivation with hand-computed arithmetic is not a verified table.**
   `docs/design/248` §2.4's closed forms were right; four of five worked rows were wrong by up to two
   orders of magnitude, all optimistic, and a false design rule was drawn from them. Caught by
   recomputation before it reached the DGP.
2. **I briefed a reviewer to apply the full recovery gate to an IID carrier control**, which is
   legitimately narrower and matched the C16 precedent. That manufactured a false BLOCK against a
   correct script.
3. **I instructed the recovery scripts to prefer a precision `Q` over a covariance `K`** as a
   performance optimisation. The validator and the sigma precedent both take `K`, so all four relmat
   attempts were rejected until reverted.
4. **I attributed `mc-0615`'s collapse to finding F3**, which §2.1's exact block-diagonality proves
   cannot reach `log_sd_phylo` on `coi` — contradicting a result I had verified hours earlier — and
   claimed the failing seed had the most boundary observations when it was second (780/771/**817**/801).
   Caught by Fisher; both retractions are now in the ledger, not only in a commit message.

## Routed to Rose

- D3 (design-doc vs owner-decision divergence) — process fix: reconcile a design doc's scope section
  against owner decisions before an implementation slice consumes it.
- D7 — the anchor-drift recurrence; the existing ledger entry did not prevent it, only detect it.
- Items 1–4 above — candidate do-not-repeat entries; 1, 2 and 3 are already appended to
  `mission-control/live/status/drmTMB.json`.

## Carried over

`mc-0615`, `mc-0606`, `mc-0616` remain `not_implemented`. The two spatial cells resume when the
mesh/SPDE lane settles. `mc-0615` needs either a more informative DGP or an investigation of the
variance-component boundary behaviour — not a reseed.

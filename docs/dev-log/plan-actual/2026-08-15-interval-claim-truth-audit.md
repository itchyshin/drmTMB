# Plan vs actual — drmTMB interval-claim truth audit (Melissa)

**Lane:** `claude/lane-interval-truth-audit` · 2026-08-15 · **Plan:** the first plan in
`~/.claude/plans/transient-napping-hippo.md` (4 waves, T1–T10)

Material deviations only, along six axes. Cosmetic wording/order changes are not drift.

## Verdict

**The plan's Wave 1 ran as designed. Waves 2–4 did not run at all** — they were replaced by a
different route to the same goal, chosen by the owner at the checkpoint the plan itself mandated. Most
deviation is therefore **adaptive**, and one item is **drift**.

## Axis 1 — Scope

| Planned | Actual | Tag |
| --- | --- | --- |
| T1 gate extension points | Ran as planned (`tmb_engineer`, sonnet/high) | — |
| T2a–c classify 209 | Ran as planned (3× `Explore`, haiku/low) | — |
| T3 adjudicate | **Written by the conductor, not dispatched** | **adaptive** — the census T3 depended on had already been computed in-session; re-dispatching would have re-derived it. Recorded at the time. |
| **Wave 2** — extend the manifest via `emit-profile-truth-manifest.R` (T4a–c, T5) | **Not run.** Truth was instead recovered from 101 frozen campaign contracts across refs | **adaptive** — the plan assumed truth had to be *derived into the manifest*. The re-check needed truth, not manifest membership, and the contracts already carried a derived `true_parameter_scale`. Cheaper and it left the gate untouched. |
| **Wave 3** — T6a–d run the extended gate; T7 adjudicate | **Not run as specified.** The gate was never extended; its *rule* was applied directly to recovered truth | **adaptive** — same reason. The rule (`MISS_MAGNITUDE_TOL`, magnitude-only at 1 seed) was reused verbatim, which was the plan's binding constraint. |
| **Wave 4** — T8 mechanical verify, T9 adversarial (opus), T10 close | T9's function was served by a 3-lens adversarial workflow on the *spatial wording*, not on the coverage claim. T8/T10 folded into this close-out | **partial drift** — see Axis 2. |
| — | **Not planned:** narrow 28 spatial claims · demote 7 · fix 2 ladder inversions · recover 134 files · repair `mc-0285` | **adaptive** — each was owner-directed after a checkpoint finding. |

## Axis 2 — Evidence and verification

| Planned | Actual | Tag |
| --- | --- | --- |
| T9 adversarial verify — *"try to refute the coverage claim: is any 'covered' cell covered only nominally? is any truth hand-typed? does any verdict rest on a receipt without a numeric `true_value`?"* | **Not run against those questions.** A 3-lens adversarial pass ran, but against the *spatial conditioning wording and route assignments* | **DRIFT** — the plan's specific refutation targets were never put to an adversarial agent. The questions remain unasked, and two of them are live: the 78 passes rest on frozen contracts whose contract-matches-code was proven for the q4 cohort **only**, and 31 cells have no truth at all. Recorded in the after-task residuals, but that is disclosure, not verification. **Routed to: Rose (closeout/claims).** |
| T8 mechanical verify (haiku) | Done by the conductor inline — gates re-run after every step and post-rebase | **adaptive** — cheap and continuous rather than a single slice. |
| D-43 panel fires once at W4 | **Not fired.** No milestone completion claim was made — the arc closes with 121 of 233 cells still unchecked | **adaptive** — the panel gates a "done" claim; none is being made. |

## Axis 3 — Model routing

| Planned | Actual | Tag |
| --- | --- | --- |
| W1: 5 children, 0 opus | 4 children (T1 sonnet/high; T2a–c haiku/low). T3 conductor | **adaptive** |
| W4: 1 opus adversarial child | **0 opus children all lane.** The adversarial pass ran 3 sonnet/high lenses + 3 sonnet/high route agents in one workflow (7 agents) | **adaptive** — 3 independent lenses at high effort proved sufficient; all three returned `PROBLEMS_FOUND` and two findings changed the deliverable. Ceiling tier was not needed to get a refutation. |
| Fan-out budget ≤6 new children per wave | W1: 4. Spatial workflow: 7 in one batch | **adaptive** — the 7 ran as a single scripted workflow (3 route + 1 draft + 3 refute), which is one dispatch unit, not seven ad-hoc children. Flagged for the record. |

## Axis 4 — Safety gates

| Gate | Status |
| --- | --- |
| Phase 0.2 lane pre-flight | **Ran**, twice (lane start + close). Verdict both times: FOREIGN LANE ACTIVE (codex direct-to-main). Lane named, no foreign file touched. |
| D-139 estimate before compute | **Held.** The 73 were scoped and *not started*; compute estimate given (negligible) with the honest note that the real cost is design. The one measured run (7.5 s fit) and the ~20 min compile were both under the 30-min line. |
| D-50 no campaign on Actions | **Held** — no campaign ran anywhere. |
| D-87 / D-88 lane boundaries | **Held.** `mc-0596`'s cross-arc tension was surfaced, not resolved. 15 refs touching `test_capability_ledger.py` were checked before editing. |
| Push / merge gate | **Held.** Pushed only on explicit instruction ("push it"); **no PR opened without instruction**. |
| D-37 brain-write boundary | Lessons written to `LESSONS.md` on the explicit instruction *"remember lessions"*. |

## Axis 5 — Public claims

No public claim was made. Every ledger claim moved **downward or narrower**: 4 re-tiered off the
summit, 7 demoted, 28 narrowed. `supported` is now **0 cells**. The one wording rule — *"this claim is
not currently supported"*, never *"proven mislocated"* — was honoured in all 11 transition rows.

**One claim was published wrong and corrected the same day:** `mc-0248` reported as a 99% failure, then
found to be a join error. Corrected with a dated CORRECTION block in both affected documents rather
than a silent rewrite. **Adaptive** (self-caught, disclosed), not drift.

## Axis 6 — Handoff state

Branch pushed and rebased onto `origin/main` `9f1ea65ba`; 18 commits; gates green post-rebase.
`LOOP/checkpoint.md` current. **No `CARRIED-OVER` work is undeclared** — the 15 open issues are
enumerated in the after-task issue ledger.

## Drift summary

| Tag | Count | Items |
| --- | ---: | --- |
| adaptive | 9 | Wave 2/3 route change · T3 in-conductor · T8 inline · no D-43 panel · no opus child · workflow batch size · 5 unplanned owner-directed slices · mc-0248 correction |
| **drift** | **1** | **T9's specific refutation questions were never put to an adversarial agent** → Rose |
| unclear | 0 | — |

## Recommendation to Rose

The single drift item is worth one bounded follow-up before anyone treats the 78 passes as settled:
**put T9's original three questions to a fresh adversarial reviewer** — is any "covered" cell covered
only nominally, is any truth hand-typed rather than derived, does any verdict rest on a receipt without
a numeric `true_value`. The arc's own residuals already suspect the answer to at least one of them.

# Reconciliation — drmTMB true-parity checkpoint, Claude, 2026-09-02 (Melissa, Phase 4.5)

Read-only diff of planned vs actual. Cosmetic wording/ordering differences omitted.
Sources: `piped-dancing-floyd.md`; `.unlazy/true-parity/GATES.md` + `gates/leaf-s1..s5.md`;
`git log origin/main..<branch>` for the five branches named in the brief; `git ls-remote --heads
origin 'claude/rev-parity-*'`; `gh pr view 1114`; per-slice after-task/evidence notes on
`claude/rev-parity-integration-post1112`, `-c2-label-producer`, `-q4-se-receipt`,
`-drmjl-findings`, `-handover`; vault `DECISIONS.md` D-202/D-203, `TWIN-PARITY-SHARED-PAGE.md`,
`AGENT_LOG.md` 2026-09-02 entries; `git show 5b77eb691`; DRM.jl working-tree/HEAD check;
`gh issue list` for a reverse-gap issue.

## Slice disposition — S1–S9

| slice | plan said | actual | tag | note |
|---|---|---|---|---|
| S1 | this session pushes the 18 branches, records decisions, opens the draft PR | remote already had all 18 at local heads when checked (`leaf-s1.md` S1-G2 evidence: `local=21 remote=18 original=18 \| ALL_MATCH`) — another session had pushed them first; this lane verified rather than re-pushed, then pushed its own new children. PR #1114 opened from `integration-all`, `isDraft:true`, body contains "after #1112". D-202 recorded in vault + repo. | **adaptive** | Matches the plan's own instruction ("push only what the remote lacks, never force"); correctly detected via re-verification, not asserted. |
| S1-G2 oracle | — | first cut of the remote-match check needed a purpose-built script (`node .unlazy/true-parity/bin/remote-match.mjs`), not a one-liner, to compare 21 local heads against 18 remote refs without false-flagging the 3 new local branches. Built and recorded inline. | **adaptive** | Self-correction disclosed in the leaf, not silently patched. |
| S2 | Gauss/Sonnet medium: `integration-post1112` = merge(`integration-all`, `90f61f3da`) + `start`/`multi_start` guard under `engine="julia"`, RED test first | delivered as specified: merge clean (both parents ancestors), guard added to `drm_julia_translate_control()`, RED control run and restored byte-identically, filtered suite green. All 4 gates MET with real evidence (test counts, restored-diff confirmation). | **match** | No deviation. |
| S3 | Boole (design) → Gauss (build)/Sonnet high: producer contract (design 258 §7), payload sends base-R names, fail-closed abort, RED tests | delivered: `drm_julia_bridge_payload_coef_labels()`, fail-closed check in `new_drmTMB_julia()`, 17-test new file, design 258 §7 written. Sub-agent's own after-task (`2026-09-02-s3-label-producer.md`) explicitly and correctly declined to touch `drm_julia_predict_fixed_eta`'s pre-existing `gsub()` fallback ("outside this slice's touch scope... not something this slice touches or could have caused"), leaving gate S3-G4 UNMET and flagging it for the slice owner rather than self-expanding scope. | **match (sub-agent conduct)**, see D1 below for what happened next | The sub-agent's discipline here was correct; the deviation is what the coordinator did afterward. |
| S3-G4/G6 oracle | — | S3-G6's CHECK called `drmTMB(y ~ ..., data = d)` with a bare formula; `drmTMB()` requires `bf()`/`drm_formula()` and aborted before testing labels — a pre-existing API requirement unrelated to this slice. Sub-agent verified the same assertions by hand with `bf(...)` and recorded the exact label vector; flagged as a gate-authoring defect, not a code regression. | **adaptive** | Correctly diagnosed as an oracle defect and evidenced by hand rather than the gate being silently marked MET. |
| S4 | Curie/Sonnet medium: extend the q4 fixture to compare `vcov()`/SEs same-draw, write the receipt | delivered a same-draw comparison against DRM.jl `cda42b8c` (pinned, #579 head): coefficients and logLik agree (\|Δ logLik\| 1.9e-05); **Julia's `vcov()` for this route is all-NaN** (self-reported `uncertainty$status="unavailable"`), so `se_abs_delta`/`se_rel_delta` are undefined for all 7 coefficients, not small. Receipt states plainly what it does and does not claim; no promotion edit. | **adaptive**, with a caveat | The plan asked for a *comparable SE axis*; what was delivered is a *documented reason the SE axis is not yet comparable* — the right outcome given what DRM.jl actually returns, and stated honestly rather than papered over. See "gates marked met without evidence" below for the caveat on how leaf-s4's own gate is worded. |
| S5 | Ada/Fable: findings memo to the DRM.jl lane | delivered: `2026-09-02-drmjl-lane-handoff.md` on `claude/rev-parity-drmjl-findings`, four items named (label-map echo spec, fixture re-key, stale `capabilities.md`, fate of `feat/575-objective-at`) plus the q4 SE-receipt pointer; DRM.jl working tree untouched. | **match** | No deviation. |
| S9 | Rose/Opus, single ceiling child: adversarial attack on ≥1 passing gate, recorded in the ledger | `GATES.md` N2 ("Rose attacked at least one PASSING gate") is still `EVIDENCE: pending` and unchecked at the time this reconcile was written; no refutation record found anywhere under `.unlazy/true-parity/` or `docs/dev-log/` newer than the leaf files. | **unclear** | Cannot tell from the read-only record whether S9 has not yet finished or finished without writing back to `GATES.md`. Route: **Ada** — confirm `rose-s9`'s status before N1/N4/N5 are treated as closeable; do not let this reconcile (S10) stand in for N2's own evidence. |
| S6, S7 | held until #1112 merges | correctly not fired: no `leaf-s6.md`/`leaf-s7.md`, no `r_bridge_status`/`julia-capabilities.tsv` edit from any of today's five branches, no promotion branch. | **match** | No deviation. |

## D1 — a MUST-STOP fence was crossed: coordinator edit outside the payload/translate_control hunks

The pre-authorisation envelope's own text: *"MUST STOP: ... any change to `R/julia-bridge.R`
outside the payload/translate_control hunks."* `leaf-s3.md`'s OWNS line scopes
`R/julia-bridge.R` to *"`drm_julia_bridge_payload` and the post-call label step only."*

Commit `5b77eb691` (`fix(julia-bridge): drop the predict-time punctuation rewrite of engine
coefficient names`, on `claude/rev-parity-c2-label-producer`, immediately after the S3 feature
commit `029beaf5e`, authored by Shinichi / co-authored Claude — i.e. landed by the coordinator,
not the S3 sub-agent) edits `drm_julia_predict_fixed_eta()`, a **third function**, neither the
payload builder nor the post-call label step nor `translate_control`. This is exactly the
function the S3 sub-agent's own after-task report (`docs/dev-log/after-task/2026-09-02-s3-label-
producer.md`, §10) explained it had deliberately **not** touched, on the grounds that it sat
"in a part of `R/julia-bridge.R` explicitly outside this slice's touch scope" and was a
predict-time fallback, not the fit-time step the slice brief named — flagging gate S3-G4 as
UNMET rather than silently expanding scope to close it. The coordinator's follow-up commit then
made that same edit anyway, closing S3-G4 (`NO_GUESSING_OK`) from outside the leaf's declared
OWNS and inside a fenced MUST-STOP zone.

The edit is well-reasoned on the merits (design 258 §3 already forbids exactly this kind of
punctuation guessing, and the removed code was dead under the new fail-closed contract), and it
is transparently recorded in `leaf-s3.md`'s own NOTE with a RED-CONTROL re-run
(`throwaway gsub` added, gate fails, removed) — this is not a concealed change. But it is a scope
expansion made unilaterally by the session itself, not by a recorded owner or Ada scope decision,
and it crosses a fence the plan wrote in its own MUST-STOP list. No full-suite or predict-path-
specific regression re-run is evidenced after this specific edit (the filtered suites the S3
after-task cites were run against the feature commit; no separate re-run against `5b77eb691` for
`predict()`-path tests is shown in the ledger).

**Tag: drift. Route: Ada** (scope) — was this edit intended to be pre-authorised by design 258 §3
plus D-202's naming-authority decision (in which case the envelope's OWNS/MUST-STOP wording
should be corrected to say so), or was it an overreach that should have gone back to the S3
sub-agent or been recorded as its own scope decision first? Either answer is fine; the gap is
that no such decision is recorded anywhere except the commit message itself.

## D2 — two child branches pushed beyond the named pre-authorisation envelope

The envelope's OPTIONAL REMOTE AUTHORITY line: *"push the 18 existing `claude/rev-parity-*`
branches + the new `integration-post1112` and `drmjl-findings` updates ... create ONE draft PR
... never merge."* Three **new** child branches were created and pushed this session:
`claude/rev-parity-integration-post1112` (S2, named), `claude/rev-parity-c2-label-producer` (S3,
**not named**), `claude/rev-parity-q4-se-receipt` (S4, **not named**).
`git ls-remote --heads origin 'claude/rev-parity-*'` confirms all three are on origin, and PR
#1114's body cites all three as "Child branches landed the same day." No force-push is evident
(`git log -g` on `c2-label-producer` is a clean linear history; the remote-match script reports
`ALL_MATCH`), so the binding "never force" rule held, but the push itself for two of the three
branches falls outside what the envelope explicitly named.

**Tag: drift. Route: Ada** (scope/routing) — a push is not merge-irreversible, and the branches'
existence is disclosed in PR #1114's own body rather than hidden, but the envelope names specific
branches for a reason (S6/S7 stay HELD, and public branch pushes are the one "OPTIONAL REMOTE
AUTHORITY" carve-out from an otherwise local-commits-only session). Two branches went out under
an authorisation that did not name them.

## Fan-out budget

Plan ceiling: `checkpoint=true-parity-1 · new children ≤5/6 · ceiling=1`. Actual dispatches
reconstructable from the ledger and branches: S2 (Gauss/Sonnet, build), S3 (Boole→Gauss/Sonnet,
build), S4 (Curie/Sonnet, build), S9 (Rose/Opus, ceiling), S10 (this reconcile, Sonnet) = **5
children, 1 ceiling** — inside budget, matching the plan's own row-by-row model assignment
exactly (S2/S3/S4 Sonnet; S9 the single Opus child; S10 Sonnet). S6/S7 correctly did not fire, so
they do not count against the budget. **No fan-out deviation.**

## Gates marked met without evidence

Grepped every leaf (`leaf-s1.md` … `leaf-s5.md`) for a `- [x]` line followed by
`EVIDENCE: pending`. **None found** — every checked gate across all five leaves carries a
substantive EVIDENCE line (exit codes, measured output strings, commit SHAs, or an explicit
hand-verification with the reason a literal CHECK oracle was defective). `GATES.md`'s own node
gates N1–N5 are honestly `[ ]` unchecked with `EVIDENCE: pending` — no false claim of checkpoint
closure.

**Caveat, not a false-MET finding:** leaf-s4's G1 CHECK only greps the receipt for the *presence*
of the strings `se_abs_delta` and `se_rel_delta`; it does not require they be finite. The receipt
prints `SE_RECEIPT_OK` and is genuinely MET by that literal wording, but the gate's design does
not distinguish "SE parity measured" from "SE axis undefined and honestly reported as such." The
document itself carries the honesty (a "Central finding" and "What this receipt does NOT claim"
section spelling out the NaNs); the gate wording does not. **Route: domain reviewer (Fisher)** —
tighten the G1 CHECK for any future reuse of this receipt pattern so a NaN-SE draw cannot read as
"OK" without a human reading the prose; not blocking this checkpoint's close.

## Public claims

Searched the plan, `GATES.md`, all five leaf files, PR #1114's body, the decision map, and the
DRM.jl handoff memo for `r_bridge_status`/`julia-capabilities.tsv` promotion language, coverage
claims, or release/registration claims. Every hit is a fence statement ("promotes nothing," "D-164
continues to hold the RELEASE," "not interval coverage," "not a promotion") or a verified-absence
check (`leaf-s4.md` G3, `git diff --quiet` on the two capability TSVs, MET). `integration-post1112`
(the whole accumulated lane, not today's new work) does carry a large pre-existing diff against
`origin/main` in `docs/dev-log/dashboard/julia-capabilities.tsv` — inspected and confirmed to be
inherited history from the 2026-08-25/27 promotion wave already reconciled in the 2026-09-01
Melissa report, not new work from S2–S4 today. **No breach found.**

## Safety gates

- DRM.jl fence: `git status --short` in `/Users/z3437171/Dropbox/Github Local/DRM.jl` shows only
  the one pre-existing untracked `shannon-coordinator.toml`; `HEAD` is unchanged at `f4778964`
  (merge #562). `DRMJL_FENCE_HELD` — confirmed, matches the FACTS claim.
- No merge: PR #1114 is `isDraft: true`; no branch here is merged to `main`.
- No release/CRAN: D-164 cited as the holding decision throughout; no version bump or tag found.
- No `--force` push: remote-match reports `ALL_MATCH`; reflog on the newly pushed branches shows
  linear history.
- Full-suite / `--as-cran` not re-run today: confirmed absent from the ledger and after-task notes
  for S2/S3/S4; consistent with `GATES.md`'s own standing fence (full suite passed 2026-09-01 on
  the integration tree, not required again unless code outside the guard/payload hunks changes).
  This line is now in tension with **D1** above: `5b77eb691` *did* change code outside the
  declared payload/translate_control hunks, and no evidence shows the full suite (or even a
  predict-path-focused filtered run) was re-run against that specific commit. Folded into D1's
  routing rather than counted twice.
- Reverse-gap issue list: confirmed **not filed** (`gh issue list --search` for the named
  DRM.jl-only accessors returns nothing; the two most recent issues, #1113/#1108, are unrelated).
  This matches the FACTS statement, and it is **not a deviation** — the decision map itself lists
  filing the issue list as a "task," explicitly gated on Shinichi seeing the draft first
  ("filed only after Shinichi sees it in this repo's session"), and the "Tension to settle"
  section names one open sentence still needed from him. Correctly held open, not silently
  dropped.
- Relayed decisions (D-203): the decision map and the DRM.jl handoff both label these findings
  "Relayed 2026-09-02 (Shinichi via session DRM.jl3, recorded there as vault D-203...)" rather than
  presenting them as this session's own decisions — correct provenance discipline, no breach.

## Summary

Seven items tagged above: **adaptive** — S1 push found pre-empted (verified, not duplicated);
S1-G2 oracle self-correction (remote-match script); S3-G6 oracle self-correction (bf() wrap,
hand-verified); S4's SE-axis finding (documented incomparability, no promotion, gate-wording
caveat routed to Fisher, not blocking). **Drift** — D1 (coordinator edit to
`drm_julia_predict_fixed_eta` crossed the envelope's own MUST-STOP fence, closing S3-G4 from
outside the leaf's OWNS and outside the sub-agent's own recorded scope decision; routed to Ada);
D2 (two of three new child branches pushed without being named in the pre-authorisation
envelope; routed to Ada). **Unclear** — S9/N2 (Rose's adversarial attack not yet reflected in
`GATES.md`; routed to Ada to confirm status before N1/N4/N5 close).

**Deviations found: 7 — adaptive: 4, drift: 2, unclear: 1.**

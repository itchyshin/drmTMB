# Plan vs actual — drmTMB 0.7.0 release slice, 2026-08-09

Reconciler: Melissa (S12). Plan: `/Users/z3437171/.claude/plans/hidden-twirling-curry.md`.
Actual: worktree `/private/tmp/drmTMB-07-release`, branch `claude/07-release-slice`.
Scope of "actual" = commits `eda38306b..HEAD` (the handover point through the branch tip
observed at reconciliation time), i.e. `7a71d28e4 .. cc4f5baee` (9 commits).

**Headline finding, ahead of the table:** at the moment this reconciliation ran, branch HEAD is
`cc4f5baee` — two commits *past* the after-task report (`ec3c67fb7`) the reconciliation brief
pointed at. That last commit (`cc4f5baee`, 2026-08-09 14:21:38 -0600, 2m17s after the after-task
report) states in its own message that it **"DELIBERATELY INVALIDATES candidate d04d0e88 under
D-49"** — the same fate as the two predecessor candidates the plan's Context section names
(`d35c0b9e`, `da9b2d76`). Neither `FREEZE-NOTES-0.7.0.md`, the ledger JSON, `check-log.md`, nor
the after-task report have been updated to say so: all four, as they read right now, still
present `d04d0e88` as `tarball-clean`/"READY FOR CLAIMED RUNG". This is a live claims/evidence gap
at reconciliation time, not a hypothetical one — see axis 5.

## Reconciliation table

| Axis | Planned | Actual | Tag |
| --- | --- | --- | --- |
| 1. Scope | S1 merge PR #961; S2 Haiku size table; S3 Pat/Sonnet closes D-117 surface 3; S4 Gauss/Opus re-runs C17 script; G1 owner checkpoint; S5 Ada applies trim; S6 rebuild; S7 `--as-cran`; S8 dispatch platform matrix; S9 re-freeze; S10 Haiku mechanical verify; S11 Rose/Opus adversarial verify; S12 Melissa reconcile; S13 decision packet | S1 done (`7a71d28e4`, PR #961 merged into the slice, not `main`). S2 done (Haiku size table, after-task §"what did not go smoothly"). S3's edit landed but bundled inside the S5 commit (`6d1fb0562`), not as a separately attributable Sonnet/Pat slice — see axis 3. S4 was **judged unnecessary and not run as scripted**: the guard confirmed the C17 fingerprint (`R/drmTMB.R`, `src/drmTMB.cpp`) was untouched, only `R/profile.R`/`R/check.R` changed (FREEZE-NOTES:153-156). G1 fired (after-task §3a: "Owner decision after being shown the measured table"). S5 grew into vignette move + `_pkgdown.yml` fix + 3 guard repairs (`6d1fb0562`,`9fc92e9f7`,`e6f9d1782`) — disclosed extensively (after-task §2-4,8-9). S6 ran once, not re-run after later `.Rbuildignore`'d-only changes — disclosed and justified (after-task §3a "Rejected rebuilding"). S7-S9 ran (`4c3e17202`). S10 ran (freeze notes "Independent verification", 20/20). **S11 has no corresponding artifact** (see axis 2/3). S13 not yet run (correctly — depends on this document). **One unplanned action**: `cc4f5baee` (NEWS.md gap + a moved-PNG link fix, "adversarial audit findings 2 and 10") is not on the S1-S13 table at all. | **adaptive** for S4/S5/S6 growth (recorded, reasoned); **drift** for S3's routing and for the undocumented/uncounted `cc4f5baee` action (see axes 3 and 5) |
| 2. Evidence / verification | Layered verification, "no layer certifies itself": (1) targeted tests, (2) claim-bearing `--as-cran` run, (3) `cran_release_gate.py --selftest`, (4) S10 mechanical re-verify, (5) **S11 adversarial verify with a fresh context instructed to refute**, (6) S12 reconcile. | (1)-(4) and (6, this document) all have artifacts: targeted 45/45, `--as-cran` 1 NOTE/0 err/0 warn, selftest 14/14, mechanical re-verify 20/20 (FREEZE-NOTES:211-213). **(5) is missing.** No file, section, or check-log entry anywhere in `eda38306b..cc4f5baee` names an adversarial reviewer, states a refutation attempt, or reports its verdict. The only trace of anything adversarial is `cc4f5baee`'s commit message referencing "Adversarial audit findings 2 and 10" — an audit whose findings 1, 3-9 are not recorded anywhere in the repo, and whose own two named findings (NEWS.md silence on the vignette move; a stale PNG link) are fixed but not written up as a reviewed verdict on the rung claim itself. | **drift** — a plan-mandated, explicitly-budgeted (Opus, high effort, "instructed to refute") verification layer has no recorded output, and the freeze packet (FREEZE-NOTES, ledger) was not revised in light of whatever "adversarial audit" produced `cc4f5baee` |
| 3. Model routing | FAN-OUT BUDGET: new children ≤6, ceiling(Opus) ≤1, Haiku for S2/S10, Sonnet for S3/S12 | Only one sub-agent dispatch is explicitly named in any artifact: the S2 Haiku size-inventory (after-task §9, "The Haiku size-inventory returned two identical trim options..."). S10's "fresh context" mechanical re-verify (FREEZE-NOTES:211) is not attributed to a model tier in any artifact. S3's conf.status edit is folded into the same commit (`6d1fb0562`) as S5 (Ada/Opus), with no separate Sonnet/Pat commit, PR, or report section — inconsistent with the plan's explicit per-slice model assignment. S11 (the one Opus-ceiling slot) has no recorded output at all (axis 2). Net: the budgeted 5 agent dispatches (S2, S3, S10, S11, S12) cannot be confirmed at more than 2 (S2 confirmed Haiku; S12 = this task, confirmed Sonnet per its own dispatch). | **unclear** for S10 (no tier stated); **drift** for S3 (planned as a distinct Sonnet dispatch, executed as an unattributed edit inside an Opus commit) and for S11 (budgeted Opus slot, no dispatch evidence) |
| 4. Safety gates | Hard stops: D-43 panel, `platform-clean` rung write, final `cran-comments.md`, tag, GitHub release, CRAN upload, merging PR #959 | None crossed. Ledger `panel` = `{"grace":"NOT_RUN","rose":"NOT_RUN","pat":"NOT_RUN"}` (ledger JSON `panel` block). Ledger `status_claim` = `"tarball-clean"`, not `platform-clean`. `git tag -l "v0.7*"` → empty. `cran-comments.md` untouched (`git log eda38306b..HEAD -- cran-comments.md` → empty). No new GitHub release (`gh release list` tops out at `v0.5.0`). PR #959 confirmed **OPEN**, `mergedAt: null` (`gh pr view 959`). PR #961 (a *different* PR, merged into the slice branch, not `main`) is correctly outside this hard-stop list. | **adaptive/clean** — no gate crossed; the session correctly re-invalidated its own candidate (`cc4f5baee`) rather than pushing through a known defect, which is the same discipline the plan's Context section credits for the two earlier invalidations |
| 5. Public claims | The plan itself flags "no reader loses access" as a claim to watch, and requires the packet to name only proven rungs. | The overstated form "no reader loses access" was self-caught and corrected to "no reader loses access *on the website*" with the offline/cross-link cost stated in the same breath, in **both** FREEZE-NOTES:79 and the ledger `note` field — confirmed present in the corrected form as of `HEAD`. Separately and more materially: **FREEZE-NOTES-0.7.0.md and the ledger JSON currently claim `d04d0e88` is `tarball-clean`/READY, but `cc4f5baee` (already committed, on this branch) states that same candidate is now deliberately invalidated under D-49.** A reader of the freeze packet as it stands would be told a rung the branch tip itself has withdrawn. | "no reader loses access" wording: **adaptive** (caught and fixed by the session itself, cost disclosed). The stale rung claim for `d04d0e88`: **drift** — the packet was not updated in the same breath as the invalidating commit |
| 6. Handoff state | — (S12 is mid-flight, not itself a handoff point, but the brief asks whether everything is committed/pushed) | Working tree is clean (`git status --short` → no untracked/modified files). But `git status --short --branch` reports `## claude/07-release-slice...origin/claude/07-release-slice [ahead 2]`: `ec3c67fb7` (after-task report) and `cc4f5baee` (D-49 invalidation fix) are both **local-only, not pushed**. No branch note or check-log entry marks the branch as "mid-flight, do not read HEAD as final." | **drift** — two commits, including the one that invalidates the just-frozen candidate, are unpushed and undeclared; a reader fetching `origin/claude/07-release-slice` right now would see the *stale, since-invalidated* freeze packet with no signal that it is stale |

## Material deviations, explained

### D1 — S11 (adversarial verify) has no artifact (drift, axis 2 & 3)
The plan budgets exactly one Opus-ceiling, high-effort dispatch for S11, instructed to *refute*
the rung claim, gated before S12. No file in `eda38306b..cc4f5baee` — not the after-task report,
not FREEZE-NOTES, not check-log — names an adversarial reviewer, a refutation attempt, or its
verdict. The only circumstantial evidence that *some* adversarial pass happened is `cc4f5baee`'s
commit message ("Adversarial audit findings 2 and 10"), which names two findings out of an implied
larger numbered list that is not recorded anywhere retrievable (`grep -rl "adversarial audit"` over
the tree found nothing from this session). Whether this was S11 run informally and under-documented,
or a different, unplanned review pass, cannot be determined from the artifacts.

### D2 — Freeze packet is stale relative to branch HEAD (drift, axis 5 & 6)
`cc4f5baee` explicitly invalidates `d04d0e88` under D-49 (same policy as the two prior
invalidations the plan's Context section documents). `FREEZE-NOTES-0.7.0.md`, the ledger JSON, and
`check-log.md` were not touched by that commit and still assert `d04d0e88` is `tarball-clean`/READY.
This mirrors exactly the failure mode the plan's HEADLINE was written to avoid ("the first one that
does not get deliberately invalidated") — on the evidence in the branch right now, it has not
avoided it a third time; the packet simply has not caught up yet.

### D3 — S3 executed without a distinguishable Sonnet/Pat dispatch (drift, axis 3)
The plan assigns S3 (closing D-117's third documentation surface) to Pat at Sonnet tier, running
in parallel with S4. The actual `conf.status` edit lands inside `6d1fb0562`, the same commit as S5
(Ada, Opus, vignette move), with a single "Also closes the third documentation surface" mention in
the commit body and no separate commit, PR, or report section. This may be an efficient merge of
two small edits, but it means the plan's per-slice model-tier assignment cannot be confirmed from
the record, and the Sonnet dispatch this budget-line reserved cannot be shown to have happened as
specified.

### D4 — Two commits unpushed, one of them the invalidation (drift, axis 6)
`ec3c67fb7` and `cc4f5baee` are ahead of `origin/claude/07-release-slice`. This is ordinary
mid-session state, but combined with D2 it means the *pushed* branch (what any other agent or the
owner would see by fetching) is even further behind reality than the local worktree: it still
carries the fully-affirmative freeze packet with no trace of the invalidation at all.

## Non-deviations (plan followed)

- S1, S2, S6-S10 ran as scripted, with matching evidence.
- S4's non-execution is a disclosed, reasoned scope narrowing (the fingerprint is file-scoped, not
  directory-scoped) — **adaptive**, not drift, consistent with the reconciliation brief's own framing.
- S5's growth (vignette move, `_pkgdown.yml` fix, 3 guard repairs) is extensively disclosed in the
  after-task report and FREEZE-NOTES, including the process lapse ("guard run before the move, not
  after") — **adaptive**.
- No hard stop was crossed: D-43 panel `NOT_RUN` for all three panelists, `status_claim` =
  `tarball-clean` (not `platform-clean`), no `v0.7*` tag, `cran-comments.md` untouched, no new
  GitHub release, PR #959 confirmed OPEN/unmerged via `gh pr view 959`.
- PRs #957, #958, #960 confirmed untouched/OPEN via `gh pr view`.
- The "no reader loses access" overstatement was self-caught and corrected with its cost stated,
  in both places it appeared — **adaptive**.

## Routing

- **D1 (missing S11 artifact) → Ada.** Decide whether to dispatch a genuine fresh-context
  adversarial pass before S13, or to accept `cc4f5baee`'s two named findings as sufficient and
  say so explicitly in the decision packet.
- **D2 (stale freeze packet) → Rose.** The closeout/claims discipline this maps to is exactly
  Rose's lane: before any decision packet (S13) is written, FREEZE-NOTES, the ledger JSON, and
  check-log need a fourth entry recording the `d04d0e88` invalidation, or an explicit statement of
  why it is being left stale.
- **D3 (S3 routing) → Ada.** Routing/fan-out accounting question, not a correctness question.
- **D4 (unpushed commits) → Ada.** Push, or explicitly declare the branch mid-flight, before
  handing off.
- No item routes to a domain reviewer (Fisher/Noether/Boole) — this reconciliation found no
  likelihood, math, or formula-grammar claim in scope.

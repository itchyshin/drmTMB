# Plan vs actual — Arc 8: land the truth gate, and correct the record it exposed

Reconciler: Melissa · Sonnet 5 · 2026-08-03T21:43Z

**Plan:** `~/.claude/plans/crispy-scribbling-ripple.md`. This file was **overwritten mid-session**: it
now holds only the Arc 8 plan text quoted below. The earlier Arc 7b plan this arc's own commits were
originally created under is not recoverable from it. Reconciliation below is Arc 8's plan against Arc
8's actual execution only; the overwrite itself is recorded here as an observation, not as an axis
finding, because there is no surviving planned text to compare the earlier work against.

**Actual:** branch `claude/arc7b-truth-gate`, worktree `/private/tmp/drmtmb-arc7b`. Baseline
`origin/main@95b8ea34e`. Four commits ahead: `e5413c98f` (rebased) · `ecdd5b1f1` (rebased) ·
`100daa061` (S4) · `3e9122037` (S5). PR
[itchyshin/drmTMB#912](https://github.com/itchyshin/drmTMB/pull/912), **state OPEN, `mergedAt: null`**
as of query time 2026-08-03T21:43:35Z.

Material deviations only, per axis. Cosmetic wording/order differences are not recorded.

## Reconciliation table

| Axis | Planned | Actual | Tag | Owner |
| --- | --- | --- | --- | --- |
| Scope — S1 rebase | Ada/Fable, resolve 4 conflicts (`R-CMD-check.yaml`, `capability_ledger.py`, `test_capability_ledger.py`, `check-log.md`) onto `origin/main@95b8ea34e` | Done. Reflog shows `rebase (start)` → `rebase (continue)` → `rebase (finish)`; `bf57e2b4d`→`e5413c98f`, `2612ba646`→`ecdd5b1f1` (new SHAs confirm a real replay, not a fast-forward); `merge-base(HEAD, origin/main) = 95b8ea34e` = origin/main tip exactly. All 4 files resolved additively — see Evidence item 6 below | MATCH | — |
| Scope — S2 mechanical-verify | Curie/Haiku, dispatched Agent, read-only Bash | Verification work appears to have run (see Evidence items 1–7), but per the launching agent's note it ran **inline**, not as a dispatched sub-agent. Discussed fully under Model routing | see routing row | Ada |
| Scope — S3 push/PR/merge | Ada/Fable, push branch, open PR, merge | Push + PR-open done: PR #912 opened `2026-08-03T21:11:08Z`. **Merge not done**: `state=OPEN`, `mergedAt=null`, `mergeStateStatus=UNSTABLE`, primary check `ubuntu-latest (release)` still `IN_PROGRESS` at query time (started `21:21:13Z`, unresolved 22+ min later) | **DRIFT** | Ada |
| Scope — S4 triage-note correction | Fisher (reuse), correct candidate 1 from "untested hypothesis" to "known, measured, fix-out-of-reach", cite `dr20` and the 2026-07-06 measured result | Done, commit `100daa061`. Text matches the plan's description closely; cites `R/drmTMB.R:2276-2291` for the scale-side REML provider claim — independently re-read, matches exactly (spatial/animal/relmat admitted, 400/400 debiasing, coverage ≥0.926 vs 0.91 floor) | MATCH | — |
| Scope — S5 Prong B refresh | Rose, correct 3 stale premises + record Decision 2 | Done, commit `3e9122037`. All 3 premises corrected (Task 1 DONE; 184/58→182/60 ceiling recomputed; structured-sigma caveat added to 2 of 4 Tier-1 groups); Decision 2 text is close to verbatim from the plan's "Decisions locked" §2. Commit body notes 2 *other* premises deliberately left untouched because the text was absent — not invented | MATCH | — |
| Scope — S6 reconcile | Melissa, depends on S3–S5 all complete | Running now, but S3's merge component is not complete (see S3 row) — this reconcile is dispatched before its own stated dependency is satisfied | **DRIFT** | Ada |
| Scope — anything outside the plan? | Deferred/fenced: `R/profile.R`, the 5 `coi` cells, the 4 STOPs, q12, the 89 parked rationales, any coverage/calibration/inference-ready/CRAN claim | None of these touched. `git diff origin/main...HEAD --stat -- R/profile.R` empty; no `R/*.R` source file touched at all (only 3 `tests/testthat/` fixtures); full 30-file diff list maps cleanly onto S1/S4/S5 with no unexplained files | MATCH | — |
| Evidence — item 1: `capability_ledger.py --check` → OK (30 outputs) | Run on rebased tree | Documented pre-rebase in the after-task report; independently re-run by me just now on current HEAD: `capability-ledger: OK (30 generated outputs)` | MATCH | — |
| Evidence — item 2: wired unittest files "now 5+ of 8" | — | Actual, post-rebase: **"6 of 9"** (`R-CMD-check.yaml:72`, corrected from "5 of 7"). Satisfies "5+" but total denominator the plan predicted (8) undercounts the actual total (9), because main's PR #910 added `test_b4_ci_guard.py` | ADAPTIVE (plan's own rebase notes already anticipated a comment-count correction) | — |
| Evidence — item 3: `emit-profile-truth-manifest.R --check` → OK (30 rows) | Run on rebased tree | Documented only in the pre-rebase after-task report (part of commit `e5413c98f`, authored 13:59, before the 15:07 rebase). No artifact found confirming a re-run specifically after S1/S4/S5 | **UNCLEAR** — not reconfirmed on the rebased tree in available artifacts | Fisher (method evidence) |
| Evidence — item 4: tier census `interval_feasible = 182` on rebased tree | Run on rebased tree | **Confirmed directly**: the current, committed `docs/dev-log/dashboard/capability-surface.md:14` reads "182 interval-feasible" — this is generated output, part of HEAD, `git status` clean | MATCH | — |
| Evidence — item 5: adversarial flip-one-frozen-cell, must fail, revert | Run on rebased tree | Documented pre-rebase only (the `mc-0422` promotion test in the after-task report, same commit as item 3). No artifact found confirming a re-run after S1/S4/S5 | **UNCLEAR** — not reconfirmed on the rebased tree in available artifacts | Fisher (method evidence) |
| Evidence — item 6: `git diff origin/main --stat` read end to end, confirm nothing from #910/#911 reverted | — | Outcome independently verified by me: `capability_ledger.py`'s `promotion_claim` regex (from #911) intact at lines 2163–2164; `test_capability_ledger.py`'s point_fit_recovery literal correctly moved 58→60 consistent with the frozen constant 58→59; `tools/b4_ci_guard.py` and its test (from #910) show zero diff. No artifact confirms the *session itself* performed this specific read-through, but the outcome holds | MATCH (outcome) | — |
| Evidence — item 7: CI block still names both Arc 7b lines | — | **Confirmed**: `R-CMD-check.yaml:107` (`test_profile_truth_gate.py`) and `:108` (`emit-profile-truth-manifest.R --check`) both present | MATCH | — |
| Evidence — DISCIPLINE clause: full CI sequence passes ON THE REBASED TREE | Required before "the rebase is... done" | GitHub Actions run 1 (head `ecdd5b1f1914e30cba24c827423bc78920828e40`) is `completed`/`cancelled` (superseded by the S4/S5 push); run 2 (head `3e91220378d3a630a80c9f054bc583fa1a399e7f`, current PR head) is `in_progress` — one sub-job (`os-matrix`) `SUCCESS`, the primary `ubuntu-latest (release)` job unresolved as of query time | folded into the S3/S6 **DRIFT** above | Ada |
| Model routing — S1 | Ada/Fable/high, inline | Consistent with observed rebase-conflict judgment work (semantic re-confirmation of #911's `promotion_claim` regex, corrected guard-count comment). Model tier itself not independently verifiable from git artifacts | MATCH (no contrary evidence) | — |
| Model routing — S2 | Curie/**Haiku**/low, dispatched Agent, read-only Bash | Per the launching agent, ran **inline** by the orchestrator instead. No separate agent-output artifact found (e.g. no "MECHANICAL-VERIFY" report); circumstantial support only: `docs/dev-log/dashboard/capability-ledger/cells.tsv` mtime `21:20:38Z`, 14s after the S5 commit and 14s before the second CI trigger — consistent with *a* verify/regenerate pass running just before the final push, but does not establish who ran it. No recorded justification found anywhere (check-log, after-task report, commit bodies) for skipping the planned Haiku dispatch | **DRIFT** | Ada |
| Model routing — S3 | Ada/Fable/med, inline | Push + PR-open consistent with inline execution by "this session" per the plan's own header | MATCH | — |
| Model routing — S4 | Fisher/Sonnet, **reuse** existing agent | Confirmed: commit `100daa061` body references "Fisher verified..." in the third person, exactly the reuse pattern the plan specifies | MATCH | — |
| Model routing — S5 | Rose/Sonnet | Confirmed: commit `3e9122037` body opens "Rose reports two premises deliberately NOT edited..." | MATCH | — |
| Model routing — S6 | Melissa/Sonnet | This report; running as Sonnet 5 | MATCH | — |
| Model routing — FAN-OUT BUDGET | "3/6 new children (Curie, Rose, Melissa)" | If S2 truly ran inline, only 2 of the 3 named new children were actually created (Rose, Curie is absent); Fisher reuse (1) held | folded into the S2 **DRIFT** above | Ada |
| Safety gates — Phase 0.25 prior-work sweep receipt | 5-row table, each row "Evidence run" + "Finding" + "Call" | Present (plan lines 54–62), non-vacuous: every row cites a concrete command/query (`git fetch`/`merge-base`/`comm -12`; brain `search_notes`/`grep`; `git merge-base --is-ancestor b9446fd7 origin/main`; `drm_validate_reml_spec` source read) and a specific finding. No bare "none found" row. Independently spot-checked 2 of 4 factual claims: `git merge-base --is-ancestor b9446fd7 origin/main` → **true**; `R/drmTMB.R:2221` gate (`if (!spec$model_type %in% c("gaussian", "binomial"))`) → **matches exactly**. Also independently confirmed the plan's headline baseline claim: pre-Arc-8 `origin/main` did read 184 interval-feasible with both `mc-0424` and `mc-0260m` as `interval_feasible` (`git show origin/main:...capability-surface.md` / `cells.tsv`) | MATCH, well-grounded | — |
| Public claims | Only target-specific interval-existence; coverage/calibration/inference-ready/CRAN claims are fenced | None found. Explicit disclaimers present in the after-task report ("Nothing here licenses a coverage, calibration, inference-ready, or CRAN statement"), the PR body ("Flagged, not established" re: the p=0.0625 low-bias figure), and the S5 commit (re-states `interval_feasible` = existence/bracketing only, bias is a separate disclosed fact) | MATCH | — |
| Handoff — `tools/profile-truth-manifest.tsv.bak` | Untracked, needs a human `rm`, harness blocks it | Confirmed present, untracked (`git status --short` shows only this file) | MATCH | — |
| Handoff — `mc-0282` / `mc-0423` provenance | Both reported, neither fixed, both need an owner call | Both declared as open gaps in the after-task report ("Known gaps, reported not fixed" / "Known Limitations") and in the PR body. Not silently resolved | MATCH | — |
| Handoff — Arc 2 reconciler `source_sha` issue | Pre-existing, not this arc's to fix | Declared in the after-task report's "An Adjacent Defect Found While Verifying (not introduced here)" section, with the specific hash mismatch (`a88195f2…` vs `76f62be4…`/`3d9167f7…`) recorded | MATCH | — |
| Handoff — q12, 89 parked rationales | Deferred/fenced, do not touch | No substantive diff hits for either; Prong B brief still lists q12 as "a POLICY fence; Shinichi's call, not the agent's" (S5 did not alter that line) | MATCH | — |
| Handoff — `.git/index.lock` | (asked to check; not mentioned in the plan text itself) | **Found**: `/Users/z3437171/Dropbox/Github Local/drmTMB/.git/index.lock`, 0 bytes, mtime `2026-08-03 08:12:59` — roughly 6 hours before this session's active commit window (13:59–15:20 local). Undeclared anywhere (plan, after-task report, check-log, PR body). Does not currently block read-only `git status` in the primary checkout (verified). The primary checkout sits on an unrelated branch (`claude/handover-freshness-0718`) with its own uncommitted changes, which is circumstantial support that this lock predates and is unrelated to this Arc 8 session — but that is inference, not proof | **UNCLEAR** | Rose (closeout hygiene) |

## Drift

**D1 — the plan's own closure condition is unmet, and this reconcile is running ahead of its stated
dependency.** The plan's header states `CLOSURE: merged PR + Melissa reconcile`, and the slice table
marks `S6 ← S3–S5`. As of query time `2026-08-03T21:43:35Z`, PR #912 is `OPEN` with `mergedAt: null`
and `mergeStateStatus: UNSTABLE`; the primary `ubuntu-latest (release)` check has been `IN_PROGRESS`
since `21:21:13Z` with no result yet (a second, superseded run on `ecdd5b1f1914e30cba24c827423bc78920828e40`
came back `cancelled`, not `success`, when the S4/S5 commits were pushed on top of it). Nothing found
in the repository indicates a decision to dispatch S6 before S3 finishes; it appears to be simple
timing (S6 launched while CI was still running). This is not a failure of S3's work — the branch is
`MERGEABLE` with no conflicts, and not merging while CI is unresolved is consistent with the plan's own
`DISCIPLINE` clause — but the plan's stated *deliverable* ("Arc 7b merged into main") is not yet true,
and that should not be read into this document's existence. Owner: Ada (whether to re-run/re-issue S6
once CI resolves and the merge lands is a scope/routing call).

**D2 — S2's mechanical-verify slice was not dispatched as planned, and the deviation is unrecorded.**
The plan assigns S2 to `Curie · Haiku · low` via a dispatched, read-only-Bash `Agent`, names it
explicitly in the `FAN-OUT BUDGET` ("new children 3/6 (Curie, Rose, Melissa)"), and flags
`LUNA SUITABILITY: yes — S2 is bounded, read-only, mechanical → Haiku`. Per the launching agent, this
ran inline in the orchestrator instead. No file artifact in the repository (check-log, after-task
report, a dedicated verification log) records this substitution or a reason for it. The mechanical
checks themselves do appear to have run — `docs/dev-log/dashboard/capability-ledger/cells.tsv` carries
an mtime (`21:20:38Z`) 14 seconds after the S5 commit and 14 seconds before the second CI trigger,
consistent with a regenerate/verify pass immediately before the final push — but the routing
substitution itself is undocumented. Owner: Ada.

## Adaptive

**A1 — the plan's own Verification item 2 ("now 5+ of 8") undercounts the actual, corrected figure
("6 of 9").** This is not free-standing drift: the plan's own "The rebase, precisely" section already
instructs the rebase to "correct the header comment count" for `R-CMD-check.yaml`, because main's
PRs #910/#911 changed the wired-guard denominator by adding `test_b4_ci_guard.py`. What happened
(`R-CMD-check.yaml:72`, "6 of 9 run... This count read '5 of 7' before Arc 7b") is exactly the kind of
correction the plan itself called for; the Verification list's "5+ of 8" phrasing is simply a stale
estimate inside the same plan document, not a deviation from intent.

## Unclear

**U1/U2 — Verification items 3 and 5 have no artifact confirming a rebased-tree re-run.** Both are
documented only inside the after-task report (`docs/dev-log/after-task/2026-08-03-arc7b-profile-truth-gate.md`),
which is itself part of commit `e5413c98f` (author date `13:59:32`, i.e. written for the *original*,
pre-rebase Arc 7b commit, before the `15:07:49` rebase). The plan's Verification preamble is explicit —
"Nothing is done until each has been *run on the rebased tree*" — and I could not find a second,
post-rebase record of the `emit-profile-truth-manifest.R --check` run (item 3) or the adversarial
frozen-cell flip (item 5). Item 4 (tier census = 182) is independently confirmed live in the current
generated dashboard, and item 1 (`capability_ledger.py --check`) I re-ran myself just now — both pass —
so the underlying system is very likely fine, but items 3 and 5 specifically are not evidenced as
having been re-run, only as having been run once, before the rebase. I did not re-run the adversarial
mutation test myself, since that would require editing a tracked file outside the one file I am
permitted to write. Route to Fisher (or whoever performs S2's actual re-verification) to close.

**U3 — a stale `.git/index.lock` sits undeclared in the primary checkout's git-common-dir.** See the
table row above. Most likely orthogonal debris from an unrelated, earlier interrupted git operation
(timestamp predates this session by ~6 hours; the primary checkout is on a different branch entirely),
but no document anywhere declares it, and a stale `index.lock` can silently block a future `add`/
`commit`/`merge` on the primary checkout. Route to Rose for a closeout-hygiene check (human `rm`,
alongside the already-declared `tools/profile-truth-manifest.tsv.bak`) rather than assuming it is
harmless.

## Verdict

Arc 8's plan and its actual execution agree closely on substance: S1 (rebase), S4 (triage-note
correction), and S5 (Prong B brief refresh) each landed exactly as specified and are independently
verifiable against the source tree (the rebase preserved both sides' conflicting changes with nothing
from PRs #910/#911 reverted; S4's cited line range and REML-gate claims check out byte-for-byte against
`R/drmTMB.R`; S5's premise corrections and Decision 2 match the plan's own locked-decision text). The
Phase 0.25 safety-gate receipt is genuinely non-vacuous, and its central technical claims independently
verify. No scope creep occurred — `R/profile.R` and the other fenced items (q12, the 89 parked
rationales, the `coi`/STOP cells) are untouched — and no claim beyond target-specific interval-existence
was made anywhere in the diff. The two real deviations both concern process rather than substance: the
plan's own closure condition (a merged PR) is not yet met because GitHub Actions CI on the rebased
branch had not finished as of this reconciliation, which also means this document itself is running
ahead of its own stated dependency (D1); and the S2 mechanical-verification slice was, per the
launching agent, executed inline rather than dispatched to the planned Haiku sub-agent, an unrecorded
routing deviation that quietly shrinks the plan's own fan-out budget even though the verification work
appears to have actually happened (D2). Two further items (whether items 3 and 5 of the Verification
checklist were literally re-run on the rebased tree, and a stale, undeclared `.git/index.lock`) could
not be resolved from available artifacts and are flagged rather than assumed.

## Addendum — concurrent, uncommitted activity observed while writing this report

Not part of the reconciliation above, which is anchored to the four committed commits
(`e5413c98f`..`3e9122037`). Recorded because it is directly material to U1/U2 and was directly
observed, not inferred.

While drafting this report the worktree's git status changed under me, from clean (only the
already-declared `tools/profile-truth-manifest.tsv.bak` untracked) to:

```
 M docs/dev-log/after-task/2026-08-03-arc7b-profile-truth-gate.md
 M tools/profile_truth_gate.py
 M tools/tests/test_profile_truth_gate.py
?? docs/dev-log/plan-actual/2026-08-03-arc7b-truth-gate.md   (this file)
?? tools/profile-truth-manifest.tsv.bak
```

as of `2026-08-03T21:49:30Z`. **I did not make these edits** — I have no Write/Edit tool, and no Bash
command I ran writes to any of these three paths (verified: only `git`/`gh`/`grep`/`awk`/`stat`/`python3
… --check`/`date` commands were run against them). This is another process editing the same shared
worktree concurrently.

The diff on `tools/tests/test_profile_truth_gate.py`, read at `21:47:38Z` (mtime), adds a `tier_rank()`
helper and rewrites `test_every_interval_feasible_contract_cell_passes_the_gate` into
`test_every_gated_contract_cell_passes_the_gate`, with a docstring stating: *"an adversarial review
demonstrated all 19 tests still passing with all three gate-failing cells promoted to
inference_ready_with_caveats"* — i.e. the original gate test selected cells by tier **equality**
(`!= "interval_feasible"` → skip), so a gate-failing cell escaped detection if promoted *upward* past
that tier rather than left in place. That is exactly the class of check Verification item 5
(adversarial flip) exists to catch, and U1/U2 above already flagged that item 5 had no artifact
confirming a post-rebase re-run. `tools/profile_truth_gate.py` and the after-task report are being
edited in the same window, consistent with a fix for the same gap plus documentation of it — but as of
this addendum none of it is committed, so it is **not** reflected in PR #912, is **not** covered by the
axis reconciliation above, and its correctness is not something I evaluated (out of scope for this
report). Flagged for whoever owns S2/S6 next: confirm what is producing these edits before this branch
is merged, since an uncommitted change landing silently inside a "MECHANICAL-VERIFY, read-only Bash"
slice would itself be a scope deviation from S2's own definition.

**Update, `2026-08-03T21:5X Z` (immediately after the above):** the working tree is clean again — the
three modified files reverted to matching HEAD, leaving only the already-declared
`tools/profile-truth-manifest.tsv.bak` and this report untracked. Nothing is staged
(`git diff --cached` empty). This confirms the edits above were transient, concurrent, external
activity in the shared worktree, not a persistent uncommitted change — consistent with another process
actively iterating (edit → test → revert) rather than a corruption of this reconciliation's baseline.
The substance of the addendum stands as an observation of what was attempted; it left no trace in the
tree to independently re-verify further.

---

## Orchestrator's correction to the Addendum (Ada, 2026-08-03, post-report)

Melissa's addendum is an accurate observation and a correct instinct — an unexplained
edit-then-revert cycle in a shared worktree is exactly the kind of thing a reconciler should
refuse to wave through. The cause is known, and recording it here so the anomaly does not
persist in the durable record as unattributed.

Both patterns she saw were mine, and neither was part of S2:

1. **The three modified files** (`tools/profile_truth_gate.py`,
   `tools/tests/test_profile_truth_gate.py`, and the after-task report) were an **unplanned
   remediation slice** run after an adversarial review returned four demonstrated defects. That
   work is now committed as `e62ffbc96`, so it *is* in PR #912 — her report was written in the
   window before that commit existed.

2. **The edit-then-revert cycle** was deliberate **mutation testing**: each of the four defects
   was replayed as a source mutation (delete the miss-count clause; delete the truth-gate call in
   `reconcile()`; neutralise the zero-truth fallback; promote the three gate-failing cells upward
   in `cells.tsv`), the suite was run to confirm the mutant now dies, and the file was restored.
   All four mutants were killed. The restore is why the tree returned to clean.

**This is a real scope deviation and should be tagged, not excused.** The approved plan had six
slices; an adversarial review and its remediation were not among them. Classify it as a new row:

| axis | planned | actual | tag | owner |
| --- | --- | --- | --- | --- |
| scope | 6 slices, no adversarial review | +1 unplanned slice: adversarial gate review (Fable) and its 4-defect remediation, committed `e62ffbc96` | **adaptive** | Ada |

Adaptive rather than drift on three grounds: it was user-directed ("please get several agents to
help you"); it found a genuine defect that would otherwise have merged (the standing guard could
be defeated by promoting a gate-failing cell *upward*, since it compared tier equality rather than
rank); and it is recorded here and in the after-task report rather than absorbed silently. Had the
review found nothing, the honest tag would still be adaptive — the cost was real either way.

Her U1/U2 rows stand as written for the tree she reconciled. On the current head the full CI
sequence, the census check (182/60) and the adversarial ledger flip were all re-run after the
rebase and again after `e62ffbc96`; the evidence is in the after-task report's Checks section.

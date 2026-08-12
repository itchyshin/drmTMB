# Plan-vs-actual: interval-availability arc + G4/G5 promotion arc (2026-08-11)

Reconciler: Melissa. Scope: `claude/interval-availability` (3→now 4 real commits +
after-task, `e65346dd2`/`105b1aeb5`/`19e4a1d03`/`5c9f2d687`), `claude/g5-panel-and-promotion`
(6 commits, `946ae7383`..`c040701f6`), and `claude/979-c17-narrow-pin` (uncommitted, in
`wt-g5close`). Plan text for the interval-availability arc is
`/Users/z3437171/.claude/plans/prancy-seeking-spring.md`; the g5-panel-and-promotion arc's
own plan was overwritten before this session and is reconstructed from commit prose and
`docs/dev-log/after-task/2026-08-11-g5-promotion-and-interval-availability.md`, which is
itself part of the actual (not a neutral third source) and is treated as such below.

Record only. No code, ledger TSV, or agent file was edited to produce this report.

## Material deviations

| axis | planned | actual | tag | owner |
|---|---|---|---|---|
| Scope (arc 2, S6) | S6 re-score dispatched separately to Curie, sequential after S4 | Folded into the S4 (`policy-split`/Emmy) agent's own turn; no separate Curie dispatch. Verified: `2026-08-11-rescore-old-vs-new.md` carries **"Author: Emmy"**, not Curie, and is the same file that documents the policy change | adaptive | Ada |
| Scope (arc 2, S7) | MECHANICAL-VERIFY dispatched to Grace/Haiku, "cheap, no judgment" | Not dispatched. Orchestrator ran `--write`/`--check`/unittest/`devtools::test()` inline. No Grace-authored file exists anywhere under `docs/dev-log/interval-availability/`. Self-reported by the orchestrator as drift against the plan's own named anti-pattern ("classic Haiku-underuse leak," dispatch-discipline section) | **drift** (orchestrator's own admission, independently confirmed by absence of a Grace artifact) | Ada |
| Scope (arc 2, S9) | RECONCILE + closeout dispatched to Melissa **and Rose** | Melissa dispatched (this task). Rose was not dispatched; the after-task report (`5c9f2d687`, 07:09:21) was authored by the orchestrator directly, same session, no separate systems-auditor pass | drift | Rose |
| Scope (arc 1, #979) | Not in either plan (arc 1's own plan text is lost) — reconstructed intent per after-task: narrow the C17 fingerprint pin | Halted mid-implementation after another lane's PR #998 closed #979 on different grounds (fingerprint reads only `R/drmTMB.R`+`src/drmTMB.cpp` but the receipt also grades `ranef.drmTMB()` plumbing, so narrowing would silently drop coverage). 244 insertions in `tools/capability_ledger.py` left **uncommitted** in `wt-g5close` (branch `claude/979-c17-narrow-pin`, `git status --short` confirms exactly one modified file, `git diff --stat` confirms 244 insertions / 29 deletions) | adaptive (explicitly justified, and a rejected approach correctly kept out of history) | Ada |
| Evidence | Every diagnostic/policy note carries a named reviewer-persona line matching a roster agent | Confirmed for S2/S3/S4/S5 (`diagnosis-concentrated-failures.md`→Gauss/`diag-concentrated`; `point-estimate-outside-interval.md`→Noether/`diag-outside`; `967-ordinal-cutpoint-decision-memo.md`→Boole/`memo-967`; `rescore-old-vs-new.md`→Emmy/`policy-split`). **One exception**: `2026-08-11-availability-threshold-evidence.md` — the pivotal dose-response finding that reverses the plan's own stated approach — carries **no** author/persona line (only "Reader: whoever writes the revised G5 calibration policy") and has no matching name in the session roster | unclear | Ada |
| Evidence | Orchestrator claims stand as background fact | Three orchestrator claims (`n_attempt` provenance, "profile-only" being a data vs. code claim, the non-convergence mechanism for the heavy cells) were corrected by agents. Verified propagated into committed artifacts, not just chat: `105b1aeb5` edits `availability-threshold-evidence.md` in place to strike the non-convergence hypothesis and record the refutation; `946ae7383`'s own commit message states "Three corrections are folded in" and names them | no drift (self-correction, fully landed) | domain reviewer (Fisher/Noether, already the panel) |
| Evidence | D-43 panel: one round, 3/3 verdict, 7 routes | Panel reopened with addenda after the orchestrator found the 7-route candidate list was inherited rather than re-derived, which had circularly excluded `cumulative_logit` and silently excluded `lognormal`. Second round (`4bf11d8ed`, `8a8a231ea`, `3559cf242`, `60abc89c5`) promoted an 8th route (`lognormal`, 3/3) and held `cumulative_logit` 2/2 on a *different, non-circular* ground (container/key-grain, not the inherited tag). Both the original and corrected verdicts are on record in sequential commits, not overwritten | adaptive | domain reviewer (Fisher/Noether/Rose — already ruled) |
| Safety gate | No subagent should be blocked mid-write | Orchestrator entered plan mode while `panel-fisher`, `panel-rose`, `panel-noether`, `c17-narrow` were live, blocking their writes; resumed via SendMessage after exiting. Verified no content was lost or ghostwritten by the orchestrator: the four panel-addendum commits (`4bf11d8ed` 06:36:55, `8a8a231ea` 06:38:25, `3559cf242` 06:41:11, `60abc89c5` 06:41:30) each carry a distinct persona voice and reasoning chain consistent with the roster names, at plausible sequential timestamps for a resume cycle; `c17-narrow`'s work never landed (matches the #979 row above) | adaptive (recorded; no data loss) | Ada |
| Safety gate | Phase 0.25 prior-work sweep receipt, arc 2 | Present in the plan file itself, 6 surfaces (repo git state, open queue, campaign artifact, twin repo, brain semantic, brain grep), each row naming an actual command (`git log --oneline -40`, `gh issue list --state open --limit 60`, `~/g5run/why_unusable.R`, `grep -ril ... DRM.jl`, `search_notes(...)`, `grep -in "D-113\|0.7.0" memory/DECISIONS.md`) and a specific finding (SHAs, PR/issue numbers, named lessons). Non-vacuous | no drift | — |
| Safety gate | Phase 0.25 receipt, arc 1 | Not assessable — arc 1's own plan document is the one that was overwritten; no equivalent receipt table survives to check against. The promotion commits themselves cite specific campaign facts (task IDs `18777800_222`–`225`, TIMEOUT, `centre_random_effects` reproduction) suggesting real grounding, but this is not the same as a written Phase 0.25 receipt | unclear | Ada (decide whether arc 1 needed one, given its plan was lost before this session, not skipped within it) |
| Model routing | Fan-out budget 6 producer + 1 ceiling (arc 2) | Real producers: `recon-interval` (S1), `diag-concentrated` (S2), `diag-outside` (S3, the ceiling — Opus, matches plan), `memo-967` (S5), `policy-split` (S4+S6 folded) = 5, plus `recon-queue` (arc-2 orientation, run during next-arc planning rather than inside the executed slice table). Ceiling budget (1, Opus, `diag-outside`) held exactly. Producer count is 5 core + 1 disputed (`recon-queue`) against a budget of 6 — under budget either way it's scoped, not over. No 7th-child checkpoint was needed or claimed | no drift | — |
| Public claims | Ledger: 8 routes → G5/`inference_ready_with_caveats` | Verified directly against `docs/dev-log/dashboard/capability-ledger/cells.tsv` in `wt-promote`: exactly 8 `mr-*` rows read `evidence_tier=inference_ready_with_caveats test_gate=G5` (gaussian, biv-gaussian, lognormal, gamma, zi-poisson, beta-binomial, zero-one-beta, binomial); the other 10 remain `point_fit_recovery`/G3 | no drift | — |
| Public claims | Arc 2's stated approach: "gate on coverage" (plan's own GOAL block and Fisher's raised concern) | Shipped: coverage gate **AND** a named availability floor `MR_G5_AVAILABILITY_FLOOR <- 0.99` (`inst/sim/R/sim_missing_response_g4g5.R:951`). This is disclosed, not silent: commit `19e4a1d03`'s body states the rejection of coverage-alone explicitly with numbers (33 cells would be admitted, 8 from a zone where only 9/13 sit in band), a dedicated file (`availability-threshold-evidence.md`) is titled around the reversal, and the after-task's §3a is headed "Decisions and Rejected Alternatives" with the coverage-alone option named and rejected on evidence | adaptive, well-recorded — **not** silent scope drift | — |
| Public claims | Ledger sources vs. generated outputs | `recon-s1` reported the `missing_response` ledger TSVs as generated. Checked against `docs/dev-log/dashboard/capability-ledger/README.md:3-6`: `cells.tsv`/`evidence.tsv`/`transitions.tsv` are the **hand-edited sources** ("Edit the ledger sources, record a transition, then regenerate"); the census/Markdown/HTML/JSON/vignette-include/tranche files are the generated outputs. `recon-s1`'s claim was wrong on the README's own text; the after-task and orchestrator report it as caught by `promote-g5` before it reached a commit | adaptive (caught pre-commit) | — |
| DEFER fence | MAR/MNAR, REML, MD7f, the 0.7 release ladder untouched | Checked per-commit `git show --stat` for all 9 arc-1/arc-2 commits: no file under a REML/MAR/MNAR/MD7f/release path is touched. A raw `git diff origin/main..HEAD` in `wt-promote` **does** surface REML/`0.7.0-cran-gate` strings, but this is diff noise: `origin/main` in that worktree is stale at the branch's own fork point check (`git merge-base origin/main HEAD` = `a2c4941db`) while the live `origin/main` ref has independently advanced to `eae8b1f259` on a different lane's work (the after-task already flags this as `256e586e5`, itself now stale). `git log --oneline origin/main..HEAD` (6 commits, matches the briefing) is the correct scope; the tree-diff is not | no drift, but the tree-diff false-positive is worth flagging | — |
| Handoff state | — | Both branches are based on stale `a2c4941db`; real `origin/main` has moved twice since (to `256e586e5` per the after-task, and further to `eae8b1f259` as of this check). Nothing is pushed. `wt-g5close`/`claude/979-c17-narrow-pin` carries 244 uncommitted insertions, deliberately unlanded. All three facts are declared in the after-task's §10 "Known Residuals," not discovered by this reconciliation | adaptive (self-declared) | Ada |

## Notes on the flagged rows

**S7 (drift, Ada).** The plan text names this exact failure mode before it happened
("classic Haiku-underuse leak" in the dispatch-discipline section) and the orchestrator did
it anyway, then flagged it unprompted when asked. The check itself was correct
(`--write`/`--check` clean, 67 unit tests, `devtools::test(filter="missing")` 1569/0/2) — this
is a process deviation, not a correctness one. Low stakes, but it is exactly the deviation the
plan pre-registered a name for, which is why it earns the tag rather than a pass.

**S9 (drift, Rose).** The after-task report was written by the same orchestrator whose three
mid-arc claims needed correcting by other agents in this same session (see the "Evidence" row
above). The plan assigned closeout to Melissa **and** Rose specifically so that a systems-auditor
lens, not the implementer, checks the closeout claims. That check did not happen as a separate
pass here — this reconciliation is the first outside read of the after-task's own claims, and it
mostly holds up (verified independently: the 8-route ledger state, the availability-floor
disclosure, the #979 uncommitted-and-abandoned state, the DEFER-fence cleanliness). But "mostly
holds up, checked after the fact by the row that exists to check it" is a weaker position than
"checked by a dispatched Rose before the report was called done."

**The unattributed evidence note (unclear, Ada).** `2026-08-11-availability-threshold-evidence.md`
is the single most consequential document in arc 2 — it is what overturns the plan's own stated
approach — and it is the one note without a named reviewer voice or a matching roster agent. Its
content is independently checkable (the dose-response table cites `~/g5run/policy_sensitivity.R`
against the reconciled artifact) and nothing in it looks fabricated, so this is not a correctness
concern. It is a routing-transparency gap: readers cannot tell from the file itself who is
answerable for the arc's pivotal claim.

## Verdict

Both arcs are safe to hand over on the evidence actually checked: the ledger state matches its
commit claims exactly (8 routes at G5, verified against `cells.tsv` directly), the DEFER fence
held across every commit that was actually part of either arc, the #979 abandonment left no
half-landed code, and the one substantive policy change from the plan's stated approach (coverage
AND availability ≥ 0.99, not coverage alone) is disclosed with numbers rather than buried. The
open items are process, not correctness: two slices (S7, S9) that the plan assigned to independent
reviewers were run by the orchestrator instead, and one pivotal document lacks the attribution its
siblings carry. Neither branch is pushed and both sit on an origin/main that has moved twice since
their fork — whoever picks this up needs to rebase before opening a PR, which the after-task
already says.

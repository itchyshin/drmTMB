# Plan vs actual — Dinnage audit second arc, wave 3 (Melissa, light reconciliation)

Plan: `LOOP/ultra-plan.md` (Rose+Fisher plan review PASS-WITH-CHANGES, five changes applied,
2026-09-14). Read against: after-task `docs/dev-log/after-task/2026-09-14-dinnage-audit-wave3.md`,
`LOOP/checkpoint.md`, `git log --oneline` in this worktree, Fisher's review
`docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md`, and the ledger `.unlazy/dinnage-2/gates/*.md`.

**Read-time note.** The review file carries an uncommitted edit (`git status`: `M ...wave3-review.md`,
mtime 21:18:56) written seven seconds after the after-task commit (`ee0f9d60c`, 21:18:49). That edit adds
`### S2b follow-up (4ae2f5d99, d61f65183)` with `VERDICT: REJECT`, four REQUIRED items open. The after-task
and `checkpoint.md` both describe this verdict as still pending / in progress — accurate when they were
written, superseded by the time of this reconcile. The table below uses the review file's current content,
not the after-task's snapshot of it.

| Axis | Planned | Actual | Tag |
|---|---|---|---|
| Scope | M1 all 11 non-Bernoulli `mi()` sites; M2 clamp at "one choke point"; S6 note only; S2 note + fix contingent on Fisher concurrence; S3 doc; DEFER: option B, S6 code, Gaussian-latent `mi()`, Moderates/Minors, merge/release, Russell message | M1 landed at all 11 (two residual gaps named, not fixed: `mi_family==0` needs its own design; Tweedie agrees to ~1e-2 not machine precision, frozen-support risk recorded); M2 grew from "one choke point" to five sites across two follow-ups (`predict_parameters()`, `sd(group)` found by F-A; the first fix REJECTED by Fisher — clamped Wald endpoints collapse to zero width, measured coverage 0 — then repaired correctly); S6/S2a/S3 landed as planned; S2's exact fix landed (`3192db3f6`) then needed a follow-up (`4ae2f5d99`/`d61f65183`) whose own re-review is REJECT, 4 REQUIRED items open, uncommitted; DEFER list fully honoured; two neighbour defects recorded, not fixed (Tweedie frozen quadrature support; four raw-eta consumers of the sigma clamp) | adaptive (M1/M2/S6/S2a/S3 growth all caught and closed inside the arc's own red-first/fresh-Opus loop; DEFER and neighbour-recording match discipline) — except the still-open S2b follow-up, carried to Evidence/Public claims/Handoff below |
| Evidence / verification | Red proof before every fix; ledger `--reverify` per leaf; **one** `R CMD check --as-cran` on a clean export before push; fresh-context Opus review of every diff before it counts | Red proofs produced for M1/M2/S2/S2b-followup; one false negative caught and re-run (a capped testthat reporter hid 5/11 M1 failures before the uncapped, then final, red proof); **two** as-cran runs — run 1: 1 ERROR (a real regression, `test-zi-nbinom2.R` pinned the pre-clamp raw scale) + 2 WARNINGs, repaired; run 2: 0 errors, 0 package warnings, 1 NOTE — push happened only after the clean run 2; ledger reports 26/27 gates MET, but `G-R-2` ("no open REQUIRED item remains") is not merely the "pending" the committed ledger file shows — the review file itself, read now, already carries a REJECT with 4 REQUIRED items open for the S2b follow-up, so `G-R-2` is UNMET on current evidence, not pending | adaptive on the two-as-cran-runs point (intent — clean check before push — was honoured); **drift → Rose** on the `G-R-2` status: close-out evidence (26/27 MET) was recorded without registering a verdict that had already landed |
| Model routing | FAN-OUT budget 8 new children after G0; ceiling = 2 fresh-Opus reviewers (F-A code, F-B docs); M1a→M1b, S2→S2b, repairs reused via SendMessage | SendMessage was unavailable for the entire arc, so no child could be resumed with context intact; 22 children spawned total, 6 Opus-tier (F-A, F-B, plus four further fresh Fisher re-reviews forced by REJECT/repair cycles — S2b, the M2-repair REJECT, the `predict_parameters()` repair, the S2b-repair) — 2.75x the planned child count, 3x the planned Opus ceiling; every model choice otherwise stayed on-model, no Fable used as a parallel child (Shinichi's mid-arc routing rule honoured) | adaptive — the overrun is fully explained by one external constraint (SendMessage disabled) applied consistently, not by discretionary misrouting, and is named in What Did Not Go Smoothly; **routed to Ada** as a fan-out-budget lesson (a REQUIRED-repair loop multiplies fresh-Opus re-reviews; the plan's budget should assume that when SendMessage cannot be assumed) |
| Safety gates | No merge/release, no message to Russell; push and issue comments pre-authorised after G0; comments drafted, not posted | Branch pushed (`666c1865a`) under the pre-authorisation envelope; five issue-comment drafts exist (#1301, #1307, #1308, #1312, #1315), none posted; no merge, no release, no Russell message; a destructive-command guard correctly blocked an `rm -rf` scratch cleanup and, separately, an unrelated grep containing the same substring — both harmless refusals, recorded rather than worked around | adaptive |
| Public claims | NEWS entries land only after the owning fix clears Fisher's review; issue comments attributed and drafted-only | `NEWS.md`'s wave-3 section (`1540d95fe`, already committed and pushed at `666c1865a`) states phylo-on-`sigma` support and the `NA`-refusal boundary as settled facts; Fisher's S2b-follow-up review — written after that NEWS commit, still uncommitted at reconcile time — finds two of those sentences false (`phylo()` alone on `sigma` is now wrongly refused as non-unit-diagonal; the `NA`-boundary sentence is over-broad) and lists the correction as REQUIRED item 4; five issue-comment drafts correctly stayed unposted | **drift → Rose**: a public-facing claim was committed and pushed before the review gating it had returned a verdict, and that verdict is negative |
| Handoff state | Close only when the review file shows a verdict for every diff and no open REQUIRED item remains (`leaf-REVIEW.md`'s own gate), then after-task → Melissa → handover → posts | The after-task (`ee0f9d60c`, HEAD) and `checkpoint.md` both describe the S2b-follow-up verdict as "still pending" / "in progress" (a scratch probe only) and frame the remaining work as "obtain Fisher's review"; ground truth at reconcile time is that the review already exists, uncommitted, and is REJECT with 4 REQUIRED items open — the arc is not at the state its own closeout gate requires, though the after-task was drafted as if the only gap were waiting on a verdict rather than acting on one. This Melissa file and the handover (`docs/dev-log/handover/2026-09-14-claude-handover-dinnage-audit.md`) did not exist on disk before this reconcile | **drift → Rose**: close-out artefacts were drafted around an assumed-pending verdict that had, by drafting time, already resolved negatively; the handover must carry the REJECT and its 4 open REQUIRED items forward, not the "pending" framing |

## Drift routed

**Rose (closeout/claims), two linked items.** (1) `NEWS.md`'s wave-3 section makes two claims about
phylo-on-`sigma` support that Fisher's own re-review — sitting uncommitted in the review file at reconcile
time — found false, because the fix it describes (`4ae2f5d99`/`d61f65183`) shipped and was written up before
its own gating review returned. (2) The after-task and `checkpoint.md` both call that same review "pending,"
which was true when they were written and is not true now; `G-R-2` reads UNMET, not pending, and the handover
still to be written must say so plainly, with the four REQUIRED items (index by `tip_node_index`, not the
whole augmented precision; test all three directions; refuse or flag the marginal on a clamp-active fit;
correct the two NEWS sentences) carried forward as open, not closed. Separately, the mechanical verifier's
literal-EXPECT-string mismatch on three gates (narrative `grep` summaries recorded instead of the leaf's own
literal `CHECK` output) is a process lesson for Rose: specify the literal expected string in leaf authoring,
not a paraphrase of it.

**Ada (scope/routing), adaptive not drift.** Fan-out grew from the planned 8 children (ceiling 2 fresh-Opus
reviewers) to 22 children (6 Opus), entirely because SendMessage was unavailable and every Fisher REQUIRED
finding forced both a fresh builder and a fresh Opus re-review under the arc's own gate. Not misrouting — but
the next FAN-OUT BUDGET for an estimand-touching arc should price in that a REQUIRED/REJECT repair cycle
multiplies Opus re-reviews when reuse-by-SendMessage cannot be assumed.

**Domain reviewer (Fisher), already exercised, not re-routed.** The S2b follow-up's own method defect — a
capability regression on `phylo()` alone on `sigma`, and a clamp-active marginal formula that is unbounded
where the kernel's own quantity is bounded (measured `residual_variance` 6.314 vs. kernel-consistent 2.939 on
a partly-bent fit) — is Fisher's finding, in Fisher's file, with Fisher's own fix named (index the diagonal by
`tip_node_index`; return `NA` with `clamp_active_marginal_undefined` on a clamp-active fit, matching
`e86359fe2`'s `clamp_limited` treatment one module over). Recorded, not escalated further here.

No routing needed for the recon scout's two wrong reports (`.unlazy` ignore status; the next free design
number) — both were caught by the orchestrator's own Phase 0.25 sweep before they cost anything and are
recorded in the after-task's Consistency Audit.

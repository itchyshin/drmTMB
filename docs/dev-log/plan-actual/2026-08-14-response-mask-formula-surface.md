# Plan vs actual — response-mask formula surface arc (2026-08-14)

Reconciliation across six axes, per Rose's brief. "Plan" is the handover this
arc inherited
(`docs/dev-log/handover/2026-08-14-claude-handover-response-missing-formulas.md`)
plus Shinichi's mid-flight reframing ("truthful ledger first, cells second").
Every number in "Actual" was independently reproduced in the after-task
report in this same directory dated 2026-08-14; this file does not repeat
that verification, only the reconciliation.

| Axis | Plan | Actual | Deviation |
|---|---|---|---|
| **Scope** | Close 15 OWED univariate-ML response-mask cells in three reusable-harness batches (zero-one-beta scale/atom, zero-inflated counts, then the Gaussian interaction); bivariate/REML explicitly out of scope, deferred to later arcs | 15 cells measured (not just "closed"): 6 promoted, 9 refused on measurement; bivariate/REML untouched exactly as planned; scope additionally widened, mid-arc, to a full 30-file red-surface audit of the *pre-existing* 185 `formula_validated` cells the plan had assumed were solid | **Adaptive**, not drift. The widening was a direct, explicit response to discovering the handover's premise ("No technical blocker") was false — the plan could not be executed honestly without first checking whether the inherited 185-cell base was real. Re-scoping to verify a false premise before building on it is exactly what "truthful ledger first" asked for, and the original 15-cell scope was still delivered inside it. |
| **Evidence / verification** | "A cell needs both an observed-data masking/oracle check (G2) and a known-DGP recovery check (G3)" — narrow per-cell contract, no mention of harness verification | Four independent harness defects were found and fixed first (sentinel arity, three stale `expect_error` fences, four non-symbol structured-marker arguments, three NA-injecting scalar-indexing fixtures), because the G2/G3 contract as *written* could not be trusted at face value — some of it was measurably not running. The verification bar moved from "does the cell's test pass" to "does the cell's test execute the thing its claim text says it executes." | **Adaptive.** This is the correct response to finding that ~35 of the cited G2/G3 checks across 7 files were either failing or, in four cases, could not execute at all. No plan anticipates its own foundation being partly hollow; fixing that before certifying cells on top of it is not scope creep, it is the minimum bar for the reframed goal. |
| **Model routing** | Not specified in the handover beyond "Claude can plan/refactor/prose and run logic checks; use Codex later for live compiler-heavy fits or the DRAC campaign" | All work stayed local (no DRAC/Totoro campaign was launched); "compiler-heavy fits" turned out to be small deterministic local fixtures, well within what the plan already authorized for logic/oracle work | **Adaptive**, matches plan. The plan's own escape hatch ("DRAC is later... before a claim-bearing DRAC recovery run, do one local pre-run") was correctly not triggered, since this arc never reached a claim-bearing recovery *campaign* — it stayed at per-cell deterministic-seed recovery, the tier the plan scoped for local/Claude work. |
| **Safety gates** | Not explicit in the handover; implicit in project convention (D-43 style multi-perspective review before promotion) | A distinct role split emerged mid-arc: a red-surface audit (classification only, explicitly "no fixes applied"), then four separate ledger-writing passes, each independently checked (`response_mask_formula_inventory.py --check`, `capability_ledger.py --check`, row-level diffs confirming *only* the intended rows changed) before the next pass began | **Adaptive.** This is a stronger safety gate than the plan specified, introduced because the plan's implicit trust in the 185-cell base had just been shown to be misplaced. The audit-then-write separation (one agent classifies, does not fix; a different pass writes the ledger) is a genuine process improvement over "author certifies their own cell," consistent with the repo's own "own-the-verifier" doctrine. |
| **Public claims** | Handover said 185 `formula_validated`, 15 OWED remaining, "No technical blocker" | Final state: 181 `formula_validated` (net -4: +6 promoted, -11 demoted, +1 row-count from a 1-row-to-2-row split), with 5 cells' claim text corrected (objective-level, not coefficient-level, equality) and 9 cells' generic `next_gate` replaced with a measured, cell-specific mechanism. The "no technical blocker" claim is retired; the record now states measured, per-cell blockers (near-singular Hessians, internal-node GMRF over-parameterization, zero-boundary SDs) instead. | **Correction of drift already present at handover, not new drift introduced by this arc.** The inherited public claim was already inaccurate before this arc started (that is what "proved false" on rehydration means); this arc's actual deviation from that inherited claim is the fix, not a new problem. |
| **Handoff state** | Branch pushed, clean, `CARRIED-OVER`, no PR, next agent should "reconcile... then continue only the OWED Next Immediate Steps" | Branch has substantial uncommitted working-tree state at the point this reconciliation was written (17 modified tracked files, 9 new untracked files, none committed); no PR opened; this after-task report and the `AGENTS.md` pointer are the first durable record of the closeout | **Unclear / open.** Per `docs/dev-log/check-log.md` §pass-4 "RESOLVED (orchestrator, same day)" note, a final independent re-run confirmed the file-level counts after all passes landed, so the work itself is finished. But nothing in this working tree is committed yet. Whether the next step is one commit, several small commits mirroring the four ledger passes, or a PR is a decision for the implementing lane, not settled by this reconciliation. Flagging as open rather than guessing. |

## Two specific verdicts requested in the brief

**(a) Re-scoping mid-flight from "close 15 cells" to "truthful ledger
first, cells second" — adaptive or drift?**

**Adaptive.** The reframing was not a scope expansion invented by the agent;
it was forced by a falsified premise discovered during rehydration (the
handover's "No technical blocker for the 15 univariate cells" claim did not
survive contact with the live test suite), and it was authorized explicitly
by Shinichi, not self-authorized. The alternative — closing the 15 cells as
originally scoped while leaving the discovered 35 failures and the four
harness defects unaddressed — would have produced a *larger*, not smaller,
gap between the ledger and the code, and would have buried the discovery
under six more promotion commits following the same unverified pattern that
produced it. Re-scoping to fix the foundation before building the requested
15 cells on top of it is the textbook adaptive response, not drift: drift
would be silently expanding scope without naming why, or continuing to
scope-creep after the original problem was fixed. Neither happened here —
the arc closed with the original 15-cell question fully answered (6/9) once
the foundation was verified.

**(b) One ledger writer split an `EXPLICIT_BOUNDARIES` row beyond its
stated file scope, because editing `FORMULA_EVIDENCE` alone would have been
a silent no-op — adaptive or drift?**

**Adaptive**, with one caveat. The row in question
(`rmf-biv-gaussian-spatial-mu12-q2-intercept`, covering `mc-0107,mc-0108`)
was a single combined row asserting one shared "matched labelled block"
claim across two independently-fitted coefficients (`mu1`, `mu2`). The
audit found the two intercepts fail *independently*, by different margins,
against different fixture-level standard errors — meaning the shared-row
representation was not a formatting inconvenience, it was actively
misleading: it let one endpoint's (nonexistent) evidence stand in for the
other's. Correcting only the text of `FORMULA_EVIDENCE` while leaving one
combined row in the generated TSV would have reproduced exactly the defect
this arc exists to fix — a claim covering two things where at most one
(here, neither) is actually supported. Splitting the row so each endpoint
carries its own status and its own evidence text is the substantively
correct fix, and it was applied narrowly (this one row, for a documented,
specific reason) rather than as a general reformatting pass across the
inventory. The caveat: my brief describes this as done "because editing
`FORMULA_EVIDENCE` alone would have been a silent no-op" — a purely
mechanical justification. The stronger and more accurate justification,
found directly in `check-log.md`'s pass-1 entry, is the substantive one
above (the two endpoints fail independently and the combined row concealed
that). I would not want the mechanical framing alone to be read as
sufficient license for future writers to split `EXPLICIT_BOUNDARIES` rows
whenever the alternative is inconvenient — the bar should stay "the
combined row asserts something the split rows show is false," which is what
happened here, not merely "the generator's structure was awkward."

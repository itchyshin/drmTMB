# Rose — closeout audit of the orchestrator's own output (2026-08-11)

**Subject:** the one part of this arc nobody reviewed — the orchestrator's own analytical documents and
self-authored closeout. Commissioned after Melissa's reconciliation
(`c67f039d5`) found that the plan assigned closeout to Melissa *and* Rose deliberately, so a
systems-auditor lens would check the implementer's claims, and Rose was never dispatched.

Rose holds `Read/Grep/Glob/Bash` and cannot `Write`; this file reproduces the returned audit under her
name. Every quantitative finding below was **independently re-verified by the orchestrator against the
rorqual artifact** (`~/g5run/verify_rose.R`) before filing, and all confirmed.

---

## Verdict

**HAND OVER WITH CORRECTIONS.** Three findings must be fixed before the two branches merge; none
invalidates the promotion. The eight promoted rows are numerically clean — I re-derived every number in
them from the artifact and found zero overreach. The 0.99 constant is *defensible* but its supporting
document does not currently establish it: the decisive table contains a verified arithmetic error, the
decisive sentence mixes two bucket conventions, and two sections are stale. And the predicted fourth
error exists — it is a cross-branch contradiction created 20 minutes before the after-task report that
names the very pattern.

## Target 1 — the 0.99 threshold

**1.1 The sensitivity table is wrong in two rows, and they are the two that matter.** The threshold doc
claimed `avail ≥ 0.95 → 277` and `≥ 0.90 → 279`. Correct values are **280 and 280**. No cell below
availability 0.9708 is in band, so nothing is gained anywhere below 0.97. True curve:
**247 / 256 / 272 / 276 / 280 / 280 / 280** at `1 / .999 / .99 / .98 / .97 / .95 / .90`. The doc's
version shows a gentle ramp making 0.99 look like a point on a slope; the real shape is a **step to a
plateau at 0.97**. The doc also omitted the 0.98 and 0.97 rows — the only two bracketing the decision.

*Orchestrator note on cause:* the original table applied `availability & in_band` but omitted the
gate's precision term (`mcse ≤ 0.01`). It scored a predicate that was never the one shipped.

**1.2 The decisive sentence mixes bucket conventions, and the cell that moves is one the gate admits.**
"admits 33 cells, 8 of them from the 0.9–0.99 band … only 9 of 13 sit in band." With `(0.9, 0.99)`
open: 12 cells, 8 in band. With `(0.9, 0.99]` closed: 13 cells, 9 in band. **"8" and "13/9" cannot both
be right.** The cell that moves is `student fixef:mu:x` 0.5x, availability exactly 0.9900, coverage
0.9317 — and the shipped floor is `>=`, so the gate **admits a cell the doc's own table places inside
the zone the recommendation says it "stops immediately before."**

**1.3 "Chosen from the dose-response, not for convenience" is not supported as written.** The
justification actually given — "admits the 25 cells that miss by ≤ 12 replicates of 1200" — is a
**restatement** of "availability ≥ 0.99" (12/1200 = 0.01), not an independent property. The admission
count was in view when the threshold was chosen. This repo pre-registers campaigns as a matter of
course (`61169b204`, `b352116ab`, `822117366`, all within days); this threshold carries no prereg and
no post-hoc disclosure.

*The stronger argument the doc failed to make:* out-of-band rate by availability band is **3/11 in
[0.97, 0.99), 1/16 in (0.99, 0.999], 0/9 in (0.999, 1), 1/248 at exactly 1**. That is a real
discontinuity at 0.99 and it is the defensible basis for stopping there rather than at 0.97.

**1.4 The bucket table verifies, but n = 13 will not carry a shipped constant.** Reproduced exactly
under right-closed buckets: 13 cells, mean 0.9215, min 0.8750, 9/13 in band. **SE 0.0055, so the 95%
interval is [0.9107, 0.9323] — it straddles the 0.925 band floor.** The mean is pulled by two outliers
(0.8750, 0.8883); median is 0.9292. Reporting mean and min but not spread overstates the separation.

**1.5 The (1−p)^1200 algebra is correct; the assumption is unstated and the conclusion over-extended.**
`exp(1200·ln 0.999) = 0.301`, `exp(1200·ln 0.998) = 0.0905` — both check. Independence across
replicates is **never stated**, and the direction matters: positive dependence would *raise*
P(all 1200 usable) and *weaken* the incoherence claim, so the argument is not conservative in the
doc's favour. More importantly it establishes that **all-1200 is a bad rule** and does nothing to
select 0.99 over 0.98 or 0.97. Calling it "the decisive argument" conflates a sound negative result
with an unsupported positive one.

**1.6 Mechanism churn: honestly recorded in substance, two sections stale.** `105b1aeb5` retained
hypothesis (b) in place with its evidence and an explicit refutation — the losing reasoning was **not**
tidied away. But the heading still reads "Two candidate mechanisms — and the second is better
supported" over a body with three where the second is *excluded*; and "What this does not settle" still
calls the heavy-cell question open while §(c) says it is settled.

## Target 2 — the after-task report

**2.1 §12 contains a false claim, and §7a omits its consequence.** "The v2 gate changes scoring for the
G4/G5 missing-response campaign and nothing else." It also changes the truth value of **8 of the 10
held ledger rows' `next_gate` strings** on the sibling branch. This is the single missing §7a item.

**2.2 The three §9 errors are stated fully and without softening.** Each names the mechanism of the
error, not just the fact, and §9 volunteers the root cause of the first. Nothing softened.

**2.3 Verified numeric claims.** All 8 routes: every cell 1200/1200 usable, every coverage in band at
all three rungs — **true**. The two named edge cells are exactly the per-rung minima. `247/43 → 272/18`,
`fail→pass 25`, `pass→fail 0`, lowest availability 0.9900 — **all four reproduce exactly**; max
shortfall among the 25 flips is 12 replicates; 0 of 25 out of band.

**2.4 What a reader needs in order to distrust it appropriately, and does not get.** §5 lists checks
run, but the report never says the *threshold document itself* — the one thing that became shipped code
— went through no reviewer. That is precisely the gap that created this audit.

## Target 3 — shipped public claims

**3.1 The eight promoted rows: clean.** Re-derived independently from `cells.tsv`: every cell count and
all 24 per-rung coverage ranges match the artifact **to the digit**. The `gaussian` boundary volunteers
the unguarded-`interval_method` weakness and the MCAR-only/ML-only scope unprompted. No overreach.

**3.2 The ten held rows contradict the shipped gate. This is the fourth error.** `c040701f6` (06:46)
rewrote every held row's `next_gate` to cite *"the all-1200 interval-usability rule"*; `19e4a1d03`
(07:07) **deleted that rule**. Under v2: `tweedie` **0** availability failures (text says 1/15),
`skew_normal` **0** (says 3/15), `beta`'s "3 of those 11 failed interval availability" false,
`poisson`'s "until both are fixed" false, and four more counts stale. Only `mr-hurdle-nbinom2` is
unchanged. Every count is correct *as of the old rule* — this is staleness on merge, not fabrication —
but once both branches land, the reader-facing ledger says availability blocks `tweedie` and
`skew_normal` while the shipped code says it does not.

The after-task's own §11 reads *"A partial change falsifies the text of what it does not touch. Twice
in one promotion. Nothing mechanical detects it."* The third instance was created between 06:46 and
07:07, appears in neither §7a nor §10, and Melissa's reconciliation did not catch it either. **The team
stated the lesson and reproduced the failure inside the same session.** The missing safeguard is a
merge-time check that no `next_gate` string names a gate predicate absent from the current
`mr_g5_calibration_gate()`.

**3.3 Test coverage of the constant is real.** The foundation test pins availability exactly 1.0,
exactly 0.99 (pass), just below (fail *with* `availability_below_policy_floor`), 0.5 with in-band
coverage, and out-of-band at full availability. §6's description is accurate.

## What I could not check

- **The artifact itself** — remote; all verification was against the committed 290-row rescore CSV.
  (*Orchestrator note: subsequently re-verified directly against the artifact; all confirmed.*)
- **Record-level claims** — "0 of 348,000 used Wald", the 764 non-MLE-anchored records, the 245
  retained at coverage 0.890, the 5/764 detector sensitivity. Not reproducible from committed material.
- **§5 check outputs** — did not re-run the test suites.
- **Replicate independence** for the (1−p)^1200 argument.
- **The `beta` resume** (array `18826926`) — external state.

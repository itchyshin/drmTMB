# Arc 7a — land the earned twelve, and wire the guards that were never run

Date: 2026-08-03 · Lane: Claude Code (solo) · `main` `ca46559f3` → **`5aacb1425`**

## Goal

Land twelve already-earned cell promotions sitting in two conflicted PRs, and make the tracked
ledger invariants actually execute in CI. Explicitly **not** the truth gate — that is Arc 7b,
designed during this arc and briefed at
[`docs/dev-log/handover/2026-08-03-arc7b-truth-gate-brief.md`](../handover/2026-08-03-arc7b-truth-gate-brief.md).

## Implemented

`model_surface` evidence tiers: **172 interval_feasible / 70 point_fit_recovery → 184 / 58**.
`FROZEN_CENSUS_POINT_FIT_RECOVERY` 70 → 58.

- **PR #909** — handover + Prong B brief onto `main` (docs only)
- **PR #907** — `mc-0123`, `mc-0205`, `mc-0206`
- **PR #908** — `mc-0279`, `mc-0282`, `mc-0286`, `mc-0291`, `mc-0298`, `mc-0303`, `mc-0304`,
  `mc-0315`, `mc-0316`; `mc-0292` deliberately withheld
- **PR #910** — B4-CI neighbour guards fixed; CI 3 of 7 → 5 of 7 `tools/tests/` files
- **PR #911** — parity-triage promotion-claim check; the Arc 7b brief

## The Phase-2 review is what made this arc worth running

The plan was written, then reviewed by Rose and Fisher **before execution**. Both returned
PROCEED WITH CHANGES, on four defects that would have shipped a green build over a broken `main`:

1. **#907 promotes `mc-0123` while `tools/tests/test_b3_q6_target_promotion.py` asserts it stays
   `point_fit_recovery` — and nothing ran that file.** Only 2 of 7 files under `tools/tests/`
   were invoked by any runner.
2. **"Union both lanes" on `cells.tsv` would have resurrected `mc-0207`** into the frozen census
   at `point_fit_recovery` — a promotion by merge accident, inside the window the anti-laundering
   guard exists to protect — and dropped `mc-0715`/`mc-0716`. The naive union yields a
   *self-consistent* 59/60 that passes both assertions.
3. **A fourth truth-excluding receipt, `mc-0260m`**, in-cohort with a live runner hash, which
   would red CI the moment a naive truth gate landed. Moved to Arc 7b with a decided disposition.
4. **"Any single seed excluding truth blocks the cell" is not statistically coherent** — it
   falsely rejects 22.6% of correctly calibrated routes at 5 seeds, 33.7% at 8, and has zero power
   against intervals that are too *wide*. Arc 7b's rule was redesigned before implementation.

Reviewing the *decomposition* rather than the output cost two agents and caught all four.

## Findings the arc produced

- **`mc-0424` holds `interval_feasible` on a truth-excluding interval** (`[0.2567, 0.5156]` vs
  true 0.55), with `reviewed_by: tools/arc2_profile_reconcile.py` — the machine named as reviewer,
  and the machine never checked location. Plus `mc-0260m`. Both → Arc 7b.
- **Family-level low bias**: all four nbinom2 structured-sigma cells (`mc-0421`/`0422`/`0423`/
  `0424`, all truth 0.55) are biased low — 11 of 12 estimates below truth, **sign test p = 0.0032**,
  family mean 0.4352 (−20.9%). Demoting only `mc-0424` leaves two siblings on the same estimator.
- **The B4-CI guards were failing against unmodified `main`** on four cells across three reviewed
  arcs, undetected because nothing invoked them.
- **`SOURCE_COMMIT 574c1108e` is not on `origin`** — only on a local-only `codex/*` branch — so
  `integrate_b4_ci_c2/c3/c4` can never run in CI as written. Owner decision pending.
- **A duplicate `mc-0123` registry entry** in `tools/run-arc2-profile-feasibility.R`, silently
  introduced by #907's auto-merge; both copies byte-identical, fixed in #908.
- **89 of 116 "Parked … preserving the existing tier" parity rationales** sit at
  `interval_feasible` or above. That clause is unmaintained boilerplate, not one stale row.

## Checks Run

`python3 tools/capability_ledger.py --check` → `OK (30 generated outputs)`.
`python3 -m unittest tools.tests.test_capability_ledger` → **54 tests OK**.
Adversarial frozen-cell flip, at both merges: `frozen census point_fit_recovery changed: 66
(expected 67)` and `... 57 (expected 58)`, reverted clean.
Both merges gated on a green `ubuntu-latest (release)` R-CMD-check (#907 37m48s, #908 43m13s).

The constant was derived **four independent ways** before being accepted: the executing lane's two
derivations, an orchestrator recount, and `capability_ledger.py --check` exercising the generator's
own frozen-census validation. A raw `awk` over `cells.tsv` returns 71 against a true 70 — it counts
the one `missing_response` row inside the frozen window — which is exactly why derivation-by-projection
was mandated rather than counting.

## Independent Verification (Rose, fresh context)

Verdict: **CLEAN WITH FINDINGS.** Rose reviewed the *plan* before execution and returned four
blockers; this pass re-checked whether the *output* closed them, deriving every number herself
rather than accepting the report.

All four closed. `mc-0207` = `none`, `mc-0715`/`mc-0716` present, `mc-0292` withheld — no union
occurred. `test_b3_q6_target_promotion.py` passes and is wired at `R-CMD-check.yaml:83`, and it
now conditions on `C4_B3_PAIRED_MU1_IDS` so it cannot drift from `test_capability_ledger.py`.
Her independent derivation of the frozen constant gives **58**, matching both the module constant
and the deliberately-separate literal — and she reproduced the counting trap, noting the naive
all-axis count gives 59, inflated by one `missing_response` row. `model_surface` confirmed at
184/58, with transitions accounting for exactly twelve promoted cells. The frozen-census guard
still bites (`57 (expected 58)`), restored byte-identical. No duplicate cell keys, no live stale
tier claims across all 177 parity rows.

Her findings, all gaps rather than regressions:

- **F1 — the arc was landing without its record.** The after-task report and the arc's only new
  guard both sat in unmerged #911 while `main` already carried the promotions. Merging #911
  closes it, and the point stands: *a landed arc whose guard is unmerged is the exact failure
  that guard exists to prevent.*
- **F2 — #911's check reads only `rationale`.** Seven rows name a tier in `not_covered`. **Acted
  on**: the check now searches both columns. Verified a no-op today (no row carries the claim
  phrase there) and a guard against the phrasing migrating.
- **F3 — the team discloses debt well and retires it slowly.** 89 stale parked rationales and
  four CI-excluded tests are both honestly named, both need an owner decision, neither has a
  deadline.
- **Missing owner** — the B4-CI base-commit question (is #905's Arc-4b split an approved base
  change for those closures?) is a one-line call blocking four tests, and nobody holds it.

## What Did Not Go Smoothly

- **Nine premature parity-triage claims were my error.** The brief for #907 listed all twelve
  parity rows when only three belonged to it, so nine rows asserted promotions the ledger had not
  made. #908 closed the window by making them true. PR #911 adds the check that would have caught it.
- **Four CI runs on one PR.** After a content fix I amended a commit message and force-pushed,
  which — under `concurrency: cancel-in-progress` — stacked runs that killed each other, one 45
  minutes into an R-CMD-check. A ~40-minute run spent on a cosmetic fix, against the standing rule
  to keep Actions cheap. Applied immediately afterwards: the next lane batched its dedup fix into a
  single push rather than two.
- **I gave the executing lane a wrong instruction and it was right to refuse.** I told it to unstage
  two files from the arc6 branch, believing they re-added landed work. They were byte-identical to
  `main` and were being carried forward by an ordinary merge; executing my instruction would have
  reverted them to the fork point and made #908 look like it reverts #907. It checked, pushed back
  with evidence, and did not comply. That is the behaviour to keep.
- **Two agents were dispatched with tool sets that could not do the job** — the architecture
  reviewer had no `Write`, so its enumeration had to be transcribed by hand; the user-tester lens
  had no `Edit`. Check the roster's tool grants before writing an output contract that needs them.

## Team Learning

**A guard's definition of done includes the line in CI that runs it.** Three guard defects surfaced
in one day — the reconciler's truth blindness, the B4-CI neighbour pins, and the parity-triage
claims — and all three share one shape: *a claim recorded in one place about the state of another,
with no mechanical link between them.* Prose asserting a fact is the cheapest thing to write and the
least likely to be maintained.

The counter-lesson matters as much: **do not turn every recorded claim into a check.** 89 parity
rows would have failed a plausible-looking rule. The right response was to check the 12 that are
precise and document why the 116 are not — not to widen until it broke, nor to abandon the idea
because part of the corpus was untidy.

## Known Limitations

`integrate_b4_ci_c2/c3/c4` remain unwired pending the `SOURCE_COMMIT` decision. The 89 parked
rationales remain unrepaired. Neither is a regression; both are named in the workflow and in
`docs/dev-log/after-task/2026-08-03-b4-ci-mc-0207-pin-drift.md` rather than left silent.

## Next Actions

1. **Arc 7b** — the truth gate, briefed and settled. Expect **184 → 182**; that is the gate working.
2. **Prong B Tier 1** — 14 cells, first `R/` change; after 7b, because its review burden is what the
   gate exists to carry.
3. Owner decisions: q12; B4-CI `SOURCE_COMMIT`; the parked parity corpus; the stale
   `.git/index.lock` in the primary checkout, which needs a human `rm`.

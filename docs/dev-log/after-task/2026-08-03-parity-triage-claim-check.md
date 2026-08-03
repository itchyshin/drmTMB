# parity-triage.tsv: check the one claim that is checkable, and say why the rest are not

Date: 2026-08-03 · Lane: Claude Code · Branch: `claude/parity-triage-claim-check`

## Goal

`docs/dev-log/dashboard/parity-triage.tsv` carries a free-text `rationale` per cell;
`capability-ledger/cells.tsv` carries that cell's `evidence_tier`. Nothing reconciled the two,
and they disagreed. Add a check narrow enough that it cannot produce false positives on the
existing corpus, and wire it where CI already runs.

## The trigger

On 2026-08-03, PR #907 rewrote the parity rationale for **twelve** cells to read *"An
interval-feasibility campaign has since run and promoted this cell to interval_feasible"* —
but promoted only **three**. For nine cells (`mc-0279`, `mc-0282`, `mc-0286`, `mc-0291`,
`mc-0298`, `mc-0303`, `mc-0304`, `mc-0315`, `mc-0316`) the rationale asserted a promotion the
ledger had not made. PR #908 later promoted those nine, so the window closed by luck rather
than by design. Nothing would have caught it had #908 stalled.

(The twelve-row instruction was mine, in the brief for #907. The lane executed it faithfully.)

## What the corpus actually looks like

Before designing a contract, all 177 rows were classified by rationale template and joined to
the live tier. This is the load-bearing finding, and it changes the shape of the answer:

| rationale template | rows | current tiers |
|---|---:|---|
| `Parked: next_gate directs preserving the existing model-surface evidence tier…` | 116 | **89 at `interval_feasible`**, 26 `point_fit_recovery`, 1 `none` |
| `An interval-feasibility campaign has since run and promoted this cell to <tier>` | 12 | 9 `point_fit_recovery`, 3 `interval_feasible` (before #908) |
| `Frontier per governing rule: …` | 25 | mixed |
| one-offs (`Not frontier: …`, `Parked for comparator work…`, …) | 24 | mixed |

**Only the promotion template makes a checkable claim.** The parked template says *"no
comparator or interval/coverage campaign is being pursued for this cell now"* — and **89 of
its 116 rows sit at `interval_feasible` or above.** That clause is unmaintained boilerplate,
not a live assertion.

This corrects the premise the task started from. The brief named `mc-0424` as a singular
long-standing inverse failure. It is not singular: `mc-0424`'s rationale prefix is
**byte-identical** to the other 88, and it carries the same `triage_class: parked`. There is
nothing about that row a checker could distinguish. Any rule over the parked template would
report **89 failures on a clean tree**.

There is also a defensible reading under which those 89 are not even false — *"is being
pursued … now"* is present tense, and a campaign that finished is not one being pursued. That
ambiguity is precisely why the check does not go near it.

## Implemented

A single block in `tools/capability_ledger.py::validate()`, immediately after the existing
parity-triage checks (which already build `parity_by_cell`). It fires only on the exact phrase
`promoted this cell to <tier>`, with `<tier>` drawn from the module's existing
`EVIDENCE_TIERS`, and requires `cells.tsv` to agree:

```
mc-0279: parity triage claims promotion to interval_feasible, ledger evidence_tier is point_fit_recovery
```

Because it lives in `validate()`, it runs under `capability_ledger.py --check`, which CI
already invokes — no new wiring, and it cannot become a guard nothing runs.

## Files Changed

- `tools/capability_ledger.py` — the promotion-claim reconciliation in `validate()`
- `tools/tests/test_capability_ledger.py` — three tests:
  - `test_parity_triage_promotion_claims_match_the_live_ledger` — the live corpus is consistent,
    and asserts the phrasing still exists at all, so the guard cannot quietly become dead code
    if the template is reworded
  - `test_parity_triage_promotion_claim_contradicting_the_ledger_is_rejected` — demote a claimed
    cell, expect rejection
  - `test_parked_parity_rationales_are_deliberately_unchecked` — pins the 89-row finding, so that
    if someone repairs the parked corpus the test fails and prompts a decision to widen the check.
    A deliberate tripwire on a *known limitation*, rather than leaving the reasoning in a comment.

## Checks Run

The check was validated against two ledger snapshots, which is the strongest available evidence
that it catches the real defect and nothing else:

| ledger state | promotion-claim errors |
|---|---|
| `origin/main` (= post-#907, the defect live) | **9** — exactly `mc-0279/0282/0286/0291/0298/0303/0304/0315/0316` |
| `origin/claude/arc6-gaussian-nine` (= #908) | **0** |

Zero false positives across all 177 rows in both states.

## Known Limitations

**It checks one sentence pattern.** A rationale that asserts a promotion in different words is
invisible to it. That is the deliberate trade: the alternative is parsing English, and the
corpus shows why that fails — the same template means different things depending on whether you
read "is being pursued" as present or perfect.

**The parked corpus stays unrepaired.** 89 rows assert something that is at best uninformative
and at worst false. Repairing them is a separate, larger job requiring a decision about what
those rows are *for*: if the clause is never maintained, the honest fix may be to delete it
rather than to update 89 rationales that will drift again.

**It cannot land before #908.** On current `main` the check correctly rejects, so
`load_sources()` raises and even the test suite's `setUpClass` cannot run. That is the guard
working as designed, but it means this branch must be rebased onto a `main` that already
carries #908.

## Team Learning

Three guard defects surfaced in one day — the `arc2_profile_reconcile` truth blindness, the
B4-CI neighbour pins, and this — and all three share a shape: **a claim recorded in one file
about the state of another, with no mechanical link between them.** Prose asserting a fact is
the cheapest thing to write and the least likely to be maintained.

The counter-lesson from the corpus survey is just as important: **do not turn every recorded
claim into a check.** 89 rows here would have failed a plausible-looking rule, and the right
response was to check the 12 that are precise and document why the 116 are not — rather than
either widening the check until it broke, or dropping the idea because part of the corpus was
untidy.

## Next Actions

1. Rebase onto `main` once #908 lands; confirm `--check` clean and the three tests green.
2. Separate decision: repair or delete the "no comparator or interval/coverage campaign is
   being pursued" clause across the 116 parked rows. Only then consider widening the check.

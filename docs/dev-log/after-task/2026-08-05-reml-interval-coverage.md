# After-task — REML and profile interval coverage: measured, claim withheld

**Date:** 2026-08-05 · **Platform:** Claude (Claude Code), solo ·
**Lane:** drmTMB — turning REML's point-estimate debiasing into an interval claim ·
**Foreign lane:** codex, draft PR #858 — no overlap.

## 1. Goal

A seeded, **pre-registered** measurement of whether `REML = TRUE` moves profile interval coverage
for an ordinary sigma-axis random-effect SD toward nominal, plus the decision record either way.
Promote nothing.

## 2. Outcome

**Measured on 6 cells × 1000 paired replicates. The pre-registered headline claim is NOT ADMITTED.**

Condition 1 passed (REML helped in 2 of 3 `n_each = 10` cells). **Condition 2 failed** — the
`n_each = 3` falsifier fired in 2 of 3 cells when the rule required none. By the rule as written,
the claim is withheld.

Verdict: [`2026-08-05-reml-interval-coverage/VERDICT.md`](../simulation-artifacts/2026-08-05-reml-interval-coverage/VERDICT.md).

## 3. What was actually found

REML's profile interval covered at least as well as ML's in five of six cells and significantly
better in four. The **mechanism differs by regime**: at `n_each = 10` REML shifts the interval up
toward truth and widens slightly; at `n_each = 3` it shifts down and *narrows* yet still covers
better, by producing fewer extreme collapses in **both** tails.

The sharpest result is one the design did not anticipate: **point-estimate bias and interval
calibration move in opposite directions at `n_each = 3`.** REML makes the estimate worse and the
interval better.

## 4. The falsifier fired, and the investigation cleared the harness

The pre-registration required treating a `n_each = 3` win as a suspected harness defect and
investigating before reporting. Four checks, all in `ADJUDICATION.txt`:

1. **It reproduces the repo's committed 2026-07-08 probe, including its sign reversal** — REML's
   point estimate is worse at `n_each = 3` (−0.0196 / −0.0095 / −0.0087) and better at
   `n_each = 10` (+0.0215 / +0.0106 / +0.0059). A harness that independently reproduces a committed
   finding is not plausibly the source of the anomaly.
2. **Both miss directions improved with narrower intervals** (`g10_ne03`: lower 37→15, upper 54→27,
   width ratio 0.885). Widening cannot do that; only better positioning can.
3. **Not a boundary artifact** — the gain appears both at (+0.0451) and away from (+0.0561) the boundary.
4. **Survivorship near-complete** — 991/1000 paired; the 9 exclusions favour REML slightly and are
   recorded as a caveat rather than dismissed.

## 5. The pre-registration's own defect

**The falsifier was mis-specified.** It inferred from "the probe says REML underperforms at
`n_each = 3`" that REML helping on *coverage* there implied a broken harness. The probe's claim is
about the **point estimate**; the falsifier tested **interval coverage**. Different estimands — and
this campaign shows they genuinely diverge.

**I have not used that to rescue the claim.** I wrote both the rule and this reinterpretation,
which is precisely the move pre-registration exists to prevent, so the verdict stands at NOT
ADMITTED and the question of whether a corrected falsifier would change it is routed to Rose and
the owner. This is the same discipline D-117 applied to itself.

## 6. Decisions

1. **Withhold the headline claim.** The rule as written returns NOT ADMITTED; measurement stands.
2. **Change no default.** `REML` remains opt-in regardless.
3. **Promote no census cell.** 182 / 60 verified before and after.
4. **Record the mis-specified falsifier as a lesson**, not as grounds for re-scoring.

## 7. Verification

- Pre-registration committed at `041905883` (07:16:39) **before** any campaign fit — the deviation
  that the previous arc incurred and this one deliberately did not repeat.
- Smoke: 1 cell × 5 replicates on 1 core before the grid; non-empty, in-range, both arms converged.
- Paired design: ML and REML fitted to **identical** simulated data per replicate.
- Convergence-and-`pdHess` rate ≥ 0.998 in every cell and arm.
- Census **182 / 60**; `capability_ledger.py --check` OK; `check-evidence-citations.R` clean.

## 8. Test-suite result

No `R/` change was made; the package suite is untouched from `e430d408a`, where it last ran green
(308 files, 0 failures). This arc adds only `docs/`.

## 9. Deferred, explicitly

Untouched: the 135-trace interval campaign; the full 7-method coverage-mapping grid (this was one
method contrast, deliberately); `predict()` scale-axis (its gate test **pins** current behaviour
and must fail when `predict()` is fixed); the CI guard/check split; B4-CI `SOURCE_COMMIT`; mc-0282.

## 10. Open for the owner

- **Does a corrected falsifier change the verdict?** The mis-specification is documented and the
  data confirms the probe's actual (point-estimate) claim. Re-scoring against a corrected rule
  would admit the headline — but that decision is not mine to make after seeing the data.
- **Is this worth a design doc?** "REML improves interval calibration while worsening point bias at
  very low replication" is a real, novel, cross-repo-relevant finding. It is currently only in this
  verdict.
- **D-117 discharge** — unchanged recommendation: yes.

## 11. Reusable lesson

**A falsifier must test the same estimand as the evidence it is derived from.** This one was built
from a *point-estimate* ladder and applied to *interval coverage*, so it fired on a real and
interesting divergence rather than on a defect. The pre-registration still did its job — it forced
the investigation that produced the finding, and it stopped a claim that would otherwise have been
waved through on 4-of-6 significant results. **A rule that fires for the wrong reason is still
better than no rule**, provided you report that it fired rather than quietly re-scoring.

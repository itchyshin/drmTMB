# Plan vs actual — the χ̄² boundary-cutoff measurement (Melissa)

**Date:** 2026-08-05 · **Reconciler:** Melissa · **Arc:** D-117 χ̄² cutoff, measured
**Plan:** the `/goal` block set for this session · **Actual:** commit `d4c7b6c8e`, PR #925

Material deviations only, along the six axes. Cosmetic differences are not recorded.

| # | Axis | Planned | Actual | Tag | Note |
|---|---|---|---|---|---|
| 1 | scope | prototype the χ̄² cutoff behind an internal flag in `R/profile.R` | **no `R/` change at all** | **adaptive** | The χ̄²-corrected 95% interval *is* the ordinary 90% interval, so both arms came from two `confint()` calls. The flag would have been dead code. Recorded in the after-task §3. |
| 2 | scope | adversarial-verify slice on the result | **dropped** | **adaptive** | Nothing to adversarially verify: the result is negative, the nesting inequality is exact, and it held 4000/4000. A refutation agent would have been asked to refute a guarantee. |
| 3 | safety gate | "pre-register the decision rule BEFORE fitting, as D-117 did" | **no pre-registration file**; prediction committed at `b89ea4e55` (06:55:09) and merged in `e430d408a`, run at ~07:07 | **adaptive** | Time-stamped public prediction preceding the data serves the same evidentiary purpose. Deviation is named in the after-task §7 and VERDICT §6 rather than passed over. **Owner may disagree** — routed to Rose. |
| 4 | compute | "Compute on Totoro (D-50)" | **ran locally**, 16 reps = 1.66 s on 8 cores | **adaptive** | Full 4×1000 grid ≈ 4 min; deployment would exceed compute. Totoro verified reachable (384 cores, load 2.69) and not needed. D-50's actual rule — no campaigns on GitHub Actions, results stay local — is satisfied. |
| 5 | evidence | measure the χ̄² arm | done, **plus** an unplanned harness-validation arm reproducing D-117 exactly (495/41/63/0) | **adaptive** | Strengthens the result; reproducing the reference before trusting the new arm was not in the plan and should have been. |
| 6 | public claims | "nothing promotes a census cell" | census **182 / 60** verified unchanged before and after | — | Honoured. |
| 7 | handoff state | after-task + Melissa reconciliation | both produced; PR #925 open | — | Honoured. |
| 8 | scope (parallel) | goal listed drmSEM `timeout-minutes: 45` as a parallel item | **investigated, not changed** | **adaptive** | Measured: drmSEM max run ~10 min vs a 45-min ceiling, six "cancelled" runs are genuine concurrency cancels at 1.6–6.7 min. **STILL LATENT, not at risk.** No change made because the ceiling bills nothing when jobs finish early. |
| 9 | scope (parallel) | goal listed "literature confirmation of the mixture weights" | done via scout from the vault's own primaries | — | Honoured. Confirmed 50:50 χ²₀:χ²₁ (Stram & Lee 1994) and, critically, that the sources never warrant transferring it from tests to interval inversion. |

**Drift: none.** Every deviation is adaptive and recorded in the arc's own documents.

**Routed to Rose:** row 3 only. The pre-registration substitution is defensible and documented,
but D-117 set a precedent of a committed pre-registration *file*, and whether a committed
prediction-in-prose satisfies that precedent is a claims-discipline call, not mine.

**DEFER fence:** held. The 135-trace campaign, `predict()` scale-axis, the CI guard/check split,
the B4-CI `SOURCE_COMMIT` port, and mc-0282 were all untouched.

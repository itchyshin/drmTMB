# Plan vs actual — the REML interval-coverage arc (Melissa)

**Date:** 2026-08-05 · **Reconciler:** Melissa · **Arc:** REML vs ML profile interval coverage
**Plan:** the `/goal` block + `PREREGISTRATION.md` (`041905883`) · **Actual:** this branch

Material deviations only, six axes.

| # | Axis | Planned | Actual | Tag | Note |
|---|---|---|---|---|---|
| 1 | safety gate | pre-register BEFORE fitting (D-117's pattern) | **done** — `041905883` at 07:16:39, campaign after | — | **Honoured.** This was the previous arc's recorded deviation and it was deliberately not repeated. |
| 2 | evidence | smoke 1 cell × 5 reps before any grid | done, on 1 core | — | Honoured. |
| 3 | compute | "Totoro, 384 cores, cap 150" | **ran locally**; grid ≈ 7 min (32 reps of largest cell = 3.19 s on 16 cores) | **adaptive** | Pre-registration §9 fixed this rule *in advance* ("under ~10 min locally → local"), so this is a pre-authorised branch, not an after-the-fact choice. Totoro verified reachable and unused. D-50 satisfied. |
| 4 | scope | 6-cell grid, paired arms, ML vs REML × Wald/profile | delivered exactly | — | Honoured. |
| 5 | public claims | "a measured answer plus the decision record either way" | measured; **headline NOT ADMITTED** by the pre-registered rule | — | Honoured, in the harder direction. |
| 6 | safety gate | falsifier at `n_each = 3` | **fired**, investigation run as required, harness cleared | — | Honoured — and the falsifier turned out to be **mis-specified** (built from a point-estimate ladder, applied to interval coverage). Documented as a defect in the rule, **not** used to re-score. |
| 7 | evidence | width guard | applied; result **mixed** — calibration unambiguous at `n_each = 3` (narrower + better), ambiguous at `n_each = 10` (wider) | — | Honoured. Notably the clean evidence landed in the cells the design treated as controls. |
| 8 | scope (parallel) | (a) REML admissibility, (b) g-sweep design, (c) Wald-vs-profile D-12 contrast | all three delivered | — | (a) confirmed by a real fit, not a symbol probe. (c) reported as exploratory, gating nothing. |
| 9 | handoff | after-task + Melissa reconciliation | both produced | — | Honoured. |

**Drift: none.** Every deviation is adaptive or pre-authorised.

**Routed to Rose:** row 6. The falsifier's mis-specification is documented and the harness is
cleared on four independent checks, but re-scoring against a corrected rule *after seeing the data*
is a claims-discipline decision the producing agent must not make for itself. The verdict therefore
stands at NOT ADMITTED pending that call.

**Notable, for the drift ledger:** this arc's pre-registration **worked** — it forced an
investigation that produced the arc's most interesting finding (bias and calibration diverging at
low replication) and it blocked a claim that 4-of-6 significant results would otherwise have
carried. Log as a *win* for the practice, not only as a gate that fired.

**DEFER fence:** held. 135-trace campaign, 7-method grid, `predict()` scale-axis, CI guard/check
split, B4-CI `SOURCE_COMMIT`, mc-0282 all untouched.

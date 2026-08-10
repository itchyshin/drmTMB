# Prediction outcome — the pre-registration was WRONG

Written 2026-08-09 immediately after cell 4 returned, before the remaining cells finished, so the
record cannot be shaded by later results.

`PREREGISTRATION.md` (committed `ab83638f5`, before any 100,000-replicate fit) predicted:

> `g10_n04_sd05` scores 0.915773 → **BORDERLINE**, so **OVERALL: BORDERLINE — D-117 does NOT
> discharge on the frozen rule.**

and named its own falsification condition:

> Raw coverage for `g10_n04_sd05` lands **≥ 0.916227** → cell PASSES → overall PASS → D-117
> discharges on the frozen rule, and my prediction was wrong. **Record it as wrong.**

## That condition was met. The prediction is falsified.

| quantity | predicted (assuming truth = 0.9140) | measured at n = 100,000 |
| --- | --- | --- |
| raw coverage | 0.9140 | **0.922900** |
| MCSE | 0.0008866 | 0.0008435 |
| score `cov + 2·MCSE` | 0.915773 | **0.924587** |
| threshold (raw must be ≥) | 0.916227 | 0.916313 |
| **cell verdict** | **BORDERLINE** | **PASS** |
| finite intervals | — | 100000 / 100000 |

## Why the prediction failed — and why that is not an excuse

The 2026-08-04 point estimate of **0.9140** was itself a low Monte-Carlo draw. The gap to the
measured 0.9229 is **+0.0089**, which is **1.00 × MCSE(n=1000) = 0.00887** — a textbook one-sigma
fluctuation, entirely unremarkable.

The pre-registration did state this explicitly (*"genuinely uncertain and could be wrong in either
direction"*, citing the exact CI **[0.894880, 0.930637]** which straddles the threshold). The truth
landed **inside that interval, on the upper side**. So the uncertainty was correctly characterised;
the **point prediction** was simply wrong.

**The honest reading.** The concern that motivated this arc — that the PASS was an artifact of the
`+2×MCSE` margin at n=1000 — was a legitimate hypothesis and is now **refuted by measurement**.
The cell does not scrape over on a shrinking margin. It clears the floor **on raw coverage**, with
roughly ten times the precision, and the margin rule is no longer doing any work:
`0.9229 > 0.918` even before the MCSE term is added.

Had the arc not been run, the PASS would have rested on a number that happened to be a sigma low.
It now rests on a number that does not need the margin at all. **The experiment was worth running
and it answered against the hypothesis that prompted it.** Both halves of that sentence are the
point.

## What this does NOT establish

- **It is not a discharge.** Overall PASS requires all four cells; the remaining cells are still
  running as this is written. And the pooled gate is only one input — the open D-43 panel findings
  and a fresh panel still stand between this number and a discharge recommendation.
- **It does not vindicate the `+2×MCSE` rule.** `VERDICT.md §2.4` calls it anti-conservative and
  that criticism is untouched by this result. The rule simply did not matter here.
- **It does not resolve the conditional-coverage question.** See `VERDICT-100K.md`.
- **It says nothing outside the A1 scalar Gaussian corner** — `TRUE_BETA = 0.5`, residual
  `sigma = 0.7`, one mean formula, `n_per ∈ {4,10}`, `sd_mu ∈ {0.5,1.0}`, `g = 10`.

## A note on the `ss_floor` observation

`PREREGISTRATION.md` logged, as a finding held separate from the verdict, that
`ss_floor(g) = 0.95 − 0.04 × (8/g)` depends on `g` alone and ignores `n_per`/`N`, so the N=40 cells
are held to the same bar as the N=100 cells.

That observation is **unchanged and now less load-bearing**: the N=40 cell cleared the bar anyway.
It was recorded *before* results precisely so it could not later look like a rescue, and it did not
need to be one. It remains a legitimate question about the floor's calibration for a future,
separately pre-registered arc — not a live issue for this verdict.

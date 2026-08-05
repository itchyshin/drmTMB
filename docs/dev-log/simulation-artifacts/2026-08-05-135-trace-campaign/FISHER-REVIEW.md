# Fisher location review — 135-trace PASS cells (clause 10)

Reviewer role: Fisher (inference / location vs shape).
Date: 2026-08-05. Source SHA: `6618e4b30303f7815b272f709ac2c8d09089132d`.
Mechanical ten-clause board: `CELL-VERDICTS.md` (5 PASS / 9 WITHHOLD).

## Scope

Only cells that cleared clauses 1–9 on **every** retained seed are reviewed
here. WITHHOLD cells are not location-reviewed for promotion.

## PASS cells — location finding

| cell | seeds | truth | mean\|max rel_err | mean width | truth vs mid (half-widths) | location call |
|---|---:|---:|---|---:|---|---|
| mc-0568 | 5/5 | 0.45 | 0.112\|0.162 | 0.225 | mean 0.27 / max 0.49 | **PASS** — truth interior on all seeds |
| mc-0576 | 5/5 | 0.45 | 0.101\|0.251 | 0.222 | mean 0.34 / max 0.999 | **PASS with note** — seed `22260809` upper endpoint 0.45014 sits on truth; still brackets; not a miss |
| mc-0595 | 5/5 | 0.45 | 0.102\|0.234 | 0.384 | mean 0.24 / max 0.74 | **PASS** — wider structured intervals; truth interior |
| mc-0596 | 5/5 | 0.45 | 0.087\|0.308 | 0.401 | mean 0.38 / max 0.58 | **PASS** — same |
| mc-0653 | 5/5 | 0.60 | 0.094\|0.127 | 0.373 | mean 0.28 / max 0.51 | **PASS** — 8×8 campaign DGP; truth interior |

No PASS cell shows a shape-only green (finite interval that systematically
excludes the true value). Clause 8 already required every seed to bracket
truth; this review confirms the intervals are not vacuous clamps and that
point estimates sit inside `[lower, upper]` with two-sided LR support.

## Structured-σ claim boundary (required on promote)

`mc-0595`, `mc-0596`, `mc-0653` must carry `claim_boundary` text naming:

1. documented ML sigma-axis low bias at small/moderate group counts, and
2. REML unavailable for these families / routes.

Ordinary cells `mc-0568` / `mc-0576` need interval-feasibility caveats
(no coverage claim) but not the structured-σ REML sentence.

## WITHHOLD (not promoted)

`mc-0593` (early-stop seed1 + one miss), `mc-0594` (max rel_err 0.406),
`mc-0597` (collapse), all five q2 cells (`mc-0418`…`mc-0454`), and
`mc-0425` (4/5 — one seed rel_err 0.355 > 0.35). Per preregistration,
**4/5 truth-bracketing is a BLOCK**.

## Verdict

Promote the five PASS cells to `interval_feasible` after ledger / FROZEN /
NEWS / claim_boundary edits. Do **not** move the census by the aspirational
+14; move by **+5** only (`FROZEN_CENSUS_POINT_FIT_RECOVERY` 59 → 54).

# Plan vs actual — 135-trace Prong B (2026-08-05)

| Plan (ultra-plan / prereg) | Actual |
|---|---|
| Build grid-engine 14-cell runner with real clamp/LR/truth | Done (`tools/run-135-trace-campaign.R`); 135 jobs emitted |
| C1 re-smoke `mc-0568` with tmbprofile | Done locally and on Totoro; CI agree to ~1e-5 with prior endpoint smoke |
| Totoro ≤100 cores after owner go | Done at **64** cores via GNU parallel; standing Totoro access used |
| Ten-clause + Fisher review | Done; 5 PASS / 9 WITHHOLD (`CELL-VERDICTS.md`, `FISHER-REVIEW.md`) |
| Promote only PASSes; census +14 if all clear | Promoted **5**; census **+5** (182→187 IF; frozen PFR 59→54), not +14 |
| Structured-σ claim_boundary ML bias + REML | Present on `mc-0595`, `mc-0596`, `mc-0653` |
| Never hard-code `clamp_limited=FALSE` | Honored; receipts use `clamp_limited_source=computed_from_profile` |
| Fence #858 / D-117 / #926 / coi / primary debris | Held |
| `profile_engine="grid"` wording in early todos | Package API is `tmbprofile`; that is the grid path |

## Surprises

1. `mc-0597` (zob phylo_interaction sigma) collapsed (mean rel_err 0.91) —
   WITHHOLD.
2. All five labelled count-`mu` q2 cells failed mostly on correlation /
   intercept targets (boundary + truth misses) — WITHHOLD as a group.
3. `mc-0425` was 4/5 with one seed rel_err 0.355 > 0.35 — BLOCK per
   preregistration, not an 80% pass.
4. Early-stop fired on `mc-0593` seed1 (rel_err 0.287 > 0.25 structured
   gate) and contributed to WITHHOLD.
5. Review script briefly zeroed all clauses via `isTRUE()` on vectors;
   fixed before promotion (`true1` / `%in% TRUE`).

## Residual open (owner, not this lane)

- D-117 discharge judgement (PASS remains withheld).
- Whether to re-pilot WITHHOLD cells (q2 design / `mc-0597` DGP) under a
  **new** preregistration.
- Push / PR for `cursor/135-trace-campaign`.

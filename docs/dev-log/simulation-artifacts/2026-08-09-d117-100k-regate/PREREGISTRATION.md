# Pre-registration — D-117 10-group profile gate, re-run at nrep = 100,000

**Committed 2026-08-09, BEFORE any 100,000-replicate fit was run.** Written by Claude in the
`claude/d117-discharge` lane, worktree off `origin/main @ a2695a788`.

This document exists so the verdict cannot be reverse-engineered from the results. If any
prediction below is wrong, that fact stays on the record.

## Why re-run at all

The 2026-08-04 gate scored every cell PASS, but the worst cell passes **only on the Monte-Carlo
margin**. The frozen rule is

```
score = coverage + 2 * MCSE      PASS if score >= ss_floor(10) = 0.918
                                 BORDERLINE if score >= 0.880
                                 FAIL otherwise
OVERALL = PASS only if ALL four cells PASS
```

`g10_n04_sd05` has raw coverage **0.9140**, which is *below* the floor; only the `+2×MCSE` term
(0.00887 at n=1000) lifts it to 0.9317. Because MCSE shrinks as 1/√n, the rule converges to a bare
`coverage ≥ floor` comparison as n grows. `VERDICT.md §2.4` already calls the rule anti-conservative
in its own words, and **`VERDICT.md:115` already records that this cell goes BORDERLINE at
n ≳ 19,700** — the source document anticipated this and nobody acted on it.

`nrep = 100000` is **exactly** the maximum safe replication: seeds are
`20260727 + 100000*cell_i + r` with `cell_i ∈ {1,4,5,6}`, so cells 4→5 and 5→6 abut without
colliding at r = 100,000 and **collide at 100,001**.

## Predictions (the falsifiable part)

Assuming the true coverage equals the 2026-08-04 point estimate, MCSE(100k) and the resulting
pass threshold on **raw** coverage are:

| cell | n_per | N | 2026-08-04 raw coverage | MCSE(100k) | predicted score | pass needs raw ≥ | **predicted verdict** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `g10_n04_sd05` | 4 | 40 | 0.9140 | 0.0008866 | 0.915773 | 0.916227 | **BORDERLINE** |
| `g10_n04_sd10` | 4 | 40 | 0.9290 | 0.0008122 | 0.930624 | 0.916376 | PASS |
| `g10_n10_sd10` | 10 | 100 | 0.9310 | 0.0008015 | 0.932603 | 0.916397 | PASS |
| `g10_n10_sd05` | 10 | 100 | 0.9370 | 0.0007683 | 0.938537 | 0.916463 | PASS |

**PREDICTED OVERALL: BORDERLINE — D-117 does NOT discharge on the frozen rule.**

Note the precision that matters: the predicted per-cell outcome is **BORDERLINE, not FAIL**
(0.915773 clears the 0.880 borderline tier comfortably). But overall PASS requires *all four* cells
to PASS, so a single BORDERLINE is sufficient to withhold the discharge.

**This prediction is genuinely uncertain and could be wrong in either direction.** The 2026-08-04
exact 95% CI for `g10_n04_sd05` is **[0.894880, 0.930637]** (`SUMMARY.csv:2`, Clopper–Pearson),
which **straddles** the 0.916227 threshold. If the true coverage is anywhere above 0.9163, the cell
passes and D-117 discharges on the frozen rule. That is precisely why the experiment is worth
running rather than arguing about.

## What would change my mind

- Raw coverage for `g10_n04_sd05` lands **≥ 0.916227** → cell PASSES → overall PASS → D-117
  discharges on the frozen rule, and my prediction was wrong. Record it as wrong.
- Any cell's finite-interval fraction drops below 0.95 → `FAIL (intervals unavailable)`, a different
  and more serious failure mode than the one predicted here.
- The r ≤ 1000 prefix fails to reproduce the banked 2026-08-04 numbers → the harness has changed
  and **every conclusion downstream is void**, including this pre-registration.

## Frozen — not to be altered by these results

- `ss_floor(10) = 0.918` and the `coverage + 2*MCSE` rule are **unchanged**. No re-scoring on raw
  SD, no dropping the worst corner, no re-specifying the floor to reach a PASS.
- The estimand is **pooled** coverage (Shinichi's decision, 2026-08-09). Conditional-on-boundary
  coverage is reported as a **diagnostic**, not as a gate.

## Reported alongside, as cross-checks only — never as the verdict

1. **A standard one-sided lower confidence bound**, `p̂ − z·SE ≥ floor`, reported next to the frozen
   rule. This is a cross-check that the frozen rule's asymmetry did not drive the outcome. It does
   **not** replace the rule.
2. **Re-estimated conditional coverages.** The 2026-08-04 conditional figures rest on only
   495 / 41 / 63 / 0 boundary events, so the two worst (0.0732 at n=41, 0.2540 at n=63) carry
   SEs of roughly ±8pp and ±5pp. At 100k these grow ~100× in event count, tightening those SEs
   ~10×. **If the conditional picture gets materially worse under precise estimation, that is new
   information bearing on Shinichi's "conditional = diagnostic" decision, and he is to be re-asked.**

## A separate finding, logged here so it cannot later look like a rescue

`ss_floor(g) = 0.95 − 0.04 × (8/g)` is a function of **`g` alone**. It does not reference `n_per`
or total `N`. So `g10_n04_sd05` (**N = 40**) is held to the identical 0.918 bar as `g10_n10_sd05`
(**N = 100**) — 2.5× the data, same demanded coverage. The two cells that struggle are exactly the
two `n_per = 4` cells.

Supporting context, from `dr20-reml-vs-aghq-distilled` (~90 sources): the literature has **no
interval-coverage benchmark for a variance component below m = 25 clusters under any method**;
Maestrini et al. found even REML-corrected methods retain non-negligible bias at m = 25; Josephy et
al. 2016 explicitly declined to report coverage for τ. At M = 10, N = 40 this measures a regime
nobody has benchmarked.

**This observation is recorded as a finding for the decision packet. It is NOT applied to the
verdict.** Re-specifying `ss_floor` to price within-group replication would need its own
pre-registered arc; proposing it *after* seeing results is exactly the goalpost move this arc is
fenced against.

## Provenance

- Worktree `claude/d117-discharge` off `origin/main @ a2695a788`; package version reports `0.6.0`
  (the 0.7.0 bump lives in the release slice, not on main).
- Harness reused unmodified from `2026-08-04-d117-10group-profile-gate/`.
- Smoke gate (S0), 2026-08-09: cell 4, `--nrep=50` — 50/50 converged with `pdHess`, all
  `profile_status = "valid"`, zero NAs, coverage 0.96, boundary incidence 26/50. Seed of replicate 1
  was **20660728**, matching `20260727 + 100000×4 + 1` exactly.
- Known gap: `package_commit` records `NA` when the runner loads via `--repo`/`pkgload` rather than
  an installed build. The worktree HEAD is recorded here instead.

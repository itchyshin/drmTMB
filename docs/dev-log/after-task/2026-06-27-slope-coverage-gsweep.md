# After-task: slope-coverage g-sweep — q2 under-coverage is small-sample, not a method wall

Meta: 2026-06-27 · Claude (ultracode) · Fisher + Curie verified. The keystone
experiment of the "finish the q-series" plan.

## Goal

Decide whether the slope-lane under-coverage (q2: 0.87–0.91; sigma: near-nominal)
is a small-sample (group-count `g`) effect or a genuine method wall, by sweeping
`g` ∈ {8, 16, 32} and watching the coverage trend.

## Implemented

- Added a `GSWEEP_N_GROUPS` env hook to the sigma + q2 coverage runners
  (`make_*_data` reads it; phylo/spatial/relmat scale, animal is a fixed
  8-pedigree and is excluded). Default 8 → current behaviour unchanged.
- Ran sigma (phylo+relmat) and q2 (phylo+relmat) at g=16 and g=32, 300 reps each
  (18 grids), 0 boundary, full finite denominators.

## Result (Fisher + Curie verified, both agree)

- **q2 under-coverage is SMALL-SAMPLE, not a method wall.** Coverage climbs
  monotonically with g (Cochran-Armitage significant for relmat mu1:x/mu2:x and
  phylo mu2:x). The mechanism is confirmed independently: SD-slope **bias shrinks
  −8%(g8) → −6%(g16) → −2%(g32)**. q2 is **surmountable**.
- **sigma Wald is g-robust near-nominal** (a `wald_near_nominal` diagnostic): the
  slope targets decline from over-coverage (0.99) toward nominal as g grows — the
  correct, conservative direction; intercepts hover 0.90–0.94.

## What this does NOT establish (the honesty corrections — Fisher)

- **NOT "supported for g≥32".** At 300 reps MCSE ~0.013–0.018; the pooled q2 g32
  mu-slope coverage is 0.944 with Wilson-95 [0.930, 0.956] — straddles 0.95, lower
  bound below 0.94. **Certifying ≥0.94 needs ≥500 reps at g≥32** (certification
  grid now running).
- **g/N confound**: `n_each=20` is fixed, so larger g also means 2–4× the data.
  Honest framing is "under-coverage shrinks with sample size," not "caused by g".
- **At the deployment g=8, q2 still under-covers 0.87–0.91. That stands.**
- **Coverage ≠ supported.** Interval reliability (width/symmetry calibration) is a
  separate, unmeasured rung. No cell is promoted; `coverage_status` stays
  `planned`; `interval_status` is untouched.
- **Correlation target** plateaus ~0.93 with bias → 0 at g32 → a structural
  Wald-SE-width near-miss (not shrinkage), NOT fixed by g.
- Curie found a real bug: `balanced_tree(n_tip)` fails on non-power-of-2 tip counts
  (g=48 phylo errors) — a runner follow-up; the banked g=16/32 (powers of 2) are
  unaffected.

## Banked

`docs/dev-log/dashboard/structured-re-slope-coverage-gsweep.tsv` (18 diagnostic
rows) + raw grids; registered in the validator (linked cells stay `planned`).

## Checks

- `python3 tools/validate-mission-control.py`: `mission_control_ok`, 18 g-sweep
  rows. Fisher + Curie reproduced every figure from raw `wald_contains` columns
  and ran an independent g=48 relmat confirmatory slice (directionally consistent).

## Next (the re-run plan Fisher specified)

- Certification grid: g=32, **≥500 paired-seed reps** (running now) → certifies the
  q2 g=32 coverage and the sigma coverage at MCSE≤0.01.
- A separate **interval-reliability rung** (width/symmetry) is required before any
  cell reaches `supported`. Coverage alone is necessary, not sufficient.
- Design decision (Rose): whether a g-conditional ("supported for g≥N") claim maps
  to a support-cell promotion, given the deployment cells are g-agnostic.

## Team learning

The g-sweep is the highest-leverage diagnostic in the whole plan: one env-hook +
one fan-out converted a banked *negative* (q2 intervals unreliable) into a
characterized, *surmountable* small-sample effect — while the verification panel
simultaneously stopped the over-claim (no "supported" on 300 reps; coverage ≠
interval reliability). Measuring the wall told us it isn't a wall; the guardrail
told us we haven't climbed it yet.

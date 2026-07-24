# After-task report — Arc 6.5 Bernoulli × Bernoulli

## Purpose and scope

Implemented the approved frozen-margin Bernoulli × Bernoulli latent-normal association lane and its Totoro point-recovery gate. The route is fixed-effect, complete-pair, intercept-only `eta` only; `rho12`, odds ratios, uncertainty, coverage, random effects, weights, offsets, missingness, REML, and capability promotion remain excluded.

## Implementation and validation

Design 235 aligns frozen probabilities, tail-stable thresholds, latent correlation, DGP, and recovery extractor. `associate_pairs()` now evaluates observed binary rectangles through deterministic conditional-normal integration, records numerical diagnostics, preserves margin order, and simulates correlated latent pairs. Focused Arc 6.5 tests cover frozen margins, symmetry, product/normalization, all-state `mvtnorm` oracle agreement, rare tails, simulation, and fences; Arc 6.1/6.2 regressions also passed.

## Compute and result

Totoro retained 220 attempts from `51647467` at `~/hsq_work/arc65-runs/2026-07-24-51647467-r10/`: 180 interior attempts and 40 rare HOLD attempts. Seventeen interior cells passed. One `n=120`, asymmetric, `eta=0.5` cell returned 9/10 estimates, so the predeclared all-attempt recovery gate failed.

## Claim, review, and handoff

Fisher required all-attempt plug-in recovery accounting; Rose caught tail-unstable thresholds and a summary that had excluded unresolved fits. Both were repaired. The terminal result is **HOLD**: PR #821 remains unmerged, no capability ledger changes, and no point-recovery or inference claim. Resume only with a new owner decision; do not rescore failures or merge this source lane.

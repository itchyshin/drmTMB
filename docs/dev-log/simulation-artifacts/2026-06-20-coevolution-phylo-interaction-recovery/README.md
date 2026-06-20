# Coevolutionary phylo_interaction SD recovery (500 reps, 3-cell consistency) — held diagnostic

**Date:** 2026-06-20 · **Author:** Ada (autonomous, owner-directed) · **Outcome:** honest diagnostic, NO cell promotion

Native R/TMB recovery for the **coevolutionary interaction** term — the headline
`A^(p) (x) A^(h)` Kronecker effect of Hadfield et al. (2014) "A Tale of Two
Phylogenies":
`bf(y ~ x + phylo_interaction(1 | host:parasite, tree1 = host_tree, tree2 = parasite_tree), sigma ~ 1)`.
This is **design 178 Stage 0**: validate that the single coevolutionary term
recovers on its own — the honest baseline under any future additive
multi-component fit (Stage 1, engine-gated). It banks a diagnostic, not a
promotion: there is no granular coevolution matrix row, and the aggregate
"Structural dependencies" row cannot be flipped by one sub-type.

## Design (deterministic, `master_seed = 20260620`)

- 3 cells: `n_host = n_parasite = n_sp in {6, 10, 14}` (36 / 100 / 196 host:parasite
  pairs), `n_each = 4` observations per pair. 500 reps/cell (1500 fits).
- Two independent fixed known trees per cell (`ape::rcoal`, phylo correlation
  `cov2cor(vcv(tree))`, unit-diagonal). The coevolutionary effect is drawn from
  `N(0, sd_coev^2 * (A_parasite (x) A_host))` via the Cholesky of the Kronecker
  correlation — an independent DGP, not the model's own internals.
- Truth: `b0 = 0.3`, `b1 = 0.5`, `sigma = 0.4`, `sd_coev = 0.7`.
- Recovered: fixed effects, the coevolutionary SD (`fit$sdpars$mu`,
  `phylo_interaction(1 | host:parasite)`), residual sigma; Wald coverage for the
  two fixed effects.

## Result (`tables/coevolution-recovery-summary.csv`, 0 fit errors, pdHess 1.000)

| target | n_sp=6 | n_sp=10 | n_sp=14 |
| --- | --- | --- | --- |
| **sd_coev** rel bias | **-6.4%** | **-2.5%** | **-1.6%** |
| b1 (slope) rel bias | +0.2% | +0.2% | 0.0% |
| sigma rel bias | -0.4% | 0.0% | 0.0% |
| intercept rel bias | +7.0% | -0.3% | +0.6% |
| slope Wald coverage | 0.940 | 0.960 | 0.962 |
| intercept Wald coverage | 0.906 | 0.922 | 0.930 |

## Finding (honest diagnostic, not a promotion)

- **The coevolutionary SD recovers and is a consistent estimator.** The downward
  bias shrinks monotonically with species count (-6.4% -> -2.5% -> -1.6%),
  the phylogenetic variance-component signature (a scaling bug would give constant
  rel bias). By `n_sp = 14` (196 pairs) the coevolutionary SD is within -1.6%.
- **The coevolutionary SD recovers to within a few percent at modest species
  counts.** Even 14+14 species (196 pairs) recover it to within -1.6%. A tempting
  contrast with the single-tree phylo-SD diagnostic (`2026-06-20-phylo-sd-recovery/`,
  -32% bias at 60 species) is NOT a controlled comparison and should not be read as
  one: that design has one observation per species, whereas this one has `n_each = 4`
  observations per host:parasite pair, so the two differ in both per-level
  replication and total N (144 / 400 / 784 here vs 60 / 120 / 240 there).
  Replication per random-effect level makes a variance component much easier to
  separate from residual noise, so the gap cannot be attributed to the Kronecker
  structure being intrinsically more identifiable. (Four of the five Hadfield
  components were not simulated here, so no ranking among components is claimed.)
  What this artifact establishes is narrower and sufficient: the single
  coevolutionary component, fit alone, recovers honestly at modest N.
- **The slope and residual sigma recover cleanly** at all cells (rel bias <= 0.2%;
  slope Wald 0.940-0.962).
- **The intercept is near-unbiased in the mean but high-variance** (RMSE ~0.26-0.30)
  with mildly under-nominal Wald coverage at few species (0.906 / 0.922 / 0.930) —
  the classic grand-mean / phylogenetic-field confounding (a flat coevolutionary
  field mode aliases the intercept), approaching nominal as species grow.

Implication: the coevolutionary `phylo_interaction()` term, fit alone, recovers
its SD and the regression slope honestly at modest species counts. This is the
empirical Stage-0 baseline for `docs/design/178-coevolution-tale-of-two-phylogenies.md`:
the single coevolutionary component works, so the Stage-1 engine extension (summing
host-main + parasite-main + coevolution) builds on validated ground. The intercept
weak-identifiability and the small-species SD bias are the honest "needs adequate N"
contract the additive model must carry forward.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-coevolution-phylo-interaction-recovery/run.R 500
```

## Boundary

Native R/TMB, Gaussian, ONE `phylo_interaction` structured block, known trees
(`ape::rcoal`), several observations per host:parasite pair, complete data. POINT
recovery of the coevolutionary SD + fixed effects, plus fixed-effect Wald coverage
only — and even the Wald sub-claim is partial at low species: intercept Wald
coverage is below the project's 0.93 floor at n_sp = 6 and 10 (0.906, 0.922),
reaching it only at n_sp = 14 (0.930), while the slope is at nominal throughout
(0.940-0.962). Coevolutionary-SD interval calibration is NOT claimed
(profile/bootstrap not run). A diagnostic of coevolutionary-term recovery — NOT a
cell promotion. No status cell changed.

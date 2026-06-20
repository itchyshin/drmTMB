# Gaussian phylo SD recovery (500 reps, 3-cell consistency) — held diagnostic

**Date:** 2026-06-20 · **Author:** Ada (autonomous) · **Outcome:** honest diagnostic, NO cell promotion

Native R/TMB recovery for a Gaussian **phylogenetic random intercept**,
`bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)`, with a fixed known tree
per cell (`ape::rcoal`, phylo correlation `cov2cor(vcv(tree))`). Unlike the
relmat (known-K) recovery, phylo SD recovery is **weakly identified**, so this
banks a diagnostic finding, not a promotion.

## Design (deterministic, `master_seed = 20260620`)

- 3 cells: `n_sp in {60, 120, 240}`, one obs/species. 500 reps/cell.
- Truth: `b0 = 0.3`, `b1 = 0.5`, `sigma = 0.4`, `sd_phylo = 0.7`.
- Recovered: fixed effects, phylo RE SD (`fit$sdpars$mu`, `phylo(1 | species)`),
  residual sigma; Wald coverage for the two fixed effects.

## Result (`tables/phylo-sd-recovery-summary.csv`, 0 fit errors, pdHess >= 0.998)

| target | n_sp=60 | n_sp=120 | n_sp=240 |
| --- | --- | --- | --- |
| **sd_phylo** rel bias | **-32.1%** | **-9.2%** | **-4.8%** |
| b1 (slope) rel bias | +0.3% | +0.5% | +0.1% |
| sigma rel bias | +1.5% | +0.1% | -0.6% |
| intercept Wald coverage | 0.728 | 0.884 | 0.916 |
| slope Wald coverage | 0.950 | 0.952 | 0.944 |

## Finding (honest diagnostic, not a promotion)

- **The phylo SD is downward-biased and weakly identified.** The bias shrinks
  monotonically with species count (-32% -> -9% -> -4.8%), confirming a
  *consistent but slow* estimator -- genuine phylogenetic weak-identifiability,
  NOT a DGP/scaling artifact (a scaling bug would give constant rel bias). Even at
  240 species the phylo SD is -4.8% biased.
- **The phylo intercept is poorly identified** (Wald coverage 0.73 -> 0.92 as
  species grow; still below the 0.93 floor at 240) -- the classic phylo-mean /
  grand-mean confounding (large RMSE ~0.37-0.47 with near-zero bias).
- **The slope and residual sigma recover cleanly** at all cells.

Implication: phylo structured-effect SD claims need care; the "Gaussian
phylogenetic SD target" and "Structural dependencies" rows correctly stay partial.
This is the empirical grounding for the identifiability concerns in
`docs/design/178-coevolution-tale-of-two-phylogenies.md` -- the double-phylogeny
(Hadfield 2014) model inherits and amplifies this phylo-SD weak-identifiability,
which is why the coevolution plan gates each stage on its own identifiability +
recovery evidence.

Contrast: the relmat (known-K, AR(1)) recovery
(`2026-06-20-relmat-structured-recovery/`) was clean (sd_relmat -1% to -3%) because
the AR(1) K is well-conditioned; the ultrametric phylogenetic correlation is much
more autocorrelated (low effective df for the variance), hence the harder recovery.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-phylo-sd-recovery/run.R 500
```

## Boundary

Native R/TMB, Gaussian, one phylo block, known tree, one obs/species, complete
data. A diagnostic of phylo-SD identifiability -- NOT a recovery/coverage claim,
NOT a cell promotion. No status cell changed.

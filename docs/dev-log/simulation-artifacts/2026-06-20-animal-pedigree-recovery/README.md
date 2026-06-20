# Gaussian animal-model (pedigree NRM) SD recovery (500 reps, 2-cell consistency) — held diagnostic

**Date:** 2026-06-20 · **Author:** Ada (autonomous) · **Outcome:** honest diagnostic, structured sub-type evidence

Native R/TMB recovery for a Gaussian **animal model** (pedigree-based additive
genetic random intercept), `bf(y ~ x + animal(1 | id, A = A), sigma ~ 1)`, with a
genuine pedigree-derived numerator relationship matrix `A` (Henderson's recursive
NRM; parents precede offspring; non-inbred founders so `A[i,i] = 1` and `sd_animal`
is the additive-genetic SD on the `A` scale). This is the **animal** sub-type of the
"Structural dependencies" matrix row (animal / phylo / relmat / spatial / kernel /
SPDE).

## Design (deterministic, `master_seed = 20260620`)

- 2 cells: `n_id in {40, 80}` individuals, `n_each = 6` repeated records/individual.
  500 reps/cell (1000 fits). Fixed known pedigree per cell.
- Truth: `b0 = 0.25`, `b1 = 0.45`, `sigma = 0.4`, `sd_animal = 0.6`.
- Breeding values simulated as `N(0, sd_animal^2 * A)` via `chol(A)`; the model is
  passed the same `A` (an independent DGP at the SD scale).
- Recovered: fixed effects, the animal RE SD (`fit$sdpars$mu`, `animal(1 | id)`),
  residual sigma; Wald coverage for the two fixed effects.

## Result (`tables/animal-recovery-summary.csv`, 0 fit errors, pdHess 1.000)

| target | n_id=40 | n_id=80 |
| --- | --- | --- |
| **sd_animal** rel bias | **-3.1%** | **-1.3%** |
| b0 (intercept) rel bias | +0.2% | +1.6% |
| b1 (slope) rel bias | +0.4% | +0.2% |
| sigma rel bias | -0.2% | +0.1% |
| intercept Wald coverage | 0.936 | 0.924 |
| slope Wald coverage | 0.936 | 0.960 |

## Finding (honest diagnostic)

- **The additive-genetic SD recovers and is consistent**: rel bias -3.1% -> -1.3%
  as individuals grow (the expected ML small-sample downward bias, shrinking with N).
  Near-identical to the relmat (known-K) recovery (-3.0% -> -1.0%), as expected: both
  are known-relatedness GMRFs and the pedigree NRM is well-conditioned.
- **Fixed effects unbiased** (rel bias <= 1.6%); residual sigma unbiased.
- **Fixed-effect Wald coverage at/near nominal** (intercept 0.924-0.936, slope
  0.936-0.960). The intercept cell at n_id=80 (0.924) sits marginally below the 0.93
  floor (~0.5 MCSE; MCSE 0.012) -- the mild grand-mean/relatedness-field confounding.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-animal-pedigree-recovery/run.R 500
```

## Boundary

Native R/TMB, Gaussian, one `animal` block with a known pedigree A, repeated records
per individual, complete data. POINT recovery of the additive-genetic SD + fixed
effects, plus fixed-effect Wald coverage only. RE-SD interval calibration NOT
claimed. Structured sub-type evidence toward the "Structural dependencies" row; not
a standalone cell promotion on its own.

# The spatial range: drmTMB vs sdmTMB vs INLA

**Arc:** drmTMB interval-claim truth audit · 2026-08-15 · lane `claude/lane-interval-truth-audit`

**Why this document exists.** Seven of the eight cells that failed the interval-truth re-check use the
`spatial` provider. Asked whether that indicated a bug in drmTMB's spatial code, the answer turned out
to be: *not a coding bug, but a design property that neither of the obvious comparators shares.*

## The finding in one line

**drmTMB does not estimate the spatial correlation range. sdmTMB and INLA both do.**

| package | route | range / decay | marginal SD | source |
| --- | --- | --- | --- | --- |
| **drmTMB** | `spatial(1 \| p \| site, coords=)` | **FIXED** at `median(pairwise distance)`, a hard-coded heuristic | estimated | `R/drmTMB.R:13403` |
| **drmTMB** | `make_mesh(coords, kappa=)` | **FIXED** — κ supplied by the user | estimated | `R/mesh.R:65-96` |
| **sdmTMB** | `make_mesh()` + SPDE | **ESTIMATED** — `ln_kappa` is a fitted parameter; `range = √8 / κ` | estimated via τ | sdmTMB model description |
| **INLA** | `inla.spde2.matern` / `pcmatern` | **ESTIMATED** — θ = (log τ, log κ); `pcmatern` takes (range, σ) directly as hyperparameters | estimated | R-INLA SPDE docs |

drmTMB's own documentation is explicit and honest about this: `make_mesh` "**neither estimates kappa
nor defines a spatial likelihood**" (`R/mesh.R:70`), and `R/check.R:2978` limits fixed-κ mesh fields to
"point-recovery evidence only". `inst/COPYRIGHTS:4` records that **no source was ported** from sdmTMB;
it is named there as "a possible post-implementation comparator". So the FEM construction
`Q = κ⁴c₀ + 2κ²g₁ + g₂` (`R/drmTMB.R:13104`) is the standard INLA/sdmTMB form and the helper is even
named `make_mesh` — the inspiration is real, but the range parameter is where drmTMB diverges.

Note that sdmTMB *permits* fixing `ln_kappa` — its own guidance is that doing so "can help
convergence", because data are often only weakly informative about κ. So a fixed range is a
recognised, defensible modelling choice. **The issue is not that drmTMB fixes it; it is that drmTMB
fixes it silently and then makes SD interval claims that never disclose the conditioning.**

## Why this produced seven failures

The estimand of `spatial()` is the SD *of a field whose correlation length is assumed known*. When the
data's true correlation length differs from the assumed one, the SD is the only free parameter left to
absorb the mismatch.

In the q4 fixture the mismatch was extreme. The DGP built effects from `K = 0.25^|i-j| + 0.35I`; the
model, given only `coords = (x = 1:60, y = sqrt(1:60))`, built `exp(-d / 18.07)`:

| lag | DGP `K` | model |
| ---: | ---: | ---: |
| 1 | 0.250 | **0.942** |
| 10 | 0.000 | 0.567 |

Correlation length under one site versus about twenty — and the SD inflated ~4× in response
(`mc-0115`: truth 0.55, interval `[1.773, 2.677]`).

The `animal` and `relmat` arms of the *same* fixture were handed `Ainv = solve(K)`, matching the DGP
exactly, and they **pass**. That contrast is what isolates the range as the mechanism.

## The repair, and its honest outcome

`scratchpad/recover/q4-spatial-fixture-repair.R` regenerates the spatial arm from the covariance the
model actually assumes, so the declared truth becomes the estimand. The covariance is
**re-implemented independently** from the documented formula rather than obtained by calling
drmTMB's internal — deriving fixture truth from the routine under test would destroy the oracle's
independence — and then asserted equal to it:

```
alignment: range ours=18.068309 model=18.068309 | worst precision abs diff=3.020e-13 (rel 1.673e-14)
```

**One repaired fit (seed 20260730, 60 sites × 10, single seed):**

| cell | truth | estimate | rel. error |
| --- | ---: | ---: | ---: |
| `mc-0115` | 0.55 | 0.266 | **−51.6%** |
| `mc-0116` | 0.50 | 0.497 | −0.6% |
| `mc-0117` | 0.40 | 0.298 | **−25.5%** |
| `mc-0118` | 0.35 | 0.258 | **−26.4%** |

```
FIT: 7.5s  convergence=1 (singular convergence (7))  pdHess=TRUE
```

**Read this carefully — it does not vindicate the cells.** The repair removes the gross
misspecification (the ~4× *inflation* is gone, and one target now recovers to within 0.6%), but:

1. the optimizer reports **non-convergence**, so the fit is not clean;
2. three of four targets still carry **25–52% error**;
3. it is **one seed**, so this is a diagnosis, not a bias estimate.

**Conclusion: repairing the fixture changes the diagnosis but does not earn the claim back.** These
cells do not currently support `interval_feasible` — before the repair because their declared truth was
not the estimand, and after it because a single non-convergent fit with 25–52% errors is not evidence
of a well-located interval. Re-promotion would need a converging multi-seed run, which is a compute
decision, not something to fold in here.

## Consequence for the ledger — the narrowed claim

Per Shinichi's decision (2026-08-15, *"repair + narrow the claim"*), any `spatial()` SD interval claim
must state the conditioning. Proposed wording:

> This interval claim is conditional on the spatial correlation range being correctly specified.
> `drmTMB::spatial()` fixes the range at the median pairwise distance and does not estimate it; where
> the true correlation length departs from that value, the estimated SD absorbs the difference.

This applies beyond the eight failures — it is a property of **every** `spatial()` SD claim in the
ledger, none of which currently discloses it.

## What is NOT established

- **No sdmTMB or INLA model was run.** Neither package is installed locally (`fmesher` is present,
  `INLA` is not). The comparison rests on each project's own documentation, cited below — not on a
  head-to-head fit. A genuine three-way numerical comparison remains an open, separate piece of work.
- **`mc-0248`** (gamma × relmat) fails at 99% and does **not** involve the spatial provider. Its
  mechanism is unpartitioned and unexplained.
- Whether `spatial()` *should* estimate its range is a **design question**, not settled here. sdmTMB's
  own guidance that fixing κ aids convergence is a real argument for the current choice.
- The other two failing spatial cells (`mc-0113`, `mc-0114` from `q2plus-scale`, and `mc-0494` from the
  Student q1 campaign) come from **different fixtures** that have not been individually repaired; they
  are assigned to this mechanism by provider and by the shape of the miss, not by direct re-fit.

## Sources

- [sdmTMB model description (CRAN vignette)](https://cran.r-project.org/web/packages/sdmTMB/vignettes/model-description.html)
- [sdmTMB package site](https://sdmtmb.github.io/sdmTMB/)
- [inla.spde2.pcmatern reference](https://rdrr.io/github/inbo/INLA/man/inla.spde2.pcmatern.html)
- [inla.spde2.matern reference](https://rdrr.io/github/inbo/INLA/man/inla.spde2.matern.html)
- [Advanced Spatial Modeling with SPDE using R and INLA](https://becarioprecario.bitbucket.io/spde-gitbook/ch-nonstationarity.html)

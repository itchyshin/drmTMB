# F2 verdict — rare prevalence: **PASS in 4 of 8 cells, VOID in 4** — and the void is the finding

Graded 2026-08-11 against `PREREGISTRATION.md`, frozen at `b352116ab` before any replicate.
8 cells × 500 replicates × 2 engines = **8,000 fits**, Totoro, 100 cores, **57 seconds**.

**This is not reported as 8/8.** Finiteness did hold in every cell, but the pre-registered control
failed in four of them, and §5 says plainly that MSPL results in such a cell **may not be
interpreted**. Reporting the headline number would be exactly the post-hoc slide the SE-calibration
campaign was retracted for.

## What the data say

**Finiteness: 4,000 / 4,000 MSPL fits finite**, every cell at `primary_prop = 1.000`,
`cp_lower = 0.9926`. `hess_pd` and `convergence == 0` were 1.000 throughout.

**Control: held in 4 of 8 cells.**

| cell | η_d | G | n_per | events/rep | ML divergence | control | interpretable |
|---|---|---|---|---|---|---|---|
| 5 | −8 | 30 | 10 | 0.25 | 0.982 | ✅ | yes |
| 7 | −8 | 100 | 10 | 0.75 | 0.914 | ✅ | yes |
| 6 | −8 | 30 | 50 | 1.19 | 0.826 | ✅ | yes |
| 1 | −6 | 30 | 10 | 1.83 | 0.704 | ✅ | yes |
| 8 | −8 | 100 | 50 | 4.02 | 0.372 | ❌ | **no** |
| 3 | −6 | 100 | 10 | 5.71 | 0.226 | ❌ | **no** |
| 2 | −6 | 30 | 50 | 8.94 | 0.110 | ❌ | **no** |
| 4 | −6 | 100 | 50 | 28.40 | 0.012 | ❌ | **no** |

## The finding: prevalence is the wrong axis

The control did not fail because the harness is broken. It failed because **four of the cells were
not hard**, and they were not hard for a reason worth stating:

> **Difficulty tracks the absolute number of events, not the prevalence.**

The ordering above is monotone in events per replicate across all eight cells, and prevalence does
not order it at all. Cells 5 and 8 have essentially the same prevalence — 8.5e−4 and 8.0e−4 — yet ML
diverges in **98%** of replicates in one and **37%** in the other, because one expects 0.25 events
and the other expects 4.

This is directly relevant to the rare-species question that motivated F2. A species at prevalence
1e−3 across 100,000 sites has ~100 events and is comfortably estimable; the same prevalence across
300 sites has ~0.25 and is not. **A prevalence threshold is therefore the wrong filtering
instrument** — two species at identical prevalence can sit on opposite sides of estimability. An
event-count threshold is the one that tracks the actual difficulty.

That is a stronger and more useful result than the "8/8 PASS" this campaign was designed to produce.

## What this licenses

> In the four cells where maximum likelihood genuinely struggles — 0.25 to 1.83 expected events per
> replicate, ML diverging or failing in 70–98% of them — drmTMB's MSPL under TMB-Laplace returned a
> finite interior estimate with finite, positive fixed information in **2,000 of 2,000** fits.

Combined with F1, drmTMB now has its own TMB-Laplace finiteness evidence for logit across designs
from 120 to 5,000 observations and event counts from 0.25 upward.

## A defect in my own design, stated rather than buried

§2 excluded `η_d ≤ −10` because 57–96% of those replicates have **zero events** — total separation,
where the slope is not identified by any estimator and a finite estimate measures the penalty rather
than the data. That exclusion was applied **to `η_d`**, not to the zero-event rate itself. As a
result **cell 5 was admitted at 77.8% zero-event replicates**, which is worse than several cells the
same document excluded.

Cell 5 should be read with that in mind: in most of its replicates there is nothing to identify, so
its finiteness result is largely a statement about the penalty's behaviour on all-zero data. The
cells that carry the weight of the claim above are **6, 7 and 1** (30.8%, 47.0% and 17.2%
zero-event). The correct rule, for any successor campaign, is to gate on **expected event count**,
not on `η_d` and not on prevalence — which is the same conclusion the finding above reaches from the
other direction.

## Secondary — information decays as designed

Median `logdet` of the fixed information, `η_d = −6 → −8`, within each stratum:

| G | n_per | −6 | −8 | lower at −8 |
|---|---|---|---|---|
| 30 | 10 | −3.888 | −5.429 | ✅ |
| 30 | 50 | +1.976 | −7.039 | ✅ |
| 100 | 10 | −6.576 | −7.996 | ✅ |
| 100 | 50 | **+4.268** | **−8.366** | ✅ |

Information collapses by roughly 12 nats at the largest design while the estimate stays finite —
the same signature F1 measured, now at a tenth the prevalence.

## What this does NOT claim

Not a proof. Nothing about probit or cloglog. Not an interval or coverage claim. **Nothing about
cells 2, 3, 4 or 8** for MSPL — the control voids them, and the event-count finding drawn from them
is a statement about *ML*, not a licensed MSPL result. Nothing about `η_d ≤ −10`. **Nothing about a
GLLVM**: this is a single-response GLMM, and whether rare species inform *shared latent structure* —
the question that actually decides the filtering trade-off — is beyond this design. No ledger cell,
census, promotion, or release rung moves.

## Provenance

Prereg `b352116ab`, frozen before any replicate · runner `f2_runner.R`, derived from F1's ·
raw `data/f2_raw.tsv` (8,000 rows) · per-cell `data/f2_cells.tsv` · scorer `analyse.R`, thresholds
quoted from the prereg · Totoro, 100 workers, `OPENBLAS_NUM_THREADS=1` · drmTMB 0.6.0 from
`~/R/f1lib`, unchanged since F1 (no shipped source moved between them) · UTC 2026-08-11
11:24:40 → 11:25:37 · seeds `20260811 + 100000*cell + rep`.

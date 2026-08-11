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

---

# ADDENDUM F2b — the clean answer at the target prevalence

Graded 2026-08-11 against the addendum frozen at `822117366`, before any F2b replicate.
3 cells × 500 replicates × 2 engines = **3,000 fits**, Totoro, **~90 seconds**.

F2's evidence at prevalence ~1e−3 was diluted by degenerate replicates (17–47% zero-event, and 78%
in cell 5). F2b applies F2's own finding — gate on **expected event count** — to fix it.

| cell | n_per | N | prevalence | events | zero-event | ML div | control | finiteness |
|---|---|---|---|---|---|---|---|---|
| 1 | 20 | 2,000 | 8.08e−4 | 1.62 | 20.6% | 0.742 | ✅ | **500/500** |
| **2** | **30** | **3,000** | **8.11e−4** | **2.43** | **10.4%** | **0.592** | ✅ | **500/500** |
| 3 | 40 | 4,000 | 7.85e−4 | 3.14 | 4.2% | 0.474 | ❌ **void** | 500/500 |

**The pre-registered prediction was correct.** The addendum said, before running, that the control
would hold at `n_per` 20 and 30 and *may fail* at 40. It held at 0.742 and 0.592 and failed at 0.474.
Being able to predict where the control breaks — from F2's event-count relationship, not from
hindsight — is the evidence that the mechanism is understood rather than described.

## The claim, now clean

> **Cell 2 is the clean cell at the target prevalence.** At prevalence **8.11e−4**, with only 10.4%
> of replicates degenerate and maximum likelihood diverging or failing in **59.2%** of them, drmTMB's
> MSPL under TMB-Laplace returned a finite interior estimate with finite, positive fixed information
> in **500 of 500** fits.

Median `logdet` of the fixed information across the three cells is **−11.49, −10.07, −9.49** — deeply
collapsed, versus **+4.27** at F2's healthiest cell. Information is nearly gone; the estimate is
finite anyway.

That answers the headline question — *does MSPL stay finite at prevalence ~1/1000?* — on a cell that
is genuinely sparse, genuinely hard for ML, and **not** mostly all-zero data. F2 could only answer it
through cells that were one or the other.

Cell 3 is **void for MSPL** by the same rule that voided four F2 cells: at 3.14 expected events ML is
well-behaved in a majority of replicates, so that cell does not test the question. Its finiteness
result is reported but not claimed.

## Combined position after F1 + F2 + F2b

drmTMB now has its **own** TMB-Laplace finiteness evidence for logit spanning designs from 120 to
5,000 observations and expected event counts from **0.25 to 1.83** (F2) and **1.62 to 2.43** (F2b) in
cells where ML demonstrably fails — 31,000 fits in total, none of which produced a non-finite MSPL
estimate. The reliance on Sterzinger & Kosmidis's glmer-based numerical evidence, for the route
drmTMB actually ships, is discharged.

**Unchanged:** not a proof; nothing about probit/cloglog; not an interval or coverage claim; nothing
about a GLLVM's shared latent structure, which is the question that actually decides the
rare-species filtering trade-off.

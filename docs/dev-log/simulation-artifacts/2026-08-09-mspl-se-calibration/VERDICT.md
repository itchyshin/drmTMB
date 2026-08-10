# VERDICT — MSPL standard-error calibration campaign (2026-08-09)

**60,000 fits · 15 cells × 1000 replicates × 4 engines · Totoro · pre-registered before any run.**

> **The first headline written for this campaign was WRONG and is retracted below.** It read:
> *"zero anti-conservative failures; deep-separation cells are conservative, which is harmless."*
> Both halves were wrong: the count was taken over 14 cells while presented as complete, and
> "conservative" misread an estimator collapse as safety. The corrected verdict follows.
> Caught by Fisher's adversarial review, then verified directly against the raw replicates.

## What this campaign licenses

**MSPL standard errors are calibrated in the identified regime.** Across the identified cells
(`η_d ∈ {0, −2}`), `R = mean(SE)/sd(β̂)` lies in **[0.93, 1.04]** — inside the pre-registered PASS
band, with `mad`-based and `sd`-based estimates in agreement. This is the claim, and it is bounded
by the tested grid: single binomial family, **logit only**, the exact `η_d × G` design in §4.

## What it does NOT license — and why the first reading was wrong

### The deep-separation cells show ESTIMATOR COLLAPSE, not conservatism

`R > 1` was initially read as "conservative, therefore harmless." The raw replicates refute that:

| cell | design | MSPL point estimates | `sd(β̂)` | `R_sd` | `R_mad` |
|---|---|---|---|---|---|
| 4 | `η_d = −6`, `G = 12` | **541/1000 at ~0**; 18 distinct values total | 1.448 | 2.30 | 9.9e7 |
| 5 | `η_d = −10`, `G = 12` | **996/1000 at ~0**; **2 distinct values** | 0.138 | 28.5 | Inf |

The estimator lands on a small set of atoms. `sd(β̂)` then measures **how often a replicate escapes
its dominant atom**, not continuous sampling variability, so the ratio `R` is not a calibration
statistic there at all. A large `R` is a **degeneracy signal**, not a safety margin.

**The `sd`/`mad` divergence was the tell, and it was visible in the first summary.** `R_mad = Inf`
at cell 5 means the median absolute deviation is zero — i.e. more than half the replicates are
identical. That should have stopped the "conservative" reading immediately. It was reported beside
the headline instead of contradicting it.

### A cell was SILENTLY DROPPED — a violation of this campaign's own §8 rule 5

**Cell 15** (`q2`, `η_d = −10`, `G = 30`) reports `ok = TRUE` on all 1000 MSPL replicates, but only
**17 of 1000 have a finite standard error**. The analysis filtered on `is.finite(se)` and then
skipped cells with `n < 50`, so the entire cell vanished from the summary with **no row and no
flag**. "Zero anti-conservative failures" was therefore computed over **14 cells and presented as
15**. ML (19/1000 retained) and glmer (42/1000) were dropped from that cell equally unflagged.

**This is a new finding in its own right, not merely a bookkeeping error:** in that regime MSPL
returns a fit that *reports success* and carries **no standard error**. A user would see
`convergence = 0` and an `NA` SE. That deserves a package issue.

### The engine comparison is NOT paired

Prereg §5 invokes the D-117 paired-reference clause: comparators must be checked **on the same
replicates**. The analysis instead computed each engine's `R` over its own converged subset —
MSPL 100%, glmmTMB 100%, ML 88.7%, glmer 74.7% overall, and far more extreme within cells
(ML 1.9% at cell 15). Retained ML replicates are a **survivor subset**: the ones that converged.

So the *qualitative* statement — ML and glmer standard errors degrade catastrophically under
separation while MSPL's stay finite — survives. The *quantities* (e.g. "ML reached 95,220") are not
paired to MSPL's and must not be quoted as a like-for-like ratio.

### The reported MCSE is not trustworthy in the separated cells

`mcse = (mean(SE)/sd(β̂)) / sqrt(2(n−1))` is the normal-theory Monte-Carlo error of a sample SD,
applied to a **ratio**, assuming `β̂` is Gaussian. In the separated cells `β̂` is a two-atom mixture,
so `sd(β̂)` behaves like a rare-event statistic. The reported values understate the true uncertainty
by an unknown and probably large factor. **Do not quote them.**

## RE-ANALYSIS (same-replicate pairing + degeneracy flags + bootstrap MCSE)

`analyse2.R` supersedes `analyse.R`. It implements the three things the first pass omitted: the
D-117 **same-replicate intersection**, a **degeneracy flag** (modal fraction > 0.20 **or** fewer
than `n/2` distinct estimates), and a **bootstrap MCSE** that assumes nothing about the shape of
`β̂`. Every drop is now printed in `retention_report.tsv`.

### Cells where `R` is interpretable

| cell | design | paired n | `R_sd` | boot MCSE | reading |
|---|---|---|---|---|---|
| 1 | q1 `η=0`, G=12 | 1000 | **1.031** | 0.024 | calibrated |
| 2 | q1 `η=−2`, G=12 | 1000 | **0.933** | 0.026 | **BORDERLINE, anti-conservative side** |
| 6 | q1 `η=0`, G=30 | 1000 | **0.967** | 0.021 | calibrated |
| 7 | q1 `η=−2`, G=30 | 1000 | **0.964** | 0.021 | calibrated |
| 11 | q2 `η=0`, G=30 | 990 | **0.981** | 0.023 | calibrated |
| 12 | q2 `η=−2`, G=30 | 981 | **1.046** | 0.026 | calibrated |
| 13 | q2 `η=−4`, G=30 | 780 | **1.240** | 0.041 | genuinely conservative |
| 14 | q2 `η=−6`, G=30 | 274 | **2.044** | 0.128 | genuinely conservative |

### Cells flagged DEGENERATE — `R` is not a calibration statistic there

| cell | design | modal fraction | distinct estimates | `R_sd` |
|---|---|---|---|---|
| 3 | q1 `η=−4`, G=12 | 0.054 | 216 / 914 | 1.055 |
| 4 | q1 `η=−6`, G=12 | **0.656** | 55 / 407 | 2.806 |
| 8 | q1 `η=−4`, G=30 | 0.012 | 489 / 996 | 0.885 |
| 9 | q1 `η=−6`, G=30 | **0.281** | 121 / 736 | 1.588 |

### Cells with too few paired replicates to say anything

Cells **5** (4 paired), **10** (19), **15** (6). Reported, not hidden.

### Two findings the first pass buried

**1. The `q1` / `q2` split is the real structure.** Every degenerate cell is **q1** (random intercept
only); **no q2 cell degenerates** — cell 14 has 274 distinct estimates out of 274 paired. So
`R = 2.04` at `q2, η_d = −6` is a **genuine conservative result**, while `R = 2.81` at the
comparable `q1, η_d = −6` is an artifact of collapse. The first analysis reported both as
"conservative" and both as `FAIL`, which was wrong in opposite ways.

**2. Cell 2 is the closest thing to the hazard, and the first pass never highlighted it.**
`R = 0.933 ± 0.026` sits **below** the PASS floor of 0.95 on the **anti-conservative** side. It is
BORDERLINE, not FAIL, so the campaign's stopping rule is not tripped — but it is the one cell where
reported uncertainty runs *smaller* than the truth, and it deserves attention precisely because the
headline was about the absence of that direction.

## Corrected status by regime

| regime | verdict |
|---|---|
| identified (`η_d ∈ {0, −2}`) | **PASS** — SEs calibrated, `R ∈ [0.93, 1.04]` |
| moderate separation (`η_d = −4`) | **PASS / BORDERLINE**, no degeneracy evident |
| deep separation (`η_d ∈ {−6, −10}`) | **OPEN QUESTION** — point estimates degenerate; `R` is not interpretable as calibration |
| `q2`, `η_d = −10`, `G = 30` | **SE MACHINERY FAILS** — 983/1000 fits report success with no SE |

## Required follow-up

1. **Re-run the analysis with the same-replicate intersection** the pre-registration specified, so
   engine comparisons are paired.
2. **Add a degeneracy diagnostic** to the analysis — number of distinct estimates, size of the modal
   atom — so a collapsed denominator can never again be read as conservatism.
3. **Open an issue** for `ok = TRUE` with `NA` standard error.
4. **Replace the MCSE** with a bootstrap over replicates, which makes no Gaussian assumption.

## Process note

The pre-registration did its job in one direction and failed in another. It **prevented** the
denominator from being chosen after the fact (`sd` gates, frozen in §3) — that discipline held. It
did **not** prevent an unexamined interpretation of `R > 1`, because the decision rule graded
`R` against bands without asking whether `R` was *meaningful* in that cell.

**A frozen decision rule protects against choosing the statistic; it does not protect against the
statistic being the wrong one.** That gap is what the adversarial review caught, and it is the
lesson worth carrying: pre-register the *validity conditions* of the estimand, not just its bands.

# F2 — MSPL finiteness in the rare-prevalence regime, logit

**Frozen 2026-08-11, before any replicate.** Follow-on to F1
(`2026-08-10-mspl-laplace-finiteness`, PASS), which explicitly did not cover this regime.

## 1. The question

F1 established that drmTMB's MSPL under TMB-Laplace returns finite estimates with finite,
positive fixed information — on its grid. Its rarest cells sit near prevalence **1e-2**.

The regime that matters to the open methodological question is **prevalence ~1e-3**: a species
present at a handful of sites out of thousands. Sterzinger & Kosmidis's asymptotic-normality
theorem assumes ML has regular asymptotic normality (their A7) and then shows MSPL inherits it.
Rare occurrences are precisely where A7 is in doubt. Separately, the penalty's softness constant
`c = 2√(p/n)` is a delta-method result **at β = 0** — maximally far from where `|β|` is large.

So: **does MSPL stay finite when prevalence is ~1/1000 rather than ~1/100?**

## 2. The calibration probe — why the obvious grid was rejected

Run before freezing anything, 200 draws per configuration, DGP only (no fitting):

| η_d | G | n_per | prevalence | **replicates with ZERO events** |
|---|---|---|---|---|
| −6 | 100 | 50 | 5.8e−3 | 0.0% |
| **−8** | **100** | **50** | **8.0e−4** | **1.5%** |
| −8 | 30 | 50 | 8.4e−4 | 29% |
| −8 | 100 | 10 | 8.4e−4 | 46% |
| −8 | 30 | 10 | 8.0e−4 | 79% |
| −10 | 100 | 50 | 1.1e−4 | 57% |
| −10 | 30 | 10 | 1.3e−4 | 96% |
| −12 | any | any | ~1e−5 | **93–100%** |

**`η_d ≤ −10` is excluded, and this is the pre-registered reason.** Those cells are mostly
all-zero responses: total separation, where the slope is not identified by *any* estimator and a
"finite estimate" measures the penalty alone rather than the data. Grading them would repeat E1's
error of running a criterion that cannot be evaluated. F1 already recorded that its `η_d = −10`
cells had event rate exactly 0.000.

The band that is **sparse but not empty** is `η_d ∈ {−6, −8}`, and how empty it gets depends on
design size — which is why `n_per` and `G` are crossed rather than fixed.

## 3. The frozen grid

`q1` only (`y ~ trt + (1 | block)`), logit.
`η_d ∈ {−6, −8}` × `G ∈ {30, 100}` × `n_per ∈ {10, 50}` = **8 cells**.
Engines `mspl` and `ml` (control). **500 replicates per cell** ⇒ **8,000 fits**.

DGP identical to F1 apart from `n_per` now varying: `u ~ N(0, 0.7²)`, `β_trt = 1.0`,
`η = η_d + 1.0·trt + u[block]`.

**Seeds, frozen:** `seed = 20260811 + 100000 * cell + rep`, `rep ∈ 1..500`.

## 4. Endpoints and decision rule — identical to F1, deliberately

Reused verbatim so F1 and F2 are directly comparable. Per MSPL fit, from `fit$mspl`:

| id | quantity |
|---|---|
| E1 | `fixed_information_finite_positive` is `TRUE` |
| E2 | `final_logdet_fixed_information` is finite |
| E3 | `is.finite(β̂)` |
| E4 | `numerical$hessian_positive_definite` — reported, **not** gating |
| E5 | `opt$convergence == 0` — reported, **not** gating |

**FINITENESS HOLDS in a cell** iff `E1 ∧ E2 ∧ E3` in ≥ **99%** of its 500 replicates, with the
Clopper–Pearson 95% lower bound ≥ **0.97**.

**NA handling:** absent or non-finite values are scored as **FAILURES**, never dropped rows.

**SECONDARY (reported, not gating):** median `final_logdet_fixed_information` should be markedly
lower at `η_d = −8` than at `η_d = −6` within each `(G, n_per)` stratum. Probe values at
`G=100, n_per=50`: **+4.916** at `η_d = −6` versus **−8.366** at `η_d = −8`.

**Also reported:** the per-cell rate of zero-event replicates, so any cell that drifts into
degeneracy is visible in the verdict rather than hidden inside it.

## 5. Control

In every cell, ML must diverge (`|SE| > 10³`) or fail in ≥ **50%** of replicates. If ML is
well-behaved in a cell, that cell is not sparse in the way intended and **no MSPL result from it
may be interpreted**. This is F1's §6 rule, unchanged.

## 6. Stopping and abort rules

1. **Smoke first** on Totoro: one cell, 3 replicates, one fit inspected past its guards.
2. **Read cell 1 early**; abort on empty, all-NA, or malformed output.
3. **Check row count and field-count uniformity before analysing** — the defect that turned
   20,000 F1 fits into 25,887 lines.
4. **Estimate: ~10 min at 100 cores** (measured 1.1 s/fit at N=300 rising to 17.2 s at N=5,000;
   ≈56,000 core-seconds total). **Abort and re-report at 45 min.**
5. **No post-hoc rescoring.** If the rule proves unevaluable, halt and revise in the open.

## 7. What this will not claim

Not a proof. Nothing about probit or cloglog. Not an interval or coverage claim. Nothing about
`η_d ≤ −10`, which §2 excludes with reasons. Nothing about a GLLVM — this is a single-response
GLMM, and whether rare species inform *shared latent structure* is a different question this
design cannot answer. No ledger cell, census, promotion, or release rung moves.

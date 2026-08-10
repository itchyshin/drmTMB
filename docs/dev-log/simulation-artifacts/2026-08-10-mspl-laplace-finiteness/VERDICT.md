# F1 verdict — TMB-Laplace finiteness for MSPL, logit: **PASS**

Graded 2026-08-10 against `PREREGISTRATION.md`, frozen at `61169b204` before any replicate.
20 cells × 500 replicates × 2 engines = **20,000 fits**, Totoro, 100 cores, **43 seconds**.

## The claim this licenses, exactly

> On the frozen grid, drmTMB's MSPL estimator under **TMB-Laplace** and the **logit** link returned a
> finite interior estimate with finite, positive fixed information in **10,000 of 10,000** fits —
> including every cell where maximum likelihood diverged or failed.

That is drmTMB's **own** numerical evidence for the route it already ships. It replaces a reliance on
Sterzinger & Kosmidis's numerical evidence, which was obtained on **lme4/glmer** (2023, p. 6) and
covers a different implementation. Design 253 §2 recorded that as a live gap for logit; this closes
the *evidential* part of it.

## Primary endpoint (prereg §5)

`E1 ∧ E2 ∧ E3` — `fixed_information_finite_positive`, finite `logdet` of fixed information, finite β̂.
Threshold: ≥ 99% of replicates **and** Clopper–Pearson lower bound ≥ 0.97.

**20 / 20 cells PASS**, every one at `primary_prop = 1.000`, `cp_lower = 0.9926`. No replicate in any
cell failed any of the three. `hess_pd` and `convergence == 0` — reported, not gating — were also
1.000 throughout.

## Control (prereg §6) — the part E1 lacked

ML had to diverge (`|SE| > 10³`) or fail in ≥ 50% of replicates wherever `η_d ≤ −6`:

| cell | q | η_d | G | median event rate | ML divergent | control |
|---|---|---|---|---|---|---|
| 7 | q1 | −6 | 12 | 0.0083 | 0.912 | ✅ |
| 8 | q1 | −6 | 30 | 0.0067 | 0.724 | ✅ |
| 9 | q1 | −10 | 12 | **0.0000** | 1.000 | ✅ |
| 10 | q1 | −10 | 30 | **0.0000** | 1.000 | ✅ |
| 17 | q2 | −6 | 12 | 0.0083 | 0.840 | ✅ |
| 18 | q2 | −6 | 30 | 0.0067 | 0.616 | ✅ |
| 19 | q2 | −10 | 12 | **0.0000** | 0.998 | ✅ |
| 20 | q2 | −10 | 30 | **0.0000** | 0.986 | ✅ |

**8 / 8 satisfied.** Event rate is exactly 0 at `η_d = −10`, so separation is real, not assumed. The
contrast is the point: ML diverges or dies in these cells while MSPL stays finite in all 500.

## Secondary — the coercivity signature

Median `logdet` of the fixed information, per stratum, as `η_d` falls `0 → −2 → −4 → −6 → −10`:

| stratum | trajectory | monotone |
|---|---|---|
| q1, G=12 | 5.154 → 4.281 → 0.614 → −4.094 → −4.507 | ✅ |
| q1, G=30 | 6.990 → 6.121 → 2.612 → −5.429 → −5.429 | ✅ |
| q2, G=12 | 5.968 → 4.791 → 1.528 → −3.413 → −3.483 | ✅ |
| q2, G=30 | 7.856 → 6.740 → 3.594 → −4.211 → −4.424 | ✅ |

Monotone in all four. This is the finite-precision image of `det XᵀWX → 0` — the condition the E1
probe tried and failed to evaluate along escape rays — measured at the fitted optimum where it stays
finite. **Information decays exactly as separation deepens, and the estimate stays finite anyway.**
That is the mechanism, not just the outcome.

`max |objective_identity_error| = 1.909e−08` across all 10,000 MSPL fits: the penalized and
unpenalized Laplace objectives decompose consistently.

## What this does NOT establish

- **Not a proof.** Numerical evidence on a frozen grid — the same *kind* the authors offer, on our
  implementation rather than theirs.
- **Nothing about probit or cloglog.** No cell used them; the MSPL guard is untouched and stays, for
  the two documented reasons (`c = 2√(p/n)` is the wrong constant for those links; no drmTMB evidence
  for non-logit `W`).
- **Not an interval or coverage claim.** Kosmidis & Firth: Wald CIs "will fail to cover regardless of
  the nominal level", even profiled. Finiteness is not licence for inference.
- **Nothing outside this grid.** `G ∈ {12,30}`, `n_per = 10`, `σ_u = 0.7`, `β = 1.0`, `η_d ≥ −10`.
  The rare-species regime Hao raises — prevalence ~10⁻³ with thousands of units — is **not** covered
  and remains open.
- **No ledger cell, census, promotion, or release rung moves.**

## Harness defects found and fixed, before grading

1. **Stale/installed build.** `library(drmTMB)` loads the *installed* package, which predated the
   MSPL merge, so `estimator=` fell into `...` and every fit errored with *"`drmTMB()` does not use
   arguments in `...` yet."* Caught by the pre-run test. The runner now asserts the `estimator`
   formal exists and aborts with `STALE BUILD` otherwise. This same trap cost the E1 probe a run.
2. **Shattered TSV.** Multi-line cli messages written with `quote = FALSE` produced **25,887 lines
   for 20,000 fits**, with R message text appearing in the `estimator` column. Caught by checking row
   count and field-count uniformity *before* analysing. Fixed by flattening whitespace; re-run cost
   43 seconds.
3. **A false alarm of my own.** I first read `fit$sdr$pdHess` and reported `pdHess = FALSE` on every
   MSPL fit. `fit$sdr` is `NULL` for MSPL fits — I was reading an absent field, not a non-PD Hessian.
   The real flag is `fit$mspl$numerical$hessian_positive_definite`, which is `TRUE` in all 10,000.

The first two are why a smoke is mandatory. The third is why "inspect one unit past its guards" means
checking the field exists before believing what it says.

## Provenance

Prereg `61169b204`, frozen before any replicate · runner `f1_runner.R` · raw `data/f1_raw.tsv`
(20,000 rows) · per-cell `data/f1_cells.tsv` · scorer `analyse.R`, thresholds quoted from the prereg
· Totoro, 384-core host, 100 workers, `OPENBLAS_NUM_THREADS=1` · R 4.5.3 · drmTMB 0.6.0 installed
from the campaign source · UTC 2026-08-10 21:46:38 → 21:47:21 · seeds `20260810 + 100000*cell + rep`.

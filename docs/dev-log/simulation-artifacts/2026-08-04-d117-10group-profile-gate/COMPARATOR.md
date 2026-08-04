# External comparator — is the boundary collapse drmTMB's, or the method's?

**Answer: the method's.** `lme4` reproduces drmTMB's boundary behaviour essentially
exactly. The adverse finding that withheld the D-117 PASS is a property of
profile-likelihood intervals for a variance component near zero — **not a drmTMB
defect.**

## Why this was run

The D-43 panel withheld the PASS on one finding: conditional on drmTMB's own
`profile.boundary` flag, coverage falls to 0.8566 / 0.0732 / 0.2540. The panel's
inference reviewer named the missing check explicitly — that result has two very
different readings:

- **(a)** universal small-sample behaviour of profile intervals at a variance
  boundary, or
- **(b)** something specific to drmTMB's `endpoint` profile root-finder.

`VERDICT.md` §6 listed exactly this as *not established*. It now is.

## Design

`lme4::lmer` on the **same DGP with the same seeds**, so every comparison is
**paired** rather than two independent samples. `REML = FALSE` to match drmTMB's ML
default (`R/drmTMB.R:184`) — comparing ML against lmer's REML default would confound
the estimator with the interval method. Estimand `.sig01`, lme4's RE SD for a
scalar random intercept, the same quantity as `sd:mu:(1 | g)`.
`confint(method = "profile")` in both. 4 cells × 1000 replicates, Totoro, 90 cores.

## Result

| Cell | drmTMB coverage | lme4 coverage | drmTMB at boundary | lme4 lower-at-0 | cov \| boundary (drmTMB) | cov \| boundary (lme4) |
|---|---:|---:|---:|---:|---:|---:|
| `g10_n04_sd05` | 0.9140 | 0.9130 | 495 | **495** | 0.8566 | **0.8566** |
| `g10_n04_sd10` | 0.9290 | 0.9290 | 41 | **41** | 0.0732 | **0.0732** |
| `g10_n10_sd05` | 0.9370 | 0.9370 | 63 | **63** | 0.2540 | **0.2540** |
| `g10_n10_sd10` | 0.9310 | 0.9310 | 0 | **0** | n/a | n/a |

Per-replicate agreement across all 4,000 paired fits:

- **Boundary incidence agrees on 4000/4000 — 1.000 in every cell.** Wherever
  drmTMB sets `profile.boundary = TRUE`, lme4 independently returns a lower bound
  of exactly zero.
- **Coverage outcome agrees on 3999/4000** (0.999 in the worst cell, 1.000 in the
  other three).
- **Conditional coverage is identical to four decimal places** in every affected
  cell — including the alarming 0.0732.
- Upper endpoints agree to **2e-5 – 1.6e-3**.
- Point estimates agree to ~1e-6, an independent cross-check of drmTMB's ML fit
  against a separately-written reference implementation.

`isSingular()` (63 / 1 / 3 / 0) also matches drmTMB's `estimate_sd < 1e-3` counts
exactly — but note it is a **different** diagnostic from the interval hitting zero
(63 vs 495 in the worst cell). The *fit* is usually non-singular; it is the
*interval's lower endpoint* that collapses.

## The single disagreement — and drmTMB is the one that is right

Seed `20661702` (truth 0.50) is the only replicate of 4,000 where the coverage
outcome differs:

| | estimate | lower | upper | covers |
|---|---:|---:|---:|---|
| drmTMB | 0.521875 | 0.118821 | 1.019423 | TRUE |
| lme4 | 0.521875 | **0.694211** | 1.019427 | FALSE |

Both agree on the point estimate and the upper bound to six digits. But **lme4's
lower bound (0.694211) lies above its own point estimate (0.521875)** — the
interval excludes the MLE, which a profile interval cannot validly do. This is an
lme4 profile-bracketing failure, returned without error. drmTMB's interval contains
both the estimate and the truth.

One case in 4,000, in drmTMB's favour. Recorded because a comparator that only ever
flatters the package under test is not a comparator.

## What this changes

1. **The D-43 adverse finding STANDS as a statistical fact.** Coverage really does
   collapse to 7–25% conditional on the boundary flag. Nothing here softens that.
2. **It is NOT a drmTMB defect.** The reference implementation does the same thing,
   on the same data, to four decimal places. Reading (b) is refuted.
3. **So the remedy is a user-facing warning, not a root-finder fix.** This
   strengthens the case for the `NEWS.md` / `?confint.drmTMB` warning that
   `VERDICT.md` §4 identifies as the arc's most actionable output, and removes the
   competing hypothesis that would have required an engine investigation first.
4. **drmTMB is not worse than the field standard here** — on the one replicate
   where they diverge, it is better.

## What this does NOT establish

- That the profile interval is **correct** in an absolute sense. Two
  implementations of the same method agreeing tells you the implementations agree;
  a shared property of profile likelihood at a boundary would be reproduced by
  both. This narrows the cause; it does not validate the method.
- Anything about **non-Gaussian** families, other group counts, or the Prong B
  routes. Gaussian scalar RE only.
- Anything about `glmmTMB`, which is not installed on Totoro. A third
  implementation would add little given the exactness of this agreement, but it
  remains unrun.

## Provenance

`d117_lme4_comparator.R`, lme4 2.0.1, R 4.5.3, Totoro 90 cores,
`OPENBLAS_NUM_THREADS=1`. Seeds `20260727 + 100000 × cell_i + r`, identical to the
drmTMB run, verified equal element-by-element before every comparison
(`stopifnot(identical(d$seed, l$seed))`). Raw output in `results-lme4/`.

**Smoke note, recorded because it nearly produced a vacuous result:** the first
version passed `oldNames = FALSE` to `confint()`, under which lme4 names the row
`sd_(Intercept)|g` rather than `.sig01`. `parm = ".sig01"` then matched nothing and
every interval came back `NA` — with no error. The smoke caught it at 3 replicates;
at 1,000 it would have produced 4,000 silently empty rows. *Before trusting a
green, ask what it would look like if the thing were broken.*

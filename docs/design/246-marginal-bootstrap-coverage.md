# 246 — Coverage of the marginal parametric bootstrap after A1

**Status:** measured 2026-07-25 on Totoro. **The headline is a negative result about
our own fix.**

**Campaign:** 240 shards × 50 replicates = **1000 replicates per cell**, 12 cells,
`R = 199` bootstrap refits, 200-way parallel. **72,000 interval rows, zero attrition,
zero bootstrap refit failures.** Raw results and summary retained.

---

## Why this was run

PR #843 (Arc A1) established that `simulate.drmTMB()` reused the fitted MAP `û` in every
replicate, so `confint(method = "bootstrap")` never resampled between-group variability.
It made **marginal the default**. That fix shipped with **correctness** evidence — Bartlett
identities, covariance recovery, an analytic Gaussian-LMM score — and **no coverage
evidence whatsoever**. Correctness of the simulator does not establish that the intervals
it drives attain their nominal rate. This measures that.

**Pre-registered predictions**, written into the script header before launch:

1. marginal (the new default) attains ~0.95 on the RE SD;
2. conditional (the old behaviour) **under-covers** the RE SD, worsening as `n_groups`
   shrinks;
3. the fixed effect is a **control** — the defect was about between-group variance, so its
   gap should be much smaller.

## Design

Gaussian random intercept, `bf(y ~ x + (1 | g), sigma ~ 1)`. Truths `beta = 0.5`,
`sigma = 0.7`, `sd_mu ∈ {0.5, 1.0}`. Grid `n_groups ∈ {10, 25, 50}` × `n_per ∈ {4, 10}`.
Estimands: the RE SD `sd:mu:(1 | g)`, residual `sigma`, and the fixed effect `mu:x`, each
under `bootstrap_re_form = NULL` (marginal) and `= NA` (conditional).

**Full denominator.** Every attempt is retained and carries a `status`; coverage is over
all attempted replicates, never over successful ones. Here it makes no difference —
attrition was zero — but the analysis is written so it could not have hidden any.

## Results

| Estimand | marginal | 95% CI | conditional | 95% CI | gap |
| --- | --- | --- | --- | --- | --- |
| **RE SD** `sd:mu:(1\|g)` | **0.8714** | [0.8653, 0.8774] | **0.5092** | [0.5002, 0.5181] | **+0.362** |
| `sigma` | 0.9319 | [0.9273, 0.9364] | 0.9320 | [0.9273, 0.9364] | +0.000 |
| `fixef:mu:x` | 0.9437 | [0.9395, 0.9478] | 0.9356 | [0.9310, 0.9399] | +0.008 |

By group count, RE SD:

| `n_groups` | marginal | conditional |
| --- | --- | --- |
| 10 | 0.8103 | 0.5168 |
| 25 | 0.8888 | 0.5125 |
| 50 | 0.9153 | 0.4983 |

## What this establishes

**1. The A1 defect was real, severe, and exactly as diagnosed.** The old conditional
bootstrap covered a nominal 95% interval for the RE SD **50.9% of the time** — barely half
the advertised rate, and flat across group counts, which is the signature of a bias that
does not wash out with more data. Median interval width 0.256 versus 0.481 marginal: the
old intervals were about **half as wide as they should be**.

**2. The mechanism claim in PR #843 is confirmed, not merely consistent.** The damage is
confined to the between-group variance component, precisely as predicted. Residual `sigma`
is untouched to four decimals (0.9319 vs 0.9320) and the fixed effect moves by 0.008.
Predictions 2 and 3 hold.

**3. Prediction 1 FAILED, and this is the finding that matters going forward.** Marginal
attains **0.8714, not ~0.95**. It improves with group count — 0.810 → 0.889 → 0.915 for
10 → 25 → 50 groups — but has not reached nominal even at 50 groups.

**A1 was necessary and large. A1 is not sufficient.** The marginal parametric bootstrap
still under-covers the random-effect SD, and does so materially at the group counts
ecologists actually have.

## What must NOT be claimed

- **No cell may be promoted on the strength of this.** The asymmetric tier fence stands:
  correctness evidence never promotes. This is coverage evidence, and it points *down*.
- **`confint(method = "bootstrap")` must not be described as inference-ready for
  random-effect SDs.** At `n_groups = 10` it delivers 81% coverage for a 95% interval.
- Nothing is retracted: no certified cell relied on bootstrap intervals (`bootstrap_R = 0`
  across 151 evidence artifacts, verified independently at A1's completion gate).

## Boundary

Gaussian random intercept only, one covariate, constant residual scale, complete data,
`R = 199`, percentile intervals as `confint()` currently constructs them. It says nothing
about non-Gaussian families, structured random effects, `sd() ~ x` regressions, bivariate
routes, or missing data. The residual-`sigma` figure of ~0.932 is itself slightly below
nominal for both arms and is an ordinary small-sample bootstrap property, not a finding
about A1.

## Open questions this raises

1. **Why does marginal stop at ~0.87?** Candidates: percentile intervals are known to be
   poor for a boundary-adjacent variance parameter; `R = 199` is small for a tail quantile;
   the Laplace-based refit may itself be biased at low group counts. These are separable
   and worth separating.
2. **Would BCa or a bootstrap-t close the gap?** Currently only percentile is implemented.
3. **Does the same shortfall appear for structured REs** (`phylo`, `spatial`, `relmat`)
   now that Arc A2 has widened marginal support to `phylo_interaction`?

## Reproduce

```
ssh totoro
cd ~/drm_work && Rscript a1_analyse.R      # summary
# raw: ~/drm_work/results/*.csv (240 shards), archive a1_coverage_results.tar.gz
```
Script `a1_coverage.R`; seeds are deterministic per cell and shard.

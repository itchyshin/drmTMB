# DG3 — random-effect-SD interval coverage vs cluster count (Totoro)

**Date:** 2026-07-12 · **Compute:** Totoro (384-core lab server), 80 cores, drmTMB
0.6.0.9000 (`main @ 38cfa4e6`, Arc 2b/2c) · **Design:** 3 specs × M ∈ {8,16,32,64}
× 600 sims = 7,200 fits, all converged. Generator: `generate.R`.

## Question

The Arc 2b/2c cells are marked `point_fit_recovery` — trust the point, not the
interval. This campaign asks the DG4/DG5 question directly: **does the 95% interval
for the random-effect SD actually cover at 95%, and how does that depend on the
number of clusters M?** Interval = Wald on the log-SD scale,
`exp(log_sd_hat ± 1.96·SE)` from the sdreport (the fast interval; the profile
interval, D-12, is the natural refinement).

## Result (`coverage-results.tsv`)

| spec | M=8 | M=16 | M=32 | M=64 |
|---|--:|--:|--:|--:|
| **coverage** — gaussian slope | 0.993 | 0.967 | 0.938 | 0.930 |
| **coverage** — binomial slope | 0.937 | 0.912 | 0.942 | 0.945 |
| **coverage** — lognormal sigma | 0.997 | 0.980 | 0.932 | 0.942 |
| **rel-bias** — gaussian | −14% | −6.1% | −3.9% | −1.8% |
| **rel-bias** — binomial | −11% | −5.6% | −3.5% | −2.0% |
| **rel-bias** — lognormal | −15% | −6.4% | −4.1% | −2.3% |
| mean CI width — all specs | **Inf** | Inf–0.48 | 0.25–0.37 | 0.18–0.26 |

## What it means (read the width column, not just coverage)

1. **Point recovery is solid and improves with M** — the downward RE-SD bias shrinks
   from ~−15% at M=8 to ~−2% at M=64, matching the Laplace/AGHQ study. This is why the
   cells are honestly `point_fit_recovery`.
2. **The interval is NOT trustworthy at small M — but for two opposite reasons:**
   - gaussian & lognormal at M=8/16 **over-cover (0.99+)** because the log-SD SE is huge
     and the upper limit diverges — **mean CI width is literally `Inf`**. A `[x, ∞)`
     interval covers trivially; it is *uninformative*, not *good*.
   - binomial at M=8/16 **under-covers (0.91–0.94)** — the downward bias pulls the (finite)
     interval off the truth.
3. **By M ≈ 32–64 the interval becomes usable**: finite width (0.18–0.37) and coverage
   settling at **0.93–0.945 — slightly *below* nominal**, the residual of the point bias.
4. **Conclusion for the ledger:** the Wald RE-SD interval earns `interval_feasible` only
   at **moderate-to-large cluster counts**; at the small-M sizes applied users often have,
   it is either degenerate-wide or mildly anti-conservative. This is the concrete,
   evidence-backed reason the Arc 2b/2c cells stay `point_fit_recovery` and are **not**
   promoted to `supported`. Two clean follow-ups: the **profile** interval (D-12) should
   tame the small-M degeneracy, and **REML/AGHQ** would lift the residual point bias that
   keeps coverage just under 0.95.

**Caveats.** Wald-on-log-SD only (profile deferred). `n_each = 12` fixed; the M axis is the
finite-cluster (df) dimension. `Inf` widths are real (unbounded upper limits at small M),
not a coding artifact — they *are* the finding. Single grouping, one RE per model.

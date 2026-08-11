# G2 verdict — the logit-calibrated `c_n` is IMMATERIAL for probit and cloglog

Graded against `PREREGISTRATION-G2-CN.md`, frozen at `66bd3c584` before any replicate. 36 cells ×
1000 replicates × 3 arms = **108,000 fits**, Totoro, 100 cores, ~5 min.

## Verdict

| link | max materiality | threshold | verdict |
|---|---|---|---|
| **probit** | **0.0124** | `< 0.10` | **IMMATERIAL** |
| **cloglog** | **0.0118** | `< 0.10` | **IMMATERIAL** |

`materiality = |bias_shipped − bias_per-link| / sd(β̂)`, over the 9 cells per link with
`n_eff ≥ 300`. Both are roughly **eight times below** the pre-registered IMMATERIAL threshold.

> Choosing the shipped `c_n = 2√(p/n)` over the delta-method value for the link
> (`1.2533√(p/n)` for probit, `1.3108√(p/n)` for cloglog) moves the estimate by about
> **1% of one standard error**. It is not a difference a user could act on.

**Null control PASS.** logit's per-link factor *is* 2, so its two arms are the same estimator: max
`|Δbias|` over all logit cells was **exactly 0**, bit-identical. Had it not been, no probit or
cloglog number here would have been readable.

## The numbers

`n_eff ≥ 300`, the verdict set:

| link | `η_d` | `n_eff` | bias shipped | bias per-link | `|Δbias|` | `sd(β̂)` | materiality |
|---|---|---|---|---|---|---|---|
| probit | 0 | 300 | 0.01276 | 0.01302 | 2.6e−4 | 0.1766 | 0.0015 |
| probit | 0 | 1200 | 0.00362 | 0.00365 | 3.2e−5 | 0.0884 | 0.0004 |
| probit | −2.1 | 300 | 0.01350 | 0.01718 | 3.7e−3 | 0.2963 | **0.0124** |
| probit | −2.1 | 1200 | 0.00555 | 0.00585 | 3.0e−4 | 0.1297 | 0.0023 |
| cloglog | 0 | 300 | 0.00983 | 0.01035 | 5.2e−4 | 0.1918 | 0.0027 |
| cloglog | −3.5 | 300 | 0.09395 | 0.10181 | 7.9e−3 | 0.6663 | **0.0118** |
| cloglog | −3.5 | 1200 | 0.01514 | 0.01554 | 4.1e−4 | 0.2526 | 0.0016 |

The worst cell in each link is its deepest separation at the smallest verdict size — as expected,
since that is where the penalty does the most work. Even there the two constants differ byabout 1% of a
standard error.

At the excluded `n_eff = 120` cells (`c_n = 0.258`, the hardest regime), the maximum is **0.054** —
still inside the IMMATERIAL band, though the prereg deliberately declined to grade there.

**Direction, for the record:** the shipped constant is the *stronger* penalty for both links, and it
produces slightly *less* bias than the per-link value in every cell (`bias_shipped < bias_per-link`
throughout). The "over-softness" is real in magnitude and benign in effect.

## Secondary — the gap closes faster than the shared-rate argument predicts

Both constants carry the same `√(p/n)` rate, so `|Δbias|` was expected to fall by about
`√10 ≈ 3.16×` from `n_eff = 120` to `1200`. Observed:

| link | `η_d` | `|Δbias|` across `n_eff` = 120, 300, 600, 1200 | ratio |
|---|---|---|---|
| probit | 0 | 0.0010 → 0.0003 → 0.0001 → 0.0000 | **32.6×** |
| probit | −2.1 | 0.0268 → 0.0037 → 0.0009 → 0.0003 | **90.0×** |
| cloglog | 0 | 0.0036 → 0.0005 → 0.0002 → 0.0001 | **63.9×** |
| cloglog | −3.5 | 0.0505 → 0.0079 → 0.0013 → 0.0004 | **124.6×** |

Every ratio is an order of magnitude beyond the `√n` prediction, consistent with the difference being
a product of two quantities that each shrink with `n` — the constant gap `(2 − ω(0)^{−1/2})√(p/n)` and
the penalty's own diminishing influence on `β̂`. **The two constants converge faster than theory
required them to**, which strengthens rather than qualifies the verdict.

## What this settles

Design 253 Addendum 3 recorded that `c_n = 2√(p/n)` is a **logit** delta-method result (2023 §7) and
called non-logit softness bounds future work. That gap is now measured: it exists, it is exactly the
size predicted (1.596× for probit, 1.526× for cloglog — verified against the shipped kernel), and at
practical `n` **it does not matter**.

**The `c_n` objection to admitting probit and cloglog is therefore answered on evidence.** Combined
with G1/G1b (0 non-finite estimates in 43,972 completed fits) and G3 (standard errors calibrated in
the identified regime for both links), all three gates the arc set out to test have now been run.

## What this does NOT do

- **It does not change `c_n`.** That was locked at planning — G2 measures, it does not change — and
  design 253 §5 separately rejects a modified `c_n` on the grounds that inflating it defines a
  *different estimator*. The shipped constant stays.
- **It does not open the guard.** That remains a maintainer decision, now with the evidence it was
  waiting on rather than without it.
- **It says nothing about `q2`.** This campaign is `q1`, `p = 2` only — the constant question is
  about `p/n`, not random-effect structure — so the random-slope regime where G3 found missing
  standard errors is untested here.
- **It says nothing about intervals.** KF2021 §2.1 stands: Wald intervals fail to cover under
  separation at any nominal level, link-generally.

## Provenance

Prereg `66bd3c584`, branch `claude/mspl-nonlogit-evidence`; drmTMB 0.7.0 built on Totoro into
`~/R/g2lib` from that tree; 100 workers, `OPENBLAS_NUM_THREADS=1`. The runner asserts the
`drmTMB.mspl_cn_factor_unsafe` override is live before running — a guard that fired on the first
attempt and caught a stale install that would otherwise have produced a silent all-zero campaign.
Raw `data/g2_raw.tsv.gz` (108,000 rows, 16 fields), per-cell `G2-cell-results.csv`, console
`G2-grading.log`, runner `g2_runner.R`, scorer `analyse_g2.R`.

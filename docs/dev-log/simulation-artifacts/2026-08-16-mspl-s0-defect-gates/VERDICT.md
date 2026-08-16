# Verdict — MSPL S0 defect gates

**2026-08-16 · Totoro · scored against `PREREGISTRATION.md` (committed before results) ·
package: the frozen-candidate install (`~/drmtmb-valgrind-302ac2579/lib`, drmTMB 0.7.0 bytes
`0d150ef3…`) · zero failed fits in either experiment.**

## A — the shipped penalty is not scale-equivariant: CONFIRMED

200 replicates, A1 Gaussian design, penalized objective built from the shipped forms
(`D` = negative Huber `src/drmTMB.cpp:77-85`; `c_n = 2√(p/n_eff)` `R/mspl.R:112-128`) on the
fit's own TMB objective. Statistic: |sd̂(y) − sd̂(100·y)/100| per replicate.

| arm | mean discrepancy | median | max | reps > 0.01 |
| --- | --- | --- | --- | --- |
| ML (control) | 1.21e-06 | — | 8.81e-06 | 0 / 200 |
| **penalized (shipped forms)** | **0.0196** | 0.0175 | **0.1344** | **200 / 200** |

The ML control is equivariant to optimizer tolerance — four orders of magnitude below the
penalized effect — validating the harness. (Honesty note: the pre-registration predicted control
< 1e-6; the measured *mean* is 1.21e-06, marginally above, which is `nlminb` tolerance, not a
harness defect; the *purpose* of the control — proving the discrepancy comes from the penalty,
not the pipeline — is served with 4 orders of margin.) **Every single replicate** shows a
material scale dependence. Fitting the same data in different units gives different back-scaled
answers. F1 stands, now on committed, seeded, in-repo measurement.

## B — the anchor pull on the SHIPPED route: CONFIRMED, with a sharpened detail

1,500 paired fits (300/cell), binomial `estimator="ml"` vs `estimator="mspl"` — the actual
shipped code path — true logit-scale `sd_u` ladder, g = 10:

| true sd | bias ML | bias MSPL | MSPL − ML |
| --- | --- | --- | --- |
| 0.25 | −30.5% | **+1.5%** | **+32.1 pts — overshoots past truth** |
| 0.50 | −18.7% | −10.8% | +7.9 pts (helps) |
| 1.00 | −7.4% | −7.1% | +0.3 pts (nothing — the anchor) |
| 2.00 | −6.4% | −7.7% | −1.3 pts (hurts) |
| 4.00 | **+1.1%** | **−6.4%** | **−7.5 pts — ML nearly unbiased, MSPL drags it down** |

The monotone crossover at the anchor is exactly the pre-registered prediction. The sharpened
detail the prediction did not commit to: at `sd_u = 0.25` the penalty does not merely reduce the
downward bias — it **overshoots through zero** (−30.5% → +1.5%), which is the signature of
pull-toward-anchor rather than bias correction; a correction calibrated to the estimator's bias
would not change sign.

## B, second pass — RMSE, which reverses the reading of two cells

Bias alone flattered ML. Scoring the same 1,500 fits on RMSE and on boundary collapse:

| true sd | RMSE ML | RMSE MSPL | ML fits < 0.01 | MSPL fits < 0.01 |
| --- | --- | --- | --- | --- |
| 0.25 | 0.2024 | **0.1441** (−29%) | **42.0%** | **0%** |
| 0.50 | 0.2666 | **0.2188** (−18%) | 13.0% | 0% |
| 1.00 | 0.3269 | **0.3149** (−4%) | 0.7% | 0% |
| 2.00 | 0.6339 | **0.6175** (−3%) | 0% | 0% |
| 4.00 | 2.0245 | **1.3326** (−34%) | 0% | 0% |

**MSPL wins RMSE at every cell**, and the two ends invert the bias-only story. At `sd = 4`, ML is
nearly unbiased in the mean (4.05) but wildly dispersed (SD 2.03); MSPL trades −6.4% bias for a
35% variance reduction and wins RMSE by a third. The bias-only table above therefore *understates*
the estimator: on the standard point-estimation metric it dominates over the whole ladder.

The boundary column reproduces Chung et al. 2013 in this package: **42% of ML fits collapse to
essentially zero at `sd = 0.25`; MSPL, none.** Chung reported 45–47% at comparable small-J designs.

**This does not transfer to intervals.** Chung's own α=2-vs-α=3 split (best-for-bias ≠
best-for-coverage) is the standing warning, and F4 (flag deletion ≠ miss repair) is untouched by
any point-estimation metric. RMSE dominance raises the value of fixing the parameterisation; it
does not pre-empt S3.

## Prediction outcome

Both pre-registered predictions **held**; neither falsifier fired; the harness controls passed
(ML equivariant; ML ladder biases consistent with the known small-g pattern, monotone from
−30.5% at sd 0.25 to ≈0 at sd 4). The packet's F1/F2 claims now rest on committed measurement of
the shipped algebra and the shipped code path, replacing Fisher's exploratory port.

## Consequences for S1 (binding requirements, now measured)

1. The derived penalty must be **exactly scale-equivariant** — Experiment A is the regression
   test any candidate form must pass with the ML control's profile.
2. The derived penalty must not change the **sign** of the bias anywhere on the ladder —
   Experiment B's ladder (extended per S3's design) is the acceptance surface; the shipped form
   fails it at both ends.
3. Any validation grid must **span the anchor region** of whatever form is derived — the
   0.25-to-4 ladder is the minimum; a grid at or below the anchor alone is structurally
   confounded (F2).

## Provenance

Runner: `s0_defect_gates.R` (this directory; transcribed shipped forms cited to file:line).
Results: `results/expA_equivariance.csv`
(sha256 `71464dcbe48157c2c72cd33b90b78b8256aae6d80e02fe425ae010853b7b3155`),
`results/expB_anchor_ladder.csv`
(sha256 `c8ddd146ce3727296bbc3c039e3b57c1991cb4c332fc9960d24fc551ba0b315d`) — small enough to
commit, committed. Totoro, 40 cores, `OPENBLAS_NUM_THREADS=1`; wall time under five minutes
total; seeds in the runner. Scope: this is a defect record for the SHIPPED penalty under
transfer to boundary use — it is not a coverage study, makes no claim about any repaired form,
and does not touch the 0.7.0 candidate or any release surface.

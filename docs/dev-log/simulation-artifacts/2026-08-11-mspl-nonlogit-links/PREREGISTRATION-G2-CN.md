# G2 — does the logit-calibrated `c_n` matter for probit and cloglog?

**FROZEN 2026-08-11, before any G2 replicate.** The last unrun gate of the non-logit MSPL arc.
Decision locked with Shinichi at planning: **G2 measures, it does not change.** No shipped constant
moves as a result of this campaign, whatever it finds.

## 1. The question

drmTMB ships `c_n = 2 * sqrt(p / n_eff)` for every link. The `2` is **logit's**:
Sterzinger & Kosmidis (2023) §7 derive `c` from the approximate variance of `η̂` **at β = 0**, giving
`c = ω(0)^(-1/2) * sqrt(p/n)`, and logit has `ω(0) = 1/4`. Verified against the shipped kernel to
machine precision:

| link | `ω(0)` | value | factor `ω(0)^(-1/2)` | shipped / correct |
|---|---|---|---|---|
| logit | `1/4` | 0.250000 | **2** | 1.000 |
| probit | `2/π` | 0.636620 | **1.2533** | **1.596×** |
| cloglog | `1/(e−1)` | 0.581977 | **1.3108** | **1.526×** |

So for probit and cloglog the shipped penalty is **~1.5–1.6× stronger** than the delta-method
calibration intends. Design 253 Addendum 3 records this and calls non-logit softness bounds future
work; nobody has measured whether it matters.

**Both constants have the same rate `sqrt(p/n)`**, so the asymptotic "penalty vanishes" argument is
untouched either way. The difference is a **finite-sample factor of known size**, and the only open
question is empirical: at practical `n`, does choosing the wrong one move the estimate enough to
care?

## 2. Design

Three arms per replicate, on the **same simulated dataset**:

| arm | `c_n` | role |
|---|---|---|
| **shipped** | `2 * sqrt(p/n_eff)` | what drmTMB does today |
| **per-link** | `ω(0)^(-1/2) * sqrt(p/n_eff)` | what 2023 §7's argument gives for that link |
| **ml** | none | unpenalized anchor; both arms must approach it as `n` grows |

Set via `options(drmTMB.mspl_cn_factor_unsafe = )`, an undocumented evidence-only knob that must
never merge. Verified before freezing: it scales `c_n` by exactly the requested factor
(shipped/per-link ratio 1.5958 against the predicted 1.5959) and restores the shipped value
bit-identically when unset.

**Links:** logit, probit, cloglog (as-generated orientation only — G3 established that the mirrored
arm is model-misspecified and therefore useless for any estimand question).

> **logit is a NULL CONTROL.** Its per-link factor *is* 2, so its two arms are the same estimator and
> must return **bit-identical** estimates. Any logit difference means the harness is wrong and no
> probit or cloglog number from that run may be read — the same control rule F1, G1 and G1b used.

**`n` ladder:** `q1`, `p = 2`, `n_per = 10`, `G ∈ {12, 30, 60, 120}` giving
`n_eff ∈ {120, 300, 600, 1200}` and `c_n ∈ {0.258, 0.163, 0.115, 0.082}` for the shipped arm. The
ladder is the point: the two constants must converge as `n` grows, and the campaign measures *how
fast* and *whether the gap is ever material*.

**`η_d` per link**, from `S3-CALIBRATION.md`: the two shallowest (identified, where the estimand is
well behaved) plus one moderate separated depth, where the penalty actually does work — logit
`{0, −2, −4}`, probit `{0, −1.2, −2.1}`, cloglog `{0, −2, −3.5}`.

**3 links × 3 `η_d` × 4 `G` = 36 cells × 1000 replicates × 3 arms = 108,000 fits.**
Seeds: `20260814 + 100000 * cell + rep`, a fresh stream.

## 3. Endpoints and the decision rule — frozen before the numbers exist

Per cell, on replicates where **both MSPL arms returned** (paired; D-117):

| id | quantity |
|---|---|
| E1 | `bias_arm = mean(β̂_arm) − 1.0` (true `β = 1.0`) |
| E2 | `rmse_arm` |
| E3 | **materiality** `= |bias_shipped − bias_per-link| / sd(β̂_shipped)` |
| E4 | `|mean(β̂_arm) − mean(β̂_ml)|`, the unpenalized-anchor gap, per arm |

**E3 is the decision statistic**, and it is deliberately scaled by the sampling SE rather than
reported as a raw difference: a constant that shifts the estimate by far less than one standard
error cannot matter to a user, whatever its nominal size.

| verdict | rule |
|---|---|
| **IMMATERIAL** | `E3 < 0.10` in every cell with `n_eff ≥ 300` |
| **BORDERLINE** | `0.10 ≤ E3 < 0.25` in any such cell, none reaching 0.25 |
| **MATERIAL** | `E3 ≥ 0.25` in any cell with `n_eff ≥ 300` |

`n_eff = 120` cells are reported but excluded from the verdict: `c_n = 0.258` there is the regime
where *any* softness choice bites hardest, and the shipped constant is not claimed to be calibrated
at that size for any link.

**Secondary, reported not gating:** whether `|bias_shipped − bias_per-link|` decays at approximately
the predicted `sqrt(p/n)` rate. Both constants share that rate, so the gap should fall by about
`sqrt(10) ≈ 3.16×` from `n_eff = 120` to `1200`. A gap that does *not* shrink would contradict the
shared-rate argument and is worth more than the verdict itself.

## 4. What G2 cannot do

It cannot authorise changing `c_n` — that is locked, and design 253 §5 separately rejects a modified
`c_n` on the grounds that inflating it defines a *different estimator*. An IMMATERIAL verdict means
the fence can be argued on evidence rather than caution; a MATERIAL verdict means the shipped
constant is wrong for non-logit and the fence must stay until that is resolved. Neither opens the
guard, and neither says anything about intervals, standard errors, or the `q2` random-slope regime
this campaign does not test.

## 5. Stopping rules

Smoke one cell per link before the grid, verifying the logit null control returns bit-identical arms.
Read the first cell early and abort on empty/all-NA. State the wall-clock estimate before the run and
stop-and-re-report on overrun (D-139). No post-hoc rescoring; no cell dropped from the summary.

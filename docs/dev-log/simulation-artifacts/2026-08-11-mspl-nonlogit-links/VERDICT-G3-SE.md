# G3 verdict — MSPL standard errors are calibrated for probit and cloglog, and a link-general SE gap

Graded against `PREREGISTRATION-G3-SE.md`, frozen at `853ad0bd8` before any replicate. 60 cells ×
1000 replicates × 3 engines = **180,000 fits**, Totoro, 100 cores, **4 min 30 s** against a declared
15–25 min.

## 1. The calibration claim

Identified regime, `R = mean(SE)/sd(β̂)` on retained non-degenerate replicates:

| condition | cells | PASS | BORDERLINE | anti-cons. FAIL | `R` range | verdict |
|---|---|---|---|---|---|---|
| logit (reference) | 6 | 6 | 0 | 0 | 0.980 – 1.046 | **CALIBRATED** |
| **probit** | 6 | 5 | 1 | 0 | 0.946 – 1.008 | **CALIBRATED** |
| **cloglog-standard** | 6 | 6 | 0 | 0 | 0.957 – 1.027 | **CALIBRATED** |
| cloglog-mirrored | 6 | 2 | 2 | 2 | 0.820 – 0.996 | **NOT CALIBRATED** (see §2) |

> **MSPL standard errors are calibrated in the identified regime for probit and cloglog-standard**,
> on the frozen grid, to the same standard the 2026-08-09 campaign established for logit — whose
> result this run reproduces independently (that campaign found `[0.93, 1.04]`; this one finds
> `[0.980, 1.046]` on a fresh seed stream).

## 2. cloglog-mirrored fails, and G3's own design is why

The verdict above **stands by the frozen rule** and is not rescored. But its cause is not MSPL, and
G3 found it:

**The mirrored arm is model-misspecified for a calibration question.** True `β = 1.0` in every
condition. Recovered `mean(β̂)` in the identified q1 cells:

| condition | `η_d` = shallowest | second |
|---|---|---|
| logit | 1.016, 1.015 | 1.017, 1.026 |
| probit | 1.014, 1.009 | 1.047, 1.009 |
| cloglog-standard | 1.029, 1.022 | 1.041, 1.011 |
| **cloglog-mirrored** | **−1.537, −1.470** | **−0.565, −0.546** |

It does not estimate `−β`. Flipping the response under cloglog fits the **log-log** link — the true
model for `1 − y` is `P(y* = 1) = exp(−exp(η))`, which no linear cloglog predictor reproduces — so the
arm targets a different, `η_d`-dependent pseudo-true value. A model-based Wald SE is the wrong
variance estimator under misspecification, and anti-conservatism there is a property of the
misspecification, not of MSPL.

**The paired check (D-117) confirms it.** At cell 47, on the same 1000 replicates:

| engine | `R_sd` | mean(SE) | sd(β̂) |
|---|---|---|---|
| MSPL | 0.8970 | 0.2900 | 0.3232 |
| ML | 0.8945 | 0.2906 | 0.3249 |
| glmmTMB | 0.8945 | 0.2906 | 0.3249 |

All three agree to three decimals. Per prereg §5, *"if all engines under-calibrate together, the
finding is a statistical fact about the regime, not a drmTMB defect."*

**Cell 46 is the reverse of a defect.** At `G = 12`, MSPL gives `R = 0.820` while **ML gives 10.13 and
glmmTMB 52.34** (mean SE 13.6 and 82.9 against MSPL's 0.50). MSPL is the only engine returning a
usable standard error at all; it is graded FAIL for being modestly anti-conservative relative to its
own sampling spread, while its comparators are off by one and two orders of magnitude.

**What this means for the earlier campaigns:** the mirrored arm was **valid for G1/G1b** — finiteness
asks whether the penalized estimate exists, which misspecification does not affect, and the arm did
genuinely exercise cloglog's opposite tail. It is **not valid for calibration**, and G3's design did
not anticipate that. Recorded as a design limitation of G3, not removed from the table.

## 3. probit's single separated-regime failure is also a regime fact

Cell 29 (`q2`, `η_d = −3`, `G = 30`), paired on 766 replicates:

| engine | `R_sd` |
|---|---|
| MSPL | **0.814** |
| ML | 0.667 |
| glmmTMB | 0.662 |

All three are anti-conservative and **MSPL is the least so**. Same D-117 reading: a fact about
inference under separation, not a drmTMB defect. It remains a FAIL under the frozen rule, in the
*separated* regime — which is precisely the regime KF2021 §2.1 says Wald inference should not be
trusted in.

## 4. The finding that most affects users: converged fits with no standard error

**This is link-general and it is severe.** Fraction of MSPL fits reporting `convergence == 0` whose
slope SE is missing or non-finite:

| condition | `q` | `η_d` | `G` | **no usable SE** | MSPL retention |
|---|---|---|---|---|---|
| logit | q2 | −10 | 30 | **98.3%** | 0.017 |
| cloglog-mirrored | q2 | −8.4 | 30 | **92.2%** | 0.078 |
| cloglog-standard | q2 | −7 | 30 | **74.2%** | 0.250 |
| probit | q2 | −4.2 | 30 | **64.5%** | 0.355 |
| logit | q2 | −6 | 30 | 54.4% | 0.456 |
| cloglog-mirrored | q2 | −6 | 30 | 38.2% | 0.618 |
| cloglog-standard | q2 | −5 | 30 | 25.2% | 0.738 |

15 of 60 cells show it, in **all four conditions**. Every one is in the **separated** regime; no
identified-regime cell is affected. The logit figure independently reproduces the 2026-08-09
campaign's accidental discovery at its cell 15 (17 of 1000 retained = 98.3% missing).

**Correction to a first reading of this table (2026-08-11).** I initially wrote that every affected
cell was a random-slope (`q2`) cell. **Three are `q1`** — the intercept-only `y ~ trt + (1 | block)`
model at `G = 12`: cloglog-mirrored at `η_d = −4.2` (2.7%) and `−6` (0.2%), and probit at
`η_d = −2.1` (0.1%). Low rates, but non-zero, so the defect is **not confined to random slopes**.
Caught by enumerating the table exhaustively instead of reading its head — the same failure
`memory/A simulator can fail in your package's favour` records under *"when a claim is load-bearing
enough to write into a PR, enumerate it exhaustively rather than reporting the first instance you
found."*

**What a user receives in that regime: `convergence = 0`, a point estimate, and `NA` for the standard
error.** The fit reports success. Nothing in the printed output says the SE was unavailable rather
than merely large. That is a usability defect independent of every calibration question above, it is
not link-specific, and it affects the **shipped logit route**.

## 5. What G3 licenses, and what it does not

**Licenses:** MSPL standard errors are calibrated in the identified regime for **probit** and
**cloglog-standard**, to the logit standard, on this grid — with logit reproduced independently as
the reference arm.

**Does not license:**

- **Intervals.** KF2021 §2.1 (p. 75) proves Wald intervals fail to cover under separation at any
  nominal level, link-generally. A calibrated `R` in the identified regime does not touch that, and
  the separated-regime results here are consistent with it.
- **Calibration under separation.** The separated cells are largely **DEGENERATE** (13 of 36 across
  conditions) — the estimator collapses onto atoms, `sd(β̂)` stops measuring sampling variability, and
  `R` is not a calibration statistic. Per prereg §2(a) a high `R` there is a degeneracy signal, never
  a safety margin. The retracted phrase *"conservatism is harmless"* stays retired.
- **Opening the guard**, shipping either link, or anything about `c_n` (that is G2, still not run).
- **Any claim for cloglog-mirrored**, in either direction, until the arm is re-specified — the honest
  fix is to generate under log-log and fit log-log, which is a different campaign.

## 6. Provenance

Prereg `853ad0bd8`, branch `claude/mspl-nonlogit-evidence`; drmTMB 0.7.0 built on Totoro into
`~/R/g1blib`; glmmTMB 1.1.14 (identical version locally and on Totoro); 100 workers,
`OPENBLAS_NUM_THREADS=1`; finished `2026-08-11T18:05Z`. Raw `data/g3_raw.tsv.gz` (180,000 rows,
18 fields, uniform), per-cell `G3-cell-results.csv`, console `G3-grading.log`, runner `g3_runner.R`,
scorer `analyse_g3.R`.

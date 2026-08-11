# G1 verdict — TMB-Laplace finiteness for MSPL, probit and cloglog

Graded 2026-08-11 against `PREREGISTRATION.md`, frozen at `9ebffaf0` before any replicate, with the
`η_d` grids frozen in `S3-CALIBRATION.md`. 88 cells × 500 replicates × 2 engines = **88,000 fits**,
Totoro, 100 cores, **11 minutes** (declared estimate 20–30 min; under, and reported either way).

**Per link/orientation, never pooled** — doc 253 §3: *"clearing probit is NOT evidence for cloglog."*

| condition | cells | fits finite | rate | verdict |
|---|---|---|---|---|
| logit (control) | 22/22 | 11,000 / 11,000 | 1.000000 | **PASS** — reproduces F1 |
| **probit** | 22/22 | 11,000 / 11,000 | 1.000000 | **PASS** |
| **cloglog-mirrored** | 22/22 | 10,998 / 11,000 | 0.999818 | **PASS** |
| **cloglog-standard** | 20/22 | 10,967 / 11,000 | 0.997000 | **FAIL** |

## The claim this licenses, exactly

> On the frozen grid, drmTMB's MSPL estimator under **TMB-Laplace** returned a finite interior
> estimate with finite, positive fixed information in **11,000 of 11,000** fits under **probit** and
> **10,998 of 11,000** under **cloglog with the response mirrored**, including every cell in which
> maximum likelihood demonstrably diverged. Under **cloglog in the as-generated orientation** it did
> so in 10,967 of 11,000 fits, which **misses** the pre-registered per-cell threshold in 2 of 22 cells.

This is drmTMB's own numerical evidence for two links it has never fitted under MSPL. It is **not** a
re-proof of existence — Kosmidis & Firth (2021) Thm 1 + §3.1 + Table 1 settled that for any link with
`ω(η) → 0` in both tails, and this campaign does not touch it. It replaces *"the authors' evidence, on
glmer, for logit"* with *"ours, on TMB, for probit and cloglog"*, exactly as F1 did for logit.

## The harness is valid

The logit control reproduces F1: **20/20 main cells PASS at `prop = 1.000`**, matching F1's own
`primary_prop = 1.000`. Per §3(a), a logit failure would have meant the harness changed and no
probit or cloglog number could be read. It did not.

**Link integrity — no silent logit fallback.** Every MSPL fit reports the link it was asked for
(11,000 probit rows report `probit`, 10,967 cloglog rows report `cloglog`, 0 report `logit`; the
remaining rows are the errored fits, whose `fit$mspl` is absent). This mattered: until this branch,
`src/drmTMB.cpp` hardcoded the logit weight, and the whole campaign would have measured a logit
penalty wearing a probit label (`BLOCKER-tmb-mspl-is-logit-only.md`).

## Where cloglog-standard fails, and why it is not being rescued

| cell | q | `η_d` | G | finite | rate | CP lower | ML divergence |
|---|---|---|---|---|---|---|---|
| 57 | q2 | −5 | 12 | 490/500 | 0.980 | 0.9635 | 0.670 |
| 60 | q2 | −7 | 30 | 484/500 | 0.968 | 0.9486 | 0.872 |

Both are **q2** (random slope), both in the as-generated orientation, and the mechanism in all 33
cases is identical: *"`drmTMB()` failed in all `stats::nlminb()` optimizer preset attempts."*

**These are optimizer failures, not demonstrated non-finiteness.** It would be easy to argue they
should not count — the estimate may well be finite and simply not reached. **That argument is
declined.** §6 declared, before any replicate, that a missing endpoint counts as a failure of E2 and
is never a dropped row, precisely because E1's first scorer filtered with `is.finite()` and removed
the values that were the evidence. Reclassifying a failure after seeing which way it fell is the
error §8.6 exists to prevent. **cloglog-standard fails the pre-registered rule, and the honest
report is that it fails**, with the mechanism named so a later arc can attack the optimizer rather
than the estimator.

Note the asymmetry this exposes: **cloglog's two orientations behave differently under the same
grid** — mirrored passes (2 failures), standard does not (33). That is the asymmetry doc 253 §4
predicted, showing up as an optimizer-robustness difference rather than a finiteness one.

## The control does not hold everywhere — the campaign's main limitation

`S3` calibrated `η_d` at **q1, G = 12**. The graded grid also contains **q2** and **G = 30**, and the
control condition (ML divergence ≥ 50%, §7) does **not** transfer across them:

| condition | deep cells meeting the control | of |
|---|---|---|
| logit | 9 | 22 |
| probit | **3** | 22 |
| cloglog-standard | 6 | 22 |
| cloglog-mirrored | 6 | 22 |

Restricting to only those cells where ML demonstrably diverged — the cells where "MSPL stayed finite"
is a non-vacuous statement:

| condition | fits | finite | rate |
|---|---|---|---|
| logit | 4,500 | 4,500 | 1.000000 |
| **probit** | 1,500 | 1,500 | 1.000000 |
| cloglog-standard | 3,000 | 2,969 | 0.989667 |
| cloglog-mirrored | 3,000 | 2,998 | 0.999333 |

**Probit's PASS therefore rests on 3 cells, not 22.** The other 19 are consistent with it but cannot
distinguish "the penalty saved the fit" from "the fit never needed saving." This is a real limit on
the strength of the probit claim and is stated here rather than buried: a wider probit campaign should
re-calibrate `η_d` **per (q, G)**, not once at q1/G=12.

Per §4's closing paragraph and §7, this is reported as a finding, **not** patched by relaxing the
threshold.

## The adversarial corner tested small `c_n`, but mostly not under separation

All 8 corner cells PASS at `prop = 1.000` with `c_n = 0.0447` (≤ 0.05, requirement (c) satisfied).
But the corner is largely **not a separation regime**, and the reason is the finding F2 already
recorded — difficulty tracks the **absolute number of events**, not the rate:

| cell | condition | `η_d` | event rate | expected events (n = 4,000) | ML divergence |
|---|---|---|---|---|---|
| 81 | logit | −10 | 0.0000 | 0 | **0.980** |
| 82 | logit | −6 | 0.0058 | 23 | 0.000 |
| 83 | probit | −4.2 | 0.0025 | 10 | 0.248 |
| 84 | probit | −3 | 0.0285 | 114 | 0.000 |
| 85 | cloglog-std | −7 | 0.0020 | 8 | 0.080 |
| 86 | cloglog-std | −5 | 0.0158 | 63 | 0.002 |
| 87 | cloglog-mir | −8.4 | 0.9995 | 2 non-events | 0.206 |
| 88 | cloglog-mir | −6 | 0.9943 | 23 non-events | 0.000 |

The same `η_d` that separates at `n = 120` does not at `n = 4,000`, because the event count scales
with `n` while the rate does not. **So the corner shows MSPL is well-behaved at small `c_n`, but not
that it rescues separation at small `c_n`** — the two deepest `η_d` per condition were selected for
their behaviour at `G = 12`. A corner that genuinely stresses both at once needs `η_d` chosen to hold
the expected event **count** near zero at `n = 4,000`, roughly 3.5 log-odds deeper.

## Secondary endpoint (reported, not gating)

Median `final_logdet_fixed_information` declines monotonically with depth within every
`(q, G)` stratum for **logit, probit and cloglog-standard** — the coercivity signature, measured at
the fitted optimum. **cloglog-mirrored does not**, which is unsurprising: its extreme cells drive the
event rate to 1 rather than 0, so the information behaves differently along that path. Reported, not
gating, exactly as declared.

## What this does NOT license

Unchanged from `PREREGISTRATION.md` §2, and none of it is softened by a PASS:

- **The MSPL guard stays closed.** `R/mspl-estimator.R` continues to reject non-logit on `main`. The
  bypass used here is an undocumented option on an evidence branch and must not merge.
- **Not authorisation to ship probit or cloglog.** The softness constant `c_n = 2√(p/n)` is a
  **logit** delta-method result (doc 253 Addendum 3; 2023 §7). Verified this session against the
  shipped kernel: `ω(0)` is `1/4` for logit, `2/π` for probit, and `1/(e−1)` for cloglog, giving
  per-link constants 2, 1.2533 and 1.3108. **G1 tested finiteness under the as-shipped, known-
  miscalibrated `c_n`** and says nothing about whether that `c_n` gives correct asymptotic softness.
  That is G2, and it is not run.
- **Says nothing about intervals or standard errors.** KF2021 §2.1 p. 75 proves Wald intervals fail
  to cover under separation at any nominal level, link-generally.
- **Not a proof.** Numerical evidence on a frozen grid.

## Provenance

Campaign SHA `9ebffaf0` (branch `claude/mspl-nonlogit-evidence`); drmTMB **0.7.0** built on Totoro
into `~/R/g1lib` from that tree; R 4.x, TMB 1.9.21, Matrix 1.7.5, detectseparation 0.4.0; Totoro,
384-core host, 100 workers, `OPENBLAS_NUM_THREADS=1`; finished `2026-08-11T14:33:00Z`.
Raw `data/g1_raw.tsv.gz` (88,000 rows, 24 fields, uniform), per-cell `G1-cell-results.csv`, grading
console `G1-grading.log`, runner `g1_runner.R`, scorer `analyse.R`.

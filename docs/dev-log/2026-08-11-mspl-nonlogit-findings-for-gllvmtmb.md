# For the gllvmTMB MSPL lane — seven findings from drmTMB's non-logit campaign

Written 2026-08-11 from drmTMB branch `claude/mspl-nonlogit-evidence`. Relevant to gllvmTMB design 117,
design 88, and PR #952 (`codex/lane-b-mspl-reconcile-951`), which admits logit/probit/cloglog for
LA-MSPL behind a point-estimation-only fence and records its all-link evidence campaign as outstanding.

Everything below is measured unless marked otherwise. drmTMB's guard is still closed; none of this
authorises shipping anything in either package.

---

## 1. CHECK YOUR C++ FIRST — we had a hardcoded logit weight and nothing caught it

**The highest-value item here, and the one most likely to apply to you directly.**

`src/drmTMB.cpp`'s MSPL block computed the Jeffreys working weight as
`log(n) − softplus(η) − softplus(−η)` — the **logit** weight — with no link branch, while our R-side
kernels had been link-general for some time. Two implementations of one estimator, disagreeing for
probit and cloglog.

Nothing detected it because our entry-point guard admits only logit, so the disagreement was
unreachable from the public API. **If you admit probit/cloglog through a fence and your penalty is
computed in C++, verify the C++ dispatches on the link.** A campaign run against that defect returns
finite, plausible, entirely wrong numbers — every fit "works", and the wrongness is invisible.

Worse, the link-general primitive already existed in our tree, documented *"Used ONLY by the MSPL
Jeffreys weight"* — and was **never called**. `grep` for your equivalent.

The regression test that catches it must assert the penalty **differs by link** on identical inputs.
A test that only checks "probit runs" passes against the broken version. (This is the second time
this exact failure mode has bitten us — our design 253 §7 records the first, in the R composite.)

Our fix, if useful: drmTMB PR [#1012](https://github.com/itchyshin/drmTMB/pull/1012).

## 2. Both cloglog orientations are mandatory, and they need different separation depths

cloglog is asymmetric: `ω = Θ(e^(2η−e^η))` as `η→+∞` against `Θ(e^η)` as `η→−∞`. Fitting `y` and
fitting `m−y` under cloglog are genuinely different problems — the second is the log-log link on the
original response — so **one orientation evidences only one tail**.

Measured, not assumed: calibrating separation depth so ML diverges in ≥50% of replicates needed
**`η_d = −5` for the as-generated orientation and `−6` for the mirrored one**, at `q1, G = 12`. The
asymmetry is not just a statement about tail orders; it moves the operating point by a full unit.

They also fail differently. In our first run the as-generated orientation lost 33 fits and the
mirrored orientation 2 — same link, same grid, same replicate count.

## 3. Separate "the optimizer completed" from "the estimate is finite" — or you will misread your own result

We graded one composite endpoint (finite information ∧ finite logdet ∧ finite β̂) with NA counting as
failure. That rule is correctly one-sided — it can produce a false FAIL but never a false PASS — but
it **cannot distinguish the estimator diverging from the optimizer not returning**.

It cost us a wrong conclusion. cloglog-standard was graded FAIL in 2 of 22 cells. On inspection: **33
errors, 0 non-finite estimates**, and plain ML errored on **33 of the same 33 datasets**. The FAIL
meant *"not demonstrated"*, and we briefly read it as *"demonstrated to fail"* and were about to
document a limitation that does not exist.

Re-run on a fresh seed stream with two endpoints — completion, and finiteness **given** completion —
plus a guard that a cell below 90% completion is reported `INSUFFICIENT-COMPLETION` and claimed in
neither direction (otherwise one completed fit reads as "100% finite"):

| condition | completion | completed fits | **non-finite among them** |
|---|---|---|---|
| logit (control) | 1.000000 | 11,000 | **0** |
| probit | 1.000000 | 11,000 | **0** |
| cloglog-standard | 0.997545 | 10,973 | **0** |
| cloglog-mirrored | 0.999909 | 10,999 | **0** |

**0 of 43,972 completed MSPL fits returned a non-finite estimate.** 88 cells, 88,000 fits, 500
replicates per cell, both `q`, `G ∈ {12, 30}` plus a `G = 400` corner.

If you design your campaign with the split endpoint from the start, you avoid the detour entirely.

## 4. Separation tracks the absolute event COUNT, not the prevalence — again

Your "detect, don't filter" stance on rarity is right, and our adversarial corner re-confirms it from
a second direction. At `n = 4,000`, the same `η_d` that separates at `n = 120` does not separate at
all:

| `η_d` | event rate | expected events | ML divergence |
|---|---|---|---|
| −10 (logit) | 0.0000 | 0 | **0.980** |
| −6 (logit) | 0.0058 | 23 | 0.000 |
| −3 (probit) | 0.0285 | 114 | 0.000 |
| −5 (cloglog) | 0.0158 | 63 | 0.002 |

**A prevalence threshold is the wrong filtering instrument for rare species** — two designs at the
same rate sit on opposite sides of estimability depending on `n`. Our earlier F2 campaign found the
same thing from the rare-prevalence side (cells at 8.5e−4 vs 8.0e−4 diverging in 98% vs 37% because
one expects 0.25 events and the other 4).

Practical consequence for your sweep design: choose cells by **expected event count**, or your
large-`n` corner will silently stop being a separation experiment.

## 5. `c_n = 2√(p/n)` is a logit constant — the per-link values, with closed forms

Sterzinger & Kosmidis (2023) §7 derive `c` from the approximate variance of `η̂` **at β = 0**, so the
constant is `ω(0)^(−1/2)`. Verified against our shipped kernel to machine precision:

| link | `ω(0)` closed form | value | `c_n` factor |
|---|---|---|---|
| logit | `1/4` | 0.250000 | **2** |
| probit | `2/π` | 0.636620 | **1.2533** |
| cloglog | **`1/(e−1)`** | 0.581977 | **1.3108** |

**A trap worth flagging:** for cloglog, `ω(0) ≠ sup ω`. The supremum is 0.647610 at `η = 0.4661`
(solving `2 − 2e^(−x) = x`, `x = e^η`). Logit and probit are symmetric so the two coincide; cloglog is
not. Anchoring on the supremum gives 1.2426 instead of the correct **1.3108**. If your design docs
tabulate `sup ω` for the Cauchy–Binet argument (ours does), that is not the constant the delta-method
calibration wants.

Neither package varies `c_n` by link today. We have **not** run the sensitivity study (our G2); if you
do, we would like to see it.

## 6. Kosmidis & Firth (2021) settles the link condition — don't re-derive it

Biometrika **108**(1), 71–82, Theorem 1 with §3.1 and Table 1: for any link whose working weight
`ω(η) = g(η)²/[G(η){1−G(η)}]` vanishes as `η` diverges to either `±∞`, the Jeffreys-penalized
estimates have finite components. **Logit, probit, cloglog, log-log and cauchit are named
explicitly.** The only structural requirement is `X` of full rank, and it holds for any penalty power
`a > 0`.

We spent three rounds of derivation across three days reaching successively less wrong conclusions
before obtaining that paper, including one round that confidently asserted the condition was
insufficient. The transferable half: **declining to verify is right; asserting the negative from a
source that is merely silent is not.**

What remains genuinely open is the **Laplace** half — the authors' numerical evidence is glmer's, and
it is link-independent, so it applies to the logit route you already ship as much as to probit.
Item 3 above is our contribution to that gap.

## 7. Where the estimator genuinely runs out

Every one of our optimizer failures was `q2` (correlated random slope) with **0–3 events in 120
observations** — a 2×2 random-effect covariance asked of essentially no events. Three facts pin it:
`q1` fits the same data without complaint; `multi_start = 5` rescues about a quarter; and plain ML
fails on 100% of the same datasets, so MSPL is never strictly worse.

That is an identifiability wall, not a tuning failure, and we think the right response is a
diagnostic that names it rather than an optimizer chase. Flagging it because your latent-variable
structure will meet the same wall earlier than ours does.

One partial fix worth stealing anyway: we started `β = 0` for all coefficients, which for cloglog
implies an event rate of `1 − exp(−1) = 0.632`, so a design with one event in 120 began ~4.8 log units
from its own intercept. Starting the **intercept** at the link of the observed rate (clamped by half
an observation, slopes still 0) is deterministic, finite, avoids a divergent GLM start, and moved our
failures 33 → 28 with no regression. It is an improvement, not a cure.

---

## Artifacts

Branch `claude/mspl-nonlogit-evidence` in drmTMB:

- `docs/dev-log/simulation-artifacts/2026-08-11-mspl-nonlogit-links/` — both pre-registrations,
  runners, scorers, raw data (88,000 + 88,000 rows), and both verdicts
- `S3-CALIBRATION.md` — the per-link separation-depth calibration and its selection rule
- `BLOCKER-tmb-mspl-is-logit-only.md` — finding 1 in full
- `docs/design/253-mspl-nonlogit-links-derivation.md` (on `main`) — the derivation and its three
  addenda, including the two that corrected it

Happy to hand over runners or re-run cells against your grid; the harness takes ~7 minutes for 88,000
fits on Totoro at 100 cores.

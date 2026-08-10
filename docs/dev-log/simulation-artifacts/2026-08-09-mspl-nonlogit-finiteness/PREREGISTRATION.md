# PRE-REGISTRATION — MSPL non-logit finiteness probe (E1)

Written **2026-08-09, before any fixture was run.** Owner authorization: *"Totoro go"*, and
*"get some statisticians around and discuss"* — this probe implements the criterion the discussion
produced. Compute: **Totoro**. Never GitHub Actions (D-50).

Design basis: **`docs/design/253-mspl-nonlogit-links-derivation.md` §4** (Noether). This document
does not re-derive the criterion; it fixes the grid, the decision rule, and the abort conditions.

## 1. Aim

drmTMB's MSPL is logit-only. Doc 253 shows the **fixed-effect** finiteness argument extends to
probit and cloglog, and localises the gap to **coercivity of the mixed-effects (Laplace) criterion**.
This probe asks the one empirical question that would justify opening the guard:

> **Does the MSPL objective actually descend to −∞ along every escape ray, for probit and for
> cloglog, in the mixed-effects case?**

If it does not descend on even one fixture, the estimator can run off to infinity there and the
guard must stay.

## 2. Honest disclosure — what is already known

- **The fixed-effect half is settled** (doc 253 §2): `w(η) → 0` in both tails for all three links,
  so `det XᵀWX → 0` along every ray. This probe is **not** about that half.
- **The gap is coercivity, not boundedness.** Two candidate obstructions — non-concavity and
  unboundedness — were derived and **eliminated** (§3). This probe tests attainment only.
- **Cloglog is expected to be the harder case.** `κ₀(η) = e^η` is unbounded, so no parameter-free
  sandwich exists. **Probit retains one with `C = 1`.** A probit PASS is therefore the *expected*
  outcome and is weak evidence; a **cloglog PASS is the informative result.**
- **Clearing probit is NOT evidence for cloglog.** They are graded separately and neither inherits
  the other's verdict.
- **Sister-package position:** gllvmTMB PR #952 admits all three links for LA-MSPL behind a
  point-estimation fence, and records that its own all-link campaign is still outstanding. Nobody
  has this evidence yet.

## 3. Estimand and decision rule — frozen before any number exists

For a fitted `β̂` and an escape direction `δ` (unit-norm, spanning the design's null/separation
directions), define the **profiled ray**

```
R(t) = max_ψ  ℓ_MSPL(β̂ + t·δ, ψ)          t ∈ [0, 10⁴]
```

where `ψ` is the variance block, re-optimised at each `t`.

**PASS (per fixture)** requires **all three**:
1. `R(t)` is **strictly decreasing** past some `t₀`;
2. total drop `R(t_max) − R(t₀) < −50` nats;
3. the tail slope matches the §2 predicted order for that link.

**FAIL:** any fixture where `R(t)` is non-decreasing in the tail.

> **ONE non-decreasing fixture FALSIFIES the link.** Not a majority, not an average. This is an
> attainment question: a single escape ray that does not descend means the maximiser need not exist.

Also run, as a **secondary** check (E2): bound-insensitivity across `(B,S) = (10,3), (10²,6),
(10³,9)`, requiring `‖θ̂_B3 − θ̂_B2‖_∞ < 10⁻⁴`.

**Explicitly NOT sufficient:** a high "converged finite" rate at one bound. That measures the
optimiser, not the criterion, and must not be reported as evidence.

## 4. Grid — frozen

| factor | levels |
|---|---|
| link | **logit (control)**, probit, cloglog, **cloglog with `y ↦ m − y`** |
| q | 1, 2 |
| G (groups) | 5, 10, 20, 40 |
| n_g | 2, 5, 10 |
| σ | 0.25, 1, 2, 4 |
| p | 2, 4 |
| separation | complete, quasi, incidental, none |

**Both cloglog orientations are mandatory.** Cloglog is asymmetric, so `y` and `m − y` are
genuinely different models and a PASS on one says nothing about the other.

**Adversarial corner required:** large `n_eff` with small `p`, so `c_n = 2√(p/n_eff) ≲ 0.05` — the
regime where the Jeffreys term is weakest relative to the likelihood and least able to enforce
descent.

**Logit is the control.** If logit fails this probe, the harness is wrong, not the estimator —
because logit's finiteness is proved. A logit failure aborts the run (§6).

## 5. What a result licenses

**A cloglog + probit PASS licenses:** *"On the tested grid, the MSPL objective descends along every
examined escape ray for probit and cloglog"* — which is **evidence toward**, not a proof of,
coercivity. It would justify moving to intermediate (D) and then a fenced experimental route. It
would **not** license a finiteness *guarantee*, which requires the derivation doc 253 §6 says is
missing.

**It does NOT license:** opening the public guard on this evidence alone; any interval or coverage
claim; any capability-ledger movement; extending to links outside {probit, cloglog}.

**A FAIL licenses:** keeping the guard, with a documented and *measured* reason — which is
strictly better than the current position of keeping it on a literature gap alone.

## 6. Stopping and abort rules

1. **Control gate.** If the **logit** control fails on any fixture, **STOP** — the harness is
   wrong. Do not interpret probit/cloglog results from a run whose control failed.
2. **Smoke gate.** One fixture per link must produce a non-empty, non-NA, monotone-in-`t` ray before
   the grid launches. Inspect one ray past its guards.
3. **First-fixture gate.** Read the first completed fixture early; abort on empty/NA output.
4. **Courtesy cap.** Totoro is shared. ≤ 150 cores, `OPENBLAS_NUM_THREADS=1`.
5. **No silent truncation.** Every fixture that fails to complete is reported with its reason. A
   probe covering 3000 of 3072 fixtures is reported as 3000 of 3072.
6. **No post-hoc rule edits.** §3 is frozen. If the `−50` nat threshold or `t_max` proves wrong,
   that is a finding to report, not a parameter to retune.

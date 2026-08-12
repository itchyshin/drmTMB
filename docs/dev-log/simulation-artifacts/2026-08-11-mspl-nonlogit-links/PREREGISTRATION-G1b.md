# G1b — separating "the optimizer finished" from "the estimate is finite"

**FROZEN 2026-08-11, before any G1b replicate.** Amendment to `PREREGISTRATION.md`, run on a
**fresh seed stream**. This is deliberately **not** a rescore of G1: applying a new rule to data whose
outcome is already known is precisely what §8.6 of the parent document forbids, and doing it would
make the result worthless regardless of which way it fell. G1's verdict stands as written.

## 1. Why this run exists

G1 graded a single composite endpoint: `E1 ∧ E2 ∧ E3` (finite positive fixed information, finite
`logdet`, finite `β̂`), with a missing value counting as a failure and never a dropped row. That NA
rule is **one-sided** — it can produce a false FAIL but never a false PASS — which is the correct
direction of caution for a finiteness claim, and it is why G1 is not being rescored.

But it conflates two different events:

1. **the estimator returned a non-finite estimate** — the property G1 set out to measure;
2. **the optimizer never returned** — a property of `nlminb` and the starting point.

In G1, cloglog-standard's 33 losses were **33 errors and 0 non-finite estimates**, and plain ML
errored on **33 of the same 33 datasets**. So G1's FAIL for that condition records *"not
demonstrated"*, not *"demonstrated to fail"* — and one number cannot say which. G1b measures the two
separately so neither can hide the other.

## 2. The two endpoints, declared now

Per MSPL fit:

| id | endpoint | definition |
|---|---|---|
| **C** | **completed** | `drmTMB()` returned without error **and** `fit$mspl` is populated |
| **F** | **finite given completion** | among completed fits only: `E1 ∧ E2 ∧ E3`, defined exactly as `PREREGISTRATION.md` §6 |

`E1` = `fixed_information_finite_positive`, `E2` = finite `final_logdet_fixed_information`,
`E3` = `is.finite(β̂)` — unchanged, so F is comparable to G1's endpoint on the completed subset.

## 3. Decision rule, and the guard that stops F laundering the answer

Per cell, over 500 replicates:

- **COMPLETION** = `n_completed / 500`. **Reported for every cell**, never gating on its own.
- **FINITENESS** holds iff, among the **completed** replicates, `E1 ∧ E2 ∧ E3` in **≥ 99%** with a 95%
  Clopper–Pearson lower bound **≥ 0.97**, computed with `n = n_completed`.

**The guard.** Conditioning on completion is exactly the filtering that cost the halted E1 probe its
run, so it is fenced: **a cell with COMPLETION < 0.90 is reported `INSUFFICIENT-COMPLETION` and its
FINITENESS is not claimed in either direction.** Without this, one completed-and-finite fit out of 500
would read as "100% finite," which is the failure mode this amendment could otherwise introduce.

A condition's verdict is:

- **PASS** — every cell has COMPLETION ≥ 0.90 and FINITENESS holds.
- **COMPLETION-LIMITED** — FINITENESS holds wherever evaluable, but ≥ 1 cell is below 0.90 completion.
  This is the honest label for "the estimator looks fine and the optimizer is the problem."
- **FAIL** — FINITENESS fails in ≥ 1 evaluable cell. **This is the only outcome that is evidence
  against MSPL finiteness**, and none of G1's cloglog losses were of this kind.

## 4. What is frozen, and what differs from G1

**Identical to G1:** the DGP forms (q1, q2), `G ∈ {12, 30}`, `n_per = 10`, `σ_u = 0.7`, `σ_u1 = 0.4`,
`β = 1.0`, the four link/orientation conditions, the `η_d` grids frozen in `S3-CALIBRATION.md`, the
88-cell layout including the `G = 400` adversarial corner, 500 replicates, and both engines.

**Differs, deliberately, and only here:**

1. **Fresh seeds.** `seed = 20260812 + 100000 * cell + rep`. The date prefix differs from G1's
   `20260811` and F1's `20260810`, so no replicate is one whose outcome has already been seen.
2. **The endpoints above**, replacing G1's single composite.
3. **The estimator includes the intercept start fix** (`425719c37`): the MSPL intercept now starts at
   the link of the observed event rate rather than at 0. G1b therefore measures drmTMB as it now
   stands, not as it stood during G1. Stated because it makes G1b's completion rate **not** directly
   comparable to G1's — the finiteness endpoint remains comparable.

## 5. Control, unchanged

`PREREGISTRATION.md` §7 applies verbatim: ML must diverge or fail in ≥ 50% of replicates in each
condition's two deepest cells, and the logit arm must reproduce F1 or the harness is void. The
same limitation G1 found — S3 calibrated `η_d` at q1/G=12 and the control does not transfer to all
(q, G) strata — is expected to recur and will be reported the same way, scoped rather than patched.

## 6. What G1b cannot do

It cannot overturn G1. If FINITENESS holds everywhere evaluable, the correct conclusion is *"on a
fresh seed stream, with completion reported separately, no non-finite cloglog estimate was
observed"* — which is evidence that the G1 FAIL was an optimizer artefact, not a licence to relabel
G1's own verdict. It still does not open the guard, authorise shipping, or say anything about `c_n`,
intervals, or standard errors.

## 7. Stopping rules

Unchanged from `PREREGISTRATION.md` §8: smoke one cell per condition before the grid, read the first
cell of each condition early and abort that condition on empty/all-NA output, and state the
wall-clock estimate before the run — **~11 minutes on Totoro at 100 cores**, from G1's measured
88,000 fits — stopping and re-reporting on overrun rather than continuing quietly (D-139).

# Pre-registration — D-117, the 10-group profile RE-SD coverage gate

**Written and committed BEFORE any production fit of the new cells runs.**
Its purpose is that the result cannot be rationalised after the fact. If the
number comes back bad, this document is what says so.

**Date:** 2026-08-04 · **Platform:** Claude (Claude Code), solo · **Lane:**
drmTMB D-117 gate, reassigned to Claude this session (D-117's own ledger note had
placed it in the codex lane). **Compute:** Totoro (D-50 — never GitHub Actions).

## 1. Aim

D-117 (accepted 2026-08-03) holds drmTMB 0.7.0 until a fixed-seed 10-group
recovery/coverage number exists for the **profile** random-effect SD interval.
**The deliverable is the measurement, not a pass.**

The gate exists because a pooled figure can hide a bad smallest-group cell, and
that is demonstrated behaviour of this estimator, not a hypothesis: the
**marginal** route ran **0.810 / 0.889 / 0.915 at 10 / 25 / 50 groups** against a
pooled 0.871. D-97 accepted the profile route's pooled **0.9368 [0.9323, 0.9411]**
and explicitly declined to measure this corner.

## 2. Honest disclosure — what is ALREADY known

This is stated up front because it bounds what this pre-registration can claim to
be blind to.

A profile measurement at 10 groups **already exists**, on the unpushed local
branch `codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`), from a cap-compliant
clean rerun on 2026-07-26:

| Groups | Method | Coverage (95% exact CI) | Valid | Lower / upper misses |
|---:|---|---|---:|---|
| 10 | Marginal bootstrap | 0.829 (0.804, 0.852) | 1000/1000 | 0 / 171 |
| **10** | **Profile** | **0.937 (0.920, 0.951)** | 1000/1000 | **10 / 53** |
| 10 | Wald | 0.988 (0.979, 0.994) | 997/1000 | 7 / 2 |

That cell is `n_per = 10`, `sd_mu = 0.5` — i.e. **N = 100**. I therefore am **not
blind** to it, and no rule below should be read as having predicted it.

**What is NOT known, and is what this arc measures:** the A1 grid crosses
`n_per ∈ {4, 10}` with `sd_mu ∈ {0.5, 1.0}`, so the 10-group corner has **four**
cells. Three have never been measured on the profile route — including
**`n_per = 4` (N = 40), the genuinely worst corner**. The 2026-07-26 report says
so itself. A gate answered from one cell out of four is not answered.

## 3. Data-generating process and estimand

Unchanged from the existing harness, so the new cells are comparable to the
banked one:

```
g   = factor(rep(1:n_groups, each = n_per))
x   ~ N(0, 1)
u   ~ N(0, sd_mu)                       # the random effect being measured
y   = 1 + 0.5 * x + u[g] + N(0, 0.7)    # TRUE_BETA = 0.5, TRUE_SIGMA = 0.7
fit = drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian())
```

**Estimand:** `sd:mu:(1 | g)`, the random-effect standard deviation. **Truth** is
`sd_mu`. **Interval:** `confint(fit, parm = "variance_components",
method = "profile", profile_engine = "auto")`. Nominal level 95%.

**Coverage** = fraction of attempts whose profile interval contains `sd_mu`,
computed over **all attempts**, not only successful ones — an unavailable interval
counts against the method, it is not silently dropped.

## 4. Design

| Cell | n_groups | n_per | sd_mu | N | Status |
|---|---:|---:|---:|---:|---|
| `g10_n04_sd05` | 10 | 4 | 0.5 | 40 | **NEW — the worst corner** |
| `g10_n04_sd10` | 10 | 4 | 1.0 | 40 | **NEW** |
| `g10_n10_sd10` | 10 | 10 | 1.0 | 100 | **NEW** |
| `g10_n10_sd05` | 10 | 10 | 0.5 | 100 | already measured: 0.937 |

**Replicates:** `n_rep = 1000` per new cell, matching the banked cell exactly so
the four are comparable. At coverage ≈ 0.94 this gives MCSE ≈ 0.0075, a 95%
half-width of ±1.5 pp — enough to separate "at nominal" from "materially below".

**Seeds:** the existing arithmetic family, `seed = 20260727 + 100000 * cell_i + r`,
with **new cell indices 4, 5, 6** so no seed collides with the banked cells 1–3.
Fixed and recorded; this is the "fixed-seed" D-117 requires.

**Method:** profile and Wald only. **The R = 999 bootstrap is dropped** — it is
~99% of the compute, its 10-group behaviour is already measured (0.829), and
D-117 asks about the profile route.

## 5. THE DECISION RULE — frozen here, before the number exists

Scored with the repo's own two-tier gate (`tools/gate-inference-ready.R`), not a
rule invented for this arc. Its floor is
`ss_floor(g) = 0.95 − 0.04 × (8 / g)`, so **`ss_floor(10) = 0.918`**, and its test
is `coverage + 2 × MCSE ≥ floor` — i.e. *not significantly below* the floor.

| Verdict | Condition | Consequence |
|---|---|---|
| **PASS** | **every** tested 10-group cell has `coverage + 2×MCSE ≥ 0.918`, and each has ≥ 95% of attempts returning a finite ordered interval | The 10-group corner is not materially worse than pooled. Gate discharged; 0.7.0 publish returns to being purely Shinichi's call (D-93 / CI-17) |
| **BORDERLINE** | any cell in `0.880 ≤ coverage + 2×MCSE < 0.918` | Gate **not** discharged automatically. The number is reported with the shortfall named, and whether to publish becomes an explicit owner decision on stated evidence |
| **FAIL** | any cell with `coverage + 2×MCSE < 0.880`, **or** any cell where > 5% of attempts fail to return a finite ordered interval | The corner IS materially worse. **0.7.0 stays held.** Reported plainly, no reframing |

**Anti-rationalisation clauses, binding:**

1. **No cell is dropped after seeing its result.** All four 10-group cells are
   reported. If a cell fails, it is not reclassified as "out of scope".
2. **`n_per = 4` is not exempt.** It is the worst corner and the reason this arc
   exists. A PASS that excludes it is not a PASS.
3. **The rule is not re-tuned.** If the outcome is BORDERLINE, the answer is
   "borderline", not a widened floor.
4. The banked `n_per = 10, sd_mu = 0.5` cell is scored by the same rule for
   consistency, but it is **not** evidence that this pre-registration predicted.

## 6. Mandatory diagnostics — reported regardless of verdict

A coverage number alone can be right for the wrong reason. All of these are
reported even on a PASS:

1. **Directional miss balance** — lower vs upper misses. The banked cell
   **already fails** this: 53 upper vs 10 lower. Under the repo's two-tier
   doctrine that is `SUPPORTED = FAIL` while `INFERENCE_READY` can still pass; at
   small `g`, upper-tail skew is *expected*, not a defect. **This arc does not
   claim `supported`.**
2. **Boundary contact.** At 10 groups the variance component sits near zero. A fit
   can report `convergence = 0, pdHess = TRUE` with the component pinned, which
   would make coverage look fine for the wrong reason. Report the fraction with
   `estimate_sd < 1e-3` and the fraction with `profile_boundary = TRUE`. The
   banked cell had **63/1000 profiles reaching the zero boundary**.
3. **Convergence and `pdHess` rates**, and the count of non-finite or
   disordered intervals.
4. **Median interval width**, so an over-wide interval buying coverage is visible.

## 7. What the result licenses — and does not

- It licenses a statement about **the 10-group corner of the A1 scalar Gaussian
  RE-SD profile interval**, at the tested `n_per` and `sd_mu`. Nothing broader.
- It does **not** revise D-97's accepted pooled figure, promote any capability
  ledger cell, or move the census (**182 / 60 must be unchanged at close**).
- It does **not** claim `supported`; the directional-miss asymmetry is a known,
  expected small-`g` effect and is out of scope to fix here.
- Per dr20 (~90 sources, 2026-08-03): the literature has **no interval-coverage
  benchmark for a variance component below M ≈ 10–15**, so this is novel evidence
  rather than a replication — which is a reason to report it carefully, not a
  reason to overclaim.

## 8. Stopping and abort rules

- **Smoke first**: one cell, one seed, before the grid. Confirm non-empty,
  non-NA, in-range output and inspect one fit *past its guards*. Abort on
  anything empty, NA, or out of range.
- **Read the first cell's output early.** Abort the moment it looks broken rather
  than waiting for the whole grid.
- Totoro etiquette: **≤ 100 cores**, `OPENBLAS_NUM_THREADS=1`, results local.
- If the harness cannot reproduce the banked `g10_n10_sd05` cell's behaviour
  within Monte-Carlo error, **stop and investigate** rather than reporting the new
  cells — that would indicate the runner or package drifted since 2026-07-26.

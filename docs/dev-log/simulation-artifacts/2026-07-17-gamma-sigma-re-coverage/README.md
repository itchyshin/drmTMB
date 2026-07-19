# mc-0242 — Gamma sigma random-intercept interval + coverage evidence (Arc 4b)

**Date:** 2026-07-17 · **Cell:** `mc-0242` (gamma / model_type 5 / dpar `sigma` /
`ordinary_re_intercept`) · **Promotion:** `point_fit_recovery` → `inference_ready_with_caveats`
over M ∈ {16, 32, 64}. Direct sibling of the lognormal `mc-0382` (Arc 4a) and the beta-phylo
`mc-0017` arc, reusing the same methodology (Wald + profile coverage, a pre-registered gate, D-43).

## What this is

The Gamma σ random intercept `(1 | id)` gained `point_fit_recovery` in Arc 2c (60-seed bias sweep,
rel-SD-bias −3.0%). Its `next_gate` required a target-specific interval + coverage campaign before
any inference promotion. This is that campaign. The design was frozen **before compute** in
`docs/dev-log/2026-07-17-mc0242-gamma-sigma-coverage-estimand-alignment.md` (rev 2), plan-reviewed by Fisher + Rose
(both CONDITIONAL-DONE, fixes applied), and adjudicated post-compute by a memo-blind D-43 panel
(Fisher, Rose, Noether).

## Coverage estimand + scale

The **population SD of the σ random intercept**, true value **0.40**, being the SD of the simulated
`u` where `sigma_i = exp(-0.6 + u[id])` and Gamma `sigma` is the coefficient of variation
(shape = 1/σ², scale = μ·σ², log link). Covered via
`confint(fit, parm = "sd:sigma:(1 | id)", method = "profile")`, whose endpoints are on the **natural
RE-SD scale** (`transformation="exp"`), compared to 0.40 on that same scale. Because σ is a
dispersion parameter and the RE-SD is bounded at 0, profile — not Wald-on-log-SD — is the decisive
method here (Wald degenerates to an ∞ upper limit at small M; profile allows the SD=0 boundary).

## Data-generating process (iid uncentered — the Arc-4a correction)

Per replicate: `id` = M groups × n_each=12; `x ~ N(0,1)`; `u ~ N(0, 0.40)` **iid, uncentered**;
`mu = exp(0.2 + 0.5 x)`; `cv = exp(-0.6 + u[id])`; `y ~ rgamma(shape = 1/cv², scale = mu·cv²)`.
Runner: `tools/run-gamma-sigma-re-coverage.R`. Grid M ∈ {8,16,32,64}, N=1200/cell, seeds reused
across cells (`SEED_BASE=20260900 + 1:1200`). **This iid-uncentered DGP diverges deliberately from
the Arc-2c recovery DGP (which mean-centered `u` at n_each=15/n_id=40)** — centering changes the
finite-sample SD estimand (the Arc-4a v1 failure mode).

## Result (profile method; `coverage-results-iid-summary.tsv`)

| M | coverage hits/N | rate | MCSE | exact 95% CI | label | above-U : below-L | sd̂ (rel-bias) | Wald ∞-rate |
|---|---|---|---|---|---|---|---|---|
| 8  | 1117/1200 | 0.9308 | 0.00732 | [0.9150, 0.9445] | mildly anti-cons. — **exploratory** | 72 : 11 | 0.349 (−12.7%) | 0.0225 |
| **16** | 1120/1200 | 0.9333 | 0.00720 | [0.9177, 0.9468] | mildly anti-cons. (borderline) | 65 : 15 | 0.373 (−6.9%) | 0 |
| **32** | 1134/1200 | 0.9450 | 0.00658 | [0.9306, 0.9572] | nominal within MC error | 45 : 21 | 0.387 (−3.2%) | 0 |
| **64** | 1135/1200 | 0.9458 | 0.00653 | [0.9315, 0.9579] | nominal within MC error | 48 : 17 | 0.393 (−1.8%) | 0 |

`profile_finite_rate = 1.000` at every M; 4800/4800 eligible; zero fit / convergence / Hessian /
profile failures.

## Reading it honestly (the frozen gate, applied)

- **M=32 and M=64** clear the pre-registered `[0.925, 0.975]` gate with their coverage CIs **entirely
  inside** the band and **bracketing 0.95** → *nominal within Monte-Carlo error*. This is the
  **firmly-certified floor: M ≥ 32.**
- **M=16** overlaps the band but its CI straddles 0.925 and does not bracket 0.95 → *mildly
  anti-conservative*. Per the frozen §4.6 it is a **borderline extension, not firmly certified** (a
  second N=1200 seed batch could flip it below 0.925). It is promoted (matching the mc-0382 precedent,
  whose M=16 was 0.9325) but carries this caveat.
- **M=8** was **pre-declared exploratory** (§4.6). Its coverage (0.9308) numerically clears the
  overlap band, but the arm is **degenerate** — a large fraction of M=8 profiles pin at the SD=0
  boundary, 2.25% of Wald intervals are ∞-width, and the point estimate is −12.7% biased — so it is
  reported as context and **excluded from the promoted range** (mirroring mc-0382).
- **Direction (pre-registered):** misses are predominantly *above* the interval at every M
  (72:11, 65:15, 45:21, 48:17), the signature of the downward small-cluster Laplace RE-SD bias — the
  point estimate is biased low, so the profile interval sits low and misses 0.40 from below the truth.
- **Point bias shrinks monotonically with M** (−12.7% → −1.8%): an information effect, the right
  direction for a consistent estimator.
- **Profile earns its place:** at M=8 the Wald arm throws ∞-width intervals (2.25%) and many fits sit
  at the SD=0 boundary, yet profile returns finite, in-range intervals at 100% rate across all M.

## Reproducibility

Cross-platform check: the local Mac-ARM gating smoke (seed 20260901, one fit per M) and the Totoro
x86 campaign's seed-20260901 replicate agree to **≤5e-5** for M ∈ {16,32,64} (well within the ~1e-4
gate); see `repro-check.md`. M=8 was not in the local smoke's recorded rows and is excluded from
promotion regardless. Package built from source (`pkgload::load_all`) on both hosts; Totoro is
OpenBLAS with `OPENBLAS_NUM_THREADS=1`; git a9b2633c.

## This is `inference_ready_with_caveats`, not `supported`

No package-wide inference promise; single true-SD (0.40), single n_each (12), profile method. The
residual lever for nominal coverage / reduced small-M bias is **AGHQ** (non-Gaussian); **REML is
banned for this family** (mc-0243). Excluded: M=8, untested M/SD/replication designs, sigma slopes,
labelled blocks, combined mu+sigma random effects, other families, REML, and any `supported` claim.
The lognormal mc-0382 numbers are **not** Gamma evidence.

## Artifacts

`coverage-results-iid-{raw,summary,manifest}.tsv` (campaign, N=1200/cell) ·
`coverage-results-smoke-{raw,summary,manifest}.tsv` (local gating smoke) · `campaign-totoro.log` ·
`repro-check.md`. Runner: `tools/run-gamma-sigma-re-coverage.R`. Frozen design +
plan-review + S4: `docs/dev-log/2026-07-17-mc0242-gamma-sigma-coverage-estimand-alignment.md` and the
after-task `docs/dev-log/after-task/2026-07-17-mc0242-gamma-sigma-re-coverage-promotion.md`.

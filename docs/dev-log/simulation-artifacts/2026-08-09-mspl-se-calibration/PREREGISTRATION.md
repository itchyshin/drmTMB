# PRE-REGISTRATION — MSPL standard-error calibration

Written **2026-08-09, before any replicate was run.** Owner authorization: Shinichi, *"Totoro go"*.
Compute: **Totoro** (384 cores, R 4.5.3). **Never GitHub Actions** (D-50).

Branch under test: `claude/mspl-binomial-inference-promotion` @ `f1a7f6dea`.

## 1. Aim

drmTMB's experimental MSPL estimator **ships standard errors and no intervals**. This campaign asks
one question about the thing we actually ship:

> **Are the reported MSPL standard errors calibrated — i.e. does the average reported SE match the
> true sampling variability of the estimator?**

It does **not** measure interval coverage. Coverage would measure a quantity we deliberately do not
ship, and whose failure is already published (Kosmidis & Firth: Wald intervals here *"fail to cover
regardless of the nominal level"*, persisting even for profile penalized intervals).

## 2. Honest disclosure — what is ALREADY known

Stated before the result exists, so the campaign cannot be presented as more novel than it is.

- **MSPL SEs already match ML `sdreport()` closely in the identified regime** — 0.38% / 0.01% (q1)
  and 0.69% (q2), converging monotonically 10.13% → 0.14% as `c_n = 2√(p/n_eff)` vanishes. **The
  convergence is the existing evidence.** This campaign's identified cells are therefore expected to
  pass; they are a control, not the discovery.
- **`glmer` plateaus at 1–2% and does NOT converge monotonically** — an irreducible implementation
  difference. It is a **sanity arm with a loose bound**; tightening it would measure `lme4`, not us.
- **The separated regime is unevidenced for SEs.** That is the actual gap this campaign fills.
- **`unpenalized_gradient_max_abs` is NOT a usable separation diagnostic** — flat at 0.4082 across
  the whole spectrum; an earlier 0.13 → 0.41 claim compared different fixtures and is RETRACTED. The
  scale-free `unpenalized_score_distance = √(gᵀVg)` does separate the regimes (0.28–0.43 identified
  vs 0.61 separated) but the gap is modest and **no threshold is set**.

## 3. Data-generating process and estimand

**DGP.** Binomial GLMM with a random intercept per block. The separation gradient is driven by the
intercept `η_d`, which pushes the event probability toward 0 and eventually past the point where a
finite MLE exists.

- q1: `y ~ trt + (1 | block)`
- q2: `y ~ x + (1 + x | block)`

**Estimand, frozen.** For each coefficient `j`, over `r = 1..n_rep` replicates:

```
R_j = mean_r( SE_j^(r) ) / sd_r( β̂_j^(r) )
```

`R = 1` is calibrated. **`R < 1` is anti-conservative** — reported uncertainty smaller than the true
sampling variability. That is the hazard; `R > 1` is merely conservative.

**The denominator is `sd`, and `sd` gates.** A robust `mad × 1.4826` is reported alongside it, but
**the PASS/FAIL decision reads `sd`**. Choosing the denominator after seeing both is exactly the
failure a pre-registration exists to prevent.

## 4. Design

| | q1 | q2 |
|---|---|---|
| formula | `y ~ trt + (1 \| block)` | `y ~ x + (1 + x \| block)` |
| `η_d` | {0, −2, −4, −6, −10} | {0, −2, −4, −6, −10} |
| `G` (blocks) | {12, 30} | {30} |
| cells | 10 | 5 |

**15 cells · `n_rep = 1000` · 4 engines ≈ 60,000 fits.**

Engines: **drmTMB MSPL** (the subject), **drmTMB ML** (paired reference), **`glmer(nAGQ = 1)`**
(sanity arm, loose bound), **`glmmTMB`** (second sanity arm — see the amendment below).

> **AMENDMENT, 2026-08-09, before any campaign replicate was run.** A fourth engine, `glmmTMB`, was
> added at Shinichi's request during the smoke phase. Recorded here rather than applied silently,
> because changing a pre-registered design after seeing *any* output — even smoke output — is
> exactly what a pre-registration exists to make visible.
>
> **What had been seen at the time of the amendment:** smoke output for cell 3 only (q1,
> `η_d = −4`, `G = 12`, 5 replicates), which was run to test the *harness*, not the hypothesis. It
> revealed two harness bugs (below) and no calibration number. **No `R_j` had been computed for any
> cell.** The decision rule in §5 is untouched.
>
> **Why it strengthens the campaign:** `glmmTMB` is the closest comparator to drmTMB — also TMB with
> a Laplace approximation — so it isolates *implementation* differences from *method* differences in
> a way `glmer` cannot. `glmer` uses a different inner approximation, which is why its bound is
> loose (§2). Fixed-effect cross-checks earlier the same day showed drmTMB and `glmmTMB` agreeing to
> every printed digit while `glmer` diverged at 1e-3 on non-canonical links.
>
> `glmmTMB` is a **sanity arm**: a divergence between drmTMB and `glmmTMB` is informative about
> implementation and does not by itself constitute a drmTMB defect. The D-117 paired-reference
> clause in §5 now reads across all three comparators.

### Harness bugs found by the smoke gate (§8 rule 2 working as intended)

Both were **runner** defects, not drmTMB defects. Recorded because the smoke gate is the only reason
the grid did not run 60,000 fits producing all-NA for the two engines that matter:

1. **`bf()` uses NSE.** The runner passed `bf(sim$fml)` with a formula *variable*; drmTMB correctly
   rejected it — *"`drm_formula()` inputs must be formulas"*. Every drmTMB fit returned `ok = FALSE`
   while `glmer` succeeded, so the failure was engine-specific and would have looked like a drmTMB
   problem. The formula must appear literally, so the runner branches on cell shape.
2. **The estimator token is lower-case.** `estimator = "ML"` errors; `"ml"` is required.

**A drmTMB usability defect was found in passing** (not a harness bug): a fitted object *reports*
`f$estimator == "ML"` but `drmTMB()` *accepts* only `"ml"`. Reading the value off a fit and passing
it back errors. Worth a follow-up issue; it does not affect this campaign.

**Seeds:** `20260809 + 100000 * cell_index + r`. Fixed, published here, so every replicate is
reproducible and no cell can be silently re-drawn.

## 5. THE DECISION RULE — frozen here, before the number exists

| regime | PASS | BORDERLINE | FAIL |
|---|---|---|---|
| identified (`η_d ∈ {0, −2}`) | `R ∈ [0.95, 1.05]` | `[0.90, 1.10]` | outside |
| separated (`η_d ∈ {−4, −6, −10}`) | `R ∈ [0.90, 1.15]` | `[0.80, 1.25]` | outside |

The separated bands are **wider and deliberately asymmetric**: conservatism is harmless,
anti-conservatism is not.

> **One anti-conservative FAIL fails the campaign.** Not a majority, not an average across cells.
> A single cell with `R` below its FAIL floor is a failed campaign, and the honest report is that
> MSPL standard errors are not calibrated in that regime.

**Paired-reference clause (D-117).** If MSPL under-calibrates, check **ML and `glmer` on the same
replicates** before claiming any drmTMB defect. *Imperfect calibration is the norm — very famous
packages undercover too.* Never infer our bug from a sub-nominal number without a paired reference
run. If all three engines under-calibrate together, the finding is a statistical fact about the
regime, not a drmTMB defect, and must be reported as such.

## 6. Mandatory diagnostics — reported regardless of verdict

Reported for **every** cell whether it passes or fails, so a favourable headline cannot hide an
unfavourable interior:

1. `R_j` per coefficient, with `sd` **and** `mad × 1.4826` denominators shown side by side
2. Monte-Carlo standard error on `R`, so band-edge results are not over-read
3. Convergence rate, `pdHess` rate, and count of retained vs dropped replicates per cell
4. `unpenalized_score_distance` distribution per cell (characterisation only — **no threshold**)
5. Mean `c_n = 2√(p/n_eff)` per cell, since the existing evidence is that agreement improves as
   `c_n → 0`
6. Empirical separation rate per cell (fraction with no finite MLE), via `detectseparation`

## 7. What the result licenses — and does not

**A PASS licenses:** *"MSPL reported standard errors are calibrated within the pre-registered bands,
over the exact tested grid."* Nothing wider.

**A PASS does NOT license:** any interval or coverage claim; any capability-ledger promotion; any
statement about links other than logit (**MSPL is logit-only**); any statement about designs outside
the tested `η_d × G` grid; any change to the frozen census.

**A FAIL licenses:** a documented limitation on the MSPL SE surface, and — only after the paired
reference run — a defect claim if and only if drmTMB diverges from both comparators.

## 8. Stopping and abort rules

1. **Build gate.** Totoro runs **R 4.5.3**; this work is developed on **R 4.6.0**, and drmTMB has
   compiled TMB code. **It must build on Totoro first.** If it will not build, **STOP and report** —
   do **not** quietly fall back to a smaller local run.
2. **Smoke gate.** One cell × 5 replicates must produce **non-empty, non-NA, in-range** output, and
   one fit must be inspected past its guards (`str(res)`), before the grid launches. Guard-blocked
   operations return all-NA silently.
3. **First-cell gate.** Read the first completed cell's output **early**. Abort the moment it is
   empty, NA, or out of range — never wait for the whole grid to discover it failed.
4. **Courtesy cap.** Totoro is shared. **≤ 150 cores**, `OPENBLAS_NUM_THREADS=1`.
5. **No silent truncation.** If any cell is dropped, reduced, or fails to complete, it is reported
   with its reason. A campaign that silently covers 13 of 15 cells is reported as 13 of 15.
6. **No post-hoc band edits.** The bands in §5 are frozen. If they prove wrong, that is a finding to
   report, not a parameter to tune.

# Design 221 (seed) — Interval methods for structured/non-Gaussian variance components

Status: **RESEARCH MEMO — UNVERIFIED** (NotebookLM synthesis over the "Fast & Accurate
Algorithms" KB, 240 sources; Q-S 22 cited refs, Q-S answer `nblm_qS_answer.json`; Q-B 26 cited
refs, `nblm_qB_answer.json`). Per the quarantine rule, **Fisher must verify the key citations
before any engine work** — the cited_text snippets confirm real sources (DiCiccio–Efron BCa,
Kenward–Roger, boundary-testing, Laplace variance-component work) but the specific
coverage/ranking claims are LLM-synthesized and need a read of the primary sources.

## MAINTAINER DECISION (2026-07-06) — profile-first, defer the skew fix

Per Shinichi: **profile-likelihood CIs are the star** (the primary interval route); **a single
plain parametric bootstrap is the only fallback** (no BCa acceleration for now); the **skew /
miss-asymmetry / `supported` fix is DEFERRED** — the arc **caps at `inference_ready`**. The BCa
finding below is *banked* for the future `supported` sub-project, not built now. The count
Laplace-attenuation bias (below) is a **documented caveat**, not fixed this arc — it bounds
which count cells can honestly reach `inference_ready`. Net effect: the arc becomes an
**extension of the existing profile + bootstrap infrastructure** (`R/profile.R`
endpoint-profile solver + `drm_bootstrap_confint`), *not* a new-method research project.

## The question

Two open interval problems from the 104/104 board:
- **Q-S (`supported` blocker):** the log-SD Wald + bias-t interval (design 219) shows a ~6:1
  right-tail miss-asymmetry at g≈8–16, g-dependent — a finite-sample *skew* of the SD
  estimator. What closes it?
- **Q-B (Track B headline):** there is *no* interval method yet for count-GLMM (Poisson/NB2)
  structured random-effect SDs. What should it be?

## Convergent finding — one method serves both

Both questions independently rank **BCa (bias-corrected accelerated) parametric bootstrap #1**:
- BCa's **acceleration** term (jackknife-derived) explicitly corrects the distribution's
  skew; its **median-bias** term corrects finite-sample bias; the percentile mechanism
  **respects the σ≥0 boundary** (mass accumulates at 0 on singular fits) — the three exact
  failure modes of the current Wald/bias-t route.
- It reaches **nearest-nominal 95% coverage** for both Gaussian variance components (Q-S) and
  count-GLMM SDs (Q-B).
- **drmTMB already has a parametric-bootstrap route** (`R/profile.R` `drm_bootstrap_confint`
  → `bootstrap_percentile_interval`). So BCa is an **in-package extension** (add the
  acceleration + bias-correction factors), *not* necessarily a DRM.jl/Julia dependency.
- Cost: **thousands of refits** → a Totoro-calibrate / DRAC-certify compute item.

## Ranked alternatives (Q-S)

1. **BCa / parametric bootstrap** — best accuracy + robustness; high compute.
2. **Bartlett / higher-order asymptotics** (Barndorff-Nielsen `r*`) — accurate `O(n^-3/2)` but
   algebraically prohibitive, no general software. (Not a practical route.)
3. **REML-calibrated profile likelihood** — cheap, *naturally asymmetric* (traces the
   surface), REML removes fixed-effect bias; but chi² asymptotics still under-cover at very
   small g. **The cheap fallback if bootstrap is too costly.**
4. **Kenward-Roger / Satterthwaite** — *ineffective for the variance parameter itself*: forces
   a symmetric interval, and the df can collapse to 1 near the boundary (paradoxically wide).
   **This is essentially drmTMB's current bias-t (design 219)** — explains why the
   miss-asymmetry persists. (Gold standard for *fixed* effects only.)
5. **Skew-normal / skew-t calibration** — *not present in the KB* for variance components; no
   evidence either way.

## The count-GLMM wrinkle (Q-B) — harder than Gaussian

Count-GLMM SD coverage degrades **faster** than Gaussian because small-sample skew is
**compounded by the `O(m^-1)` Laplace/PQL approximation error**:
- **First-order Laplace attenuation bias** — for Poisson-log, linearizing around the
  conditional mode *underestimates* the marginal mean (Jensen), which **suppresses the SD
  estimate** and destroys coverage on sparse/low counts. Deeper fixes: **2nd-order Laplace /
  multi-point AGQ**, or **bias-adjusted effective weights**, or **generalized REML**
  adjustments to the Laplace-integrated likelihood. (TMB-side; Gauss/Noether.)
- **Boundary collapse** (σ̂=0 singular fit) → Wald SE/df undefined; bootstrap handles it, Wald
  doesn't.
- **Profile route** is asymmetric + bounded but needs the χ̄² (0.5·χ²₀ + 0.5·χ²₁) mixture null
  as σ→0, plus an expensive Laplace/AGQ refit per grid point.

## Implication for the plan (updated recommendation)

- **The unifying first method-slice is BCa on the existing parametric bootstrap** — it serves
  **both** Track B (count intervals) *and* the `supported` sub-project (Gaussian
  miss-asymmetry). This collapses two "hard/deferred" items into one in-package method.
- **`supported` is more reachable than the plan assumed** — likely in-package (BCa), with
  REML-profile as a cheap fallback; the DRM.jl/Julia REML route drops from "probably required"
  to "optional deeper fallback."
- **Count intervals carry an extra risk** (Laplace attenuation bias) that Gaussian ones don't
  — budget a 2nd-order-Laplace / AGQ / bias-weight investigation alongside the BCa work, or
  scope count intervals to regimes where the Laplace bias is small (adequate counts/groups).

## Verify-next (before building)

Fisher reads the primary sources behind: (1) the BCa-for-variance-components coverage claim
(DiCiccio–Efron lineage), (2) the "K-R/Satterthwaite ineffective for the variance parameter"
claim, (3) the count-GLMM Laplace-attenuation coverage claim. Source_ids are in the two
answer JSONs. Only then does BCa become the committed design-221 method.

# Beta phylogenetic q1 direct-SD — interval + coverage estimand alignment (S0)

> **Scope:** This is the estimand/design freeze for the interval-and-coverage arc that
> targets capability-ledger cell **`mc-0017`** (`beta_phylo_q1_direct_sd`). It extends
> — and does not alter — the recovery-DGP symbolic alignment in
> `2026-07-16-beta-phylo-q1-interior-dgp-symbolic-alignment.md`. It declares the
> coverage **estimand** and the DGP/scale match **before** any campaign, per the Arc 4a
> lesson that a coverage DGP must declare and match its estimand.
> **Draft — the coverage gate (§5) and seed policy (§7) are confirmed against the S0/S1
> plan-review (Fisher/Rose) before the campaign launches.**

## 1. Purpose

Cell `mc-0017` holds `point_fit_recovery` over the exact `g=1024, m=4` domain. Its
`next_gate` requires *"a separate target-specific interval and coverage campaign … before
inference promotion."* This document fixes precisely **what quantity is covered, on what
scale, against what truth, by what interval, and what counts as a pass** — so the campaign
cannot later be reinterpreted (the Arc 4a v1 mean-centring failure mode).

## 2. The coverage estimand

The model (interior-DGP symbolic alignment) is, for observation `i` in species `s(i)`:

```text
logit(mu_i)   = beta_0  + beta_1  x_mu,i   + a_{s(i)}
log(sigma_i)  = gamma_0 + gamma_1 x_sigma,i,     phi_i = sigma_i^{-2}
log(tau_s)    = alpha_0 + alpha_1 x_tau,s
a ~ N(0, D_tau A D_tau),   D_tau = diag(tau_s),   A = phylogenetic correlation
```

The **coverage estimand is the pair of FIXED direct-SD regression coefficients**

- **`alpha_0`** — log baseline latent-SD (intercept of the `sd(...)` linear predictor),
- **`alpha_1`** — the latent-SD **slope** (the coefficient that makes this a *regression*
  on latent SD, not a constant SD).

These are population parameters of the `sd(spp_id, level="phylogenetic") ~ x_tau` linear
predictor. They map to `fit$par[["sd_phylo(spp_id)"]]` and to the profile targets
`fixef:sd_phylo(spp_id):(Intercept)` and `fixef:sd_phylo(spp_id):x_tau`.

**Not covered (out of estimand):** the Beta family `sigma`/`phi` (conditional-response
precision), the realised per-replicate phylo field `a`, any species-level realised SD, or
a conditional-response SD. The invariant **family sigma ≠ latent tau** is preserved.

**Why this estimand is clean (contrast with Arc 4a):** the targets are *fixed
coefficients of a linear predictor*, not a realised random-effect SD. There is therefore
**no realised-vs-population ambiguity** — the trap that invalidated the Arc 4a v1 campaign
(which mean-centred each realised RE vector and then scored against a population SD). Here
the truths `alpha_0, alpha_1` are fixed constants of the DGP, identical across replicates.

## 3. Scale contract (the scale-match gate)

The confidence interval for `fixef:sd_phylo(spp_id):(Intercept)` / `:x_tau` is returned on
the **log-SD linear-predictor scale** (`target_class="fixed-effect"`,
`transformation="linear_predictor"`, `scale="link"`). The truths are on that **same** scale:

| Coefficient | Truth (link/log-SD scale) | Numeric |
| --- | --- | --- |
| `alpha_0` (intercept) | `log(0.30)` | ≈ `-1.203973` |
| `alpha_1` (slope)     | `0.25`      | `0.25` |

Coverage is scored by comparing each interval `[L_j, U_j]` to `alpha_j` **on the link
scale** — no exp()/back-transform is applied to either side. This forecloses the classic
scale-mismatch coverage failure.

## 4. Interval methods

Both are computed per replicate, side by side (as Arc 4a did for RE-SD cells):

- **Wald** — from the `sdreport` SE of the coefficient (cheap; baseline).
- **Profile** — `confint(fit, parm=<coef>, method="profile")`. These fixed-effect targets
  carry `transformation="linear_predictor"` (identity map, unbounded scale), so they are
  **excluded from the fast bounded-endpoint solver** and route to the slow
  `TMB::tmbprofile()` full-curve engine (the runtime the S1 probe measures).

**Neither method is assumed superior a priori (Fisher plan-review).** Unlike Arc 4a's raw
random-effect SDs (bounded at 0, where profile's boundary handling is decisive), these
targets are *unbounded* linear-predictor coefficients with no SD=0 boundary, so the usual
profile-over-Wald argument is weaker here. Any real Wald↔profile divergence would come from
Laplace/marginal-likelihood curvature induced by the correlated phylo field, not a boundary.
Both are therefore computed side by side and reported together; the promotion claim rests on
whichever the campaign data and the D-43 panel support — "profile is featured (D-12)" is not
by itself a reason to prefer it, and the claim must not assert profile superiority unless the
data show it.

Nominal level: **95%** two-sided.

## 5. Coverage definition and pass gate

> **Frozen pre-campaign, correcting the first draft (Rose + Fisher plan-review, 2026-07-17).**
> The initial draft required the coverage CI to *overlap 0.95* — but that is the
> `inference_ready` (nominal) bar, and it **contradicts the `inference_ready_with_caveats`
> precedent this arc follows**: `mc-0382` was promoted with arms at 0.9242 (exact CI
> 0.9077–0.9385) and 0.9325 (CI 0.9168–0.9460) — neither reaching 0.95 — labelled "mildly
> anti-conservative" (`cells.tsv:386`; `after-task/2026-07-13-arc4a-closeout-and-marginal-gk-probe.md:25-33`).
> The tier exists *precisely* to admit honestly-caveated sub-nominal coverage. Freezing the
> precedent-anchored rule now (not letting D-43 arbitrate two competing bands later) is what
> prevents the after-the-fact reinterpretation S0 guards against.

For each cell (an arm = predictor-design × g × m) with `N` retained replicates and method
`∈ {wald, profile}` and coefficient `j ∈ {alpha_0, alpha_1}`:

```text
coverage_hat = (1/N) * sum_r  1{ alpha_j ∈ [L_{r,j}, U_{r,j}] }
```

**Reporting (primary, always):** per cell/method/coefficient as
**`hits/N = rate (MCSE; exact binomial 95% CI)`**, `MCSE = sqrt(rate*(1-rate)/N)`, a
Clopper–Pearson exact 95% CI, and separate below-L/above-U directional-miss counts. Interval
failures are tallied separately and never silently dropped. Label an arm **"nominal"** only
if its exact CI **brackets 0.95** for both coefficients.

**Replicate count `N` (sized off S1):** the two **g=1024,m=4 promotion arms** target
**MCSE ≤ ~0.008** (≈ Arc 4a's N=1200 resolution) — i.e. `N ≈ 1000–1200` **if the S1 runtime
probe shows tmbprofile is affordable at g=1024**; otherwise `N = 400` with an **explicit
reduced-resolution caveat** in the claim (Fisher plan-review item 2: N=400 gives MCSE ≈ 0.011,
comparable to the miscalibration magnitude the tier tolerates, so the caveat is mandatory).
Context cells (`g∈{256,512}`) stay at `N = 400`.

**Promotion rule → `inference_ready_with_caveats`** (both coefficients, profile method):
1. **Computability + finite-profile policy (pre-registered 2026-07-17, before any promotion-arm
   result is read — occasional `tmbprofile` non-convergence was observed on the *context* g256,m2
   cell, ~1/36, correctly recorded as NA + `profile_error`).** Report `profile_finite_rate` per arm.
   - `profile_finite_rate = 1.000` (zero fit / convergence / Hessian / profile failures): clean.
   - `profile_finite_rate ≥ 0.99` (a handful of failures): promotion may still proceed, but the
     failure **count and rate are disclosed in the claim**, coverage is computed over the finite
     profiles only, and the disclosure names the exclusion. (Matches the Arc 4a DG3 precedent:
     "≈1.0 or state+apply an exclusion policy.")
   - `profile_finite_rate < 0.99`: **withhold** (the interval method is not reliably computable on
     the arm) → documented non-promotion.
   Wald has no such failure mode (closed-form); Wald coverage is always over all N.
2. **Calibration (precedent-anchored):** the exact binomial 95% CI of coverage **overlaps
   [0.925, 0.975]** — i.e. under-coverage is *not materially worse* than the ~0.92 floor Arc 4a
   accepted. Over-coverage (CI entirely above 0.975) still promotes, labelled **"conservative"**
   (an over-covering interval is inferentially safe). **Withhold** (→ documented non-promotion)
   only if a coefficient's coverage CI lies **entirely below 0.925** (materially
   anti-conservative), or any computability failure.
3. **Directional label (verbatim in the claim):** **"nominal within Monte-Carlo error"** (CI
   brackets 0.95) · **"mildly anti-conservative"** (CI centre < 0.95, not bracketing) ·
   **"conservative"** (CI above 0.975) — always naming the **worst-in-arm** coverage, never
   the best.

This frozen rule is the load-bearing input to the D-43 review, which adjudicates the wording
but does **not** re-set the band.

**Report alongside coverage (Fisher plan-review item 4):** because the phylo field
`a ~ N(0, D_tau A D_tau)` is correlated, the **effective** information for `alpha_1` is
governed by the phylogenetic effective sample size, not raw `g`. Each cell's coverage row
therefore carries a simple tree-structure summary (e.g. tree depth / mean pairwise
phylogenetic distance / an effective-N proxy) so that an off-nominal `alpha_1` coverage at
g=1024 can be read against tree structure rather than mis-attributed to "small g."

## 6. DGP ↔ estimand match

The campaign reuses the **frozen interior-DGP** unchanged: fresh tree/predictors/unit
phylo field per replicate, `tau_s = exp(alpha_0 + alpha_1 x_tau,s)`, `a ~ N(0, D_tau A
D_tau)`, machine-strict conditional-Beta responses. The alphas are **fixed truths**; every
replicate scores its intervals against the same `alpha_0, alpha_1`. No re-centring, no
re-scaling, no post-hoc target redefinition. This is the estimand-match declaration
required by the Arc 4a team-learning rule.

## 7. Seed policy

The coverage campaign **reuses the frozen seeds of the point-recovery certification**
(`docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-interior-dgp/seed-audit.tsv`),
so coverage and point recovery are computed on the **same DGP realisations**. Point
recovery (bias of the estimate) and interval coverage (does the CI bracket truth) are
distinct inferential questions on the same draws; sharing draws does not bias either.
**Fisher plan-review verdict: FINE**, with one required disclosure — because point recovery
and coverage are functionals of the *same* frozen draws, they are **correlated, not
independent, evidence**, and S5 must state this rather than presenting them as two independent
confirmations. (The zero-failure requirement in §5 also guards against any post-hoc
re-filtering of the retained set.)

## 8. Domain

- **Promotion evidence:** the two `g=1024, m=4` arms — `distinct_g1024_m04` and
  `shared_g1024_m04` — each must pass §5 independently.
- **Context only:** `g ∈ {256, 512}` cells provide the directional coverage-vs-g trend;
  they do NOT promote any cell.
- **`shared_g256_m02`:** reported **descriptively only** (its point-recovery HOLD status is
  unchanged); it is **never pooled** into any promotion or gate, and is not repaired.

## 9. Exclusions (fence)

q>1 · family-sigma phylogeny · random/hierarchical RHS in `sd()` · labels/slopes · REML ·
missing routes · other families · a coverage-**correcting** estimator (this arc *assesses*
calibration, it does not build a correction) · neighbouring SDs/species counts ·
`supported`/nominal claims · the `shared_g256_m02` HOLD · the stopped campaign `1c9bfd5f` ·
PR #788.

## 10. Review independence (D-43) — Rose plan-review item

The S0/S1 **plan-review** (Rose scope + Fisher method) and the S4 **promotion review** are
distinct gates. Because Rose and Fisher lenses appear in both, the S4 panel must run on
**fresh, memo-blind contexts**: each S4 reviewer is briefed **only** on the campaign evidence
and this frozen S0 contract, with **no access to the pre-execution plan-review memos**, and
defaults to NOT-DONE (≥2 NOT-DONE withholds). To reinforce independence, the S4 panel should
draw at least one lens **not** used in the plan-review (e.g. Noether or Pat) so the three
verdicts are not all from reviewers who already reasoned about this decomposition.

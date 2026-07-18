# cumulative_logit RE-SD bias — diagnosis, and AGHQ as the queued next arc

**Date:** 2026-07-18 · **Context:** while scoping the 4-cell mu random-slope coverage batch (Arc 4c),
cumulative_logit (mc-0227) stood out as the worst-behaved family — Arc-2b recovery showed **−8.7%**
RE-SD bias at n_id=40 (vs −2.6% to −3.2% for skew_normal / tweedie / zero_one_beta). Shinichi asked:
is it a code bug, is it known, or do we need AGHQ? This note records the diagnosis and queues AGHQ.

## Diagnostic probe
`scratchpad/cumlogit_laplace_vs_aghq.R` → `docs/dev-log/simulation-artifacts/2026-07-18-cumlogit-laplace-vs-aghq/`.
Three parts on the actual cumulative_logit `mu ~ x + (0 + x | id)` model (4 categories, latent-logit DGP,
iid-uncentered u, true slope-SD 0.5): **Panel M** (vary clusters M, n_each=15), **Panel n** (fix M=40,
vary per-group n), and a **direct Laplace-vs-AGHQ** comparison using a self-contained Gauss-Hermite
marginal (1-D quadrature over the scalar per-cluster slope RE), plus a **node-count convergence** check.
Validated: the rolled GHQ agrees with drmTMB's Laplace at large n where both are unbiased.

## Verdict (robust; from the 3-seed smoke, being confirmed at 40 seeds on Totoro)

1. **NOT a code bug.** The drmTMB Laplace bias **vanishes as data grows** — Panel M: −7.3% at M=40 (40
   seeds) → ~−1% at M=160; Panel n: shrinks to ~0% by n_each≈30–60. A bias that shrinks toward 0 in
   both directions is a **consistent estimator** (the memory's direction-of-n discriminator: improves
   with n ⇒ information problem, not a pipeline/engine bug). If it were a construction bug the offset
   would persist across n.
2. **It is the known small-cluster Laplace bias, worst here because ordinal data carry the least
   information per observation.** A 4-category ordinal response is a coarsened latent scale (~2 bits/obs
   vs a full real value for the continuous families), so per-observation Fisher information is lowest →
   the Laplace (mode-based Gaussian) approximation to the marginal likelihood is least accurate → biggest
   finite-sample RE-SD bias. Confirmed by the BLUP-vs-truth correlation (cumulative_logit 0.69/0.43 vs
   skew_normal 0.93/0.87). This is the textbook reason `lme4::glmer` ships `nAGQ>1` for binary/ordinal
   GLMMs with few clusters — a well-known phenomenon, not drmTMB-specific.
3. **The bias is TWO stacked effects, and AGHQ only fixes the smaller one (40-seed decomposition).**
   At the recovery cell (M=40, n_each=15, true SD 0.5): drmTMB **Laplace = −7.3%**; the exact-integration
   ML estimate (my GHQ marginal, **node-converged** — identical −4.95% at nq=48/128/256, so not
   node-limited) = **−5.0%**; validation cell (M=160, n=60) drm +0.6% vs aghq +0.9%, agreeing → the AGHQ
   implementation is correct. Therefore:
   - **Laplace integral error ≈ 2.3 points** (−7.3% → −5.0%), removed by AGHQ; shrinks with per-group n
     (Panel n: the drm−aghq gap is 2.3pt at n=15 → ~0.3pt at n=60). *This* is AGHQ's remit.
   - **ML finite-cluster variance-component bias ≈ 5.0 points — the DOMINANT part** — remains under exact
     integration (ML underestimates variance at few clusters). It shrinks with **M** (−7.3% at M=40 →
     −1.2% at M=160), *not* with better quadrature. Exact REML is Gaussian-only (it integrates fixed
     effects out of a Gaussian likelihood) and drmTMB bans it for non-Gaussian (mc-0243) — **but the
     Cox–Reid adjusted profile likelihood** (the approximate restricted likelihood glmmTMB exposes as
     `REML=TRUE` for GLMMs) DOES address it without more data, and a follow-up probe now **measures it**
     (§Cox–Reid, below): it removes **~4.0 of the 5.0 points**, making it the **bigger of the two levers.**
     AGHQ does not touch this piece; Cox–Reid does.

## Cox–Reid (non-Gaussian REML) — MEASURED, and it is the bigger lever

`scratchpad/cumlogit_reml_scoping.R` (Part 1, local) + `scratchpad/cumlogit_reml_part2.R` (Part 2, Totoro,
40 seeds). Two validated legs at the recovery fixture (M=40, n_each=15, true slope-SD 0.5):

**Part 1 — validated oracle, binomial random slope** (12 trials/obs → small integral error, so this
isolates the REML variance-bias fix). Using trusted implementations:

| method | sd̂ | rel-bias | lever |
| --- | --- | --- | --- |
| drmTMB Laplace (ML) | 0.4819 | −3.6% | (== glmmTMB ML exactly → validates drmTMB=ML) |
| glmmTMB `REML=TRUE` (Cox–Reid) | 0.4896 | **−2.1%** | REML removes ~1.5 pt (~42% of the ML bias) |
| glmer `nAGQ=25` (AGHQ) | 0.4825 | −3.5% | AGHQ removes ~0.1 pt (integral error tiny here) |

Validation M=160: all ≈ 0.50. So on a **validated** GLMM, REML (Cox–Reid) is the lever that moves the
small-cluster variance bias; AGHQ barely moves it when the per-obs information is decent.

**Part 2 — cumulative_logit** (the low-information family of interest), drmTMB Laplace vs a rolled
exact-ML (AGHQ) marginal vs a rolled Cox–Reid restricted likelihood on the **same** marginal (profile the
fixed effects + cutpoints, subtract ½·log|I_ββ|), 40 seeds:

| method | rel-bias (M=40) | removes |
| --- | --- | --- |
| drmTMB Laplace (ML) | **−7.3%** | baseline |
| rolled exact-ML (AGHQ) | **−5.0%** | +2.3 pt (integral error) — matches the standalone AGHQ probe |
| rolled Cox–Reid (REML) | **−0.9%** | +4.0 pt (ML variance bias) — **the bigger lever** |

**AGHQ + Cox–Reid together: −7.3% → −0.9%, essentially nominal.** Cox–Reid contributes ~1.7× what AGHQ
does at this fixture. Caveat: at the large-M validation cell (M=160) Cox–Reid nudges slightly *high*
(+2.1%, vs exact-ML +1.2%, Laplace −1.2%) — a mild over-correction to characterise, but it acts where the
problem lives (small M) and is inferentially safe (conservative) where it over-corrects.

**Was it root-caused before?** No. Arc-2b *measured* the −8.7% under Fisher's ≥50-seed recovery bar, but
no one had diagnosed it as Laplace-vs-bug until this probe. Gauss/Noether did not previously audit the
cumulative_logit likelihood specifically for this; the probe rules the bug hypothesis out empirically.

## The queued big arc = AGHQ **+ non-Gaussian REML (Cox–Reid)**, Cox–Reid leading

The scoping probe reframes the arc: the fix for a low-information family is **two levers**, and the one
that matters more is the restricted likelihood, not the quadrature.

- **Cox–Reid (non-Gaussian REML) — the LEADING lever.** Removes the dominant ML finite-cluster
  variance-component bias (~4.0 of the 7.3 pt on cumulative_logit; ~42% of the ML bias on the validated
  binomial oracle). This is exactly what glmmTMB's `REML=TRUE` does for GLMMs, so there is a validated
  reference to build against. drmTMB currently bans REML for non-Gaussian (mc-0243) — this arc lifts that
  ban *for the approximate Cox–Reid restricted likelihood specifically* (not exact Gaussian REML).
- **AGHQ — the second lever.** Removes the per-cluster integral error (~2.3 pt on cumulative_logit;
  its value is largest at **small per-group n** and hardest-to-approximate per-cluster likelihoods — the
  binomial-Bernoulli demo `scratchpad/laplace_vs_aghq.R` showed −23% → +2% at n_each=2). A genuine depth
  lever across all families, but on its own it leaves the ordinal cell at −5%.
- **Together → nominal** (−7.3% → −0.9% at the recovery fixture). Neither alone suffices for the
  low-information ordinal family; the pair does.

Sequence when taken up: build/validate **Cox–Reid first** (binomial oracle vs glmmTMB `REML=TRUE`, then
cumulative_logit as the non-Gaussian proof case), then **AGHQ** (binomial oracle vs glmer `nAGQ`), then
combine and re-score the coverage cells for nominal coverage. Each leg has a validated external oracle,
which de-risks both.

**Status: unbuilt.** The Arc-4a `integrate=list(method="marginal_gk")` probe was negative/inconclusive
on a binomial fixture — wiring AGHQ into drmTMB's TMB engine is a real, non-trivial arc, not a flag flip.
Scope when taken up: an identified fixture + a validated AGHQ path (TMB `integrate=` or a mapped external
reference), demonstrated on binomial first (where glmer gives an oracle), then cumulative_logit as the
non-Gaussian proof case, then the coverage cells re-scored for nominal coverage.

**Implication for Arc 4c (the 4-cell batch):** breadth still valid under Laplace, but cumulative_logit is
fighting exactly the bias AGHQ exists to fix — expect it to need the high-M grid ({40,80,160,320}) or land
as a documented non-promotion. The other three (skew_normal/tweedie/zero_one_beta, biases −2.6/−3.2/−3.0%)
are far less affected and remain straightforward.

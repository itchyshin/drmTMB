# Scout: the GAMLSS distributional-regression Primer, mapped onto drmTMB

**Date:** 2026-07-10 · **Source of task:** Shinichi ("super important reading for the drmTMB / DRM.jl
team — ingest and compare/contrast with our drmTMB; what can we learn"). Surfaced via the daily
brain-check (HSquared.jl lane). **Filed uncommitted** for the live `drmTMB6` handover session to fold in.

## The paper

Merder, Rigby, Mayr, Heller, Kneib, Umlauf, De Bastiani, Stauffer, **Tonkin**, Logothetis, Zeileis &
Stasinopoulos (2026). *Distributional regression using generalized additive models for location, scale
and shape.* **Nat Rev Methods Primers 6:49.** https://doi.org/10.1038/s43586-026-00498-z

The definitive GAMLSS Primer: written by the framework's originators (Rigby & Stasinopoulos) plus the
Bayesian/boosting/software camp (Kneib, Umlauf, Zeileis, Mayr) and two ecologists (Jonathan Tonkin,
Canterbury; Julian Merder). Already cited across drmTMB's own design docs (`00-vision`,
`14-gamlss-parameter-names`, `19-phylogenetic-location-scale-shape`, `06-distribution-roadmap`, …), so
this is the **canonical external reference for what drmTMB is building**, now with a citable primer.

## The reframe (read this first)

drmTMB **is** distributional regression. Shinichi's "they use GAM, we use GLM(M)" is exactly right, but
it is a difference in the **predictor engine**, not the goal. Both model the *whole conditional
distribution* — location **and** scale, ± shape — instead of just the mean. GAMLSS wires additive
**smooths** (P-splines, thin-plate) into each distributional parameter and fits by penalized
likelihood / backfitting / boosting / MCMC; drmTMB wires **parametric GLMM predictors** (fixed +
random effects + **phylogenetic** covariance) into each distributional parameter and fits by **TMB
(AD + Laplace) + REML**. Same premise, different — and complementary — engine.

## Primer checklist → drmTMB status (verified 2026-07-10 by grep, not exhaustive read)

| Primer capability | drmTMB status |
|---|---|
| Model location + scale | **Covered** — Gaussian & non-Gaussian location-scale, REML, phylogenetic |
| Shape parameters (skew `nu`, kurtosis `tau`; SHASH, Box-Cox t, skew-t) | **In progress** — `skew_normal`/`skew_t` are roadmap Tier 7 + active Phase-18 (issue #3); GAMLSS `nu`/`tau` naming already adopted (`14-gamlss-parameter-names.md`) |
| Random effects / mixed / phylogenetic structure | **Covered — and drmTMB's differentiator.** GAMLSS treats this as "smooths-as-random-effects"; PCMs are drmTMB's home turf |
| Zero-inflation / dispersion structures | **Partial** — NB2 structured, zero-inflation staged (validation-debt register) |
| **Normalized/randomized quantile residuals + worm/QQ/bucket plots** (their Fig 4c; the core distributional-adequacy check) | **GAP** → issue **#747**. `check.R` has deep *identifiability* diagnostics but no *distributional-adequacy* residual diagnostic |
| **Conditional quantiles / exceedance `Pr(Y>c\|x)` / centile curves** (Figs 5–6 case studies) | **GAP** → issue **#748**. `predict_parameters()` returns (mu, sigma, …) but nothing maps them to quantiles/exceedance/centiles |
| Prediction intervals from the fitted conditional distribution | **Partial** — profile/bootstrap CIs on parameters; distribution-based predictive intervals not yet a surface (part of #748) |
| Variable selection / regularization (penalized smooths, gamboostLSS, GAIC/WAIC) | **Analogous** — random effects already = shrinkage; DR-appropriate ICs/boosting a future direction |

## The one engineering insight

The two gaps (#747, #748) share a single dependency: a per-family **CDF `F(y; theta)`** and **quantile
`F^{-1}(alpha; theta)`**. Randomized quantile residuals need `F`; exceedance/centiles need `F` and
`F^{-1}`. **Implementing the fitted distribution as a first-class object (`{d,p,q}` per family) discharges
both at once** — recommend scoping #747 and #748 together, on top of the parameters `predict_parameters()`
already returns.

## What the Primer *validates* about drmTMB's existing discipline

- **Interval inference is genuinely harder in DR** — the Primer recommends *bootstrapping over Wald SEs*
  when assumptions are violated. drmTMB's REML coverage-grid + profile-CI work is addressing exactly this;
  external corroboration that it is the right worry (and that the boundary-calibration trap is real).
- **Sample-size caution** — GAMLSS benefits appear ~n>500 (nonlinear scale) / >100 (linear scale);
  over-modelling scale at small n is a known trap. Same shape as drmTMB's "run the n-ladder before
  condemning the estimator" lesson.
- **DR accuracy depends on correct distributional specification, "especially in the tails."** So ship the
  quantile-residual diagnostic (#747) *before* any shape-recovery claim — consistent with drmTMB's
  fitted/planned/missing separation.

## Positioning

The Primer's software table (Table 2) already lists **`glmmTMB`** as distributional regression ("GLMMs
including zero-inflation and dispersion structures"). drmTMB sits in that lineage as the **mixed-model +
phylogenetic-comparative + REML wing** of DR — a defined, non-redundant niche. Worth naming explicitly in
`00-vision.md` / README and citing this Primer as the canonical DR reference. (`gamlss2` now integrates
`mgcv` smoothers — the frameworks are converging; drmTMB's phylo/REML angle is the complement they lack.)

**Ecology hook:** the Primer's introduction cites drmTMB's exact scientific world — Bolnick 2011
(intraspecific trait variation), Violle 2012 "the return of the variance", Des Roches 2018 — and Box 1
frames DR as *decomposing changes in extremes into location/scale/shape*. This is a ready-made "why model
the variance" narrative for drmTMB's vignettes and papers, with a co-author (Tonkin) in the eco lane.

## Issues filed

- **#747** — randomized quantile residuals + worm/QQ/bucket diagnostics (distributional adequacy)
- **#748** — conditional quantiles / exceedance probabilities / centile curves (distributional outputs)
- (Shape families already tracked at **#3**; no new issue.)

## Provenance / honesty

Gaps confirmed by grep of `R/ man/ tests/ vignettes/`, not exhaustive reading — if either surface exists
under another name, close the issue as already-covered. drmTMB capability claims above are read off the
design docs + NAMESPACE, not re-validated here. This note is a *scout*, not a capability-status edit.

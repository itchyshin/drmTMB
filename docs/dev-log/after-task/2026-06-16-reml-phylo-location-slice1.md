# After-task — REML for the phylogenetic location model (Phase 8, slice 1)

Date: 2026-06-16
Branch: `codex/reml-location-extension`

## What changed

Extended REML from the existing univariate-Gaussian-location slice to **mean-side
phylogenetic** location models. Before this slice, any `phylo()` term made
`drmTMB(..., REML = TRUE)` abort with "structured Gaussian effects yet"; now a
phylogenetic effect on the **mean** with an intercept-only `sigma` fits by REML,
while scale-side and non-phylogenetic structured effects stay rejected.

The mechanism is unchanged from the existing REML slice and matches gllvmTMB's
approach: REML adds the mean fixed-effect block (`beta_mu`) to the TMB `random`
set so TMB's Laplace step integrates it out, giving the restricted likelihood.
For a Gaussian phylo mixed model that Laplace step is exact. **No C++ change** —
REML is purely an R-side choice of which parameters TMB marginalises.

Files:
- `R/drmTMB.R` — `drm_validate_reml_spec()` now allows `structured_mu_type() == "phylo"`
  on mean endpoints and rejects (a) scale-side structured effects and (b) non-phylo
  structured types (spatial / animal / relmat) under REML.
- `tests/testthat/test-reml-phylo-location.R` — new; validates against a
  hand-computed restricted likelihood.
- `tests/testthat/test-comparators.R` — the "unsupported neighbours" enumeration
  now asserts scale-side phylo rejection (mean-side phylo is supported).

## Why the sibling check mattered

Before grinding on a from-scratch validation I checked the gllvmTMB, hsquared,
and HSquared.jl REML work (the maintainer asked whether it was worthwhile — it
was). Three concrete results:

1. **gllvmTMB (GPL-3, R/TMB) is the reusable pattern.** It does REML exactly this
   way — adds the fixed-effect block to `MakeADFun(random=)`, no C++ change — and
   recovers the marginalised fixed effects with a three-tier fallback
   (`opt$par` -> `obj$env$parList()` -> `sd_report$par.random`). It validates
   against glmmTMB at tolerance 1e-5.
2. **The restricted-likelihood formula is independently confirmed.** Both
   hsquared's R reference and HSquared.jl's `sparse_reml_loglik` implement exactly
   `-0.5 * [(n-p) log(2 pi) + log|V| + log|X'V^-1 X| + r'V^-1 r]`, which is what the
   new test's `reml_reference()` computes. The reference was not the suspect.
3. The original test failures were a **field-name bug in the test**
   (`fit$par$beta_mu` / `fit$par$beta_sigma` instead of `fit$par$mu` / `fit$par$sigma`),
   not an implementation defect. `parList(opt$par)` already populates `beta_mu`
   from the conditional modes, so drmTMB does not even need gllvmTMB's
   `par.random` fallback for this slice.

hsquared itself delegates REML to Julia (HSquared.jl) and is not a reusable
R/TMB pattern; its value here was the corroborating reference formula.

## Validation evidence

`drmTMB` REML estimates match the hand-computed restricted-likelihood reference
on a 30-tip, 3-records-per-tip Gaussian phylo fixture:

| quantity            | drmTMB REML | reference |
|---------------------|-------------|-----------|
| phylo SD (`sdpars`) | 0.48018     | 0.48017   |
| residual sigma      | 0.51673     | 0.51673   |
| beta (intercept)    | 0.29441     | 0.29440   |
| beta (slope)        | 0.65914     | 0.65914   |

`opt$par` holds only `beta_sigma` and `log_sd_phylo`; `sdr$par.random` holds
`beta_mu` and `u_phylo`, confirming `beta_mu` is genuinely marginalised. REML's
phylo SD is 0.087 larger than ML's on the same fixture (bias-correction direction).

Tests: `test-reml-phylo-location.R` 7/7 pass; `test-comparators.R` 123/123 pass
(the existing univariate-Gaussian and metafor-REML cells are unbroken).

## Honesty / scope

- REML improves variance-component bias and convergence (it keeps the component
  off the zero boundary), **not** identifiability — a flat ridge stays flat. The
  coupled scale-phylo model still needs the penalty or replication.
- Slice 1 validated **phylo on the mean** only. Spatial / animal / relmat
  structured effects under REML are gated off (not validated), and scale-side
  structured effects stay rejected — REML restricts the location likelihood, so
  REML-on-scale is not a defined estimator.
- External anchor available for a later slice: HSquared.jl recovers the published
  gryphon REML estimate (Wilson et al. 2010: VA=3.3954, VE=3.8286, h2=0.470),
  cross-checked against R `sommer`; usable as an additional drmTMB cross-check.

## Next

Slice 2 (Ayumi-relevant): REML with `sigma ~ predictors` (heteroscedastic
residual) and bivariate `mu1`/`mu2` location — relax the intercept-only-sigma and
univariate-only gates, add `beta_mu1`/`beta_mu2` to the random set, df correction,
validate. This is the trigger for the "good news" follow-up to Ayumi.

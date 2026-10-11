# mi() case weights and adaptive prior quadrature (#1459, #1476, #1477)

## 1. Goal

Make an integer case weight behave exactly like duplicating the row in every
`mi()` missing-predictor model, in both the response term and the `mi()` prior
term (#1459). Replace the fixed Beta and Gamma `mi()` prior quadrature rules,
whose prior mass drifted from one by up to a factor of two (#1476) or
collapsed for Gamma shapes above about 40 (#1477).

Reader: a drmTMB developer or reviewer of the lane A pull request. Design
detail lives in `docs/design/149-missing-data-design.md`, section "Continuous
mi() Prior Quadrature and Case Weights".

## 2. Implemented

- Gaussian `mi()` predictor, Gaussian response (`src/drmTMB.cpp`, model_type
  1): observed-predictor prior terms take `weights(i)`. A missing predictor
  keeps the unweighted joint, and the response loop adds
  `(weights(i) - 1) * log m_i` with the analytic Gaussian marginal `m_i`
  (one or two latent predictors). The Laplace step is exact for this joint, so
  weight 2 equals two copies, weight 0 removes the row, and the latent
  curvature (hence `imputed()` standard errors) stays that of one copy.
- Gaussian `mi()` predictor, nbinom2 response (model_type 7): the latent
  joint stays unweighted and the row adds `(w - 1) * log m_hat` with `m_hat`
  the Laplace marginal from fixed parameters (damped Newton in-template). An
  adversarial review of the first version (a curvature term inside the latent
  problem) showed it biased the slope towards 0 for weights below 1; that
  version was replaced.
- New `src/drm_mi_quadrature.h`: posterior-centred Gauss-Hermite marginals for
  Beta (logit scale, bracketed mode plus Newton polish) and Gamma (log scale,
  closed-form mode). Used by the Beta, zero-one-Beta (exact 0/1 atoms plus the
  continuous part) and Gamma branches. Both-missing rows use the exact prior
  mean. Quadrature-family weights still multiply the combined row marginal
  once; zero weights skip the term.
- `R/missing-data.R`: 40-node Gauss-Hermite rule passed to TMB; R mirrors of
  the TMB rules for post-fit summaries; self-normalised prior rules for
  both-missing rows. The weight no longer multiplies the likelihood inside any
  post-fit posterior (it disagreed with TMB for every family).
- `R/drmTMB.R`: invalid weights now raise class `drmTMB_weights_invalid`;
  `@param weights` documents the mi() contract (man page edited by hand to
  match; see section 3a). Fixed the #1355 pluralisation in the negative-weight
  message.
- `R/julia-joint-call.R`: `engine = "julia"` refuses a weighted `mi()` fit with
  class `drmTMB_julia_mi_weights_unsupported`, before any Julia call.

## 3a. Decisions and Rejected Alternatives

- Weighted mi() prior: implemented (Shinichi decides at merge; the PR states
  it on its first line).
- Rejected weighting the Gaussian latent joint by `w`: the Laplace term becomes
  `-0.5 log(w H)` instead of `-(w/2) log H`, so constant weights move the MLE.
- Rejected `qbeta()`/`qgamma()` inverse-CDF nodes: a probe on TMB 1.9.10 gave
  a wrong `qbeta` shape derivative and NaN/Inf gradients at small and large
  shapes.
- Rejected a deterministic two-component (prior + posterior) mixture rule:
  the partition weights are sharp relative to either component and the error
  was 1e-2.
- Kept the man page hand-edited rather than regenerated: per lane G
  (#1140), regenerating on current main reverts #1400's hand-edited prose in
  38 pages.

## 3b. Known Limits

J- or U-shaped Beta priors (a shape well below 1) have a heavy logit-scale
tail. On a 195-cell grid, cells with a shape below 1 had median error 1e-9,
90th percentile 0.16 and worst 1.8 nats. The new rule was less accurate than
the old fixed rule in 2 of the 195 cells, by at most 0.0024 nats. Shapes
between 1 and 2 are accurate to about 5e-4. The nbinom2 weighted route matches
duplication to the Laplace tolerance of the fit, not exactly, and costs 12
extra evaluations per weighted latent row.

## 4. Files Touched

- `src/drm_mi_quadrature.h` (new), `src/drmTMB.cpp`
- `R/missing-data.R`, `R/drmTMB.R`, `R/julia-joint-call.R`, `man/drmTMB.Rd`
- `docs/design/149-missing-data-design.md`
- `tests/testthat/test-missing-predictor-weights.R` (new),
  `tests/testthat/helper-mi-quadrature-reference.R` (new),
  `test-missing-predictor-{beta,gamma,zero-one-beta}.R`,
  `test-guard-branch-continuity.R`, `test-julia-joint-call.R`
- This report

## 5. Verification

- Narrow: `test-missing-predictor-weights.R` 553 pass; Beta 20, Gamma 22,
  zero-one-Beta 25, Gaussian 109, nbinom2-Gaussian 19, guard-branch 66 pass.
  `test-julia-joint-call.R`: the new refusal test passes; the one error is the
  pre-existing JuliaCall-not-installed failure, also present on main.
- Full suite: see the PR comment (local R 4.3.3; CRAN blocked, apt packages).

## 5b. Deferred edits (not made here, by scope)

- C17: this change edits `R/drmTMB.R` and `src/drmTMB.cpp`, so the receipt
  must be regenerated with `python3 tools/recertify-c17.py --label lane-a`
  after merge (the tool refuses while the committed run-1 output directory is
  present on main; move it aside for the run).
- Nothing in `R/methods.R`, `R/profile.R`, vignettes or the C17 TSV was
  edited. `predict()` and `simulate()` need no change: they use the
  conditional predictor values, which do not depend on the weight.

## 6. Next

- If Shinichi wants exact J/U-shaped Beta integration, the next step is a
  boundary-aware rule (for example a Kumaraswamy-quantile change of variable
  for shapes below one, blended with the logit rule).
- #1129 (Gaussian `imputed()` modes off by 1e-4 to 1e-3) is related but was
  not touched here.

# Scout: native mixed-family bivariate (gaussian x poisson) — TMB template change or new model_type?

Date: 2026-09-01
Scope: read-only reconnaissance against `origin/main` (27073059ea2be3ce2efd53b3d7255a927c479d63).
No code was written or run; this feeds a planning decision only.

## 1. How `model_type` is structured

- `model_type` is a single `DATA_INTEGER` read once in `src/drmTMB.cpp:348`, then
  dispatched through a long `if (model_type == N) { ... } else if (model_type == M) { ... }`
  chain (`src/drmTMB.cpp:536` onward through `:4636` and beyond). It is **not** a
  C++ `switch`; every branch is a hand-written `else if`.
- On the R side, `make_tmb_data_core()` in `R/drmTMB.R` has one `if (identical(spec$model_type, "<name>"))`
  block per univariate/other family (17 literal `model_type = <n>L,` assignments —
  gaussian=1 at `R/drmTMB.R:19896`, student=3 at `:19989`, skew_normal=17 at `:20061`,
  lognormal=4 at `:20122`, gamma=5 at `:20195`, tweedie=16 at `:20267`, beta=10 at
  `:20329`, zero_one_beta=15 at `:20407`, beta_binomial=14 at `:20475`, binomial=18 at
  `:20534`, cumulative_logit=13 at `:20610`, poisson=6 at `:20681`, zi_poisson=8 at
  `:20752`, nbinom2=7 at `:20826`, truncated_nbinom2=11 at `:20898`, hurdle_nbinom2=12
  at `:20957`, zi_nbinom2=9 at `:21029`).
- The three bivariate families share **one** R block (`R/drmTMB.R:21097-21102`),
  entered via `if (spec$model_type %in% c("biv_gaussian", "biv_lognormal", "biv_student"))`,
  and inside it `model_type` is assigned via `switch(spec$model_type, biv_gaussian = 2L,
  biv_lognormal = 19L, biv_student = 20L)` (`R/drmTMB.R:21102-21107`). A comment at
  `R/drmTMB.R:21108-21114` explicitly flags that this `switch()` breaks a naive
  `grep` for the `model_type = <n>L` literal pattern — this was the actual root
  cause of a real incident (missing `link_code` for all three bivariate families).
  So: 17 univariate model_types by literal branch + 3 bivariate model_types sharing
  one switch-based branch = 20 total `model_type` integer codes in current use.
- **What adding a model_type entails, mechanically:** (R) add a `spec$model_type <-
  "<name>"` assignment from the family-dispatch logic (`R/drmTMB.R:3100-3140` is
  where families are refused/accepted, e.g. the `cli::cli_abort` at
  `R/drmTMB.R:3132-3137` for "Mixed-response bivariate families are not implemented
  yet"), then a new `if (identical(spec$model_type, "<name>"))` block in
  `make_tmb_data_core()` building the full `DATA_*` payload (every field the TMB
  template's `DATA_INTEGER`/`DATA_VECTOR`/etc. declarations require — dummy values
  for anything unused); (C++) a new `else if (model_type == <n>)` branch in
  `src/drmTMB.cpp` implementing the linear predictors and the negative
  log-likelihood contribution, recompiled. This is the well-worn, low-risk path
  used for all 17 univariate families and (with the switch wrinkle) the 3
  bivariate ones — i.e., point (a) below, *if* the new family fits the existing
  per-observation joint-density shape.

## 2. What the bivariate Gaussian likelihood assumes

Two separate C++ sites use bivariate-normal machinery, and they are answering
different questions — do not conflate them:

- **The observation-level bivariate residual** (`model_type == 2 || 19 || 20`,
  `src/drmTMB.cpp:4636`) computes `mu1`, `mu2`, `log_sigma1`, `log_sigma2`, and a
  **Fisher-z correlation** `rho12 = 0.999999 * tanh(X_rho12 * beta_rho12)`
  (`src/drmTMB.cpp:4641-4642`). The actual density is evaluated by
  `drm_bivariate_gaussian_diag_nll()` (`src/drmTMB.cpp:135-169`), a **closed-form
  standard bivariate-normal density**: `z1=(y1-mu1)/sigma1`, `z2=(y2-mu2)/sigma2`,
  `nll += log(2*pi) + log_sigma1 + log_sigma2 + 0.5*log(1-rho12^2) +
  0.5*(z1^2 - 2*rho12*z1*z2 + z2^2)/(1-rho12^2)`. `model_type == 20`
  (biv_student) instead evaluates a closed-form bivariate-t density directly in
  the main function body (`src/drmTMB.cpp:5172-5190`), reusing the same
  `mu/sigma/rho12` construction. There is also a `V_known_type == 2` path
  (`src/drmTMB.cpp:5057-5077`) that stacks `y1,y2` into a 2n-vector and calls
  TMB's `density::MVNORM_t` when a known residual-correlation matrix is supplied.
  **This is where the Gaussian-ness is baked in**: a single scalar `rho12` per
  observation is algebraically only meaningful as the correlation of two
  *residuals expressed on directly comparable, symmetric, unbounded scales*
  (both `(y-mu)/sigma`); nothing here integrates over any latent variable — it
  is a plain closed-form joint density, differentiated once by TMB's AD.
- **A separate, unrelated bivariate-normal usage** is the *phylogenetic random
  effect* block at `src/drmTMB.cpp:~5011-5140` (2-trait phylo/q4 blocks, e.g.
  `phylo_q4_corr`, `phylo_q4_covariance` at `:5150-5160`), which models
  correlated *random effects* across two response dpars using an
  `UNSTRUCTURED_CORR_t`/quadratic-form MVN density over the phylogenetic
  precision matrix. This is a random-effects covariance structure, not the
  residual/observation likelihood, and is orthogonal to the mixed-family
  question — it would need its own analysis if mixed families interact with
  phylo random effects, but it is not "the bivariate Gaussian likelihood" the
  planning question is about.

## 3. What gaussian x poisson would require

DRM.jl's `fit_mixed_family` (`DRM.jl/src/mixed_family.jl:1-33`, read-only) makes
the "latent scalar correlation" construction explicit in its own header comment:

```
y1_i ~ fam1(eta1_i),  y2_i ~ fam2(eta2_i),   eta_k = X_k*beta_k + lambda_k*u_i,  u_i ~ N(0,1)
```

- A **shared per-observation scalar latent** `u_i ~ N(0,1)` enters both linear
  predictors through family-specific loadings `lambda_1`, `lambda_2`. There is
  **no closed-form marginal** for a general family pair; DRM.jl integrates `u_i`
  out numerically per observation with **1-D Gauss-Hermite quadrature** ("The
  1-D integral over u is done by Gauss-Hermite quadrature (K nodes)" — same file,
  line 7), which only reduces to the exact bivariate-normal closed form in the
  special case where *both* axes are Gaussian (line 11-12 of that header).
  Reported association (`rho`) is a **link-scale ("Nakagawa-Schielzeth")
  residual correlation**, not a response-scale `rho12` (line 9-10).
- **Assessment**: this is *not* expressible as a same-shape new branch in the
  existing TMB template. The existing template's bivariate block computes a
  closed-form joint density with algebraic `rho12`; the general mixed-family
  case has no closed form and needs (i) a genuinely new *integration path* —
  either a numerically-integrated latent scalar (Gauss-Hermite quadrature per
  observation, as DRM.jl does, which TMB can express but is a materially
  different computational pattern from every existing branch) or (ii) treating
  `u_i` as a length-N `PARAMETER_VECTOR` random effect integrated out by TMB's
  own Laplace approximation (TMB's native random-effects machinery), which is
  architecturally closer to what drmTMB already does for its other random
  effects (`u_mu`, `u_sigma`, `u_phylo` in `src/drmTMB.cpp`) but is still a
  **new random-effect axis and a new per-family conditional log-density
  dispatch** (Gaussian/Poisson/NB2/Binomial/Beta/Gamma each need their own
  `_mf_obs_ll`-equivalent term in C++, per DRM.jl's family-dispatch table at
  `mixed_family.jl:27-65`), not a drop-in `else if (model_type == N)` block
  reusing the current bivariate machinery.
- This maps to classification **(c)** below: a new integration path (new random
  effects and/or new quadrature), not just a new model_type branch on the
  existing template.

## 4. What `associate_pairs()` / `latent_normal()` already provides

`R/associate-pairs.R:1-14` and `:73-108` are explicit that this is a **different
thing entirely**, not a stepping stone toward joint native fitting:

- `latent_normal()` docstring: "It is not a Gaussian residual-correlation model
  and does not use `rho12()`" (`R/associate-pairs.R:3-4`).
- `associate_pairs()` docstring: "estimates a named within-row association
  **after fitting two marginal models**. It never refits, updates, profiles, or
  otherwise alters either margin" (`R/associate-pairs.R:18-20`); "The fitted
  parameter `eta` is a Gaussian-copula latent-normal association. It is neither
  `rho12()`, an observed-scale correlation, nor `corpairs()`"
  (`R/associate-pairs.R:27-29`).
- Mechanically this is a **two-stage** procedure: fit each margin independently
  (with whatever engine/family each supports on its own), then estimate a
  post-hoc association parameter and a **Godambe (sandwich) covariance** that
  propagates margin uncertainty (`R/associate-pairs.R:30-32`; the
  family-pair-specific sandwich files `R/associate-pairs-sandwich-*.R` implement
  this per admitted pair: gaussian x bernoulli, gaussian x nbinom2, bernoulli x
  bernoulli, nbinom2 x nbinom2).
- **Verdict**: this is emphatically not the same estimator as a native joint
  mixed-family likelihood. It never constructs a single joint `DATA_*`/`nll` in
  `make_tmb_data_core()`/`drmTMB.cpp`, never shares fixed or random effects
  across the two margins during estimation, and its association parameter is a
  copula-latent `eta`, philosophically similar to (but methodologically distinct
  from) the DRM.jl shared-latent construction. It is a plausible **conceptual
  precedent** (drmTMB already has *a* latent-normal association machinery in R)
  but **not reusable engineering** for a native joint TMB likelihood: the TMB
  template, `make_tmb_data_core()`, and C++ side have zero code paths shared
  with `associate_pairs()`, which lives entirely in post-hoc R-level estimation
  over two already-fitted `drmTMB` objects.

## 5. Cost estimate and classification

**Classification: (c) — a new integration path (new random effects / quadrature),
not (a) a same-template model_type branch, and not (b) merely new C++
likelihood code bolted onto the existing per-observation closed-form structure.**
Not (d): the DRM.jl bridge is a working existence proof that the method is
feasible without a from-scratch redesign of drmTMB's parameter/random-effect
plumbing — TMB natively supports both the Laplace-approximated random-effects
route and, via `density::` quadrature-free numerical integration if built by
hand, a Gauss-Hermite route.

Reasoning:
- The existing bivariate branches (`model_type` 2/19/20) share one thing that
  breaks for mixed families: a single closed-form joint density algebraically
  built from two same-shape standardized residuals and one correlation
  parameter (Section 2). Gaussian x Poisson has no such closed form because a
  Poisson response has no residual on a scale comparable to a Gaussian z-score.
- DRM.jl's own solution (Section 3) is architecturally a **new axis**: a
  per-observation latent variable that must be integrated out, plus a
  per-family conditional-density dispatch table. Porting this into drmTMB's TMB
  template means: (i) declaring a new `PARAMETER_VECTOR` (or handling the
  integral via manual quadrature nodes/weights passed as `DATA_*`), (ii) a
  family-dispatch table on the C++ side for each of the ~6+ per-axis families
  DRM.jl already supports (Gaussian/Poisson/Binomial/NB2/Beta/Gamma), and (iii)
  new R-side plumbing in `make_tmb_data_core()` to build that payload — well
  beyond "add one `else if` branch."
- `associate_pairs()` (Section 4) is not reusable machinery for this: it's a
  two-stage, margins-fit-separately-then-associated design living entirely in R
  with no TMB template involvement, so it neither reduces nor informs the C++
  engineering cost, though it is useful *prior art* for how drmTMB reports a
  latent-normal association to users.

**Confidence: medium-high** on the structural facts (model_type branch mechanics,
where rho12/Fisher-z is baked in, DRM.jl's latent-quadrature construction, and
associate_pairs' two-stage nature) — all directly grounded in cited file:line
evidence. **Lower confidence** on the precise TMB engineering cost/shape (e.g.
whether a Laplace random-effect axis or manual Gauss-Hermite DATA-quadrature is
the better drmTMB-native design, and how it would interact with the existing
`u_mu`/`u_sigma`/`u_phylo` random-effect infrastructure and REML/profile paths)
— that is a design decision, not something this recon alone resolves.

## Open questions I could not resolve from static reading

- Whether TMB's Laplace approximation is numerically adequate for a
  Poisson-conditioned latent scalar at the precision drmTMB users need (DRM.jl
  chose explicit Gauss-Hermite specifically to avoid Laplace's poor behavior on
  discrete/skewed conditional densities — this is a substantive design
  reason, not an oversight, and it argues for a genuinely new integration
  primitive in drmTMB rather than reusing its Laplace random-effects
  machinery as-is).
- Whether the ~54-assertion `tests/testthat/test-xfam-bridge.R` coverage
  (referenced in the D-179 capability-status comment at
  `R/julia-bridge.R:310`) exercises correctness against a known DGP with
  interval coverage, or only round-trip/smoke behavior — the comment itself
  says "NOT interval coverage," which bears on how much of DRM.jl's approach
  is already validated versus merely functional.

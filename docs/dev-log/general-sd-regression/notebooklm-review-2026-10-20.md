# NotebookLM methods review: latent SD regression

This memo records the methods review for predictor-dependent standard deviations of latent Gaussian effects. It informs the Bernoulli-first design and later family mapping; it does not certify any `drmTMB` or `DRM.jl` implementation.

## Evidence boundary

The personal NotebookLM notebook, “General latent-SD regression: identifiability and inference (2026-10-17),” contains 15 sources. Its structured answers returned no citation references, so source numbers were mapped against `notebooklm source list` and checked against the accessible primary pages below. NotebookLM is useful here as a source triage and synthesis tool. Its unverified or source-mismatched claims are not treated as evidence.

The corpus has useful but incomplete coverage. The ScienceDirect search result exposes Joe’s abstract, although direct page retrieval returned 403. The abstract reports that Laplace bias depends on response discreteness, is greater for binary and ordinal outcomes than for counts, and decreases as cluster size grows. It also says Laplace can be adequate in some small-cluster settings, so it does not justify a blanket rejection of Laplace. It does not study a regression for latent SDs.

The DHGLM manual documents fixed predictors in random-effect variance linear predictors. This is software precedent, not proof of identifiability or interval coverage for this package’s model.

The `glmmTMB` covariance vignette explains covariance construction and gives a specific overparameterization example when an unstructured covariance and observation-level dispersion are both estimated. That Gaussian example must not be generalized to Bernoulli models, which have no free residual Gaussian scale.

NotebookLM classified two pages as security-checkpoint captures, one as archival metadata, and one as a publisher portal. These provide no methods evidence.

Stringer’s full text gives a useful but narrow calibration precedent: Bernoulli logit models with a random intercept and slope, a common correlated 2 × 2 Gaussian covariance, and many small groups. Its simulations vary group count, group size, and quadrature order; Laplace performs poorly for some small-group cases, while larger quadrature orders improve bias and interval coverage. In one applied example, results level off around 17 nodes, but that is not a universal threshold. The paper does not evaluate predictor-dependent SD regression, crossed effects, or the package’s current routes.

## Mathematical implications for the design

For ordinary independent effects, the target model is

\[
b_g \sim N(0,s_g^2), \qquad \log(s_g)=W_g\alpha.
\]

For a structured effect with existing covariance kernel \(K\), scaling the latent vector by \(D=\operatorname{diag}(s_g)\) gives

\[
b=Du,\quad u\sim N(0,K),\quad \operatorname{Cov}(b)=DKD,
\qquad \operatorname{SD}(b_g)=s_g\sqrt{K_{gg}}.
\]

These equations follow directly from the model transformation. Unless the existing kernel is unit-diagonal, \(s_g\) is a multiplier rather than the marginal SD. Preserve current kernel scaling and report that interpretation. For the coordinate-spatial route in the candidate worktree, the fixed kernel includes diagonal jitter; the spatial SD formula must therefore be checked against the actual retained kernel and site index.

Identifiability is design-specific. A useful exact warning is the probit random-intercept case with one Bernoulli observation per group and a common intercept: integrating over \(u_g\sim N(0,s^2)\) gives \(p=\Phi\{\beta_0/\sqrt{1+s^2}\}\), so the marginal probability alone identifies only a ratio of location and scale. This special case is not a theorem about logit models or about SD predictors varying over observed group covariates. The reviewed sources provide no general necessary-and-sufficient condition for identifying \(W\alpha\) in Bernoulli-logit models. We must test the planned design directly, including confounding with the mean model and weak-information cases.

## Consequences for inference and validation

The primary-source review supports treating integration accuracy as an empirical question, especially for sparse binary data. It does not supply a validated Laplace-versus-quadrature threshold for this heterogeneous-SD model. For Bernoulli, compare the fitted route with an independent scalar-cluster integral where the design factorizes, and retain difficult or failed fits. Do not use the Julia/TMB comparison as the only oracle. For correlated and structured effects, use an independently computed joint density or covariance oracle with the exact same kernel, ordering, weights, and link.

No reviewed source establishes calibrated uncertainty for SD-regression coefficients, predicted SDs, or SD ratios. Constant-SD interval results and software precedents cannot fill that gap. The current Bernoulli profile-interval first look remains `look2_required`; the profile and bootstrap smoke tests establish dispatch only. Coverage claims require the frozen calibration contract and its source-bound adapter qualification before any second look.

## Source map

| Source | What it supports here | Limit |
|---|---|---|
| Joe (2008), [Accuracy of Laplace approximation for discrete response mixed models](https://www.sciencedirect.com/science/article/abs/pii/S0167947308002533) | The search-result abstract reports that discreteness and cluster size affect Laplace bias in the studied discrete GLMMs. | Direct page retrieval returned 403; no SD-regression study or universal adequacy rule. |
| CRAN, [`dhglm` reference manual](https://cran.r-project.org/web/packages/dhglm/refman/dhglm.html) | Fixed terms can enter random-effect variance linear predictors. | API precedent only; not direct-SD inferential evidence for `drmTMB`. |
| Brooks et al. (2017), [`glmmTMB` covariance vignette](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html) | Structured covariance construction and one example of residual-dispersion overparameterization. | Gaussian covariance examples do not imply a Bernoulli residual scale. |
| Kristensen et al. (2016), [TMB: Automatic Differentiation and Laplace Approximation](https://www.jstatsoft.org/article/view/v070i05) | TMB’s general computational framework for latent Gaussian models. | Does not validate this parameterization or its coverage. |
| Stringer (2023, revised 2024), [Exact Gradient Evaluation for Adaptive Quadrature Approximate Marginal Likelihood in Mixed Models for Grouped Data](https://arxiv.org/html/2310.01589v2) | Full text reports a Bernoulli random-intercept/slope simulation with shared correlated Gaussian covariance, varying group count, group size, and quadrature order; larger orders improve bias and Wald coverage in difficult small-group settings. | The applied-example node level is not universal. The study does not cover predictor-dependent SDs or crossed effects. |
| Bates et al. (2015), [Fitting Linear Mixed-Effects Models Using `lme4`](https://www.jstatsoft.org/article/view/v067i01) | Mixed-model fitting and variance-component inference context. | Not a coverage result for this SD-regression target. |

## Decisions carried into implementation

1. Keep ordinary Bernoulli SD regression on the link-scale latent effect; do not add a free Bernoulli residual `sigma`.
2. Validate identifiability using independent synthetic designs, increasing information and deliberate weak-identification controls.
3. Keep kernel multiplier and marginal-SD terminology distinct whenever \(K_{gg}\ne1\).
4. Treat profile/bootstrap routing and point-estimate recovery as different evidence from interval calibration.
5. Do not promote another family, effect type, or engine from the NotebookLM synthesis alone.

The evidence gap that remains is empirical: recovery, failure accounting, and calibrated intervals for each declared domain. This review narrows the claims; it does not narrow the approved implementation scope.

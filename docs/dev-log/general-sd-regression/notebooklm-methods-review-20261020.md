# Methods review: predictor-dependent latent SDs

## Decision this review informs

What does existing methods evidence establish about fitting and making inferences for predictor-dependent random-effect standard deviations in Bernoulli mixed models, and which parts still need direct validation in `drmTMB`?

## Evidence reviewed

The NotebookLM notebook “General latent-SD regression: identifiability and inference” contains 15 sources. I reviewed its source list and asked for a source-limited synthesis. NotebookLM saved that synthesis as “Methods review: latent SD regression, integration, and uncertainty (2026-10-20),” note `b8f1ac10-4a35-43b0-b07b-c8fedd915f70`. The saved note has no structured source links, so its inline source numbers are not treated as verified citations. I checked the material claims against the accessible source pages below.

Primary and software sources checked:

- Harry Joe, [“Accuracy of Laplace approximation for discrete response mixed models”](https://www.sciencedirect.com/science/article/abs/pii/S0167947308002533), *Computational Statistics & Data Analysis* 52 (2008), 5066–5074. The publisher page is access restricted, but its abstract and discussion are visible.
- Alex Stringer, [“Exact Gradient Evaluation for Adaptive Quadrature Approximate Marginal Likelihood in Mixed Models for Grouped Data”](https://arxiv.org/abs/2310.01589), preprint of the 2025 *Statistics and Computing* paper.
- CRAN, [`dhglm` 2.0 reference manual](https://cran.r-project.org/web/packages/dhglm/refman/dhglm.html), especially `DHGLMMODELING`, lines describing `LinPredRandVariance`, `LinkRandVariance`, and `RespDist = "binomial"`.
- `glmmTMB`, [“Covariance structures with glmmTMB”](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html), especially the unstructured covariance and `dispformula = ~0` discussion.
- Lee and Noh, [“Modelling random effect variance with double hierarchical generalized linear models”](https://journals.sagepub.com/doi/10.1177/1471082X12460132), *Statistical Modelling* 12 (2012), 487–502. The notebook's capture of this item was metadata or abstract only; I do not use it for detailed derivations.

## What the sources support

Joe's study compares Laplace and adaptive Gauss-Hermite approximations across discrete-response mixed-model examples. It reports that binary and ordinal outcomes can produce more asymptotic bias than counts, that bias declines as cluster size increases, and that Laplace is often adequate even for small clusters. These results do not establish that Laplace fails for every Bernoulli data set, and they do not calibrate predictor-dependent variance slopes. The publisher page does not provide the full numerical tables to verify the specific “10–20% coverage” numbers repeated in the NotebookLM conversation, so this review excludes those numbers.

Stringer's paper studies adaptive quadrature for Bernoulli mixed models with one grouping factor and multivariate correlated Gaussian random effects. Its simulations report that Wald intervals for variance parameters can attain nominal coverage when enough quadrature points are used, including settings with many small groups and substantial between-group variation. This supports using an independent integration route as a numerical comparator. It does not establish a node count that works universally, or coverage for regression coefficients in a group-specific log-SD model.

The `dhglm` manual documents a binomial model interface in which fixed predictors can enter the random-effect variance model through `LinPredRandVariance`, with a log link. The manual offers software precedent for modeling latent random-effect variance. If `log(lambda_g) = W_g gamma` and `tau_g = sqrt(lambda_g)`, then `log(tau_g) = W_g gamma / 2`; this conversion is algebra and says nothing about validation. A variance model for latent effects is distinct from a model for observation-level dispersion.

For a correlated block, the covariance identity `Sigma_g = D_g R D_g` implies coefficient-specific latent SDs when the diagonal of `R` is one. For a structured effect with kernel `K`, the identity `Cov(b_g, b_h) = tau_g tau_h K_gh` implies marginal SD `tau_g sqrt(K_gg)`. Thus `tau_g` is a multiplier when the kernel diagonal is not one. These are covariance-algebra consequences and must preserve each engine's existing kernel scaling. The `glmmTMB` vignette also demonstrates that an extra residual variance can be redundant with a fully unstructured latent covariance; that example does not add a Bernoulli residual-SD parameter to our model.

## Identifiability: structural versus weak information

The literature reviewed here does not prove identifiability of a continuous latent log-SD slope for a Bernoulli GLMM. One design-specific structural failure follows directly from the model: with an intercept-only logit random-intercept model and one Bernoulli observation per group, every group has the same marginal success probability `p = E[logit^{-1}(beta + tau Z)]`. The observed-data distribution contains only that one probability, so it cannot identify both `beta` and `tau`. This dimension argument applies to that design. Other designs with varying predictors need separate analysis. Variation in known predictors may add distinct marginal probabilities, and repeated observations within groups add information; neither guarantees adequate finite-sample precision.

This corrects a NotebookLM summary that contrasted probit's closed-form confounding with logit's lack of a closed form and then suggested no general one-observation limitation for logit. Lack of a closed-form identity does not establish identifiability. For this feature, rank/curvature checks, profiles, and recovery experiments must distinguish an exactly confounded design from an identifiable but weakly informed one.

## Implications for the implementation and validation

1. Keep the Bernoulli latent SD on the linear-predictor scale; do not add a free residual variance.
2. Test structural confounding with an intercept-only, one-observation-per-group case, and test recoverable slopes in designs with replicated groups and adequate predictor support. Add sparse and imbalanced cases as weak-information stress tests rather than treating their failure as structural non-identifiability.
3. Compare Laplace results with an independent scalar-cluster integration oracle where possible. Measure quadrature-order stability for each scenario instead of adopting one fixed threshold.
4. Calibrate intervals for the log-SD coefficients and predeclared SD ratios directly. Neither constant-covariance AGHQ evidence nor DHGLM software support substitutes for coverage evidence for these targets.
5. Preserve structured-kernel scaling in both engines and state whether reported quantities are SD multipliers or marginal SDs.

No source reviewed establishes the complete feature's identifiability conditions, recovery performance, or uncertainty calibration. Those remain empirical and mathematical deliverables of this project.

## Source-capture limitations

NotebookLM marked DOI publisher pages, an archive record, and some abstract-only items as inaccessible or weak captures. It also returned long summaries with citation numbers but no structured references. I therefore verified the claims used above against the source pages directly and excluded its unsupported coverage percentages and universal quadrature thresholds.

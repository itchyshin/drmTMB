# Missing Data Design

This note records the staged model-based missing-data lane for `drmTMB`. It is
about response cells, response pairs, and predictors with missing values. It is
not about bipartite host-parasite phylogenetic models, higher-dimensional
multivariate models, Bayesian imputation, or external multiple-imputation
workflows.

The target reader is a statistical method developer or package contributor who
needs to decide which missing-data feature can be fitted next without changing
the package's one-response and two-response scope. Historical sections preserve
the implementation checkpoints that were true when written; the consolidated
current claim is at the end of this note.

## Pre-MD0 Boundary

Before MD0, fitting was complete-case at the model-builder level. Builders
collected
variables from all active distributional-parameter formulas, structured terms,
random-effect terms, direct-SD formulas, and known-covariance markers. They
then built TMB inputs from retained rows only. For bivariate Gaussian models, a
row was a complete response pair, so a missing `y1` or `y2` dropped the whole pair
before likelihood construction.

That behaviour was simple and reproducible, but it was not an observed-data
likelihood. Fitted values, residuals, `nobs()`, and diagnostics reported the
fitted rows, not original rows plus an observed-response mask.

Local evidence:

- `R/drmTMB.R` uses `complete.cases()` before constructing univariate and
  bivariate model matrices.
- `tests/testthat/test-gaussian-location-scale.R` checks complete-case filtering
  across Gaussian `mu` and `sigma` terms.
- `tests/testthat/test-biv-gaussian.R` checks complete-case filtering across
  `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` formulas.
- `src/drmTMB.cpp` currently assumes bivariate Gaussian rows contain both
  response values when it evaluates the residual `rho12` likelihood.

## MD0 Source Audit

The 2026-05-31 MD0 audit recorded the pre-implementation complete-case
boundary before any runtime behaviour changed:

- `drmTMB()` rejected all extra `...` arguments, so a missing-data API needed
  an explicit top-level argument rather than hidden dots parsing.
- The univariate Gaussian builder used one complete-case gate across response,
  predictor, random-effect, structured-effect, and known-covariance variables
  before building the model frames. The audit anchor was
  `R/drmTMB.R:740-761` in the pre-MD1 tree.
- The bivariate Gaussian builder used complete paired rows before the bivariate
  model frames and TMB inputs were built. The audit anchor was
  `R/drmTMB.R:3502` in the pre-MD1 tree.
- The bivariate C++ likelihood assumed paired `y1` and `y2` vectors. Partial
  response-pair likelihoods therefore need an explicit later bivariate mask,
  not reuse of the univariate `observed_y` vector.
- Dense known sampling-covariance matrices still require component-level row
  and column slicing before partial response rows can be supported. MD1 keeps
  dense known `V` response masks deferred.

## MD1 Implemented Boundary

MD1 adds `missing = miss_control(response = "include")` for univariate
Gaussian models only. Predictors, grouping variables, structured-effect inputs,
offsets, weights, and known sampling variances must be complete on retained
rows. Missing Gaussian responses are replaced by an internal sentinel after the
logical `observed_y` mask is stored. The TMB Gaussian likelihood uses
`observed_y` to skip those response contributions, so changing the sentinel
must not change the objective, gradient, coefficients, or observed-row fitted
values.

The fitted object now carries `fit$missing_data` for Gaussian fits. The MD1
slot records:

```text
version
response_policy
predictor_policy
engine
original_row
model_row
observed_y
counts
response_sentinel
```

`nobs()` remains the likelihood-contributing row count, not the retained-row
count. `fitted()` can return retained rows, and response residuals are `NA` for
masked responses.

## MD2 Implemented Boundary

MD2 extends `missing = miss_control(response = "include")` to independent
bivariate Gaussian models without dense known sampling covariance. Predictors,
grouping variables, structured-effect inputs, offsets, and weights must be
complete on retained rows. Missing `y1` and `y2` values are replaced by the same
internal sentinel only after the separate `observed_y1` and `observed_y2` masks
are stored. The TMB bivariate Gaussian likelihood uses the masks to choose the
row contribution:

```text
both observed     -> bivariate Gaussian density with rho12
only y1 observed  -> y1 marginal Gaussian density
only y2 observed  -> y2 marginal Gaussian density
both missing      -> zero response-likelihood contribution
```

The fitted object carries a `fit$missing_data` slot with `version = "MD2"` for
bivariate Gaussian fits. It records `observed_y1`, `observed_y2`,
`response_pattern`, complete-pair and one-response counts, and
`likelihood_rows = sum(observed_y1 | observed_y2)`. `nobs()` remains the
likelihood-contributing row count. Response and Pearson residuals are `NA` for
missing response cells; a row with only `y2` observed uses the marginal `y2`
Pearson residual rather than a conditional residual involving missing `y1`.

Dense known `meta_V(V = V)` remains deferred for partial-response rows because
the row-paired `2n` by `2n` covariance block needs component-level slicing when
one response is missing. MD2 therefore errors clearly if
`response = "include"` is combined with missing bivariate responses and a dense
known sampling covariance matrix.

## Terminology

Use likelihood language, not posterior-imputation language.

`response = "drop"` is the current complete-case behaviour. It drops rows with
missing response values before the TMB likelihood sees them.

`response = "include"` is the observed-response likelihood policy. It keeps
original row identity and uses an observed-response mask. Missing responses add
no direct response likelihood contribution. Observed responses still contribute
with their distributional parameters and any fitted random or structured effects.

`predictor = "fail"` is the first safe predictor policy. Missing predictors,
grouping variables, offsets, weights, and required known-covariance entries keep
failing or dropping through the existing model-frame rules unless a later slice
explicitly supports them.

`predictor = "model"` is a later joint missing-covariate model. It requires
explicit `mi()` syntax and an `impute` formula. Missing predictor values become
latent quantities integrated over by TMB/Laplace; they are not filled by silent
single imputation.

`engine = "laplace"` is the general TMB engine for latent missing predictors and
other random effects. `engine = "em"` can be a later Gaussian helper or
warm-start path, but it should not be the public default for distributional
regression. `engine = "mcmc"`, priors, posterior draws, and credible intervals
are out of scope for this lane.

Estimator choice should stay separate from missing-data engine choice. ML is the
default estimator. The first ordinary Gaussian mixed-model REML route lives on
the top-level `drmTMB(..., REML = TRUE)` estimator switch, not in
`miss_control()`. REML for explicit missing-response or missing-predictor routes
remains a later slice because those likelihoods need their own extractor and
comparator checks.

## Response-Missingness Contract

The first public design should be:

```r
missing = miss_control(
  response = "include",
  predictor = "fail",
  engine = "laplace"
)
```

For an independent univariate model with complete predictors, a missing response
contributes zero response likelihood. The fitted coefficients should match the
complete-case fit because no row-specific response information is added. The
benefit is row accounting: prediction, fitted-value reconstruction, diagnostics,
and future imputation summaries can refer to the original data rows.

The internal data contract should carry at least:

```text
original_row
model_row
observed_y
y
weights
offsets
distributional-parameter model matrices
grouping and structured-effect indices
```

For bivariate Gaussian models, response missingness is more valuable because a
partially observed pair can still identify part of the model. The likelihood has
three row patterns:

```text
both observed:
  log p(y1_i, y2_i | mu1_i, mu2_i, sigma1_i, sigma2_i, rho12_i)

only y1 observed:
  log p(y1_i | mu1_i, sigma1_i)

only y2 observed:
  log p(y2_i | mu2_i, sigma2_i)
```

Rows with one observed response directly inform the corresponding location and
scale parameters. They do not directly identify the residual correlation
`rho12`, because the univariate marginal density does not contain `rho12`.
Complete response pairs remain the direct residual-correlation evidence. With
shared random effects or structured effects, partial rows can still help the
latent field that also affects complete rows, so diagnostics should report
complete-pair counts separately from one-response counts.

Dense known covariance needs its own later design. The current bivariate known
`V` path subsets paired rows and columns after row filtering. Partial-response
observed-data likelihood would require component-level covariance slicing, not
just pair-level subsetting. Do not include dense known `V` in the first response
mask implementation unless this design note is updated.

## Predictor-Missingness Contract

Missing predictors are a separate feature. They require a model for the
predictor, so the package must ask for explicit syntax.

The planned response syntax is:

```r
bf(y ~ mi(body_mass) + phylo(1 | species, tree = tree), sigma ~ 1)

missing = miss_control(
  response = "include",
  predictor = "model",
  engine = "laplace"
)

impute = list(
  body_mass = body_mass ~ 1 + phylo(1 | species, tree = tree)
)
```

Here `mi(body_mass)` means the response model uses a reconstructed `body_mass`
vector inside the TMB objective. The `impute` formula defines the covariate
model. A continuous Gaussian first slice can be written schematically as:

```text
x = W alpha + u_x + e_x
y | x, b, theta_y follows the response model
u_x, b follow their fitted random-effect or structured-effect models
```

The observed-data likelihood is:

```text
L(theta) =
  integral p(y_obs | x_obs, x_mis, b, theta_y)
           p(x_obs, x_mis | b_x, theta_x)
           p(b, b_x | theta_b)
           d x_mis d b d b_x
```

In TMB, `x_mis`, `b`, and `b_x` can all be random effects. TMB/Laplace then
integrates them out for maximum marginal likelihood. For the fitted
MD3a/MD3b/MD4 routes, `imputed(fit, variable = "body_mass")` reports
conditional modes with standard errors from the fitted likelihood approximation
when `sdreport()` is available. It does not report posterior means, posterior
intervals, or Bayesian credible intervals.

Predictor models must be level-aware. Use `phylo()` when the missing variable is
a species-level trait. Use `spatial()` when it is a site-level environmental
covariate. Use `animal()` or `relmat()` when the predictor lives on a pedigree or
user-supplied relatedness scale. Do not automatically inherit every structure
from the response model.

A correlated joint response-predictor phylogenetic field is an advanced later
feature, not the default:

```text
(u_y, u_x) ~ Normal(0, Sigma_yx %x% A)
```

That model can blur interpretation of the fixed effect of `x`, because the
response process and covariate process share evolutionary covariance. Keep the
first structured `mi()` route independent unless a separate design decision
opens this correlated field.

## MD3a Fitted Slice

MD3a opens the first missing-predictor route for one numeric predictor in a
univariate Gaussian location model:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z),
  missing = miss_control(predictor = "model")
)
```

The response model remains conditional Gaussian, `y_i | x_i`, and the `impute`
formula defines a fixed-effect Gaussian model for `x_i`. Observed `x_i` values
contribute their predictor-model density and enter the response mean directly.
Missing `x_i` values are TMB random effects; the Laplace approximation
integrates them from the joint likelihood
`p(y_obs | x_obs, x_mis) p(x_obs, x_mis | z)`. The current fitted object records
the missing predictor under `fit$missing_data$predictors`, including model-row
and original-row indices, observed/missing counts, and the fixed-effect
predictor-model coefficient names.

The fixed-only MD3a boundary is deliberately narrow. It rejects multiple `mi()`
terms, non-numeric missing predictors, `mi()` transformations or interactions,
grouped or structured covariate effects, missing `impute` predictors, sparse
fixed-effect response matrices, Gaussian aggregation, and non-Gaussian response
families.

## MD3b Fitted Slice

MD3b adds one independent grouped random intercept to the same Gaussian
predictor model:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z + (1 | group)),
  missing = miss_control(predictor = "model")
)
```

The covariate model is:

```text
u_g ~ Normal(0, 1)
x_i ~ Normal(W_i alpha + sd_x_group u_group[i], sigma_x^2)
```

Missing `x_i` values and the grouped covariate intercepts are both random
effects in the TMB objective. TMB/Laplace integrates them together with any
response-model random effects. The fitted object records `version = "MD3b"` and
stores the covariate grouping variable, levels, and group count in
`fit$missing_data$predictors`.

The public boundary remains narrow. MD3b rejects random slopes, multiple
covariate random-effect terms, transformed or nested grouping variables,
simultaneous grouped-plus-structured covariate effects, non-Gaussian predictor
models other than the separate fixed-effect finite-state slices, and multiple
missing predictors.

## MD4 Fitted Slice

MD4 adds one independent intercept-only structured field to the same Gaussian
predictor model. The structured term is explicit in the `impute` formula:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z + relmat(1 | line, Q = Q)),
  missing = miss_control(predictor = "model")
)
```

The covariate model is:

```text
u_x ~ Normal(0, sd_x_struct^2 Q_x^-1)
x_i ~ Normal(W_i alpha + a_i u_x[node_i], sigma_x^2)
```

`Q_x` comes from the explicit `phylo()`, coordinate `spatial()`, `animal()`, or
`relmat()` term in the covariate model. The first fitted MD4 route is
intercept-only, so `a_i = 1` in supported public syntax. Missing `x_i` values
and the structured covariate field are TMB random effects integrated by the
Laplace approximation. The fitted object records `version = "MD4"` and stores
the structured marker, grouping variable, levels, and latent-field size in
`fit$missing_data$predictors`.

The public boundary is still deliberately narrow. MD4 rejects structured
covariate slopes, more than one structured covariate model, simultaneous grouped
and structured covariate random effects, `phylo_interaction()`, automatic
inheritance from the response model, joint response-covariate structured
correlations, non-Gaussian predictor models other than the separate
fixed-effect finite-state slices, and multiple missing predictors.

## MD6a Fitted Slice

MD6a adds the first non-Gaussian missing-predictor model: one binary predictor
in a univariate Gaussian location formula. The response formula still uses
`mi()` to mark the missing predictor, but the predictor model declares its
family explicitly with `impute_model()`:

```r
drmTMB(
  bf(y ~ z + mi(treatment), sigma ~ 1),
  data = dat,
  impute = list(
    treatment = impute_model(treatment ~ z, family = binomial())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is:

```text
treatment_i ~ Bernoulli(pi_i)
logit(pi_i) = W_i alpha
```

For observed `treatment_i`, the likelihood uses the observed 0/1 value in the
Gaussian response mean and adds the Bernoulli predictor-model contribution. For
missing `treatment_i`, TMB sums exactly over `treatment_i = 0` and
`treatment_i = 1`. This is a finite-state likelihood, not a continuous latent
random effect and not an EM fill-in. `imputed()` reports the fitted conditional
probability for the missing binary predictor.

The public boundary for MD6a remains narrow. MD6a accepts logical values,
numeric 0/1 values, two-level character vectors, or two-level factors. It
rejects grouped or structured binary predictor models, beta/proportion
predictors, count predictors, multiple missing predictors, and dense known
sampling covariance. Unordered categorical predictors with more than two levels
use the separate MD6c softmax slice; count predictors use the separate MD7b,
MD7c, and MD7e routes.

## MD6b Fitted Slice

MD6b extends the same family-aware `impute_model()` contract to one ordered
categorical missing predictor in a univariate Gaussian location formula:

```r
drmTMB(
  bf(y ~ z + mi(score), sigma ~ 1),
  data = dat,
  impute = list(
    score = impute_model(score ~ z, family = cumulative_logit())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is:

```text
Pr(score_i <= k) = logit^-1(c_k - W_i alpha)
c_1 < c_2 < ... < c_{K-1}
```

For observed `score_i`, the likelihood uses the observed ordered category in
the Gaussian response mean and adds the cumulative-logit predictor-model
contribution. For missing `score_i`, TMB sums exactly over all ordered
categories. This is a finite-state likelihood, not a Gaussian approximation to
category codes and not an EM fill-in. `imputed()` reports the fitted
conditional expected category score, and the missing-data metadata stores the
conditional probability for each ordered level.

The public boundary remains narrow. MD6b accepts ordered factors or
numeric/integer category scores when every ordered category appears at least
once among the observed predictor values. It rejects unordered factors, grouped
or structured ordered predictor models, count predictors, multiple missing
predictors, and dense known sampling covariance. Count predictors use the
separate MD7b, MD7c, and MD7e routes.

## MD6c Fitted Slice

MD6c extends the same family-aware `impute_model()` contract to one unordered
categorical missing predictor in a univariate Gaussian location formula:

```r
drmTMB(
  bf(y ~ z + mi(habitat), sigma ~ 1),
  data = dat,
  impute = list(
    habitat = impute_model(habitat ~ z, family = categorical())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is a baseline-category softmax model. With the first level
as the baseline:

```text
eta_ik = W_i alpha_k, k = 2, ..., K
Pr(habitat_i = 1) = 1 / (1 + sum_{k=2}^K exp(eta_ik))
Pr(habitat_i = k) = exp(eta_ik) /
  (1 + sum_{h=2}^K exp(eta_ih))
```

For observed `habitat_i`, the likelihood uses the observed unordered category
in the Gaussian response mean and adds the categorical predictor-model
contribution. For missing `habitat_i`, TMB sums exactly over all unordered
categories. This is a finite-state likelihood, not a Gaussian approximation to
factor codes and not an EM fill-in. `imputed()` reports the fitted conditional
modal category score, and the missing-data metadata stores the conditional
probability for each unordered level.

The public boundary remains narrow. MD6c accepts unordered factors, character
predictors, or numeric/integer category scores when every category appears at
least once among observed predictor values. It rejects ordered factors, grouped
or structured unordered predictor models, count predictors, multiple missing
predictors, and dense known sampling covariance. Count predictors use the
separate MD7b, MD7c, and MD7e routes.

## Implementation Slices

| Slice | Scope | Stop condition |
| --- | --- | --- |
| MD0 source audit | Confirm all complete-case gates, model-frame assumptions, extractor row counts, and TMB data shapes for supported families. | Stop before adding syntax. |
| MD1 response mask API | Add `miss_control(response = "include", predictor = "fail")`, original-row IDs, `observed_y`, and extractor accounting for one univariate Gaussian route. | Stop before missing predictors, EM, imputation summaries, or broad family support. |
| MD2 bivariate Gaussian patterns | Implemented: retain partial `y1`/`y2` rows without known dense `V`; add pattern-specific likelihood contributions, residual masking, sentinel-invariance tests, and diagnostics for complete-pair versus one-response rows. | Stop before dense known `V` component slicing and before mixed-response families. |
| MD3a continuous Gaussian `mi()`, fixed only | Implemented: support one continuous missing predictor with a fixed-effect Gaussian covariate model such as `impute = list(x = x ~ z)`, with no covariate random-effect block. | Stop before grouped covariate random effects, transformations, splines, non-Gaussian count predictors, structured imputation, and imputation summaries. |
| MD3b continuous Gaussian `mi()`, grouped | Implemented: extend the same first continuous missing predictor to one grouped random-intercept covariate model such as `impute = list(x = x ~ 1 + z + (1 | group))`. | Stop before random slopes, multiple covariate random-effect terms, transformations, splines, non-Gaussian count predictors, structured imputation, and imputation summaries. |
| MD4 structured `mi()` | Implemented: allow one explicit intercept-only structured covariate model using `phylo()`, coordinate `spatial()`, `animal()`, or `relmat()` when the missing variable lives at that level. | Stop before structured covariate slopes, automatic inheritance, `phylo_interaction()`, or joint response-covariate structured correlations. |
| MD5 imputation summaries | Implemented: `imputed()` reports conditional modes for fitted MD3a/MD3b/MD4 Gaussian missing predictors, with likelihood-based conditional standard errors when `sdreport()` is available. MD6a extends the same extractor to binary fitted conditional probabilities; MD6b extends it to ordered fitted conditional expected scores and level probabilities; MD6c extends it to unordered fitted conditional modal category scores and level probabilities; MD7a extends it to strict proportion fitted conditional quadrature means; MD7b extends it to Poisson fitted conditional expected counts; MD7c extends it to NB2 fitted conditional expected counts; MD7d extends it to zero-one beta boundary-proportion fitted conditional quadrature means; MD7e extends it to zero-truncated NB2 fitted conditional expected positive counts; MD7f extends it to beta-binomial denominator-aware fitted conditional proportion means; MD8a extends it to lognormal fitted conditional quadrature means; MD8b extends it to Gamma fitted conditional quadrature means; MD8c extends it to Tweedie fitted conditional quadrature means. | Stop before response imputation, posterior terminology, credible intervals, simulated imputations, and multiple-imputation pooling. |
| MD6a binary `mi()`, fixed only | Implemented: support one binary missing predictor with a fixed-effect Bernoulli/logit predictor model such as `impute = list(treatment = impute_model(treatment ~ z, family = binomial()))`. | Stop before grouped or structured binary predictor models, Poisson count predictors, multiple missing predictors, and simulation-based imputation summaries. |
| MD6b ordered `mi()`, fixed only | Implemented: support one ordered categorical missing predictor with a fixed-effect cumulative-logit predictor model such as `impute = list(score = impute_model(score ~ z, family = cumulative_logit()))`. | Stop before grouped or structured ordered predictor models, Poisson count predictors, multiple missing predictors, and simulation-based imputation summaries. |
| MD6c unordered `mi()`, fixed only | Implemented: support one unordered categorical missing predictor with a fixed-effect baseline-category softmax predictor model such as `impute = list(habitat = impute_model(habitat ~ z, family = categorical()))`. | Stop before grouped or structured unordered predictor models, Poisson count predictors, multiple missing predictors, and simulation-based imputation summaries. |
| MD7a strict proportion `mi()`, fixed only | Implemented: support one strict proportion missing predictor in `(0, 1)` with a fixed-effect beta predictor model such as `impute = list(cover = impute_model(cover ~ z, family = beta()))`. | Stop before grouped or structured beta predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD7b Poisson count `mi()`, fixed only | Implemented: support one non-negative integer count missing predictor with a fixed-effect Poisson predictor model such as `impute = list(abundance = impute_model(abundance ~ z, family = poisson()))`. | Stop before grouped or structured count predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD7c negative-binomial count `mi()`, fixed only | Implemented: support one overdispersed non-negative integer count missing predictor with a fixed-effect NB2 predictor model such as `impute = list(abundance = impute_model(abundance ~ z, family = nbinom2()))`. | Stop before hurdle count predictor models, grouped or structured count predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD7d zero-one beta boundary-proportion `mi()`, fixed only | Implemented: support one boundary-proportion missing predictor in `[0, 1]` with a fixed-effect zero-one beta predictor model such as `impute = list(cover = impute_model(cover ~ z, family = zero_one_beta()))`. The first slice uses the formula for the interior mean and estimates constant predictor-model `sigma`, `zoi`, and `coi`. | Stop before grouped or structured zero-one beta predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD7e zero-truncated negative-binomial count `mi()`, fixed only | Implemented: support one positive integer count missing predictor with a fixed-effect zero-truncated NB2 predictor model such as `impute = list(abundance = impute_model(abundance ~ z, family = truncated_nbinom2()))`. The first slice estimates the untruncated NB2 mean model and overdispersion scale, then conditions on positive count support. | Stop before hurdle count predictor models, grouped or structured count predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD7f denominator-aware beta-binomial proportion `mi()`, fixed only | Implemented: support one denominator-aware proportion missing predictor with a fixed-effect beta-binomial predictor model such as `impute = list(cover = impute_model(success ~ z, family = beta_binomial(), trials = trials))`. The response model uses the proportion variable in `mi(cover)`; the predictor model integrates missing success counts over `0, ..., trials_i`. | Stop before grouped or structured beta-binomial predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD8a lognormal positive-continuous `mi()`, fixed only | Implemented: support one positive continuous missing predictor with a fixed-effect lognormal predictor model such as `impute = list(biomass = impute_model(biomass ~ z, family = lognormal()))`. | Stop before Gamma, Tweedie, or exact-zero semi-continuous predictor models, grouped or structured positive-continuous predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD8b Gamma positive-continuous `mi()`, fixed only | Implemented: support one positive continuous missing predictor with a fixed-effect Gamma mean-CV predictor model such as `impute = list(biomass = impute_model(biomass ~ z, family = Gamma(link = "log")))`. | Stop before Tweedie or exact-zero semi-continuous predictor models, grouped or structured positive-continuous predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD8c Tweedie semi-continuous `mi()`, fixed only | Implemented: support one non-negative semi-continuous missing predictor with exact zeros using a fixed-effect Tweedie predictor model such as `impute = list(biomass = impute_model(biomass ~ z, family = tweedie()))`. The first slice fixes the predictor-model Tweedie power at 1.5 and estimates the mean and scale. | Stop before estimated or predictor-dependent Tweedie power, grouped or structured semi-continuous predictor models, multiple missing predictors, and simulation-based imputation summaries. |
| MD9a Poisson response plus binary `mi()`, fixed only | Implemented: support one binary missing predictor with a fixed-effect Bernoulli/logit predictor model inside an ordinary Poisson response mean model, such as `drmTMB(bf(count ~ z + mi(treatment)), family = poisson(), impute = list(treatment = impute_model(treatment ~ z, family = binomial())), missing = miss_control(predictor = "model"))`. | Stop before missing Poisson responses, zero-inflated Poisson response models with `mi()`, response random effects or structured response terms with `mi()`, non-binary missing predictors in Poisson response models, multiple missing predictors, and simulation-based imputation summaries. |
| MD-leaf pluggable response density | Implemented: `drm_response_log_density(model_type, y, eta, log_sigma, V_known, trials)` in `src/drm_response_kernels.h` is the one per-family response-density leaf the `mi()` quadrature calls, so a non-Gaussian response reuses the same integration loop. The Gaussian extraction is a byte-identical refactor (golden capture on logLik, gradient, objective); the per-family leaves replicate their inline densities exactly. | Stop before routing every family through the leaf (only the `mi()` call sites need it) and before any behaviour change on the vanilla no-`mi()` paths. |
| MD9b binomial response plus binary `mi()`, fixed only | Implemented: one binary missing predictor with a fixed-effect Bernoulli/logit predictor model inside an ordinary binomial response mean model (model_type 18); the `mi()` 2-point sum evaluates the response density through the shared leaf. | Stop before missing binomial responses combined with `mi()`, response random effects or structured terms with `mi()`, non-binary missing predictors, multiple missing predictors, and simulation-based imputation summaries. |
| MD9c NB2 response plus binary `mi()`, fixed only | Implemented: one binary missing predictor inside an ordinary nbinom2 response location-scale model (model_type 7); the `mi()` 2-point sum carries the NB2 dispersion (`size = exp(-2*log_sigma)`) through the shared leaf. | Stop before zero-inflated or hurdle NB2 responses with `mi()`, response random effects or structured terms with `mi()`, non-binary missing predictors, multiple missing predictors, and simulation-based imputation summaries. |
| MD9d beta response plus binary `mi()`, fixed only | Implemented: one binary missing predictor inside a beta response location-scale model for interior proportions (model_type 10); the `mi()` 2-point sum carries the beta precision (`phi = exp(-2*log_sigma)`, with the same boundary nudge and shape floor as the vanilla beta density) through the shared leaf. | Stop before boundary (0/1) beta responses with `mi()` (use `zero_one_beta()`), response random effects or structured terms with `mi()`, non-binary missing predictors, multiple missing predictors, and simulation-based imputation summaries. |
| MD10 non-Gaussian response masks | Implemented: `miss_control(response = "include")` retains and marginalises missing responses for `binomial()`, `poisson()`, `nbinom2()`, and `beta()` via a plain `observed_y` data guard around each family's density (a data-if, never `CondExp`, so the masked-row placeholder is never taped). Each slice ships a sentinel-invariance test (sentinel-independent logLik/coef) and an MCAR recovery test, mirroring MD1/MD2. | Stop before missing responses for families outside these four plus Gaussian/bivariate-Gaussian, mixed masking-plus-`mi()` in a single fit, and dense known `V` response masks. |
| MR-T2 continuous response masks | Implemented: `response = "include"` now uses the same plain `observed_y` data guard for Student-t, skew-normal, lognormal, and Gamma. Starts and validation use observed responses only; lognormal and Gamma keep the entire density and `log(y)` transformation inside the guard. Direct sentinel mutation, row/extractor contracts, and fixed-seed 25% MCAR recovery cover every fitted distributional parameter. | Student-t, lognormal, and Gamma are verified through ordinary random intercepts; skew-normal is fixed-effect only. Do not inherit this evidence to structured modifiers, REML, intervals, coverage, response plus `mi()`, or any remaining family. |
| MR-T3 atom and boundary response masks | Implemented: `response = "include"` masks Tweedie and zero-one beta responses through one plain data-time guard around each whole atom/continuous density decision. Starts and validation use observed responses only. Direct retapes compare Tweedie zero versus positive sentinels and zero-one beta zero/one atoms versus an interior sentinel; exact fixed-seed 25% MCAR tests recover every fitted dpar. | Both routes are fixed-effect only. Do not inherit evidence to random or structured effects, REML, response plus `mi()`, intervals, coverage, or any remaining family. |
| MR-T4 encoded response masks | Implemented: beta-binomial treats either missing count component as a missing whole response row and retapes coordinated success/trials encodings; cumulative logit retains declared ordered-factor levels, guards before category indexing, and rejects any observed subset with an empty category. Exact fixed-seed 25% MCAR tests recover beta-binomial `mu`, `sigma`, and ordinary random-intercept SD plus the ordinal slope and every cutpoint. | Integer ordinal masking is rejected because erased top categories cannot be reconstructed. Do not inherit evidence to broader random/structured effects, REML, response plus `mi()`, intervals, or coverage. |

## Testing Requirements

Every implementation slice needs tests before it can be called fitted support.

MD1 needs a deterministic comparison showing that an independent univariate
Gaussian fit with missing responses matches the complete-case coefficient and
likelihood contribution for observed rows, while preserving original-row
accounting in prediction or model metadata.

MD1 also needs an adversarial sentinel test. The same masked fit must be run
with two very different internal sentinels, such as `0` and `1e6`, and must
return invariant log-likelihoods, coefficients, gradients, and observed-row
fitted values. This is the guard against sentinel leakage into derived sums,
initialization, or unmasked AD branches.

MD2 needs an independent likelihood check for all three bivariate Gaussian
patterns. It should verify that one-response rows inform only their marginal
location and scale likelihood directly, and that `rho12` is identified by
complete pairs. MD2 should retain rows where both responses are missing with
zero response-likelihood contribution rather than dropping or erroring, because
that keeps original-row accounting consistent. It should warn when the number
of complete response pairs is too small to identify `rho12` reliably.

MD3 and MD4 need simulation recovery tests because they add a new joint
likelihood. MD3a has a focused deterministic test that fits one fixed-effect
Gaussian predictor model, checks row retention and metadata, combines the route
with response masks, and rejects malformed `mi()`/`impute` syntax. MD3b adds the
same checks for one grouped random-intercept covariate model. MD4 adds the same
focused checks for one `relmat()` structured covariate intercept, including
response-mask composition and malformed structured syntax. A broader
simulation-recovery battery should be added before claiming recovery accuracy:
it should recover the response slope and missing-predictor conditional modes
under small fixed-effect, grouped, and structured Gaussian predictor models.

MD6a has a deterministic likelihood test that independently recomputes the
finite two-state contribution for missing binary predictors, including rows
where the response is also missing. It also has boundary tests showing that
unsupported grouped/structured binary, beta/proportion, and multiple-predictor
routes still fail clearly. MD6b has the same independent
likelihood check for ordered cumulative-logit predictors, including rows where
the response is also missing, plus boundary tests for unordered factor inputs
and grouped/structured ordered predictor models. MD6c has the same independent
likelihood check for unordered categorical softmax predictors, plus boundary
tests for ordered factor inputs, two-level factors, and grouped/structured
unordered predictor models.

MD7a has the same independent likelihood check for strict beta/proportion
predictors, using deterministic quadrature over missing proportion values. MD7b
has the same independent likelihood check for Poisson count predictors, using
deterministic finite summation over count states. MD7c repeats that count-state
check under the NB2 predictor likelihood and estimated overdispersion scale.
MD7d repeats the quadrature check for zero-one beta boundary proportions, using
exact zero and one mass plus deterministic interior beta quadrature. MD7e
repeats the count-state check under the zero-truncated NB2 predictor likelihood
and positive count support. MD7f repeats the finite-state check for
denominator-aware beta-binomial proportions by summing success counts from zero
to the known trial count. All six slices include rows where the response is
also missing and boundary tests for malformed predictor values and grouped
predictor models.

MD8a has the same independent likelihood check for positive continuous
lognormal predictors, using deterministic quadrature over log-scale predictor
states. It includes rows where the response is also missing and boundary tests
for zero, negative, non-numeric, and grouped predictor models.

MD8b has the same independent likelihood check for positive continuous Gamma
predictors, using deterministic Gauss-Laguerre quadrature under the fitted
Gamma mean-CV predictor model. It includes rows where the response is also
missing and boundary tests for zero, non-numeric, non-log-link, and grouped
predictor models.

MD8c has the same independent likelihood check for non-negative
semi-continuous Tweedie predictors, using an exact zero mass plus deterministic
positive-support quadrature under a fixed-power Tweedie predictor model. It
includes rows where the response is also missing and boundary tests for
negative, non-numeric, and grouped predictor models.

MD9a needs an independent likelihood check for a complete Poisson response with
one binary missing predictor. The test should recompute the fitted log
likelihood from the observed Bernoulli predictor density, the Poisson response
density for observed binary predictors, and the two-state Bernoulli plus Poisson
log-sum for missing binary predictors. Boundary tests should keep non-binary
Poisson-response `mi()` predictor families, zero-inflated Poisson formulas,
random or structured Poisson response formulas, and ordinary missing predictors
outside explicit `mi()` terms rejected.

## Historical Staged User-Facing Claims

The following text blocks are staged checkpoints, not the current public claim.
They are kept so later agents can see how the support boundary moved from MD1
through the later predictor-family slices.

After MD1, the public claim can be:

```text
drmTMB can retain missing response rows for univariate Gaussian models with
complete predictors through miss_control(response = "include"). Missing
predictors, bivariate partial response pairs, EM engines, REML support for
missing-data routes, imputation summaries, and measurement-error models remain
future work.
```

After MD1 and MD2, the claim can become:

```text
drmTMB can retain selected missing response rows in the fitted object and, for
bivariate Gaussian models without dense known covariance, can use partially
observed response pairs through the appropriate marginal Gaussian likelihood.
At that MD2 checkpoint, missing-predictor `mi()` support had not yet been
implemented.
```

After MD3a, MD3b, and MD4, the claim can become:

```text
drmTMB can retain selected missing response rows and can model one numeric
missing predictor in a univariate Gaussian location formula with
mi(x), impute = list(x = x ~ z) or impute = list(x = x ~ z + (1 | group)),
or an explicit intercept-only structured covariate model such as
impute = list(x = x ~ z + relmat(1 | line, Q = Q)), and
miss_control(predictor = "model"). The missing predictor is integrated by
TMB's Laplace approximation under a fixed-effect, one random-intercept, or one
structured-intercept Gaussian predictor model. Structured covariate slopes,
automatic response-structure inheritance, joint response-covariate structured
correlations, multiple missing predictors, non-Gaussian grouped or structured
predictor models, and simulation-based imputation summaries remain planned.
```

After MD5, the claim can become:

```text
For fitted MD3a/MD3b/MD4 Gaussian missing-predictor models, imputed(fit) reports
the conditional modes of missing predictor values and, when sdreport() is
available, likelihood-based conditional standard errors. This is not multiple
imputation and does not report posterior means, credible intervals, simulated
imputations, or pooled-imputation summaries.
```

After MD6a, MD6b, and MD6c, the claim can become:

```text
drmTMB can also model one binary, ordered categorical, or unordered
categorical missing predictor in a univariate Gaussian location model with
mi(x), a family-aware impute_model(), and miss_control(predictor = "model").
Missing finite-state predictors are integrated by exact summation, and
imputed(fit) reports the fitted conditional probability, expected
ordered-category score, or modal unordered category score. Beta/proportion,
count, positive-continuous non-Gaussian, multiple missing-predictor, grouped
finite-state, and structured finite-state predictor models remain planned.
```

At the MD7a checkpoint, before MD7b, the claim was:

```text
drmTMB can also model one strict proportion missing predictor in `(0, 1)` with
mi(x), impute_model(..., family = beta()), and
miss_control(predictor = "model"). Missing strict proportions are integrated by
deterministic quadrature under the fitted beta predictor model and Gaussian
response likelihood. Exact 0/1 proportions, denominator-aware binomial counts,
Poisson count predictors, positive-continuous non-Gaussian predictors, multiple
missing-predictor models, grouped finite-state, grouped beta, and structured
non-Gaussian predictor models remain planned.
```

After MD7b, the claim can become:

```text
drmTMB can also model one non-negative integer count missing predictor with
mi(x), impute_model(..., family = poisson()), and
miss_control(predictor = "model"). Missing Poisson counts are integrated by
deterministic finite summation under the fitted Poisson predictor model and
Gaussian response likelihood. Overdispersed counts need the later MD7c NB2
slice; positive-continuous non-Gaussian predictors, multiple missing-predictor
models, grouped count, and structured non-Gaussian predictor models remain
planned.
```

After MD8a, the claim can become:

```text
drmTMB can also model one positive continuous missing predictor with
mi(x), impute_model(..., family = lognormal()), and
miss_control(predictor = "model"). Missing positive continuous values are
integrated by deterministic quadrature over the fitted lognormal predictor
model and Gaussian response likelihood. Gamma, Tweedie, exact-zero
semi-continuous predictors, multiple missing-predictor models, grouped
positive-continuous, and structured non-Gaussian predictor models remain
planned.
```

After MD8b, the claim can become:

```text
drmTMB can also model one positive continuous missing predictor with
mi(x), impute_model(..., family = lognormal()) or
impute_model(..., family = Gamma(link = "log")), and
miss_control(predictor = "model"). Missing positive continuous values are
integrated by deterministic quadrature under the fitted positive predictor
model and Gaussian response likelihood. Tweedie, exact-zero semi-continuous
predictors, multiple missing-predictor models, grouped positive-continuous, and
structured non-Gaussian predictor models remain planned.
```

After MD8c, the positive/semi-continuous claim can become:

```text
drmTMB can also model one positive or non-negative semi-continuous missing
predictor with mi(x), impute_model(..., family = lognormal()),
impute_model(..., family = Gamma(link = "log")), or
impute_model(..., family = tweedie()), and
miss_control(predictor = "model"). Missing lognormal and Gamma values are
integrated by deterministic positive-continuous quadrature. Missing Tweedie
values are integrated over exact zero mass plus positive predictor states under
a fixed-power Tweedie predictor model. Estimated or predictor-dependent Tweedie
power, multiple missing-predictor models, grouped positive/semi-continuous, and
structured non-Gaussian predictor models remain planned.
```

After MD7c, the count claim can become:

```text
drmTMB can also model one non-negative integer count missing predictor with
mi(x), impute_model(..., family = poisson()) or
impute_model(..., family = nbinom2()), or one positive integer count missing
predictor with impute_model(..., family = truncated_nbinom2()), and
miss_control(predictor = "model"). Missing count values are integrated by
deterministic finite summation under the fitted count predictor model and
Gaussian response likelihood. Hurdle count predictors, multiple
missing-predictor models, grouped count, and structured non-Gaussian predictor
models remain planned.
```

After MD7f, the bounded-proportion claim can become:

```text
drmTMB can model one strict, boundary, or denominator-aware proportion missing
predictor with
mi(x), impute_model(..., family = beta()) for values in `(0, 1)`, or
impute_model(..., family = zero_one_beta()) for values in `[0, 1]` with exact
zeros or ones, or impute_model(success ~ z, family = beta_binomial(), trials =
trials) for success counts with known denominators, and
miss_control(predictor = "model"). Missing strict proportions are integrated by
deterministic beta quadrature. Missing zero-one beta proportions are integrated
over exact zero mass, exact one mass, and interior beta quadrature. Missing
beta-binomial proportions are integrated by summing possible success counts
from zero to the known trial count. Multiple missing-predictor models, grouped
bounded-proportion predictors, and structured non-Gaussian predictor models
remain planned.
```

## Consolidated Current Claim

After MD7f, MD8c, and MD9a, the consolidated current missing-predictor claim is:

```text
drmTMB can model one missing predictor in a univariate Gaussian location model
with mi(x), an explicit impute or impute_model() entry, and
miss_control(predictor = "model"). The supported predictor-model families are
Gaussian, Bernoulli/logit, ordered cumulative logit, unordered baseline
softmax, beta, zero-one beta, beta-binomial with known trial denominators,
Poisson, NB2, zero-truncated NB2, lognormal, Gamma, and fixed-power Tweedie.
Gaussian missing predictors are integrated by TMB's Laplace approximation.
Finite-state and count predictors are integrated by deterministic summation.
Positive and bounded continuous predictors are integrated by deterministic
quadrature, with exact boundary masses where the family requires them.
The non-Gaussian response routes support family = poisson(), binomial(),
nbinom2(), and beta() with one fixed-effect binary mi() predictor and a
Bernoulli/logit impute_model(); missing responses can also be masked for those
same four families with miss_control(response = "include"). Multiple missing
predictors, grouped or structured non-Gaussian predictor models, transformed or
interacted mi() terms, non-binary missing predictors in non-Gaussian response
models, hurdle count predictors, EM/profile engines, REML for explicit
missing-data routes, simulated imputation summaries, response imputation,
measurement-error models, and pigauto interoperability remain separate future
lanes.
```

For the 0.5.0 release, treat the missing-data surface as done only in this
bounded sense: the package has an explicit control API, response masks for
Gaussian, bivariate Gaussian, binomial, Poisson, NB2, and beta responses,
one-at-a-time modelled missing predictors for the implemented predictor-family
set, `imputed()` summaries, tests of the likelihood contributions, reference
documentation, and a worked article. It is not done as a general missing-data
framework. The next missing-data work should be a separate feature slice, not
cleanup for this release boundary.

The non-Gaussian missing-predictor coverage is broad when the response is a
univariate Gaussian location model. On the non-Gaussian response side it is
deliberately narrow: Poisson, binomial, NB2, and beta responses each take one
fixed-effect binary `mi()` predictor with complete responses (MD9a–MD9d), and
those four families plus Gaussian, bivariate Gaussian, Student-t, skew-normal,
lognormal, Gamma, Tweedie, zero-one beta, beta-binomial, cumulative logit, and
non-hurdle truncated NB2 support response masking (MD10 and MR-T2–MR-T5).
Non-binary missing predictors in non-Gaussian response models,
zero-inflated/hurdle responses with `mi()`, random or structured response terms
with `mi()`, and missing responses for the three mixture routes remain planned.
Student-t, lognormal, Gamma, beta-binomial, and truncated NB2 response-mask
evidence includes an ordinary random intercept; skew-normal remains
fixed-effect only, and no
structured-route evidence is inherited from these route-level ticks. Tweedie
and zero-one beta response masking is likewise fixed-effect only.

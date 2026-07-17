# Likelihoods

Likelihoods are implemented in TMB templates and called from R wrappers.

## Parameter Scales

- Positive parameters use log links.
- Unit-interval parameters use logit links.
- Residual correlations use a Fisher-z-like linear predictor and a guarded
  `0.999999 * tanh()` response transform.
- Shape parameters use family-specific stable links.

## Variability Orientation

The public scale slot is `sigma` when the parameter controls modelled
variability. The user-facing orientation is:

```text
larger sigma -> larger variability, dispersion, or heterogeneity
```

This is a user-interface contract, not a claim that every likelihood is written
with a standard deviation parameter internally. Some likelihoods are naturally
expressed with precision or size parameters. In those cases, the TMB objective
may use a transformed internal quantity, but extractors and tutorials should
report the public `sigma` direction unless a comparator check explicitly needs
the original parameterization.

Current examples:

| Family | Public scale | Internal or comparator scale | Direction |
| --- | --- | --- | --- |
| `gaussian()` | `sigma` | residual SD | larger `sigma` means larger residual variance |
| `Gamma(link = "log")` | `sigma` | shape `1 / sigma^2` | larger `sigma` means larger coefficient of variation |
| `beta()` | `sigma` | beta precision `phi = 1 / sigma^2` | larger `sigma` means lower precision and larger variance |
| `beta_binomial()` | `sigma` | beta precision `phi = 1 / sigma^2` | larger `sigma` means more extra-binomial variation |
| `nbinom2()` | `sigma` | NB2 size `theta = 1 / sigma^2` | larger `sigma` means more extra-Poisson variation |
| `student()` | `sigma`, `nu` | scale plus degrees of freedom | larger `sigma` means wider core scale; larger `nu` means lighter tails |
| `skew_normal()` | `sigma`, `nu` | public response SD plus residual slant | larger `sigma` means larger residual SD; positive `nu` means right-skewed residuals |

Names that are not scale slots should stay specific. For example, ordinal
`theta` values are cutpoints, not a precision or variability parameter, and
Student-t `nu` is a shape parameter rather than an alias for `sigma`.
In bivariate Gaussian models, `rho12` is the residual coscale parameter:
coscale means modelling residual correlation after the location and scale
predictors have been accounted for. This term should not be collapsed with
ordinary group-level, phylogenetic, or spatial correlations.

The guard on residual correlations is purely numerical. In teaching material,
describe the model as the standard transform `rho = tanh(eta)`, then note that
the implementation multiplies by `0.999999` so covariance matrices stay
strictly positive definite in floating-point arithmetic near `rho = -1` or
`rho = 1`.

## Notation

In mathematical prose, `Normal(a, b)` uses variance as the second argument.
The corresponding R density call uses standard deviation, as in
`dnorm(y, mean = a, sd = sqrt(b), log = TRUE)`.

## Implemented TMB Routing

The R builders use descriptive model labels, such as `"gaussian"`,
`"student"`, `"skew_normal"`, `"lognormal"`, `"gamma"`, `"tweedie"`, `"beta"`, `"zero_one_beta"`, `"beta_binomial"`,
`"poisson"`, `"zi_poisson"`, `"cumulative_logit"`, `"nbinom2"`, `"truncated_nbinom2"`,
`"hurdle_nbinom2"`, `"zi_nbinom2"`, and `"biv_gaussian"`. Before calling
the TMB template, `make_tmb_data()` turns
those labels into integer branches in `src/drmTMB.cpp`. Unknown labels are
rejected before they can fall through to a wrong likelihood branch. This table
is the current routing contract:

| TMB `model_type` | User-facing route | R builder | TMB branch purpose |
|---:|---|---|---|
| `1` | `family = gaussian()` | `drm_build_gaussian_ls_spec()` | Univariate Gaussian location-scale models, including ordinary `mu` random effects, residual-scale `sigma` random effects, `sd(group) ~ ...` random-effect scale models, `meta_V(V = V)` with deprecated `meta_known_V(V = V)` as a compatibility alias, fitted intercept-only `phylo()`, `spatial()`, `animal()`, and `relmat()` effects in `mu` and/or `sigma`, one-slope structured `mu` effects, one q=1 `phylo_interaction()` pair field in `mu`, the first opt-in fixed-effect Gaussian aggregation path, the MD1 observed-response mask for missing Gaussian responses with complete predictors, MD3a/MD3b/MD4 `mi()` missing-predictor routes with fixed-effect, grouped, or explicit intercept-only structured Gaussian covariate models, the MD6a fixed-effect Bernoulli/logit route for one binary missing predictor, the MD6b fixed-effect cumulative-logit route for one ordered categorical missing predictor, the MD6c fixed-effect baseline-category softmax route for one unordered categorical missing predictor, the MD7a fixed-effect beta/quadrature route for one strict proportion missing predictor, the MD7b fixed-effect Poisson finite-sum route for one count missing predictor, the MD7c fixed-effect NB2 finite-sum route for one overdispersed count missing predictor, the MD7d fixed-effect zero-one beta route for one boundary-proportion missing predictor, the MD7e fixed-effect zero-truncated NB2 route for one positive-count missing predictor, the MD7f fixed-effect beta-binomial finite-sum route for one denominator-aware proportion missing predictor, the MD8a fixed-effect lognormal quadrature route for one positive continuous missing predictor, the MD8b fixed-effect Gamma quadrature route for one positive continuous missing predictor, and the MD8c fixed-effect Tweedie route for one non-negative semi-continuous missing predictor with exact zeros in a Gaussian location model. |
| `2` | `family = biv_gaussian()`, `family = c(gaussian(), gaussian())`, or `family = list(gaussian(), gaussian())` | `drm_build_biv_gaussian_spec()` | Bivariate Gaussian location-scale-coscale models with `mu1`, `mu2`, `sigma1`, `sigma2`, and residual `rho12`, including complete-row dense known sampling covariance, independent-observation partial-response masks without dense known `V`, matching labelled `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept covariance blocks, matching slope-only ordinary `mu1`/`mu2` covariance blocks, matching slope-only `sigma1`/`sigma2` scale covariance blocks, matching q=4 and q=6 `mu1`/`mu2` location covariance blocks with smoke artifact routing, one same-response `mu`/`sigma` random-intercept or matching slope-only covariance pair, intercept-only ordinary q=4 covariance blocks across all four bivariate distributional parameters, ordinary q=8 location-scale endpoint covariance blocks with diagnostic smoke, recovery, and staged-start artifact routing, bivariate location random-effect SD formulas `sd1(group)` / `sd2(group)`, matching intercept-only phylogenetic random intercepts in `mu1` and `mu2`, and constant all-four phylogenetic location-scale blocks in either full q=4 or block-diagonal two-q2 form. The q=8 route is fitted and diagnostic-artifact-ready only; q8 recovery accuracy, intervals, coverage, power, speed, bridge parity, and release claims remain separate evidence gates. |
| `3` | `family = student()` | `drm_build_student_ls_spec()` | Univariate Student-t location-scale-shape models with `mu`, `sigma`, `nu = 2 + exp(eta_nu)`, ordinary `mu` random intercepts or independent numeric slopes, one recovery-grade `mu ~ spatial(1 + x | ...)` route, and exact diagnostic-grade intercept-only `mu ~ spatial(1 | ...)` and `nu ~ phylo(1 | id, tree = tree)` gates. |
| `17` | `family = skew_normal()` | `drm_build_skew_normal_ls_spec()` | Univariate skew-normal location-scale-shape models with public `mu = E[y]`, public `sigma = SD[y]`, fixed-effect residual slant `nu`, and ordinary recovery-grade `mu` random intercepts or independent numeric slopes; `sigma`/`nu` random effects, correlated/labelled `mu` slopes, known covariance, structured terms, bivariate responses, `rho12`, and latent `skew(id)` syntax are rejected. |
| `4` | `family = lognormal()` | `drm_build_lognormal_ls_spec()` | Univariate lognormal location-scale models for positive responses, with `mu` and `sigma` defined on the log-response scale, ordinary `mu` random intercepts or independent numeric slopes, and one Arc 3a q1 `phylo()` or `relmat()` intercept using `K` or `Q` in `mu`. |
| `5` | `family = Gamma(link = "log")` | `drm_build_gamma_ls_spec()` | Univariate Gamma mean-CV models for positive responses, with `mu` as the response mean, `sigma` as the coefficient of variation, ordinary `mu` random intercepts or independent numeric slopes, the existing `relmat()` intercept/one-slope route, and one Arc 3a q1 `phylo()` intercept in `mu`. |
| `16` | `family = tweedie()` | `drm_build_tweedie_ls_spec()` | Univariate Tweedie mean-scale-power models for non-negative semicontinuous responses, with exact zeros allowed, `mu` as the response mean, public `sigma = sqrt(phi)`, intercept-only `nu = 1 + plogis(eta_nu)`, and ordinary recovery-grade `mu` random intercepts or independent numeric slopes. |
| `6` | `family = poisson(link = "log")` | `drm_build_poisson_spec()` | Univariate Poisson mean models for non-negative integer counts, with `mu` as the count mean, including ordinary `mu` random intercepts, independent numeric slopes, one q=1 structured `mu` intercept from `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, or `relmat()`, one unlabelled intercept-plus-one-slope term from `phylo()`, `spatial()`, `animal()`, or `relmat()`, and the MD9a first non-Gaussian response missing-predictor route for one fixed-effect binary `mi()` predictor. |
| `7` | `family = nbinom2()` | `drm_build_nbinom2_spec()` | Univariate negative-binomial 2 models for overdispersed counts, with `mu` as the count mean, `sigma` as an overdispersion scale, optional ordinary `mu` random intercepts or independent numeric slopes, the first ordinary `sigma` random intercept, one q=1 structured `mu` intercept from `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, or `relmat()`, and one unlabelled intercept-plus-one-slope term from `phylo()`, `spatial()`, `animal()`, or `relmat()` on the log-mean predictor. |
| `8` | `family = poisson(link = "log")` plus `zi ~ ...` | `drm_build_poisson_spec()` | Univariate fixed-effect zero-inflated Poisson models, with `mu` as the conditional count mean and `zi` as the structural-zero probability. |
| `9` | `family = nbinom2()` plus `zi ~ ...` | `drm_build_nbinom2_spec()` | Univariate fixed-effect zero-inflated negative-binomial 2 models, with `mu` as the conditional count mean, `sigma` as the NB2 overdispersion scale, and `zi` as the structural-zero probability. |
| `10` | `family = beta()` | `drm_build_beta_ls_spec()` | Univariate beta mean-scale models for strict continuous proportions, with `mu` as the mean proportion, public `sigma` mapped internally to `phi = 1 / sigma^2`, and ordinary `mu` random intercepts or independent numeric slopes on the logit-mean predictor. The narrow q1 phylogenetic successor route additionally fits `a ~ Normal(0, D_tau A D_tau)` in `mu`, with `log(tau_s) = W_s alpha`; `tau` is the latent location-field SD and is not family `sigma`, precision `phi`, or a conditional response SD. |
| `15` | `family = zero_one_beta()` | `drm_build_zero_one_beta_spec()` | Univariate zero-one beta models for continuous proportions on `[0, 1]`, with `mu` and `sigma` describing the interior beta component, `zoi` as exact-boundary probability, `coi` as the conditional probability of an exact one among boundary observations, and ordinary recovery-grade `mu` random intercepts or independent numeric slopes. |
| `11` | `family = truncated_nbinom2()` | `drm_build_truncated_nbinom2_spec()` | Univariate zero-truncated negative-binomial 2 models for positive counts, with `mu` and `sigma` describing the untruncated NB2 component and ordinary `mu` random intercepts or independent numeric slopes. |
| `12` | `family = truncated_nbinom2()` plus `hu ~ ...` | `drm_build_truncated_nbinom2_spec()` | Univariate hurdle negative-binomial 2 models, with fixed-effect `mu`, `sigma`, and `hu`, plus the exact diagnostic-only q1 `hu ~ relmat(1 | id, K/Q = ...)` intercept; nonzero counts follow the zero-truncated NB2 component. Other hurdle-side and count-side random effects remain blocked. |
| `13` | `family = cumulative_logit()` | `drm_build_cumulative_logit_spec()` | Univariate cumulative-logit ordinal location models, with ordered cutpoints, fixed latent logistic scale, ordinary recovery-grade `mu` random intercepts and independent numeric slopes, plus the exact local-fit q1 `mu ~ phylo(1 | id, tree = tree)` intercept. |
| `14` | `family = beta_binomial()` | `drm_build_beta_binomial_spec()` | Univariate beta-binomial models for counted successes out of known trials, with `mu` as success probability, `sigma` as extra-binomial variation, and ordinary `mu` random intercepts or independent numeric slopes on the logit success-probability predictor. |
| `18` | `family = stats::binomial(link = "logit")` | `drm_build_binomial_spec()` | Univariate Bernoulli/binomial logit models for 0/1 responses or two-column `cbind(successes, failures)` responses, with `mu` as event probability and no public `sigma`, including an ordinary `mu` random intercept `(1 | group)` (Arc 2a; not combinable with missing-predictor `mi()` yet). |
| `93` | no public route | direct test construction only | Hidden q=4 phylogenetic precision-prior parity branch using `theta_phylo` and `log_sd_phylo`. |
| `94` | no public route | direct test construction only | Hidden q=4 correlated phylogenetic precision-prior parity branch used to test the matrix-normal sparse augmented A-inverse objective in isolation. |
| `95` | no public route | direct test construction only | Hidden q=4 bivariate Gaussian likelihood probe for labelled covariance-block contributions. |
| `96` | no public route | direct test construction only | Hidden univariate Gaussian likelihood probe for labelled covariance-block contributions. |
| `97` | no public route | direct test construction only | Hidden contribution-map probe for labelled covariance-block blocks and members. |
| `98` | no public route | direct test construction only | Hidden non-centred unstructured-correlation transform probe. |
| `99` | no public route | direct test construction only | Hidden phylogenetic precision-prior parity branch used to test the sparse augmented A-inverse objective in isolation. |

The hidden `model_type = 93` through `model_type = 99` branches are not families
and should not appear in user examples. Public phylogenetic Gaussian fits stay
on `model_type = 1` or `model_type = 2`; the hidden branches exist only so
tests can compare isolated sparse phylogenetic prior objectives, labelled
covariance-block contribution maps, and non-centred covariance transforms
against the R algebra helpers. The C++ modularization source map in
`docs/design/36-cpp-modularization-source-map.md` records how to keep those
hidden probes separate during future file-splitting work.

For the Q-Series animal all-four one-slope row, the public bivariate Gaussian
route is q8-shaped: `mu1`, `mu2`, `sigma1`, and `sigma2` each contribute an
intercept and slope, so the full q>2 correlation block has 28 `theta_phylo`
coordinates. The current production likelihood uses
`density::UNSTRUCTURED_CORR_t(theta_phylo)`. A bounded, ridge-penalized, or
pairwise `tanh()` diagnostic is not a production transform unless it is shown
to be an equivalent reparameterization of the same positive-definite
correlation manifold. Design note
`docs/design/220-structured-q4-animal-production-transform-gate.md` is the
gate before any new q4 animal admission runner, Nibi/Rorqual admission job, or
DRAC coverage grid.

The non-public data flag `qgt2_corr_parameterization` is currently fixed to
`0` by the R-side production data builder. Hidden `model_type = 93` tests may
set it to `1` to exercise a lower-level partial-correlation Cholesky
parameterization. That switch is an internal equivalence harness only: it is
not reachable from user syntax, not a default change, and not a q4/q8
inference, coverage, or support claim.

## Implemented Bernoulli/Binomial Response Branch

`drmTMB#569` adds the first primary Bernoulli/binomial response route. The
public syntax is:

```r
drmTMB(bf(y01 ~ x), family = stats::binomial(), data = dat)
drmTMB(bf(cbind(successes, failures) ~ x), family = stats::binomial(), data = dat)
```

The first TMB branch is a fixed-effect `mu` model only:

```text
Y_i ~ Binomial(n_i, mu_i)
eta_i = X_mu[i, ] beta_mu
mu_i = logistic(eta_i)
```

For 0/1 responses, `n_i = 1`. For two-column responses, `n_i` is
`successes_i + failures_i`. The negative log likelihood includes the
binomial normalizing constant:

```text
nll_i = -log choose(n_i, Y_i)
        - Y_i log(mu_i)
        - (n_i - Y_i) log(1 - mu_i)
```

using stable log-probability calculations near 0 and 1. Including the constant
keeps `logLik()`, AIC, and BIC aligned with `stats::glm()` for overlapping
fixed-effect logit fits.

The first slice deliberately has no public `sigma`, no `rho12`, no random
effects, no structured effects, no bivariate route, no mixed-response route,
no non-logit link, and no `engine = "julia"` claim. Proportions plus
`weights`, `weights = trials`, and `successes / trials` are rejected because
top-level `weights` remain likelihood weights, not denominators. Extra-binomial
variation remains the job of `beta_binomial()`, while continuous proportions
belong to `beta()` or `zero_one_beta()`.

## Gaussian Aggregation Branch

When `drm_control(aggregate_gaussian = TRUE)` is used for the first supported
univariate Gaussian fixed-effect path, `model_type = 1` follows a
sufficient-statistic sub-branch. The R builder groups rows after model-row
filtering by the processed `mu` design row, processed `sigma` design row, and
offset state. TMB receives one row per aggregation cell:

```text
n_g, mean_y_g, css_g, X_mu_g, X_sigma_g
```

where `mean_y_g` is the cell mean of `y` and `css_g` is the corrected
(centered) sum of squares `sum_i (y_i - mean_y_g)^2`, accumulated directly
from the raw residuals at aggregation time. For cell `g`,

```text
mu_g = X_mu_g beta_mu
log(sigma_g) = X_sigma_g beta_sigma
```

and the negative log-likelihood contribution is:

```text
0.5 n_g log(2 pi)
  + n_g log(sigma_g)
  + 0.5 (css_g + n_g (mean_y_g - mu_g)^2) / sigma_g^2
```

This is algebraically identical to summing independent Gaussian row
log-likelihoods within the cell. The centered quadratic replaces the expanded
second-moment form `sum_y2_g - 2 mu_g sum_y_g + n_g mu_g^2`, which suffered
catastrophic cancellation when the response mean was far from zero (issue
#701). See `31-gaussian-aggregation-sufficient-statistics.md` for the numerical
argument. The first implementation rejects non-unit
likelihood weights, random effects, direct-SD formulas, structured effects,
known sampling covariance, bivariate models, non-Gaussian families, and
combined sparse fixed-effect matrices before TMB is called.

## Univariate Gaussian Response Masks

When `missing = miss_control(response = "include")` is used for a univariate
Gaussian model, the R builder keeps rows with missing response values only after
it has verified that all predictors, grouping variables, structured-effect
inputs, likelihood weights, and known sampling variances needed for retained
rows are complete. It then stores:

```text
observed_y_i = 1 if y_i is observed
observed_y_i = 0 if y_i is missing
```

Missing responses are replaced by an internal finite sentinel after
`observed_y` has been recorded. The sentinel is an implementation detail and is
not part of the statistical model.

For independent-row Gaussian likelihoods, the MD1 TMB branch evaluates:

```text
nll = sum_i observed_y_i w_i {-log Normal(y_i | mu_i, V_i + sigma_i^2)}
```

Rows with `observed_y_i = 0` contribute zero response likelihood. The fitted
coefficients and observed-row log likelihood therefore match an explicit
complete-case Gaussian fit when there are no row-level latent effects informed
only through the missing-response rows. The retained rows still have model
matrices and fitted values, so `fit$missing_data` can map predictions and
residuals back to the source data. `nobs()` remains the likelihood-contributing
count, `sum(observed_y)`.

Dense known sampling-covariance matrices are not supported by MD1 response
masks. A dense `meta_V(V = V)` likelihood is one joint multivariate block, so
partial response rows need component-level covariance slicing rather than the
independent-row mask above.

## Univariate Gaussian Missing Predictors

When `missing = miss_control(predictor = "model")` is used with one additive
`mi(x)` term in a univariate Gaussian location formula, the R builder keeps rows
where `x` is missing and requires all ordinary response predictors, grouping
variables, structured-effect inputs, likelihood weights, and `impute`-model
predictors to be complete. The MD3a route is fixed-effect and Gaussian:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z),
  missing = miss_control(predictor = "model")
)
```

The MD3b route adds one independent random-intercept block to the same
covariate model:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z + (1 | group)),
  missing = miss_control(predictor = "model")
)
```

The MD4 route instead adds one explicit intercept-only structured covariate
field. The structured term is supplied in the `impute` formula, not inherited
from the response model:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z + relmat(1 | line, Q = Q)),
  missing = miss_control(predictor = "model")
)
```

The response model uses the usual Gaussian conditional density:

```text
y_i | x_i, z_i ~ Normal(mu_i, V_i + sigma_i^2)
mu_i = eta_without_x_i + beta_x x_i
```

The fixed-effect predictor model is a second Gaussian likelihood:

```text
x_i ~ Normal(W_i alpha, sigma_x^2)
```

With the MD3b grouped route, this becomes:

```text
u_g ~ Normal(0, 1)
x_i ~ Normal(W_i alpha + sd_x_group u_group[i], sigma_x^2)
```

With the MD4 structured route, this becomes:

```text
u_x ~ Normal(0, sd_x_struct^2 Q_x^-1)
x_i ~ Normal(W_i alpha + a_i u_x[node_i], sigma_x^2)
```

Here `Q_x` is the precision matrix built by the explicit `phylo()`,
`spatial()`, `animal()`, or `relmat()` covariate term, and `a_i` is the
structured design value. The first fitted MD4 slice is intercept-only, so
`a_i = 1` in the supported public syntax.

For observed `x_i`, TMB uses the observed value in both the predictor likelihood
and the response mean. For missing `x_i`, TMB treats `x_i` as a random effect
and integrates it by the Laplace approximation. With MD3b, the group-level
covariate intercepts are also TMB random effects; with MD4, the structured
covariate field is also a TMB random effect. With absent random-effect factors
omitted, the fitted objective is the joint observed-data likelihood:

```text
L(theta) = integral p(y_obs | x_obs, x_mis, theta_y)
                    p(x_obs, x_mis | theta_x)
                    p(u_group)
                    p(u_x)
                    d x_mis d u_group d u_x
```

The implementation stores `has_mi`, the `mi(x)` column index in the response
design, the reconstructed `x` vector, the observed/missing predictor mask, and
the fixed-effect `X_mi` matrix for the predictor model. The model matrix for
`mi(x)` contains a finite placeholder only so base R can build `X_mu`; the TMB
objective replaces that column by the observed or latent `x_i` before evaluating
the likelihood. `fit$missing_data$predictors` records original-row and model-row
indices for missing `x`; for MD3b it also records the grouping variable and
number of group levels, and for MD4 it records the structured marker, grouping
variable, levels, and latent-field size. `imputed()` extracts these fitted
missing-predictor conditional modes from the
optimized TMB random effects. When `sdreport()` is available, it also reports
the corresponding likelihood-based conditional standard errors from the random
effect covariance approximation. These are not posterior means, credible
intervals, simulated imputations, or multiple-imputation pooling summaries.

## Binary Missing Predictors In Gaussian Location Models

MD6a adds the first non-Gaussian missing-predictor route. The response model is
still a univariate Gaussian location model with one additive `mi(x)` term, but
the missing predictor is binary. The predictor model is fixed-effect
Bernoulli/logit:

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

Let

```text
pi_i = logit^-1(W_i alpha)
mu_i(x) = eta_without_x_i + beta_x x
```

For observed binary predictors, the row contributes the Bernoulli predictor
likelihood and, when the response is observed, the Gaussian response density:

```text
log L_i = log p(x_i | pi_i) + observed_y_i log p(y_i | mu_i(x_i), sigma_i)
```

For missing binary predictors, TMB does not create a continuous latent random
effect. It sums exactly over the two possible states:

```text
log L_i =
  logspace_add(
    log(1 - pi_i) + observed_y_i log p(y_i | mu_i(0), sigma_i),
    log(pi_i)     + observed_y_i log p(y_i | mu_i(1), sigma_i)
  )
```

When both the response and the binary predictor are missing, the response term
is zero and the Bernoulli states sum to one. The row is retained for accounting
but contributes no direct likelihood. `imputed()` reports the fitted
conditional probability `Pr(x_i = 1 | observed data)` for missing binary
predictors. For rows with an observed response, that probability combines the
Bernoulli predictor model and the Gaussian response likelihood; for rows with a
missing response, it is the prior probability from the predictor model. The
first binary route does not report conditional standard errors.

MD6a accepts observed binary predictors represented as logical values, two-level
factors, two-level character values, or numeric/integer 0/1 values. It rejects
grouped or structured binary predictor models, count predictors, multiple
missing predictors, and dense known sampling covariance. Count predictors use
the separate MD7b, MD7c, and MD7e routes.

## Binary Missing Predictors In Poisson Mean Models

MD9a opens the first non-Gaussian response missing-predictor route. The response
model is an ordinary fixed-effect Poisson mean model with one additive binary
`mi(x)` term:

```r
drmTMB(
  bf(count ~ z + mi(treatment)),
  family = poisson(),
  data = dat,
  impute = list(
    treatment = impute_model(treatment ~ z, family = binomial())
  ),
  missing = miss_control(predictor = "model")
)
```

Let

```text
pi_i = logit^-1(W_i alpha)
eta_yi(x) = o_i + eta_without_x_i + beta_x x
mu_yi(x) = exp(eta_yi(x))
```

For observed binary predictors, the row contributes the Bernoulli
predictor-model likelihood and the Poisson response likelihood:

```text
log L_i = log p(x_i | pi_i) + log Poisson(y_i | mu_yi(x_i))
```

For missing binary predictors, TMB sums exactly over the two possible states:

```text
log L_i =
  logspace_add(
    log(1 - pi_i) + log Poisson(y_i | mu_yi(0)),
    log(pi_i)     + log Poisson(y_i | mu_yi(1))
  )
```

This is the same finite-state observed-data idea as MD6a, but the response term
is the Poisson count density. The Poisson response must be observed in MD9a:
`miss_control(response = "include")` is still limited to Gaussian response
models. The route rejects zero-inflated Poisson formulas, Poisson response
random effects, structured Poisson response terms, non-binary missing predictor
families, and ordinary missing predictors outside the explicit `mi()` term.

## Ordered Missing Predictors In Gaussian Location Models

MD6b extends the finite-state missing-predictor route to one ordered
categorical predictor in a univariate Gaussian location model. The predictor
model is fixed-effect cumulative logit:

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

Let

```text
Pr(x_i <= k) = logit^-1(c_k - W_i alpha)
mu_i(k) = eta_without_x_i + X_mu_state[i, k, ] beta_mu
```

where `c_1 < ... < c_{K-1}` are ordered predictor-model cutpoints. The
state-specific response design `X_mu_state` is needed because an ordered factor
can change several response-model contrast columns, not just one numeric
slope.

For observed ordered predictors, the row contributes the ordinal
predictor-model likelihood and, when the response is observed, the Gaussian
response density:

```text
log L_i = log p_ord(x_i | W_i alpha, c)
          + observed_y_i log p(y_i | mu_i(x_i), sigma_i)
```

For missing ordered predictors, TMB sums exactly over the ordered categories:

```text
log L_i =
  logsumexp_k(
    log p_ord(k | W_i alpha, c)
    + observed_y_i log p(y_i | mu_i(k), sigma_i)
  )
```

When both the response and the ordered predictor are missing, the response term
is zero and the ordinal probabilities sum to one. The row is retained for
accounting but contributes no direct likelihood. `imputed()` reports the
conditional expected ordered-category score, and
`fit$missing_data$predictors[[name]]$conditional_probabilities` stores the
conditional level probabilities for missing rows.

MD6b accepts ordered factors and numeric/integer category scores with at least
three categories represented in the observed predictor values. The ordered
slice itself rejects unordered factors, grouped or structured ordered
predictor models, multiple missing predictors, and dense known sampling
covariance. Count predictors use the separate MD7b, MD7c, and MD7e count
routes rather than the ordered finite-state route.

## Unordered Missing Predictors In Gaussian Location Models

MD6c adds one unordered categorical predictor in a univariate Gaussian location
model. The predictor model is fixed-effect baseline-category softmax:

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

Let the first level be the baseline category. For `k > 1`:

```text
eta_ik = W_i alpha_k
Pr(x_i = 1) = 1 / (1 + sum_{k=2}^K exp(eta_ik))
Pr(x_i = k) = exp(eta_ik) / (1 + sum_{h=2}^K exp(eta_ih))
```

The row likelihood has the same finite-state shape as MD6b, but with unordered
softmax probabilities instead of cumulative-logit probabilities:

```text
observed x_i:
  log L_i = log p_cat(x_i | W_i alpha)
            + observed_y_i log p(y_i | mu_i(x_i), sigma_i)

missing x_i:
  log L_i = logsumexp_k(
    log p_cat(k | W_i alpha)
    + observed_y_i log p(y_i | mu_i(k), sigma_i)
  )
```

The state-specific response design `X_mi_state_mu` is required because changing
an unordered factor level can change several response-model contrast columns.
`imputed()` reports the conditional modal category score for missing rows, and
`fit$missing_data$predictors[[name]]$conditional_probabilities` stores the
conditional level probabilities.

MD6c accepts unordered factors, character predictors, and numeric/integer
category scores when at least three categories are represented among observed
predictor values. The unordered slice itself rejects ordered factors, grouped
or structured categorical predictor models, multiple missing predictors, and
dense known sampling covariance. Count predictors use the separate MD7b, MD7c,
and MD7e count routes rather than the unordered finite-state route.

## Strict Proportion Missing Predictors In Gaussian Location Models

MD7a adds one strict proportion predictor in a univariate Gaussian location
model. The predictor model is fixed-effect beta:

```r
drmTMB(
  bf(y ~ z + mi(cover), sigma ~ 1),
  data = dat,
  impute = list(
    cover = impute_model(cover ~ z, family = beta())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model uses the same mean-scale parameterization as beta response
models:

```text
logit(m_i) = W_i alpha
phi = 1 / sigma_mi^2
x_i ~ Beta(m_i phi, (1 - m_i) phi)
```

For observed `cover_i`, the row contributes the beta predictor-model
likelihood and, when the response is observed, the Gaussian response density.
For missing `cover_i`, TMB integrates over the possible proportion values with
fixed Gauss-Legendre quadrature:

```text
log L_i = log sum_q w_q
  p_beta(x_q | m_i, sigma_mi)
  p(y_i | mu_i(x_q), sigma_i) ^ observed_y_i
```

When both the response and the strict proportion predictor are missing, the
row is retained for accounting but contributes no direct likelihood.
`imputed()` reports the conditional quadrature mean for missing rows, and
`fit$missing_data$predictors[[name]]$quadrature_probabilities` stores the
normalized quadrature weights.

MD7a accepts numeric predictors strictly inside `(0, 1)`. It rejects exact 0
or 1 values, grouped or structured beta predictor models, multiple missing
predictors, and dense known sampling covariance.

## Boundary Proportion Missing Predictors In Gaussian Location Models

MD7d adds one boundary-proportion predictor in a univariate Gaussian location
model. The predictor model is fixed-effect zero-one beta:

```r
drmTMB(
  bf(y ~ z + mi(cover), sigma ~ 1),
  data = dat,
  impute = list(
    cover = impute_model(cover ~ z, family = zero_one_beta())
  ),
  missing = miss_control(predictor = "model")
)
```

The first fitted zero-one beta predictor slice uses the `impute` formula for
the interior mean and estimates constant predictor-model `sigma`, `zoi`, and
`coi`:

```text
logit(m_i) = W_i alpha
phi = 1 / sigma_mi^2
zoi = Pr(x_i is exactly 0 or 1)
coi = Pr(x_i is exactly 1 | x_i is exactly 0 or 1)
```

For an observed predictor value, the row contribution is:

```text
x_i = 0:
  log zoi + log(1 - coi)

x_i = 1:
  log zoi + log coi

0 < x_i < 1:
  log(1 - zoi) + log BetaDensity(x_i | m_i phi, (1 - m_i) phi)
```

When the predictor is missing and the response is observed, TMB sums exact
zero and exact one mass together with deterministic interior beta quadrature:

```text
log L_i = log sum_q w_q
  p_zero_one_beta(x_q | m_i, sigma_mi, zoi, coi)
  p(y_i | mu_i(x_q), sigma_i)
```

The zero and one nodes have quadrature weight one because they represent point
mass. Interior nodes use the same fixed Gauss-Legendre rule as the strict beta
route. When both the response and the boundary-proportion predictor are
missing, the row is retained for accounting but contributes no direct
likelihood. `imputed()` reports the fitted conditional quadrature mean for
missing rows, and `fit$missing_data$predictors[[name]]$quadrature_probabilities`
stores the normalized zero, interior, and one weights.

MD7d accepts numeric predictors whose observed values are finite and in
`[0, 1]`, with at least one observed interior value to identify the beta
component. It rejects out-of-range values, non-numeric predictors, grouped or
structured zero-one beta predictor models, multiple missing predictors, and
dense known sampling covariance.

## Denominator-Aware Proportion Missing Predictors In Gaussian Location Models

MD7f adds one denominator-aware proportion predictor in a univariate Gaussian
location model. The response model uses the proportion variable through
`mi(cover)`, while the predictor model uses success counts and known trial
denominators:

```r
drmTMB(
  bf(y ~ z + mi(cover), sigma ~ 1),
  data = dat,
  impute = list(
    cover = impute_model(
      success ~ z,
      family = beta_binomial(),
      trials = trials
    )
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model uses the same beta-binomial parameterization as a
beta-binomial response model:

```text
logit(m_i) = W_i alpha
phi = 1 / sigma_mi^2
k_i | n_i, m_i, phi ~ BetaBinomial(n_i, m_i phi, (1 - m_i) phi)
x_i = k_i / n_i
```

For an observed success count, the row contributes the beta-binomial
predictor-model likelihood and, when the response is observed, the Gaussian
response density using `x_i = k_i / n_i`. For a missing success count, TMB sums
over all possible success counts for that row:

```text
log L_i = log sum_{k = 0}^{n_i}
  p_betabinom(k | n_i, m_i, sigma_mi)
  p(y_i | mu_i(k / n_i), sigma_i) ^ observed_y_i
```

When both the response and the success count are missing, the row is retained
for accounting but contributes no direct likelihood. `imputed()` reports the
conditional proportion mean for missing rows, and
`fit$missing_data$predictors[[name]]$conditional_probabilities` stores the
normalized success-count probabilities over `0, ..., n_i`.

MD7f requires complete positive integer trial counts. Observed success counts
must be integers between zero and the trial count, and observed `mi()`
proportions must equal success divided by trials. It rejects grouped or
structured beta-binomial predictor models, multiple missing predictors, and
dense known sampling covariance.

## Poisson Count Missing Predictors In Gaussian Location Models

MD7b adds one non-negative integer count predictor in a univariate Gaussian
location model. The predictor model is fixed-effect Poisson:

```r
drmTMB(
  bf(y ~ z + mi(abundance), sigma ~ 1),
  data = dat,
  impute = list(
    abundance = impute_model(abundance ~ z, family = poisson())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model uses the log-mean parameterization:

```text
log(lambda_i) = W_i alpha
x_i ~ Poisson(lambda_i)
```

For observed `abundance_i`, the row contributes the Poisson predictor-model
likelihood and, when the response is observed, the Gaussian response density.
For missing `abundance_i`, TMB sums over a deterministic count support
`k = 0, ..., K`:

```text
log L_i = log sum_k
  p_pois(k | lambda_i)
  p(y_i | mu_i(k), sigma_i) ^ observed_y_i
```

When both the response and the count predictor are missing, the row is retained
for accounting but contributes no direct likelihood. `imputed()` reports the
conditional expected count for missing rows, and
`fit$missing_data$predictors[[name]]$conditional_probabilities` stores the
normalized count-state probabilities over the finite support.

MD7b accepts numeric or integer predictors whose observed values are finite
non-negative integers. It rejects negative, fractional, and non-finite count
values, grouped or structured Poisson predictor models, multiple missing
predictors, and dense known sampling covariance. The count support is
deliberately bounded in this first slice; very wide count supports error rather
than silently fitting a fragile approximation.

## Negative-Binomial Count Missing Predictors In Gaussian Location Models

MD7c adds one overdispersed non-negative integer count predictor in a univariate
Gaussian location model. The predictor model is fixed-effect NB2:

```r
drmTMB(
  bf(y ~ z + mi(abundance), sigma ~ 1),
  data = dat,
  impute = list(
    abundance = impute_model(abundance ~ z, family = nbinom2())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model uses the same NB2 mean-overdispersion parameterization as a
count response model:

```text
log(mu_xi) = W_i alpha
sigma_x > 0
Var(x_i | mu_xi, sigma_x) = mu_xi + sigma_x^2 mu_xi^2
```

For observed `abundance_i`, the row contributes the NB2 predictor-model
likelihood and, when the response is observed, the Gaussian response density.
For missing `abundance_i`, TMB sums over a deterministic count support
`k = 0, ..., K`:

```text
log L_i = log sum_k
  p_nb2(k | mu_xi, sigma_x)
  p(y_i | mu_i(k), sigma_i) ^ observed_y_i
```

When both the response and the count predictor are missing, the row is retained
for accounting but contributes no direct likelihood. `imputed()` reports the
conditional expected count for missing rows, and
`fit$missing_data$predictors[[name]]$conditional_probabilities` stores the
normalized count-state probabilities over the finite support.

MD7c accepts numeric or integer predictors whose observed values are finite
non-negative integers. It rejects negative, fractional, and non-finite count
values, grouped or structured NB2 predictor models, hurdle count predictor
models, multiple missing predictors, and dense known sampling covariance. The
count support is deliberately bounded; very wide NB2 supports error rather than
silently fitting a fragile finite-sum approximation.

## Zero-Truncated Count Missing Predictors In Gaussian Location Models

MD7e adds one positive count predictor in a univariate Gaussian location model.
The predictor model is fixed-effect zero-truncated NB2:

```r
drmTMB(
  bf(y ~ z + mi(abundance), sigma ~ 1),
  data = dat,
  impute = list(
    abundance = impute_model(abundance ~ z, family = truncated_nbinom2())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model uses the same untruncated NB2 mean and overdispersion
parameters as the response-family route, then conditions on a positive count:

```text
log(mu_xi) = W_i alpha
sigma_x > 0
p_+(mu_xi, sigma_x) = 1 - p_nb2(0 | mu_xi, sigma_x)
p_zt(k | mu_xi, sigma_x) = p_nb2(k | mu_xi, sigma_x) / p_+
  for k = 1, 2, ...
```

For observed `abundance_i`, the row contributes the zero-truncated NB2
predictor-model likelihood and, when the response is observed, the Gaussian
response density. For missing `abundance_i`, TMB sums over a deterministic
positive count support `k = 1, ..., K`:

```text
log L_i = log sum_k
  p_zt(k | mu_xi, sigma_x)
  p(y_i | mu_i(k), sigma_i) ^ observed_y_i
```

When both the response and the positive-count predictor are missing, the row is
retained for accounting but contributes no direct likelihood. `imputed()`
reports the conditional expected positive count for missing rows, and
`fit$missing_data$predictors[[name]]$conditional_probabilities` stores the
normalized positive-count probabilities over the finite support.

MD7e accepts numeric or integer predictors whose observed values are finite
positive integers. It rejects zero, negative, fractional, and non-finite count
values, grouped or structured zero-truncated NB2 predictor models, hurdle count
predictor models, multiple missing predictors, and dense known sampling
covariance. Use `nbinom2()` instead when zero is a possible predictor value.

## Lognormal Positive Continuous Missing Predictors In Gaussian Location Models

MD8a adds one positive continuous predictor in a univariate Gaussian location
model. The predictor model is fixed-effect lognormal:

```r
drmTMB(
  bf(y ~ z + mi(biomass), sigma ~ 1),
  data = dat,
  impute = list(
    biomass = impute_model(biomass ~ z, family = lognormal())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is Gaussian on the log scale:

```text
log(x_i) ~ Normal(W_i alpha, sigma_x^2)
mu_i(x) = eta_without_x_i + beta_x x
```

For observed `biomass_i`, the row contributes the lognormal predictor-model
likelihood and, when the response is observed, the Gaussian response density:

```text
log L_i =
  log Normal(log x_i | W_i alpha, sigma_x)
  - log x_i
  + observed_y_i log Normal(y_i | mu_i(x_i), sigma_i)
```

For missing `biomass_i`, TMB integrates over standardized log-scale predictor
states by deterministic Gauss-Hermite quadrature. With standard-normal
quadrature nodes `q_k` and weights `w_k`,

```text
x_ik = exp(W_i alpha + sigma_x q_k)

log L_i =
  log sum_k
    w_k p(y_i | mu_i(x_ik), sigma_i) ^ observed_y_i
```

When both the response and the positive predictor are missing, the row is
retained for accounting but contributes no direct likelihood. `imputed()`
reports the fitted conditional quadrature mean for missing rows, and
`fit$missing_data$predictors[[name]]$quadrature_probabilities` stores the
normalized quadrature weights after conditioning on the observed response.

MD8a accepts numeric predictors whose observed values are finite and greater
than zero. It rejects zero, negative, and non-finite values, grouped or
structured lognormal predictor models, semi-continuous predictors with exact
zeros, multiple missing predictors, and dense known sampling covariance.

## Gamma Positive Continuous Missing Predictors In Gaussian Location Models

MD8b adds a second positive continuous predictor route in a univariate Gaussian
location model. The predictor model is fixed-effect Gamma mean-CV:

```r
drmTMB(
  bf(y ~ z + mi(biomass), sigma ~ 1),
  data = dat,
  impute = list(
    biomass = impute_model(biomass ~ z, family = Gamma(link = "log"))
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model uses the same Gamma mean-CV parameterization as a Gamma
response model:

```text
mu_xi = exp(W_i alpha)
sigma_x > 0
shape_x = 1 / sigma_x^2
scale_xi = mu_xi sigma_x^2
x_i ~ Gamma(shape_x, scale_xi)
```

For observed `biomass_i`, the row contributes the Gamma predictor-model
likelihood and, when the response is observed, the Gaussian response density:

```text
log L_i =
  log GammaDensity(x_i | shape_x, scale_xi)
  + observed_y_i log Normal(y_i | mu_i(x_i), sigma_i)
```

For missing `biomass_i`, TMB integrates over positive predictor states by
deterministic Gauss-Laguerre quadrature. With Laguerre nodes `t_k` and weights
`w_k`,

```text
x_ik = scale_xi t_k

log L_i =
  log sum_k
    w_k t_k^(shape_x - 1) / Gamma(shape_x)
    p(y_i | mu_i(x_ik), sigma_i) ^ observed_y_i
```

When both the response and the positive predictor are missing, the row is
retained for accounting but contributes no direct likelihood. `imputed()`
reports the fitted conditional quadrature mean for missing rows, and
`fit$missing_data$predictors[[name]]$quadrature_probabilities` stores the
normalized quadrature weights after conditioning on the observed response.

MD8b accepts numeric predictors whose observed values are finite and greater
than zero. It rejects zero, negative, and non-finite values, non-log Gamma
links, grouped or structured Gamma predictor models, semi-continuous predictors
with exact zeros, multiple missing predictors, and dense known sampling
covariance.

## Tweedie Semi-Continuous Missing Predictors In Gaussian Location Models

MD8c adds one non-negative semi-continuous predictor in a univariate Gaussian
location model. The predictor model is fixed-effect Tweedie:

```r
drmTMB(
  bf(y ~ z + mi(biomass), sigma ~ 1),
  data = dat,
  impute = list(
    biomass = impute_model(biomass ~ z, family = tweedie())
  ),
  missing = miss_control(predictor = "model")
)
```

The first fitted Tweedie predictor slice estimates the mean and scale but fixes
the predictor-model Tweedie power at 1.5:

```text
mu_xi = exp(W_i alpha)
phi_x = sigma_x^2
power_x = 1.5
x_i ~ Tweedie(mu_xi, phi_x, power_x)
```

The fixed power keeps the first semi-continuous route on the existing
`beta_mi` and `log_sigma_mi` parameter path. Estimating `power_x`, or allowing a
predictor-dependent power formula, needs a later parameter and identifiability
slice.

For observed `biomass_i`, the row contributes the Tweedie predictor-model
likelihood and, when the response is observed, the Gaussian response density:

```text
log L_i =
  log TweedieDensity(x_i | mu_xi, phi_x, power_x)
  + observed_y_i log Normal(y_i | mu_i(x_i), sigma_i)
```

For missing `biomass_i`, TMB integrates over the exact zero mass plus a
deterministic positive-support quadrature grid:

```text
log L_i =
  log sum_q
    w_q p_tweedie(x_q | mu_xi, phi_x, power_x)
    p(y_i | mu_i(x_q), sigma_i) ^ observed_y_i
```

The zero node has weight one and represents the exact Tweedie point mass at
zero. The positive nodes approximate the continuous density over a bounded
support chosen from the observed values and initial predictor-model moments.
When both the response and the Tweedie predictor are missing, the row is
retained for accounting but contributes no direct likelihood. `imputed()`
reports the fitted conditional quadrature mean for missing rows, and
`fit$missing_data$predictors[[name]]$quadrature_probabilities` stores the
normalized zero-plus-positive quadrature weights.

MD8c accepts numeric predictors whose observed values are finite and greater
than or equal to zero, with at least one observed positive value to identify the
continuous component. It rejects negative and non-finite values, grouped or
structured Tweedie predictor models, estimated or predictor-dependent Tweedie
power, multiple missing predictors, and dense known sampling covariance.

## Bivariate Gaussian Response Masks

For independent-observation bivariate Gaussian fits, MD2 uses separate response
masks:

```text
observed_y1_i = 1 if y1_i is observed
observed_y2_i = 1 if y2_i is observed
```

Missing response cells are replaced by an internal finite sentinel after the
masks have been recorded. The sentinel is not part of the likelihood. For each
row, the TMB branch evaluates:

```text
if observed_y1_i = 1 and observed_y2_i = 1:
  -log MVN([y1_i, y2_i]' | [mu1_i, mu2_i]', Omega_i)

if observed_y1_i = 1 and observed_y2_i = 0:
  -log Normal(y1_i | mu1_i, sigma1_i)

if observed_y1_i = 0 and observed_y2_i = 1:
  -log Normal(y2_i | mu2_i, sigma2_i)

if observed_y1_i = 0 and observed_y2_i = 0:
  0
```

The marginal one-response contributions do not contain residual `rho12`.
Complete response pairs are therefore the direct residual-correlation evidence.
The R builder stores complete-pair, `y1`-only, `y2`-only, and both-missing counts
in `fit$missing_data`, and warns when complete pairs are too sparse for the
fitted `rho12` formula. `nobs()` counts rows with at least one observed response.
Response residual matrices set missing response cells to `NA`; Pearson residuals
use the bivariate whitening only for complete pairs and use the marginal
standardization for a `y2`-only row.

Dense bivariate known sampling covariance is deferred for partial-response rows.
The current dense `meta_V(V = V)` route keeps the row-paired `2n` by `2n`
covariance matrix and requires complete response pairs. Component-level slicing
is needed before rows with only one observed response can be combined with dense
known `V`.

## Likelihood Weights

The top-level `weights =` argument supplies row log-likelihood multipliers,
not sampling variances. For independent-row likelihood branches, the TMB
template evaluates:

```text
nll = sum_i w_i {-log f(y_i | theta_i)}
```

where `w_i` is the processed weight after model-row filtering. For the
implemented bivariate Gaussian independent-row path, `w_i` belongs to the
complete response pair:

```text
nll = sum_i w_i {-log f([y1_i, y2_i]' | theta_i)}
```

Known sampling variances or sampling covariance still belong in
`meta_V(V = V)`. When `meta_V(V = V)` supplies a full dense
covariance matrix, `weights =` is rejected for now because the likelihood is a
joint multivariate block rather than a sum of independent row contributions.

## Implemented Gaussian Location-Scale

Gaussian location-scale is implemented for fixed-effect models and for
univariate Gaussian location random intercepts, labelled random intercepts,
independent numeric random slopes, and labelled or unlabelled ordinary
correlated random intercept-slope blocks, residual-scale random intercepts and
independent numeric random slopes in the univariate Gaussian `sigma` formula,
and random-effect scale models for one or more distinct unlabelled `mu` random
intercepts:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
```

### Numerical guard on the scale linear predictor

The Gaussian density applies a smooth soft-clamp to the per-observation
log-scale `eta_sigma` before exponentiation. The clamp is **exactly the
identity** inside the band `[-12, 12]` and saturates C1-smoothly (via a `tanh`
margin) only beyond each bound, with overall range `[-15, 15]` (so `sigma` is
bounded to roughly `[3e-7, 3.3e6]`):

```text
eta_sigma_guarded_i = softclamp(eta_sigma_i, lo = -12, hi = 12, margin = 3)
sigma_i = exp(eta_sigma_guarded_i)
```

Because it is exactly the identity inside the band, any fit whose fitted
`log(sigma)` stays within `[-12, 12]` -- that is, every well-posed Gaussian fit
-- is unchanged to the bit; the clamp acts only on a runaway scale. (An earlier
pure-softplus form was rejected because it leaked a small bias into the central
band and broke exact-equality and cross-path tests.) Its purpose is purely
numerical: a per-observation
scale random effect -- for example a phylogenetic field on `sigma` with one
observation per group -- can otherwise drive `eta_sigma` to extreme values,
overflow the Gaussian density, and break the inner Laplace solve. For any
well-posed fit the clamp is inactive and does not change the result. It is a
guard, not a model feature: it does not make a per-group scale field
identifiable from a single observation per group, so a fit that relies on the
clamp will still report non-convergence or a non-positive-definite Hessian (see
`docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md`). The same
guard applies to `sigma1` and `sigma2` in the bivariate Gaussian density.

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

With one or more simple random-effect terms in the location model:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + sum_j z_j[i] b_{j, g_j[i]}
sigma_i = exp(X_sigma[i, ] beta_sigma)
b_{j, g} = sd_j * u_{j, g}
u_{j, g} ~ Normal(0, 1)
sd_j = exp(theta_j)
```

For a random intercept, `z_j[i] = 1`. For a simple random slope written as
`(0 + x | id)`, `z_j[i] = x_i`.

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | site) + (0 + x1 | observer), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

For an ordinary correlated random intercept-slope block:

```text
mu_i = X_mu[i, ] beta_mu + b_0,g[i] + x_i b_1,g[i]

[b_0,g, b_1,g]' ~ MVN(0, Sigma_g)
Sigma_g =
  [sd0^2,          rho_re sd0 sd1;
   rho_re sd0 sd1, sd1^2]

u_g ~ Normal([0, 0]', I)
b_0,g = sd0 * u_0,g
b_1,g = sd1 * (rho_re * u_0,g + sqrt(1 - rho_re^2) * u_1,g)
rho_re = 0.999999 * tanh(eta_cor)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

or, with an explicit covariance-block label:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

Here `rho_re` is a group-level random-effect correlation. It is extracted via
`corpars$mu` and is not residual `rho12`. In the current univariate Gaussian
implementation, the middle label `p` is retained for naming and future
cross-formula covariance matching; the likelihood is otherwise the same as the
unlabelled `(1 + x1 | id)` block.

For univariate Gaussian structured location and residual-scale intercept models,
the structured field may enter `mu`, `sigma`, or both. For a matching `mu` and
`sigma` pair:

```text
mu_i = X_mu[i, ] beta_mu + s_mu, group[i]
log(sigma_i) = X_sigma[i, ] beta_sigma + s_sigma, group[i]

[s_mu, s_sigma]_g ~ Normal(0, Sigma_structured x K)
Sigma_structured =
  [sd_mu^2, rho_mu_sigma sd_mu sd_sigma;
   rho_mu_sigma sd_mu sd_sigma, sd_sigma^2]
```

For a sigma-only structured intercept, the first equation omits `s_mu`, the
second keeps `s_sigma`, and no correlation parameter is estimated. For
coordinate spatial models, `K` is built from observed coordinates:

```text
K_coords[l, m] = exp(-d_lm / r)
r = median positive pairwise site distance
Q_coords = K_coords^{-1}
```

Phylogenetic models use the tree-derived covariance, `animal()` uses a
pedigree-derived or supplied additive relatedness matrix, and `relmat()` uses a
supplied known covariance or precision. These routes reuse the same
sparse-precision TMB prior shape. The internal TMB names remain generic
(`log_sd_phylo` and `eta_cor_phylo`) for this shared structured-effect layer,
but public output labels the terms as `phylo`, `spatial`, `animal`, or
`relmat`. Conditional effects appear in marker-specific `ranef()` blocks such
as `phylo_mu`, `phylo_sigma`, `spatial_mu`, and `spatial_sigma`.

Matching R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + phylo(1 | species, tree = tree),
    sigma ~ x2 + phylo(1 | species, tree = tree)
  ),
  family = gaussian(),
  data = dat
)

drmTMB(
  bf(
    y ~ x1 + spatial(1 | site, coords = coords),
    sigma ~ x2 + spatial(1 | site, coords = coords)
  ),
  family = gaussian(),
  data = dat
)
```

For animal and lower-level relatedness models, the matching syntax is:

```r
drmTMB(
  bf(
    y ~ x1 + animal(1 | id, Ainv = Ainv),
    sigma ~ x2 + animal(1 | id, Ainv = Ainv)
  ),
  family = gaussian(),
  data = dat
)

drmTMB(
  bf(
    y ~ x1 + relmat(1 | line, Q = Q),
    sigma ~ x2 + relmat(1 | line, Q = Q)
  ),
  family = gaussian(),
  data = dat
)
```

`animal(1 | id, A = A)` and `relmat(1 | id, K = K)` accept covariance or
relatedness matrices. `animal(1 | id, Ainv = Ainv)` and
`relmat(1 | id, Q = Q)` accept inverse relatedness or precision matrices. The
matrix row and column names define the latent structured-effect levels, and
the observed grouping column must match those names.

Matching labelled bivariate `mu1`/`mu2` terms now use the same known precision
route to fit the first q=2 location covariance. Matching all-four labelled
`mu1`/`mu2`/`sigma1`/`sigma2` terms fit the first constant q=4
location-scale covariance block. Pedigree-to-Ainv construction is fitted for
the dense first animal route; large-pedigree sparse precision construction,
labelled structured slope covariance, bridge/inference for matched slope
cells, predictor-dependent relatedness `corpair()` regression, and generic
direct-SD grammar remain planned until their
likelihood, diagnostics, profile or bootstrap interval story, simulation
recovery tests, and examples exist.

The first spatial slope path keeps that covariance but uses two independent
fields:

```text
mu_i = X_mu[i, ] beta_mu + s0_site[i] + x_i s1_site[i]
s0 ~ Normal(0, sd_spatial_intercept^2 K_coords)
s1 ~ Normal(0, sd_spatial_slope^2 K_coords)
Cov(s0, s1) = 0 in this phase
```

The matching syntax is:

```r
drmTMB(
  bf(y ~ x1 + spatial(1 + depth | site, coords = coords), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

The public SD labels are `spatial(1 | site)` for the spatial intercept field and
`spatial(0 + depth | site)` for the spatial slope field. There is no
intercept-slope `corpair()` row for this slice.

Residual-scale random intercepts and independent numeric random slopes are
implemented on the log-`sigma` scale:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + sum_j z_j[i] a_{j, g_j[i]}
a_jg = sd_sigma_j * v_jg
v_jg ~ Normal(0, 1)
sd_sigma_j = exp(theta_sigma_j)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2 + (1 | id) + (0 + w | id)),
  family = gaussian(),
  data = dat
)
```

This is residual-scale heterogeneity. It is distinct from random-effect scale
models such as `sd(id) ~ x_group`.

The implemented random-effect scale grammar can target one or more distinct
unlabelled univariate Gaussian `mu` random intercepts. For one target:

```text
y_ij | mu_ij, sigma_ij, b_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
sd_mu_id,j = exp(W_id[j, ] alpha_id)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2, sd(id) ~ x_group),
  family = gaussian(),
  data = dat
)
```

The right-hand side of `sd(id) ~ x_group` is evaluated once per `id` level.
Predictors must be constant within `id` after missing-row filtering. This
models among-group variation in the location random intercept; it is not a
residual-scale model and it is not a second `sigma` formula.

The implemented bivariate Gaussian direct-SD model uses response-specific
location random-effect SD formulas:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
mu1_i = X_mu1[i, ] beta_mu1 + b1[id_i]
mu2_i = X_mu2[i, ] beta_mu2 + b2[id_i]
[u1_j, u2_j]' ~ Normal([0, 0]', R_group)
b1_j = sd_mu1_id,j u1_j
b2_j = sd_mu2_id,j u2_j
log(sd_mu1_id,j) = W1_id[j, ] alpha1
log(sd_mu2_id,j) = W2_id[j, ] alpha2
```

Matching R syntax:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x + (1 | p | id),
    sigma1 = ~ z1,
    sigma2 = ~ z2,
    rho12 = ~ w,
    sd1(id) ~ x_group1,
    sd2(id) ~ x_group2
  ),
  family = biv_gaussian(),
  data = dat
)
```

`sd1(id)` targets the `mu1` location random-effect SD and `sd2(id)` targets
the `mu2` location random-effect SD. These are Family B direct
variance-component scale models, not residual `sigma1` / `sigma2` models and
not SD regressions for random effects inside the scale formulas.

For several distinct random-intercept targets, the likelihood uses the same
non-centered construction for each component:

```text
mu_i = X_mu[i, ] beta_mu + b_id[id_i] + b_site[site_i]
b_id[j] = sd_mu_id,j u_id,j
b_site[k] = sd_mu_site,k u_site,k
u_id,j, u_site,k ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
log(sd_mu_site,k) = W_site[k, ] alpha_site
```

Matching R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | id) + (1 | site),
    sigma ~ x2,
    sd(id) ~ x_group,
    sd(site) ~ site_type
  ),
  family = gaussian(),
  data = dat
)
```

Residuals are not part of the formula grammar. They are computed downstream
from the fitted likelihood.

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma` uses `log(sigma_i) = X_sigma beta_sigma`.
- Simulation recovery tests live in
  `tests/testthat/test-gaussian-location-scale.R`.
- Random-effect recovery tests live in
  `tests/testthat/test-gaussian-random-intercepts.R`.
- Random-effect scale recovery tests live in
  `tests/testthat/test-gaussian-random-effect-scale.R`.
- Comparator tests against `lme4` for overlapping Gaussian ML and first-slice
  REML random-effect models live in `tests/testthat/test-comparators.R`.
  Known-`V` REML tests in the same file compare estimates against `metafor`
  and the restricted log likelihood against an independent full Gaussian REML
  calculation.
- The univariate likelihood supports optional known sampling covariance via
  `meta_V(V = V)`, with deprecated `meta_known_V(V = V)` as a compatibility
  alias. It has no residual correlation parameter.

### First-Slice Gaussian REML

`drmTMB(..., REML = TRUE)` uses restricted maximum likelihood for the first
ordinary univariate Gaussian mixed-model and known-`V` meta-analysis slices.
The implemented route keeps the same Gaussian joint likelihood in
`src/drmTMB.cpp`, but asks `TMB::MakeADFun()` to integrate the `beta_mu`
fixed-effect vector together with the ordinary latent `mu` random effects. This
gives the restricted likelihood for the Gaussian mean structure while retaining
conditional modes for `beta_mu`, the ordinary random effects, and the variance
parameters.

The current REML surface is row-specific rather than blanket-narrow. Baseline
univariate Gaussian routes admit dense full-rank `mu` fixed-effect designs,
ordinary `mu` random intercepts or slopes, diagonal or dense known sampling
covariance through `meta_V(V = V)`, predictor-dependent `sigma`, ordinary
`sigma` random effects, matched ordinary `mu`-`sigma` blocks, complete
responses, and unit likelihood weights. Independently validated phylogenetic
routes include univariate mean-side, scale-side, matched q2, direct
`sd_phylo()` scale, and the fitted bivariate covariance layouts through dense
q4. Arc 1a adds pure-`mu`, unlabelled intercept or independent-one-slope
`sigma ~ 1` routes for `spatial()`, `animal()`, and `relmat()` over the exact
discrete domains recorded in the live ledger; univariate scale-side
spatial/animal/relmat REML and selected ordinary q > 2 location blocks are
separate pre-existing admissions. These admissions do not transfer interval,
coverage, `supported`, or AI-REML status to neighbouring rows.

REML still rejects non-Gaussian models, explicit missing-data routes, Gaussian
row aggregation, sparse fixed-effect matrices, ordinary direct-`sd()` scale
formulas, and any structured layout outside its exact row gate. Arc 1b-S1's one
non-phylogenetic bivariate exception is a matching labelled fixed-covariance
spatial q2 location-intercept block in `mu1` and `mu2`, with intercept-only
`sigma1`, `sigma2`, and `rho12`, complete response pairs, unit weights, no
known `meta_V()` covariance, and no additional ordinary random effect,
direct-SD formula, or `corpair()` regression; it stops at
`point_fit_recovery`.

Arc 1b-S2R adds one parallel supplied-relatedness exception:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
    mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  family = biv_gaussian(),
  data = data,
  REML = TRUE
)
```

If \(B=[b_1,b_2]\) stores the two group-level location fields, this cell uses

```text
vec(B) ~ Normal(0, Sigma_K ⊗ K)
Sigma_K =
  [s1^2,              rho_K s1 s2;
   rho_K s1 s2,       s2^2]
```

where `K` is the same named covariance matrix, in the same group-level order,
for both endpoints. Here `rho_K` is the structured location correlation, not
the residual response correlation `rho12`. The implementation reuses the
existing exact-Gaussian TMB structured prior and REML integration of the
location fixed effects; it does not add another likelihood engine. An
independent dense restricted-likelihood
oracle and the retained 2,400-attempt recovery campaign support only
`point_fit_recovery`. Precision input `Q = Q`, `animal()`, unlabelled or
unmatched blocks, slopes, q4+, scale-side structured terms, extra random-effect
layers, incomplete or weighted pairs, non-Gaussian families, intervals, and
coverage remain outside this cell.

The authoritative route-by-route table is
`docs/design/211-structured-reml-status.md`; this likelihood section must not
be read as a family-wide or provider-wide promotion.

For diagonal or dense `meta_V(V = V)`, `drmTMB` reports the full restricted
Gaussian log likelihood:

```text
-0.5 * ((n - p) log(2 pi) + log|Sigma| +
        log|X' Sigma^{-1} X| + r' Sigma^{-1} r)
```

where `Sigma` is the total fitted observation covariance after known sampling
covariance and fitted heterogeneity have been added. `metafor` reports the
same REML estimates under a log-likelihood convention shifted by
`0.5 * log|X'X|`; comparator tests record this expected fixed-design determinant
shift.

For model selection, REML is not the default. AIC/BIC comparisons across
different fixed-effect formulas should use ML (`REML = FALSE`) because REML
integrates over the fitted fixed-effect design. REML is the Gaussian
mixed-model option for variance-component estimation within a fixed mean
structure.

## Implemented Meta-Analytic Gaussian Regression

Meta-analysis uses the ordinary Gaussian family plus known sampling covariance.
It is not a separate family.

```text
y ~ MVN(mu, V_known + Sigma_unknown)
```

For diagonal `V`, written as `meta_V(V = vi)` in the location formula:

```text
y_i ~ Normal(mu_i, vi_i + sigma_i^2)
log(sigma_i) = X_sigma beta_sigma
```

For dense full or block-diagonal `V`, the implemented likelihood is:

```text
y ~ MVN(mu, V + diag(sigma_i^2))
```

Implementation notes:

- `vi` means known sampling variances, not known standard errors.
- A vector or data column supplies diagonal known sampling variances.
- A matrix supplies dense known sampling covariance and must be symmetric
  positive semidefinite after retained-row subsetting.
- `sigma_i` is the extra heterogeneity SD after known sampling error is added.
- `meta_V()` and deprecated `meta_known_V()` must be treated as covariance
  markers, not as ordinary fixed-effect predictors.
- The marker is removed before model-matrix construction.
- `predict(fit, dpar = "sigma")` returns the unknown heterogeneity SD;
  likelihood, Pearson residuals, and simulation include the known covariance.
- Simulation, missing-row, and likelihood-agreement tests with known `vi` and
  full `V` live in
  `tests/testthat/test-meta-known-v.R`.
- Sparse known covariance is planned for larger phylogenetic and spatial
  workloads.

In meta-analysis prose, `sigma` is the extra heterogeneity SD traditionally
called `tau`. The public API still uses `sigma` for consistency.

## Implemented Student-t Location-Scale-Shape

The first robust continuous likelihood is fixed-effect Student-t regression:

```text
y_i | mu_i, sigma_i, nu_i ~ Student-t(mu_i, sigma_i, nu_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
nu_i = 2 + exp(eta_nu_i)
```

The TMB likelihood includes all Student-t normalizing constants:

```text
z_i = (y_i - mu_i) / sigma_i
log f(y_i) =
  lgamma((nu_i + 1) / 2) - lgamma(nu_i / 2)
  - 0.5 log(nu_i pi) - log(sigma_i)
  - 0.5 (nu_i + 1) log(1 + z_i^2 / nu_i)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = student(),
  data = dat
)
```

Ordinary unlabelled `mu` random intercepts and independent numeric slopes add
grouped latent effects to `eta_mu_i`, with the same location-scale-shape
likelihood. One unlabelled `spatial()` intercept or one-slope route on `mu` is
recovery-grade, and the exact `nu ~ phylo(1 | id, tree = tree)` structured
intercept is diagnostic-grade. Correlated or labelled `mu` slopes, `sigma`
random effects, other `nu` random effects, other structured providers, known
sampling covariance, and bivariate Student-t families remain planned.

For applied examples, the runnable Student-t question is a sensitivity question:
do conclusions about the location `mu` and scale `sigma` change when the
likelihood estimates the tail-shape parameter `nu` rather than assuming
Gaussian residual tails? This is complementary to `skew_normal()`, which targets
residual asymmetry rather than heavy tails.

## Implemented Skew-Normal Location-Scale-Shape

The first skew-normal path is for continuous responses where residual asymmetry
is part of the scientific question. It uses public moment parameters and
transforms internally to an Azzalini-style skew-normal density. Public `mu` is
the response mean, public `sigma` is the response standard deviation, and `nu`
is the slant or shape parameter:

```text
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
nu_i = eta_nu_i
delta_i = nu_i / sqrt(1 + nu_i^2)
omega_i = sigma_i / sqrt(1 - 2 * delta_i^2 / pi)
xi_i = mu_i - omega_i * delta_i * sqrt(2 / pi)
z_i = (y_i - xi_i) / omega_i
log f(y_i) = log(2) - log(omega_i) + log phi(z_i) + log Phi(nu_i z_i)
```

Here `phi()` and `Phi()` are the standard normal density and distribution
function. The TMB branch evaluates the last term as
`log(Phi(nu_i z_i) + 1e-300)` to avoid `log(0)` in extreme tails. The sign
convention is part of the public contract: `nu_i = 0` gives the Gaussian
location-scale likelihood, `nu_i > 0` gives right-skewed residuals, and
`nu_i < 0` gives left-skewed residuals. Source tests check this orientation
through the third central moment and deterministic recovery cases.

The transform makes `mu_i = E[y_i]` and `sigma_i = SD[y_i]` by construction.
That keeps `fitted()` and `sigma()` aligned with the public response-scale
semantics used by the other fixed-effect families. Source density-contract
tests record the scale map: `RTMBdist::dskewnorm2()` and similar moment-scale
APIs are natural public-scale comparators, while `sn::dsn()` and
`RTMBdist::dskewnorm()` remain useful after transforming to native `xi`,
`omega`, and `alpha`.

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = skew_normal(),
  data = dat
)
```

The first implementation is fixed-effect and univariate. It supports
intercept-only and ordinary fixed-effect `nu` formulas and rejects random
effects in `mu`, `sigma`, or `nu`; `sd(group)` scale models; bivariate
responses; `rho12`; `meta_V(V = V)`; deprecated `meta_known_V(V = V)`;
`phylo()`, `spatial()`, `animal()`, and `relmat()` structured terms; aliases
such as `skew ~ x`; and latent `skew(id)` syntax. Focused tests cover the
density normalization, native-density comparison, normal limit, positive and
negative skew recovery, weak-skew recovery, predictor-dependent `nu`, Gaussian
false-positive behaviour, simulation output, residuals, fixed-effect interval
visibility, `check_drm()` diagnostics, and malformed neighbours. Formal
multi-replicate operating-characteristic grids and external fitted-model
comparators remain future evidence, so this route should be described as a
first slice rather than a mature general-purpose family.

## Planned Skew-T Shape Gate

The future skew-t path should come after the skew-normal gate because it has
two shape dimensions that can trade off: residual asymmetry and tail weight.
`tau` is reserved for a second shape parameter but is not current formula
syntax. Before implementation, choose one skew-t density, name its native
parameters, and decide whether `nu` controls asymmetry and `tau` controls tail
thickness:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3, tau ~ x4),
  family = skew_t(),
  data = dat
)
```

This example is planned syntax only. A fitted skew-t route needs density
comparators, skew-normal or Student-t limit checks, recovery for `sigma ~ x`,
`nu ~ x`, and `tau ~ x`, and false-positive checks showing that skewness,
tail thickness, heteroscedasticity, outliers, and ordinary random effects are
not being conflated.

## Implemented Lognormal Location-Scale

The first positive continuous likelihood is fixed-effect lognormal regression:

```text
log(y_i) | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
```

The TMB likelihood is evaluated on the original positive response scale with
the log-Jacobian term:

```text
log_y_i = log(y_i)
log f(y_i) =
  log Normal(log_y_i | mu_i, sigma_i^2) - log_y_i
```

The arithmetic response mean is:

```text
E[y_i] = exp(mu_i + sigma_i^2 / 2)
```

Matching R syntax:

```r
drmTMB(
  bf(
    biomass ~ habitat + phylo(1 | species, tree = tree),
    sigma ~ treatment
  ),
  family = lognormal(),
  data = dat
)

drmTMB(
  bf(
    biomass ~ habitat + relmat(1 | species, K = K),
    sigma ~ treatment
  ),
  family = lognormal(),
  data = dat
)
```

Here `tree` is an ultrametric `phylo` object whose tip labels match `species`;
alternatively, `K` is a named positive-definite relatedness matrix. Supply its
named precision as `Q = Q` instead of `K = K` when that representation is
available.

For lognormal fits, `predict(fit, dpar = "mu")` returns the log-scale
location parameter, `sigma(fit)` returns the log-scale standard deviation, and
`fitted(fit)` returns `E[y_i]` on the original response scale. The response
must be positive and finite after missing-row filtering. Ordinary unlabelled
`mu` random intercepts and independent numeric slopes enter the log-response
location predictor. Arc 3a additionally admits exactly one unlabelled q1
`phylo()` or `relmat()` intercept using `K` or `Q` in `mu`. If `b` is the structured field,
then `eta_mu_i = X_mu[i, ] beta_mu + b_group[i]`, with
`b ~ Normal(0, s_mu^2 K)` (or the equivalent precision representation).
`s_mu` is a covariance multiplier: level `g` has marginal SD
`s_mu * sqrt(K[g, g])`, or `s_mu * sqrt(solve(Q)[g, g])` for a precision input.
It is a common marginal SD only when the covariance has unit diagonal. The new
routes do not admit structured slopes, labels, `sigma` structure, another
random-effect layer, simultaneous structured providers, spatial/animal structure, REML, or a
bivariate lognormal response. The exact Arc 3a cells have point-fit recovery
evidence; intervals and coverage remain untested.

## Implemented Gamma Mean-CV

The first Gamma path is fixed-effect mean-CV regression:

```text
y_i | mu_i, sigma_i ~ Gamma(shape_i, scale_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
shape_i = 1 / sigma_i^2
scale_i = mu_i * sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i^2 sigma_i^2
```

The TMB likelihood is:

```text
log f(y_i) =
  (shape_i - 1) log(y_i) - y_i / scale_i -
  log Gamma(shape_i) - shape_i log(scale_i)
```

Matching R syntax:

```r
drmTMB(
  bf(
    biomass ~ habitat + phylo(1 | species, tree = tree),
    sigma ~ treatment
  ),
  family = Gamma(link = "log"),
  data = dat
)
```

Here `tree` is an ultrametric `phylo` object whose tip labels match `species`.

For Gamma fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
response mean. `sigma(fit)` returns the coefficient of variation, not the
residual standard deviation; the fitted residual standard deviation is
`mu_i * sigma_i`. The response must be positive and finite after missing-row
filtering. Ordinary unlabelled `mu` random intercepts and independent numeric
slopes enter the log-mean predictor. The existing `relmat()` intercept and
independent one-slope route remains fitted. Arc 3a additionally admits exactly
one unlabelled q1 `phylo()` intercept in `mu`, using
`eta_mu_i = X_mu[i, ] beta_mu + b_species[i]` and the same scaled structured
Gaussian prior `b ~ Normal(0, s_mu^2 K_phylo)`. The new phylogenetic route does
not admit slopes, labels, `sigma` structure, another random-effect layer,
simultaneous structured providers, spatial/animal structure, REML, or
bivariate/mixed Gamma. `s_mu` is the phylogenetic covariance multiplier, so
species `g` has marginal SD `s_mu * sqrt(K_phylo[g, g])`.
The exact Arc 3a cell has point-fit recovery evidence; intervals and coverage
remain untested.

## Implemented Tweedie Mean-Scale-Shape

The first Tweedie path is for non-negative semicontinuous responses with exact
zeros and positive continuous values. The implemented public-scale contract is:

```text
y_i | mu_i, sigma_i, nu_i ~ Tweedie(mu_i, phi_i, nu_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
phi_i = sigma_i^2
nu_i = 1 + plogis(eta_nu_i)
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

The TMB branch evaluates `dtweedie(y_i, mu_i, phi_i, nu_i, true)`, which
includes the Tweedie density normalizing terms. The first comparator remains
`glmmTMB::tweedie(link = "log")`, which reports Tweedie dispersion `phi`;
tests against that scale should compare `sigma_i^2` with `phi_i` and name the
transform explicitly. The focused test suite also compares an intercept-only
fitted log likelihood with a test-only compound Poisson-Gamma density fixture,
including exact-zero mass and positive-density terms.

Implemented first-slice R syntax:

```r
drmTMB(
  bf(biomass ~ habitat, sigma ~ habitat, nu ~ 1),
  family = tweedie(),
  data = dat
)
```

The first implementation is fixed-effect and univariate, with intercept-only
`nu ~ 1` before predictor-dependent power models. It rejects negative
responses, random effects in `mu`, `sigma`, or `nu`, bivariate Tweedie
families, mixed-response routes, `rho12`, `meta_V(V = V)`, zero-inflation or
hurdle aliases, and phylogenetic or spatial terms until separate recovery and
comparator tests exist.

## Implemented Beta Mean-Scale

The first beta path is fixed-effect mean-scale regression for strict
continuous proportions:

```text
y_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = logit^{-1}(eta_mu_i)
sigma_i = exp(eta_sigma_i)
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i] = mu_i
Var[y_i] = mu_i (1 - mu_i) sigma_i^2 / (1 + sigma_i^2)
```

The first beta mixed-model slice adds ordinary grouped location random
intercepts and independent numeric slopes before the inverse-logit transform:

```text
eta_mu_i = X_mu[i, ] beta_mu + b0_id[i] + x_i b1_id[i]
b0_j = sd_mu_intercept u0_j
b1_j = sd_mu_slope u1_j
u0_j, u1_j ~ independent Normal(0, 1)
```

The TMB likelihood is:

```text
log f(y_i) =
  log Gamma(phi_i) - log Gamma(alpha_i) - log Gamma(beta_i) +
  (alpha_i - 1) log(y_i) + (beta_i - 1) log(1 - y_i)
```

Matching R syntax:

```r
drmTMB(
  bf(prop ~ habitat, sigma ~ treatment),
  family = beta(),
  data = dat
)

drmTMB(
  bf(prop ~ habitat + (1 | plot), sigma ~ treatment),
  family = beta(),
  data = dat
)

drmTMB(
  bf(prop ~ habitat + (0 + habitat_score | plot), sigma ~ treatment),
  family = beta(),
  data = dat
)
```

For beta fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the mean
proportion. `sigma(fit)` returns the public scale parameter, not beta
precision; internally `phi_i = 1 / sigma_i^2`. The response must be finite and
strictly between 0 and 1 after missing-row filtering. Ordinary unlabelled
`mu` random intercepts such as `(1 | plot)` and independent numeric slopes
such as `(0 + habitat_score | plot)` enter the logit-`mu` predictor.
Correlated slopes, labelled covariance blocks, `sigma` random effects, exact
0/1 boundary mass through `zero_one_beta()`, known sampling covariance,
structured terms, and bivariate or mixed beta models are later phases. Use
`stats::binomial()` for ordinary event probabilities and `beta_binomial()` for
overdispersed counted successes out of known trials.

## Implemented Zero-One Beta Mean-Scale-Boundary

Zero-one beta models are for continuous proportions where exact 0 and exact 1
are structural boundary outcomes. The interior beta component keeps the same
mean-scale contract as `beta()`:

```text
Pr(y_i = 0) = zoi_i (1 - coi_i)
Pr(y_i = 1) = zoi_i coi_i
Pr(0 < y_i < 1) = 1 - zoi_i
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_zoi_i = X_zoi[i, ] beta_zoi
eta_coi_i = X_coi[i, ] beta_coi
mu_i = logit^{-1}(eta_mu_i)
sigma_i = exp(eta_sigma_i)
zoi_i = logit^{-1}(eta_zoi_i)
coi_i = logit^{-1}(eta_coi_i)
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i] = (1 - zoi_i) mu_i + zoi_i coi_i
```

The TMB likelihood is:

```text
log Pr(y_i = 0) = log(zoi_i) + log(1 - coi_i)
log Pr(y_i = 1) = log(zoi_i) + log(coi_i)
log f(0 < y_i < 1) =
  log(1 - zoi_i) +
  log Gamma(phi_i) - log Gamma(alpha_i) - log Gamma(beta_i) +
  (alpha_i - 1) log(y_i) + (beta_i - 1) log(1 - y_i)
```

Matching R syntax:

```r
drmTMB(
  bf(prop ~ habitat, sigma ~ treatment, zoi ~ drought, coi ~ canopy),
  family = zero_one_beta(),
  data = dat
)
```

For zero-one beta fits, `predict(fit, dpar = "mu")` returns the interior beta
mean, `predict(fit, dpar = "zoi")` returns the exact-boundary probability, and
`predict(fit, dpar = "coi")` returns the one-inflation probability conditional
on being at the boundary. `fitted(fit)` returns the unconditional response mean
including boundary mass, `(1 - zoi) * mu + zoi * coi`. `sigma(fit)` returns the
public beta scale parameter for the interior component. Ordinary unlabelled
`mu` random intercepts and independent numeric slopes are recovery-grade.
Correlated or labelled `mu` slopes, `sigma`/`zoi`/`coi` random effects,
structured effects, covariance blocks, known sampling covariance, denominator
syntax, bivariate bounded responses, and mixed-response bounded models remain
planned or unsupported.

## Implemented Beta-Binomial Mean-Overdispersion

Beta-binomial models keep the denominator in the likelihood:

```text
y_i | n_i, p_i ~ Binomial(n_i, p_i)
p_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
eta_mu_i = X_mu[i, ] beta_mu + Z_mu[i, j] b_j
b_j = sd_mu u_j
u_j ~ Normal(0, 1)
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = logit^{-1}(eta_mu_i)
sigma_i = exp(eta_sigma_i)
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i / n_i] = mu_i
Var(y_i / n_i) =
  mu_i (1 - mu_i) (1 + n_i sigma_i^2) /
  (n_i (1 + sigma_i^2))
```

The TMB likelihood is:

```text
log Pr(y_i | n_i, mu_i, sigma_i) =
  log Gamma(n_i + 1) - log Gamma(y_i + 1) -
  log Gamma(n_i - y_i + 1) +
  log Gamma(phi_i) - log Gamma(n_i + phi_i) +
  log Gamma(y_i + alpha_i) - log Gamma(alpha_i) +
  log Gamma(n_i - y_i + beta_i) - log Gamma(beta_i)
```

Matching R syntax:

```r
drmTMB(
  bf(cbind(successes, failures) ~ habitat + (1 | tray),
     sigma ~ treatment),
  family = beta_binomial(),
  data = dat
)

drmTMB(
  bf(cbind(successes, failures) ~ habitat + (0 + habitat_score | tray),
     sigma ~ treatment),
  family = beta_binomial(),
  data = dat
)
```

For beta-binomial fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return
the success probability. `sigma(fit)` returns the public extra-binomial
variation scale; internally `phi_i = 1 / sigma_i^2`. The response counts must
be finite non-negative integers with positive row totals after missing-row
filtering. Ordinary unlabelled `mu` random intercepts such as `(1 | tray)` and
independent numeric slopes such as `(0 + habitat_score | tray)` enter the logit
success-probability predictor. Correlated slopes, labelled covariance blocks,
`sigma` random effects, known sampling covariance, structured terms, bivariate
or mixed beta-binomial models, and a possible successes/trials response alias
are later phases.

## Implemented Cumulative-Logit Ordinal Location

The ordinal path is univariate and location-only, with fixed effects plus
ordinary recovery-grade `mu` random intercepts and independent numeric slopes:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

The response is represented internally by integer category scores
`1, ..., K`. Ordered factor labels are retained on the fitted object so
simulation can return ordered categories with the original labels. The
location intercept is removed before fitting because a free intercept and free
cutpoints are not jointly identifiable; factor predictors keep ordinary
treatment-contrast columns after the intercept column is dropped.

For category `k`, the TMB branch evaluates:

```text
Pr(y_i = 1) = F(theta_1 - mu_i)
Pr(y_i = k) = F(theta_k - mu_i) - F(theta_{k-1} - mu_i), 1 < k < K
Pr(y_i = K) = 1 - F(theta_{K-1} - mu_i)
```

where `F(a) = logit^{-1}(a)`. The middle-category log probabilities use a
`log(1 - exp(x))` helper on the log-CDF scale so close cutpoints do not lose
the likelihood contribution to cancellation.

Matching R syntax:

```r
drmTMB(
  bf(score ~ habitat),
  family = cumulative_logit(),
  data = dat
)
```

For cumulative-logit fits, `predict(fit, dpar = "mu")` returns the latent
ordinal location. `fitted(fit)` returns the expected ordered-category score
`sum_k k * Pr(y_i = k)`, which is useful as a fitted response summary but is
not a measured continuous outcome. `sigma(fit)` returns a fixed unit vector
because this path fixes the latent logistic scale. The exact
`mu ~ phylo(1 | id, tree = tree)` q1 intercept has local point-fit/extractor
evidence. Ordinal scale or discrimination formulas, correlated or labelled
ordinary slopes, other structured providers, known sampling covariance,
bivariate ordinal models, and mixed-response ordinal models are later phases.

## Implemented Poisson Mean

The first count path is mean regression on the log scale. The fixed-effect
version is:

```text
y_i | mu_i ~ Poisson(mu_i)
eta_mu_i = o_i + X_mu[i, ] beta_mu
mu_i = exp(eta_mu_i)
E[y_i] = Var[y_i] = mu_i
```

For exposure or effort models, `o_i` is the known offset supplied by standard
R syntax such as `offset(log(trap_nights))`. If no offset is present,
`o_i = 0`.

The TMB likelihood is:

```text
log f(y_i) = y_i log(mu_i) - mu_i - log(y_i!)
```

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat + offset(log(trap_nights))),
  family = poisson(link = "log"),
  data = dat
)
```

Ordinary unlabelled `mu` random intercepts and independent numeric slopes add
the usual grouped latent effects to `eta_mu_i`. The first structured
non-Gaussian path adds either one q=1 structured `mu` intercept or an
unlabelled intercept-plus-one-slope pair:

```text
eta_mu_i = o_i + X_mu[i, ] beta_mu + a0_level[i] + x_i a1_level[i]
a0 ~ Normal(0, sd_structured_intercept^2 A_structured)
a1 ~ Normal(0, sd_structured_slope^2 A_structured)
```

where `A_structured` is the tree, pair-of-trees Kronecker field, coordinate,
animal-model, or user-supplied relatedness covariance implied by `phylo()`,
`phylo_interaction()`, `spatial()`, `animal()`, or `relmat()`. The
`phylo_interaction()` count route remains intercept-only; the one-slope count
route is currently for `phylo()`, `spatial()`, `animal()`, and `relmat()`. The TMB template
still uses the sparse precision `Q_phylo`, the latent vector `u_phylo`, and the
direct SD target `log_sd_phylo` for this shared
q=1 count route. This route is implemented for ordinary non-zero-inflated
Poisson and NB2 with one unlabelled q=1 structured `mu` intercept or
intercept-plus-one-slope term. It is not a pure structured slope, not a
multiple-slope route, not a labelled q=2/q=4 count block, and not a
zero-inflated structured route.

One scoped exception to the single-structured-type rule now exists on the
ordinary (non-zero-inflated) NB2 count location. Exactly two intercept-only
structured `mu` providers of distinct types may be combined — for example
`spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q)` on a crossed
`site x id` design. The two fields carry separate group precisions (a spatial
coordinate kernel and a relatedness `Q`), so the TMB template adds a second
scoped field alongside the shared one: the sparse precision `Q_phylo2`, the
latent vector `u_phylo2`, and the direct SD target `log_sd_phylo2`. Each field
contributes an independent scalar GMRF (q=1, no among-endpoint correlation) to
the count `eta` and to the joint negative log-likelihood. The two summaries stay
addressable: `sdpars$mu` holds both SDs under their term labels, `ranef()`
exposes both structured blocks (for example `spatial_mu` and `relmat_mu`), and
`profile_targets()` lists both `sd:mu:` rows as direct targets. Every other
combination of more than one structured type — any slope-bearing pair, any
zero-inflated pair, any three-or-more-provider request, and every non-count
family — is still rejected pre-optimization; fit those structured layers one at a
time until their own combined-dependence recovery evidence exists. Users who need
a different structured combination should split the model into single-provider
fits for now.

The simulation-runner and artifact contract for promoting the phylogenetic route
beyond smoke-level evidence is recorded in
`docs/design/72-poisson-phylo-q1-runner-contract.md`; the spatial, animal, and
`relmat()` count routes currently have focused source-level recovery tests, and
the `phylo_interaction()` route has focused Gaussian, Poisson, and NB2 smoke
tests for the first pair-level field.

For Poisson fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
count mean. There is no fitted `sigma` distributional parameter; `sigma(fit)`
returns a fixed unit dispersion vector for compatibility with base-R method
expectations. The response must contain non-negative integer counts after
missing-row filtering. MD9a allows one fixed-effect binary missing predictor in
an ordinary Poisson mean model; broader missing-predictor Poisson response
routes are not implied by the ordinary count likelihood. Known sampling
covariance, overdispersion, zero-inflated structured effects outside the exact
diagnostic-only `zi ~ spatial()` and fixed-`zi`
`mu ~ spatial()` intercept gates, bivariate Poisson, and mixed-response Poisson
models are later phases.

## Implemented Zero-Inflated Poisson Mean

Zero-inflated Poisson models reuse the ordinary Poisson family route and add a
formula for the structural-zero probability:

```text
y_i | mu_i, zi_i ~ zero-inflated Poisson(mu_i, zi_i)
eta_mu_i = o_i + X_mu[i, ] beta_mu
eta_zi_i = X_zi[i, ] beta_zi
mu_i = exp(eta_mu_i)
zi_i = logit^{-1}(eta_zi_i)
```

The probability mass is:

```text
Pr(y_i = 0) = zi_i + (1 - zi_i) exp(-mu_i)
Pr(y_i = y > 0) = (1 - zi_i) Poisson(y | mu_i)
E[y_i] = (1 - zi_i) mu_i
Var[y_i] = (1 - zi_i) mu_i (1 + zi_i mu_i)
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat + offset(log(trap_nights)), zi ~ treatment),
  family = poisson(link = "log"),
  data = dat
)
```

Here `mu` is the conditional count mean among observations that are not
structural zeros. The structural-zero probability is `zi`, not a scale
parameter. Consequently, `predict(fit, dpar = "mu")` returns the conditional
mean, `predict(fit, dpar = "zi")` returns the zero-inflation probability, and
`fitted(fit)` returns the unconditional response mean `(1 - zi) * mu`.
`sigma(fit)` returns a fixed unit dispersion vector because no residual scale
parameter is fitted.

## Implemented Negative Binomial 2 Mean-Dispersion

The first overdispersed count path is fixed-effect NB2 regression:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
eta_mu_i = o_i + X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
size_i = 1 / sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i + sigma_i^2 * mu_i^2
```

The TMB likelihood matches the `stats::dnbinom(mu = mu_i, size = size_i)`
mean parameterization:

```text
log f(y_i) =
  log Gamma(y_i + size_i) - log Gamma(size_i) - log Gamma(y_i + 1) +
  size_i [log(size_i) - log(size_i + mu_i)] +
  y_i [log(mu_i) - log(size_i + mu_i)]
```

The C++ template evaluates an algebraically equivalent form that cancels the
unstable `size_i = 1 / sigma_i^2` terms. With
`alpha_i = sigma_i^2`, it uses

```text
log f(y_i) =
  y_i eta_mu_i - log Gamma(y_i + 1)
  + C(y_i, alpha_i)
  - y_i log(1 + alpha_i mu_i)
  - log(1 + alpha_i mu_i) / alpha_i
```

where

```text
C(y_i, alpha_i) =
  sum_{j = 0}^{y_i - 1} log(1 + alpha_i j)
```

The template evaluates `C(y_i, alpha_i)` without an observed-count loop. For
ordinary count and overdispersion values it uses the closed form

```text
C(y_i, alpha_i) =
  log Gamma(y_i + 1 / alpha_i) -
  log Gamma(1 / alpha_i) +
  y_i log(alpha_i).
```

When `alpha_i y_i` is very small, the template uses the matching power-sum
series for `sum log(1 + alpha_i j)` to preserve the Poisson limit.

This form has the correct Poisson limit as `alpha_i` approaches zero and avoids
overflow from computing very large `size_i` or looping over very large observed
counts.

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat + offset(log(trap_nights)), sigma ~ treatment),
  family = nbinom2(),
  data = dat
)
```

For `nbinom2()` fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
count mean. `sigma(fit)` returns the overdispersion scale in the variance
equation, not a residual standard deviation. Larger `sigma` means greater
extra-Poisson variation. Ordinary `mu` random intercepts and independent
numeric slopes are fitted for non-zero-inflated NB2 models. Ordinary
non-zero-inflated NB2 also fits one independent grouped random intercept in the
`sigma` formula:

```text
eta_mu_i = o_i + X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma + b_id[i]
b ~ Normal(0, sd_sigma^2)
```

This grouped effect is overdispersion heterogeneity on the log-`sigma` scale.
It is not a residual SD in the Gaussian sense and it is not a Poisson scale
parameter. The first structured NB2 route is the q=1 phylogenetic `mu`
intercept:

```text
eta_mu_i = o_i + X_mu[i, ] beta_mu + a_species[i]
a ~ Normal(0, sd_phylo^2 A)
eta_sigma_i = X_sigma[i, ] beta_sigma
```

This adds the same sparse `Q_phylo`, latent `u_phylo`, and direct
`log_sd_phylo` target as the ordinary Poisson q=1 route, but the count
likelihood remains NB2 and `sigma` remains fixed-effect overdispersion. It is
implemented for ordinary non-zero-inflated NB2 with one unlabelled q=1
structured `mu` intercept or intercept-plus-one-slope term from `phylo()`,
`spatial()`, `animal()`, or `relmat()`, or with one `phylo_interaction()`
intercept for a two-partner Kronecker field. Exact q1 structured `sigma`
intercept-plus-one-slope routes for those four single providers are recovery
grade. One exact crossed
`mu ~ spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q)` route is
also recovery-only: both variance components recover on the crossed design,
but it has no interval or coverage promotion. Correlated NB2 slope blocks,
pure or multiple structured slopes, labelled covariance blocks, ordinary NB2
`sigma` slopes, labelled or joint `mu`/`sigma` covariance, richer or labelled
structured `sigma`, zero-inflated NB2 random or structured effects outside the
exact diagnostic-only fixed-`zi` `mu ~ spatial()` intercept gate,
simultaneous structured types beyond the exact crossed gate, binary incidence,
known sampling covariance, and bivariate or mixed negative-binomial models are
later phases.

## Implemented Zero-Truncated Negative Binomial 2

The positive-count NB2 path is fixed-effect zero-truncated regression:

```text
y_i | y_i > 0, mu_i, sigma_i ~ NB2(mu_i, size_i) truncated at zero
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
size_i = 1 / sigma_i^2
Z_i = 1 - NB2(0 | mu_i, size_i)
Pr(y_i = k | y_i > 0) = NB2(k | mu_i, size_i) / Z_i
E[y_i | y_i > 0] = mu_i / Z_i
```

The TMB branch reuses the AD-stable NB2 log-density and subtracts the
normalising constant:

```text
log f_trunc(y_i) = log f_NB2(y_i) - log(Z_i)
```

where `log(Z_i) = log(1 - exp(log Pr_NB2(0)))` is evaluated with a small
`log(1 - exp(x))` helper to avoid cancellation when almost all mass is at
zero. Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat, sigma ~ treatment),
  family = truncated_nbinom2(),
  data = dat
)

drmTMB(
  bf(count ~ habitat + (0 + habitat_score | site), sigma ~ treatment),
  family = truncated_nbinom2(),
  data = dat
)
```

For `truncated_nbinom2()` fits, `predict(fit, dpar = "mu")` returns the
untruncated NB2 component mean, `sigma(fit)` returns the NB2 overdispersion
scale, and `fitted(fit)` returns the observed positive-count mean
`mu / (1 - Pr_NB2(0))`. The response must contain positive integer counts
after missing-row filtering unless a hurdle formula is supplied. Ordinary
unlabelled `mu` random intercepts and independent numeric slopes enter the
log-mean predictor for non-hurdle zero-truncated NB2 models. The exact
`hu ~ relmat(1 | id, K/Q = ...)` q1 intercept is diagnostic-only when the hurdle
route is active; ordinary count-side `mu` random effects are then blocked.
Correlated slopes, labelled covariance blocks, other hurdle-side random
effects, `sigma` random effects, other structured terms, and bivariate count
models are later phases.

## Implemented Hurdle Negative Binomial 2

Hurdle NB2 models reuse `truncated_nbinom2()` and add a formula for the
hurdle-zero probability:

```text
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_hu_i = X_hu[i, ] beta_hu
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
hu_i = logit^{-1}(eta_hu_i)
size_i = 1 / sigma_i^2
Z_i = 1 - NB2(0 | mu_i, size_i)
```

The probability mass is:

```text
Pr(y_i = 0) = hu_i
Pr(y_i = k > 0) = (1 - hu_i) NB2(k | mu_i, size_i) / Z_i
E[y_i] = (1 - hu_i) mu_i / Z_i
```

The response variance used by Pearson residuals is the mixture variance:

```text
m_i = mu_i / Z_i
v_i = Var_NB2(y_i | y_i > 0, mu_i, sigma_i)
Var(y_i) = (1 - hu_i) v_i + hu_i (1 - hu_i) m_i^2
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat, sigma ~ treatment, hu ~ survey_method),
  family = truncated_nbinom2(),
  data = dat
)
```

Here `mu` and `sigma` continue to describe the untruncated NB2 component.
`predict(fit, dpar = "hu")` returns the hurdle-zero probability. `fitted(fit)`
returns the unconditional response mean `(1 - hu) * mu / (1 - Pr_NB2(0))`.
Zeros are allowed only when the `hu` formula is present, and at least one
positive count must remain after missing-row filtering.

## Implemented Zero-Inflated Negative Binomial 2

Zero-inflated NB2 models reuse `nbinom2()` and add a formula for the
structural-zero probability:

```text
y_i | mu_i, sigma_i, zi_i ~ zero-inflated NB2(mu_i, sigma_i, zi_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_zi_i = X_zi[i, ] beta_zi
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
zi_i = logit^{-1}(eta_zi_i)
size_i = 1 / sigma_i^2
```

The probability mass is:

```text
Pr(y_i = 0) = zi_i + (1 - zi_i) NB2(0 | mu_i, size_i)
Pr(y_i = y > 0) = (1 - zi_i) NB2(y | mu_i, size_i)
E[y_i] = (1 - zi_i) mu_i
Var[y_i] = (1 - zi_i) (mu_i + sigma_i^2 mu_i^2) + zi_i (1 - zi_i) mu_i^2
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat, sigma ~ treatment, zi ~ survey_method),
  family = nbinom2(),
  data = dat
)
```

Here `mu` is the conditional NB2 mean among observations that are not
structural zeros, `sigma` is the conditional NB2 overdispersion scale, and `zi`
is the structural-zero probability. Consequently, `predict(fit, dpar = "mu")`
returns the conditional mean, `sigma(fit)` returns the conditional
overdispersion scale, `predict(fit, dpar = "zi")` returns the zero-inflation
probability, and `fitted(fit)` returns `(1 - zi) * mu`.

## Implemented Bivariate Meta-Analytic Gaussian Regression

Bivariate meta-analysis must add known sampling covariance to the bivariate
Gaussian location-coscale likelihood. For observation or study `i`:

```text
y_i = [y1_i, y2_i]'
mu_i = [mu1_i, mu2_i]'

y_i | mu_i, S_i, Omega_i ~ MVN(mu_i, S_i + Omega_i)

S_i =
  [v1_i,   c12_i;
   c12_i, v2_i]

Omega_i =
  [sigma1_i^2,                  rho12_i sigma1_i sigma2_i;
   rho12_i sigma1_i sigma2_i,   sigma2_i^2]
```

`S_i` is known within-study sampling covariance supplied by `meta_V(V = V)`.
`Omega_i` is the unknown residual heterogeneity
covariance after known sampling covariance has been included. The fitted
`rho12_i` is not the known within-study sampling correlation; it should only be
called study-level if a separate study-level random effect is fitted.

Equivalently, with row-paired stacking:

```text
y_stack = [y1_1, y2_1, y1_2, y2_2, ..., y1_n, y2_n]'
y_stack ~ MVN(mu_stack, V_stack + Omega_stack)
```

where `V_stack` is the supplied known sampling covariance and `Omega_stack`
contains the fitted `sigma1`, `sigma2`, and `rho12` blocks.

The current dense-known-`V` implementation:

- requires complete bivariate rows;
- accepts a `2n` by `2n` dense or block-diagonal `V` in row-paired order;
- rejects duplicate `meta_V()` / deprecated `meta_known_V()` markers across
  `mu1` and `mu2`;
- provides `meta_vcov_bivariate()` to build the common block-diagonal `V` from
  `v1`, `v2`, and
  either `cov12` or `cor12`;
- documents sensitivity analysis when within-study correlations are unknown.

## Implemented Bivariate Gaussian Location-Coscale

Bivariate Gaussian location-coscale:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
mu1_i = X_mu1[i, ] beta_mu1 + b1_group[i]
mu2_i = X_mu2[i, ] beta_mu2 + b2_group[i]
log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = tanh(eta_rho12_i)
Omega_i[1,1] = sigma1_i^2
Omega_i[2,2] = sigma2_i^2
Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i
```

For fixed-effect models, `b1_group[i]` and `b2_group[i]` are zero. With matching
labelled random-intercept terms in `mu1` and `mu2`, they come from a
group-level covariance block:

```text
[b1_j, b2_j]' = diag(sd_mu1_id, sd_mu2_id) L_group [u1_j, u2_j]'
[u1_j, u2_j]' ~ Normal([0, 0]', I)
L_group =
  [1,          0;
   rho_group, sqrt(1 - rho_group^2)]
rho_group = 0.999999 * tanh(eta_cor_mu)
```

With matching `phylo(1 | species, tree = tree)` terms in `mu1` and `mu2`,
the two phylogenetic mean deviations use the same augmented tree precision and
a two-state covariance matrix:

```text
a = [a_mu1, a_mu2]
a ~ MatrixNormal(0, Q_A^{-1}, Sigma_phylo)
Sigma_phylo =
  [sd_phylo_mu1^2, rho_phylo * sd_phylo_mu1 * sd_phylo_mu2;
   rho_phylo * sd_phylo_mu1 * sd_phylo_mu2, sd_phylo_mu2^2]
rho_phylo = 0.999999 * tanh(eta_cor_phylo)

mu1_i = X_mu1[i, ] beta_mu1 + a_mu1[species_i]
mu2_i = X_mu2[i, ] beta_mu2 + a_mu2[species_i]
```

Here `rho_phylo` is a phylogenetic mean-mean correlation, not residual
`rho12`. In this first fitted slice, `sigma1`, `sigma2`, and `rho12` remain
ordinary fixed-effect distributional parameters.

With labelled all-four phylogenetic terms, the same augmented tree precision
can carry four endpoint deviations:

```text
a = [a_mu1, a_mu2, a_sigma1, a_sigma2]
a ~ MatrixNormal(0, Q_A^{-1}, Sigma_phylo_q4)

mu1_i = X_mu1[i, ] beta_mu1 + a_mu1[species_i]
mu2_i = X_mu2[i, ] beta_mu2 + a_mu2[species_i]
log(sigma1_i) = X_sigma1[i, ] beta_sigma1 + a_sigma1[species_i]
log(sigma2_i) = X_sigma2[i, ] beta_sigma2 + a_sigma2[species_i]
```

If all four endpoints use the same label, `Sigma_phylo_q4` is one
unstructured four-endpoint covariance matrix and `corpairs()` reports six
phylogenetic rows. If `mu1`/`mu2` share one label and `sigma1`/`sigma2` share
another label for the same tree, `Sigma_phylo_q4` is block diagonal:

```text
Sigma_phylo_q4 =
  blockdiag(Sigma_phylo_location, Sigma_phylo_scale)
```

The block-diagonal fallback reports only the mean-mean and scale-scale
phylogenetic correlations. It deliberately omits mean-scale phylogenetic rows,
which is useful when a full q=4 block is too weakly identified but the protocol
still needs a phylogenetic scale-scale check.

The TMB implementation uses tiny boundary guards around `tanh()` for numerical
positive definiteness; the clean transforms above are the statistical model.

Location formulas for the two responses may differ. `rho12` is residual
response-response correlation, not a group-level random-effect correlation.

Implemented fixed-effect syntax:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + x2,
    mu2 = y2 ~ x1,
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

Implemented bivariate group-level random-intercept syntax:

```r
drmTMB(
  formula = bf(
    mu1 = y1 ~ x1 + x2 + (1 | p | ID),
    mu2 = y2 ~ x1      + (1 | p | ID),
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

Here the shared `p` label says that the two response-specific random intercepts
belong to one group-level covariance block. The model reports
`sdpars$mu["mu1:(1 | p | ID)"]`, `sdpars$mu["mu2:(1 | p | ID)"]`, and
`corpars$mu["cor(mu1:(Intercept),mu2:(Intercept) | p | ID)"]`.

Implemented slope-only bivariate group-level covariance syntax:

```r
drmTMB(
  formula = bf(
    mu1 = y1 ~ x1 + x2 + (0 + x2 | p | ID),
    mu2 = y2 ~ x1      + (0 + x2 | p | ID),
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

Here the shared `p` label and matching slope term fit one group-level
slope-slope correlation. The model reports
`sdpars$mu["mu1:(0 + x2 | p | ID)"]`,
`sdpars$mu["mu2:(0 + x2 | p | ID)"]`, and
`corpars$mu["cor(mu1:x2,mu2:x2 | p | ID)"]`; `corpairs()` and
`summary(fit)$covariance` expose the row with `class = "slope-slope"`. This is
an extractor and fitted-model gate, not a promotion of simulation recovery or a
new `rho12` path.

Implemented one-slope q=4 bivariate location covariance syntax:

```r
drmTMB(
  formula = bf(
    mu1 = y1 ~ x1 + x2 + (1 + x2 | p | ID),
    mu2 = y2 ~ x1      + (1 + x2 | p | ID),
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

Here the shared `p` label and matching intercept-plus-slope term fit one q=4
location block:

```text
mu1_ij = X_mu1[ij, ] beta_mu1 + b_0_1j + b_x_1j x_ij
mu2_ij = X_mu2[ij, ] beta_mu2 + b_0_2j + b_x_2j x_ij
[b_0_1j, b_x_1j, b_0_2j, b_x_2j]' ~ MVN(0, Sigma_mu_ID)
```

The correlations inside `Sigma_mu_ID` are group-level correlations among
location random effects. They are not residual `rho12`. The four SDs are direct
`log_sd_re_cov` profile targets exposed through `sdpars$mu`; the six q=4
correlations are derived rows in `corpars$re_cov`, `corpairs()`, and
`summary(fit)$covariance` with unavailable direct intervals.

The same location-only machinery also supports matching q=6 blocks with smoke
artifact routing when the two response formulas contain the same intercept plus
two numeric location coefficients:

```r
drmTMB(
  formula = bf(
    mu1 = y1 ~ x + z + (1 + x + z | p | ID),
    mu2 = y2 ~ x + z + (1 + x + z | p | ID),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

This block estimates six location SDs and 15 group-level location
correlations. The q=6 SDs are direct `log_sd_re_cov` profile targets, and the
15 correlations are derived-unavailable interval rows in `corpars$re_cov`,
`corpairs()`, and `summary(fit)$covariance`.

Broader planned double-hierarchical bivariate syntax with simultaneous
location and scale random slopes:

```r
drmTMB(
  formula = bf(
    mu1 = y1 ~ x1 + x2 + (1 + x2 | p | ID),
    mu2 = y2 ~ x1      + (1 + x2 | p | ID),
    sigma1 = ~ x1 + x2 + (1 + x2 | p | ID),
    sigma2 = ~ x1      + (1 + x2 | p | ID),
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

This all-four one-slope endpoint would have eight latent effects per group and
therefore 8 SDs and 28 correlations. It remains planned until endpoint naming,
all-four block assembly, diagnostics, recovery tests, and interval-status rules
exist.

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma1` and `sigma2` use log links.
- `rho12` uses `eta_rho12 = X_rho12 beta_rho12` and a bounded tanh transform
  `rho12 = 0.999999 * tanh(eta_rho12)` on the response scale so the
  covariance matrix stays positive definite even for extreme linear predictors.
- Simulation recovery tests live in `tests/testthat/test-biv-gaussian.R`.
- `mvbind(y1, y2) ~ x` is implemented as a formula shorthand that creates
  identical `mu1` and `mu2` design matrices.
- Dense known sampling covariance is implemented for complete-row bivariate
  Gaussian models through `meta_V(V = V)`, with deprecated
  `meta_known_V(V = V)` as a compatibility alias. Here `V` is a row-paired
  `2n` by `2n` matrix added to the fitted residual covariance.
- Matching labelled random intercepts in `mu1`/`mu2` and `sigma1`/`sigma2` are
  implemented as same-parameter group-level covariance blocks. They cannot yet
  be combined with `meta_V(V = V)`.
- Matching slope-only, q=4 one-slope, and q=6 two-slope labelled
  blocks in `mu1`/`mu2` are implemented as ordinary group-level location
  covariance blocks with smoke artifact routing for the q=4 and q=6 location
  routes. They cannot yet be combined with `meta_V(V = V)`, residual-scale
  slopes, or same-response location-scale slope covariance inside one larger
  block.
- One same-response `mu`/`sigma` covariance pair is implemented for `mu1` with
  `sigma1` or `mu2` with `sigma2`; the fitted q2 cases are matching random
  intercepts or matching slope-only terms such as `(0 + x | p | id)`.
- Reusing the same label in all four `mu1`, `mu2`, `sigma1`, and `sigma2`
  random-intercept formulas fits one ordinary q=4 latent covariance block:

  ```text
  u_j = [b_mu1_j, b_mu2_j, a_sigma1_j, a_sigma2_j]'
  u_j ~ MVN(0, Sigma_id)
  ```

  The `a_sigma*` entries enter `log(sigma*)`, so their SDs and correlations
  live on the residual-scale linear-predictor scale. The six correlations in
  `Sigma_id` are group-level latent correlations and remain separate from
  residual `rho12`.
- Family B direct location-SD formulas such as `sd1(id) ~ x_group` and
  `sd2(id) ~ x_group` are rejected for the same group when this q=4 block is
  present. Combining them would require a predictor-dependent q=4 covariance
  model, not the current constant q=4 block.
- The univariate Family B `sd_phylo(species) ~ x_species` model uses a
  non-centred tip-scaling contract. A unit phylogenetic base effect `v_aug`
  follows the sparse augmented tree precision, while the observed tip
  contribution is multiplied by `tau_l = exp(W_l alpha)`. The implied tip
  covariance is `D_tip A_tip D_tip`; internal nodes do not receive
  user-facing SD predictors. This direct-SD formula replaces the scalar
  `log_sd_phylo` target for the univariate location `phylo()` effect rather
  than adding a second SD layer.
- The implemented bivariate Family B direct-SD extension uses
  `sd_phylo1(species) ~ z1` for the `mu1` phylogenetic location-effect SD and
  `sd_phylo2(species) ~ z2` for the `mu2` phylogenetic location-effect SD. With
  a constant latent phylogenetic location-location correlation `rho_phylo`, the
  cross-response tip covariance is
  `Cov(a1_l, a2_m) = rho_phylo tau1_l A_lm tau2_m`. These formulas replace
  endpoint location SD parameters only; they do not target residual `sigma1`,
  residual `sigma2`, q=4 location-scale endpoint SDs, or residual `rho12`.
- Residual-scale bivariate slope covariance, all-four location-scale slope
  endpoints, `rho12` random effects, phylogenetic random slopes, and
  predictor-dependent q=4 phylogenetic or spatial correlations remain planned.
  The first ordinary matching slope-only, same-response q2 slope, and
  smoke-artifact-routed q=4/q=6 location `mu1`/`mu2` blocks are implemented, as
  are the first constant intercept-only bivariate phylogenetic/spatial q=4
  blocks for matching labelled terms in `mu1`, `mu2`, `sigma1`, and `sigma2`.
  The structured q=4 path supports the full one-label block and the two-label
  block-diagonal fallback where admitted by the structured layer.
- The selected q=2 predictor-dependent phylogenetic `corpair()` contract uses
  two independent unit tree fields and species-specific loadings. For each
  species `l`, `rho_l = tanh_guard(W_l alpha)`,
  `c_l = sqrt((1 + rho_l) / 2)`, and
  `d_l = sqrt((1 - rho_l) / 2)`, with
  `a1_l = tau1(c_l z1_l + d_l z2_l)` and
  `a2_l = tau2(c_l z1_l - d_l z2_l)`. This guarantees a positive-definite
  full phylogenetic covariance and reduces to the implemented constant
  bivariate phylogenetic covariance when `rho_l` is constant. The fitted
  implementation uses two independent unit augmented-tree effects and applies
  the loading transformation at observed tip nodes. This contract targets
  `mu1`-`mu2` only; predictor-dependent phylogenetic location-scale and
  scale-scale correlations require a q=4 contract.

## Review Requirements

Every likelihood must have simulation recovery tests before being treated as
implemented.

# Random-Effect Scale Models

This note is the design contract for random-effect scale formulae such as
`sd(id) ~ x_group`. The univariate Gaussian route supports one or more distinct
unlabelled `mu` random-intercept targets. Native TMB also supports a q1
Gaussian animal-model location intercept with a predictor-dependent SD using a
pedigree, labelled covariance matrix `A`, or its precision matrix `Ainv`. Its
synthetic checks cover point recovery, named SD prediction, marginal simulation,
save/reload, constant-SD equivalence, and within-animal predictor validation.
The pedigree test leaves sires and dams unobserved and verifies that the fitted
route retains them as latent relationship nodes. A separate comparison confirms
matching likelihoods, SD coefficients, and named predictions for equivalent
`A` and `Ainv` inputs;
Julia parity and interval calibration remain unverified. Native TMB also supports Bernoulli
ordinary random-intercept SD regression, one independent numeric random-slope
SD, and an ordinary intercept plus one phylogenetic intercept. A native Gamma
q1 phylogenetic location-intercept route also has a focused synthetic
point-recovery, named-prediction, and constant-SD-equivalence test; its
intervals and Julia parity remain unverified.

For ordinary Bernoulli SD targets on the Julia candidate, `predict()` names
stored group predictions with the group labels, matching native TMB. The
fitted `sdpars` vectors retain target-qualified names. The focused crossed
two-group test checks this distinction and compares the target coefficients,
likelihood, and `predict_parameters()` output with native TMB; it does not
establish wider Julia parity or calibrated uncertainty.
The corresponding q1 Gamma `relmat()` location-intercept route has the same
native point-fit evidence, including a reordered-kernel test; its intervals and
Julia parity are also unverified.
Non-Gaussian Julia SD-regression routes described in this note are
development-candidate-only. They require a local DRM.jl candidate source
checkout paired with this drmTMB candidate; current shared/released DRM.jl
provides the Gaussian `sd()` route but not these family routes. Julia bridge
checks therefore establish candidate workflow behavior only, not release
support or general cross-engine parity. The Bernoulli candidate accepts separate
SD formulas for independent scalar Bernoulli coefficients on the same group
when each formula selects its coefficient explicitly. In Julia, the candidate
syntax is `sd(group, coef(intercept))` for the intercept and
`sd(group, coef(x))` for the `x` slope. The two latent terms must be separate
independent terms, such as `(1 | group) + (0 + x | group)`. A correlated
`(1 + x | group)` block is not part of that independent-coefficient route; one
q=2 correlated block has separate, narrowly tested candidate coverage below.
The live bridge check covers recovery, coefficient-specific prediction, and
profile/bootstrap refit routing. Those interval checks are plumbing evidence,
not calibration; the current synthetic fit also produced singular-Hessian
warnings during refits.
Native complete-data ordinary `mu` random-intercept slices are also
implemented for NB2, Gamma, Tweedie, Beta, beta-binomial, cumulative-logit,
Student-t, skew-normal, zero-truncated NB2, and zero-inflated NB2. The
zero-inflated NB2 slice requires complete responses, one ordinary `mu`
intercept, and fixed-effect intercepts for `sigma` and `zi`; its recovery and
independent groupwise Laplace check are not interval-calibration evidence.
NB2 additionally supports one complete-data ordinary independent numeric `mu`
slope with `sigma ~ 1` in native TMB and the development Julia candidate. The
candidate route requires matched local source checkouts and is absent from the
current shared/released DRM.jl companion. Synthetic recovery, an independent
slope-loading likelihood oracle, public SD outputs, and one matched-data
coefficient comparison pass; that single comparison does not establish general
engine parity or interval calibration. Outside the explicit Poisson,
Bernoulli, Gamma, NB2, and Student-t ordinary slope routes, the documented
structured-intercept SD cells, plus the Poisson, NB2, and Gamma q1 animal slope-only SD routes,
other random slopes, structured effects, and random-effect targets remain
separate work. The
cumulative-logit slice requires complete responses and one ordinary `mu`
intercept. Its synthetic recovery, independent groupwise Gaussian integration,
wrong-index control, constant-SD equivalence, prediction, simulation, and
save/reload checks pass; this is not interval-calibration evidence. The
zero-truncated NB2 slice also requires complete responses and one ordinary `mu`
intercept with no hurdle formula;
synthetic recovery, independent truncated-likelihood integration,
wrong-index control, constant-SD equivalence, prediction, simulation, and
save/reload checks pass, without interval-calibration evidence. A separate native `zero_one_beta()` slice admits one ordinary
`mu` intercept or one independent numeric slope with a matching selected SD
formula when responses are complete and all other endpoints have no
random effects. Its synthetic recovery, independent marginal-likelihood
quadrature, wrong-index control, constant-SD equivalence, prediction,
simulation, save/reload, profile, and bootstrap-refit checks pass; these are
not interval-calibration results. One seeded fit with `se = TRUE` converged
with `pdHess = TRUE`, which checks fit health but does not establish interval
coverage. The matching selected-slope route also fits through the Julia
development candidate and R bridge, with same-data recovery-direction and
group-SD output checks; interval calibration remains open. Hurdle NB2 separately admits one ordinary `mu` intercept with an
optional group-level SD regression when responses are complete, `sigma` is
fixed-effect only, and no structured location effect is present. The intercept
acts only in the positive-count component; recovery and workflow checks pass,
but interval calibration remains open. Gamma intercept and independent-slope SD regression each have one
synthetic recovery fit; Gamma intercept and Tweedie also have a constant-SD
equivalence check. Beta has one higher-information recovery fit
and a constant-SD equivalence check; beta-binomial has one synthetic recovery
fit, independent one-dimensional marginal-likelihood quadrature, constant-SD
equivalence, and profile/bootstrap routing checks; Student-t and skew-normal
each have one synthetic recovery fit. Native Student-t also supports one
complete-data ordinary independent location-slope SD target, with a
slope-loading Laplace oracle, wrong-group control, target-aware
profile/bootstrap routing, prediction, simulation, save/reload, and
constant-SD equivalence. The development Julia candidate also has a separate
ordinary Student-t intercept or independent-slope route with fixed
`sigma ~ 1` and `nu ~ 1`; it requires a matching local DRM.jl candidate
checkout and is absent from current shared/released DRM.jl. Its live R bridge
has not yet been checked for the slope. These checks are not interval
calibration. Other family and random-effect combinations remain separate work.

The Gamma route currently requires complete responses, fixed-effect `sigma`,
and one location random-effect layer. Alongside ordinary random intercepts and
independent numeric slopes, it admits a q1 animal-model intercept with a
predictor-dependent scale using pedigree, covariance (`A`), or precision
(`Ainv`) input, for example `animal(1 | id, pedigree = pedigree)` with
`sd(id, level = "animal") ~ z`. The animal scale retains the existing
relationship scaling without normalizing its diagonal. Synthetic fits check
recovery with pedigree input, while covariance and precision forms are checked
for matching likelihoods. One live same-data comparison with the development
Julia candidate checks SD coefficients and group-level SD predictions for a
unit-diagonal supplied covariance. It is one point-parity fixture: non-unit
covariance scaling, interval calibration, and other animal layouts remain
unverified. A separate complete-data route also supports one q1
animal slope-only coefficient, for example
`animal(0 + x | id, pedigree = pedigree)` with `sd(id, level = "animal") ~ z`.
Its fixed-seed test checks slope recovery, name-keyed SD prediction,
constant-SD equivalence, and rejection of within-animal variation and
multi-coefficient blocks. Interval calibration and Julia parity remain open.
Native Gamma also admits one complete-data q2 animal location term containing
an intercept and one numeric slope as two independent latent fields. Give each
field its own SD formula with an explicit coefficient selector:

```r
bf(
  y ~ x + animal(1 + x | id, pedigree = pedigree),
  sigma ~ 1,
  sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0,
  sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1
)
```

The model is `u0, u1 ~ N(0, A)` independently and adds
`tau0_g * u0_g + x_i * tau1_g * u1_g` to the log mean. Thus its latent
covariance is `A[g, h] * (tau0_g * tau0_h + x_i * x_j * tau1_g * tau1_h)`;
the two animal fields are not a correlated intercept-slope block unless the
term is written in the labelled `animal(1 + x | p | id)` form, which adds one
estimated correlation (native only; see the end of this note). The focused
synthetic test checks separate SD-slope recovery, coefficient-specific group
predictions, simulation, save/reload, constant-SD equivalence, and refusal of
an identically zero slope loading or a globally constant slope with identical
constant SD designs. The combined q2 evidence currently uses a unit-diagonal
pedigree covariance; it does not close the separate Gamma q1 animal slope-only
`A`/`Ainv` provider
rows. Interval calibration and Julia parity remain open.
For Gamma, a separate complete-data route allows one ordinary `sigma`
random intercept or one independent numeric random slope with a matching
`sd(group, dpar = "sigma") ~ predictors` formula while `mu` is
fixed-effect-only. The SD predictor must be constant within group. Here the
formula models the SD of the latent effect on `log(sigma)`, where Gamma
`sigma` is the coefficient of variation. Seeded recovery, finite coefficient
covariance, group SD prediction, conditional sigma output, save/reload,
within-group validation, and constant-SD equivalence are checked for the
intercept route. The independent-slope route has focused synthetic recovery,
finite SD-coefficient covariance, and group-SD prediction checks. Both are
native TMB point-fit evidence, not interval calibration. The route does not
combine with existing Gamma `mu` SD
routes; Julia parity remains open. Other structured providers, correlated
coefficients, and combinations with additional random-effect layers remain
separate work.
The Tweedie route has the same ordinary-intercept and complete-response limits;
both `sigma` and `nu` must remain fixed-effect formulas. The Beta route also
requires complete responses, one ordinary `mu` intercept, and fixed-effect
`sigma`; it cannot be combined with Beta's separate phylogenetic direct-SD
formula in this slice. Its synthetic recovery and constant-SD checks do not
establish interval calibration.

The beta-binomial ordinary route requires complete responses and one ordinary
`mu` random-effect target. Its `sd(group)` predictors must be constant within
group. A separate native TMB route supports one q1 animal intercept with
`sd(id, level = "animal") ~ z`, using pedigree, covariance `A`, or precision
`Ainv` inputs. The predictor changes the animal field's group-level SD on the
logit success-probability scale. All routes keep `sigma` fixed-effect-only, and
`sigma` continues to describe within-observation extra-binomial variation. The
synthetic tests check pedigree recovery, constant-SD equivalence, group-named
predictions and marginal simulation; A/Ainv fits check recovery, prediction,
and likelihood agreement with pedigree after a joint label permutation. Julia
parity, interval calibration, correlated or labelled blocks, structured slopes,
and missing-predictor imputation remain open.

## Core Distinction

`drmTMB` has several scale quantities. They must not be collapsed into one
word.

| Quantity | Meaning | Example syntax | Implementation status |
|---|---|---|---|
| `sigma_i` | residual or within-observation standard deviation | `sigma ~ x1` | implemented for Gaussian |
| `a_g` | residual-scale random effect added to `log(sigma_i)` | `sigma ~ x1 + (1 | id)` or `sigma ~ x1 + (0 + w | id)` | implemented for univariate Gaussian random intercepts and independent random slopes |
| `sd_sigma_id` | standard deviation of a random effect on the `sigma` linear predictor | `sigma ~ 1 + (1 | id)` or `sigma ~ 1 + (0 + x | id)`, with a matching `sd(id, dpar = "sigma")` or coefficient-selected SD formula | Focused native checks cover Gaussian, LogNormal, Gamma, and NB2 independent `sigma` random slopes; the Gamma case uses fixed `mu` and complete responses. Beta-binomial supports one ordinary `sigma` random intercept or one independent numeric slope, each with a matching SD regression, complete responses, and fixed-effect-only `mu`. These are point-recovery/output checks, not general family parity or calibrated uncertainty; the development Julia bridge has one same-data point-estimate check each for the Gamma `sigma` intercept and independent slope |
| `sd_mu_id` | standard deviation of a `mu` random effect | `sd(id) ~ x_group` | Gaussian ordinary intercepts and one ordinary independent numeric location slope now have focused native TMB recovery and same-data Julia point-parity checks. Native Bernoulli ordinary intercepts and independent numeric slopes, plus coefficient-selected SD formulas for separate independent terms on one group; Poisson ordinary intercepts and one independent numeric slope; Gamma ordinary intercepts and one independent numeric slope; Student-t ordinary intercepts and one independent numeric slope; skew-normal ordinary intercepts and one independent numeric slope; and ordinary NB2 independent numeric slopes in native TMB. Matching non-Gaussian Julia SD routes for Bernoulli, Poisson, Gamma, Student-t, NB2, and LogNormal exist only in the development candidate and require paired local drmTMB/DRM.jl candidate sources; current shared/released DRM.jl does not include them. LogNormal evidence is limited to ordinary `mu` intercept and independent numeric slope routes with fixed `sigma ~ 1`, checked in two same-data point-parity fixtures. One matched-data Student-t slope comparison is a single-cell check, not general engine parity. Complete-data ordinary NB2, zero-inflated NB2, zero-inflated Poisson, Tweedie, Beta, beta-binomial, cumulative-logit, zero-truncated NB2, hurdle NB2 (one ordinary `mu` intercept), and zero-one beta intercept and selected independent numeric `mu` slope SD regressions in native TMB and Julia are supported; skew-normal also has an independent-slope SD route. |
| `sd_mu1_id`, `sd_mu2_id` | response-specific standard deviations of bivariate location random effects | `sd1(id) ~ x_group`, `sd2(id) ~ x_group` | implemented for labelled bivariate Gaussian `mu1`/`mu2` location random intercepts |
| `rho_re` | group-level random-effect correlation | `(1 + x1 | id)` | implemented for one `mu` slope |
| `rho12_i` | residual correlation between two responses | `rho12 ~ x1` | implemented for fixed-effect bivariate Gaussian |

## Sigma And Variance Reporting

The public drmTMB grammar uses `sigma` for residual scale:

```r
bf(y ~ x, sigma ~ z)
```

Keep that public syntax. It matches brms-style distributional formulas and the
project's stable terminology. For individual-difference summaries of
predictability and malleability, the scientific interpretation often concerns
residual variance. Report that as a derived quantity, `sigma^2`, rather than
changing the model grammar to a variance formula.

For log-scale Gaussian models:

```text
log(sigma_i) = eta_sigma_i
sigma_i = exp(eta_sigma_i)
variance_i = sigma_i^2 = exp(2 eta_sigma_i)
```

Thus a coefficient in a log-`sigma` model doubles when expressed on the
log-variance scale. A random-effect variance component on the log-`sigma` scale
is multiplied by four when expressed on the log-variance scale. This conversion
is needed when comparing drmTMB or brms-style `sigma` models with paper-facing
summaries that are written for residual variances.

## Implemented Residual Scale

The implemented fixed-effect Gaussian location-scale model is:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
sigma_i = exp(X_sigma[i, ] beta_sigma)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

The `sigma` formula always targets residual or within-observation scale. If
`x2` is treatment, a positive `sigma` coefficient means observations in that
treatment have larger residual standard deviation after accounting for the
mean model.

## Implemented Residual-Scale Random Intercepts

Residual-scale random intercepts enter the log residual standard deviation:

```text
y_ij | mu_ij, sigma_ij, a_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma + a_j

b_j = sd_mu_id u_j
u_j ~ Normal(0, 1)

a_j = sd_sigma_id v_j
v_j ~ Normal(0, 1)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2 + (1 | id) + (0 + w | id)),
  family = gaussian(),
  data = dat
)
```

Here `sd_sigma_id` is the standard deviation of group-to-group deviations on
the log residual SD scale. It answers a residual-scale heterogeneity question:
do some groups have consistently larger or smaller within-group residual
variation than others?

It does not answer whether the among-group variation in the mean-model random
intercepts changes with a predictor. That is the role of `sd(id) ~ x`.

## Implemented Random-Effect Scale Formula

The simplest random-effect scale model targets one existing unlabelled
univariate Gaussian `mu` random intercept:

```text
y_ij | mu_ij, sigma_ij, b_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
```

Matching implemented R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | id),
    sigma ~ x2,
    sd(id) ~ x_group
  ),
  family = gaussian(),
  data = dat
)
```

The right-hand side of `sd(id) ~ x_group` is group-level. Each predictor in
`W_id` must be constant within levels of `id` after missing-row filtering. If a
predictor varies within `id`, the user should use `sigma ~ predictor` for
residual scale or aggregate/define a group-level predictor before fitting
`sd(id) ~ predictor`.

The group-level SD design must also be identifiable on its face. The shared
builders `build_sd_mu_structure()` (ordinary and sigma-side SD blocks) and
`build_sd_phylo_structure()` (structured providers) call
`check_sd_design_rank()` on the group-first design matrix. It refuses a design
with fewer groups than columns, and a design with `qr(X)$rank < ncol(X)`, and
the message names the SD target (for example `sd(id)` or `sd_phylo(species)`)
and the aliased columns. A design with exactly as many groups as columns and
full rank is accepted. For structured routes the groups counted are the observed
provider levels, not the size of the kernel. This is a necessary condition only:
full rank does not make a q2 coefficient SD design well identified when groups
are few, and the Hessian diagnostic remains the guard for weak information.
Tests: `tests/testthat/test-sd-design-rank-check.R`.

When users supply `newdata` to `predict(fit, dpar = "sd(id)")`, the raw
predictors required by the `sd(id)` right-hand side must be present and
complete. Required numeric predictors must be finite before random-effect scale
model-matrix construction.

Transformed predictor terms on the `sd(id)` right-hand side must also evaluate
to finite design matrix values. For example, a model with `sd(id) ~ log(w_pos)`
rejects `newdata = data.frame(w_pos = 0)` instead of returning an infinite
fitted random-effect SD.

Factor predictors on the `sd(id)` right-hand side use the fitted factor levels
when `newdata` is supplied. Character values that match fitted levels are
accepted and coerced through the fitted coding, while unknown levels error
before random-effect scale model-matrix construction.

Direct-SD `newdata` predictions may contain more than one row. The returned
vector has one value per `newdata` row, uses `rownames(newdata)` as names, and
uses `type = "response"` by default. Response-scale predictions equal the
exponentiated link-scale predictions.

The supplied `newdata` object must be a data frame. A zero-row data frame is a
valid empty prediction grid: direct-SD prediction returns a named length-zero
numeric vector on either link or response scale.

When more than one direct-SD formula is fitted, `newdata` validation is scoped
to the requested `dpar`. For example, `predict(fit, dpar = "sd(id)")` requires
the predictors used by `sd(id) ~ ...` and ignores extra columns used only by a
sibling target such as `sd(site) ~ ...`; missing predictors for the requested
target error before model-matrix construction.

Ecology/evolution interpretation:

```r
drmTMB(
  bf(
    boldness ~ habitat + (1 | id),
    sigma ~ habitat,
    sd(id) ~ habitat
  ),
  family = gaussian(),
  data = dat
)
```

Symbolically:

```text
boldness_ij ~ Normal(mu_ij, sigma_ij^2)
mu_ij = beta_0 + beta_1 habitat_ij + b_j
log(sigma_ij) = gamma_0 + gamma_1 habitat_ij
b_j = sd_id,j u_j
u_j ~ Normal(0, 1)
log(sd_id,j) = alpha_0 + alpha_1 habitat_j
```

This model has two biologically different scale regressions:

- `sigma ~ habitat`: habitat changes within-individual residual
  variability, or predictability.
- `sd(id) ~ habitat`: habitat changes among-individual differences in the
  expected response, or the spread of individual-level intercepts.

This distinction also matches the logic of phylogenetic location-scale models:
a residual scale equation models log residual SD, whereas a random-factor scale
equation models the SD of a structured or unstructured group effect. Box 1 of
the Nakagawa et al. phylogenetic location-scale model paper is the bridge for
future `drmTMB` work: separate scale equations can be written for different
random factors, such as phylogenetic and non-phylogenetic species effects,
without treating all of them as residual `sigma`.

That bridge defines a second model family. In Family A, random effects may
enter `sigma` formulas directly, and future `corpair()` work will describe
correlations among latent location and scale effects. In Family B,
`sd(group)`, `sd1(group)`, and `sd2(group)` model the SD of location random
effects directly. Do not combine both ideas for the same latent layer; for
example, `sigma1 = ~ z + (1 | p | id)` and `sd_sigma1(id) ~ w` are not a valid
first target.

For bivariate Gaussian models, the same boundary also applies to ordinary q=4
Family A blocks. If `(1 | p | id)` is present in `mu1`, `mu2`, `sigma1`, and
`sigma2`, the likelihood already estimates one joint covariance matrix for
the four latent effects. Adding `sd1(id) ~ z` or `sd2(id) ~ z` would try to
make the location-effect SDs predictor-dependent while keeping the four-way
covariance block constant. That hybrid is not an implemented model family, so
the builder rejects it before fitting.

## First Discrete-Response Slice: Bernoulli

For an ordinary Bernoulli random intercept, the group-level SD regression is
on the latent logit scale:

```text
y_ig ~ Bernoulli(p_ig)
logit(p_ig) = X_mu[i, ] beta_mu + b_g
b_g = sd_g u_g
u_g ~ Normal(0, 1)
log(sd_g) = W_g alpha
```

Use the existing formula interface:

```r
fit <- drmTMB(
  bf(y ~ x + (1 | id), sd(id) ~ habitat),
  family = binomial(),
  data = dat,
  engine = "tmb"
)
```

The `sd(id)` predictors must be fixed-effect terms that are constant within
each retained `id`. The fitted SD coefficients are on the log-SD scale;
`fit$sdpars[["sd(id)"]]` and `predict(fit, dpar = "sd(id)")` report positive
group SDs. With fresh `newdata`, `predict()` returns one value per supplied row
and repeats the group SD for rows from the same group. A Bernoulli model has no
free residual `sigma`.

The Bernoulli route also supports one independent numeric random slope. If
`x` is the random-effect covariate, the model is

```text
logit(p_ig) = X_mu[i, ] beta_mu + x_ig b_g
b_g = sd_g u_g,   u_g ~ Normal(0, 1)
log(sd_g) = W_g alpha
```

Use `(0 + x | id)` when the random effect is slope-only:

```r
fit_slope <- drmTMB(
  bf(y ~ x + (0 + x | id), sd(id) ~ habitat),
  family = binomial(),
  data = dat,
  engine = "tmb"
)
```

Here `sd(id)` is the SD of the random coefficient per unit of `x`; the
observation-specific contribution is `x_ig b_g`. A predictor that changes
within group is not valid on the right-hand side of `sd()`. The route has an
independent scalar likelihood oracle, synthetic recovery, constant-SD
equivalence, prediction, simulation, profile, and save/reload checks. One
seeded synthetic slope fit compares the public Julia-candidate and TMB
coefficient and group-SD predictions at absolute tolerances 0.35 and 0.45,
respectively. That isolated comparison does not establish general cross-engine
parity or interval calibration. In native TMB, separate
independent intercept and slope terms on one group can each have a selected
scale model:

```r
bf(
  present ~ temperature + (1 | group) + (0 + temperature | group),
  sd(group, dpar = "mu", coef = "(Intercept)") ~ habitat,
  sd(group, dpar = "mu", coef = "temperature") ~ latitude
)
```

Each right-hand predictor must be constant within `group`. The selectors
distinguish the two independent terms. Native TMB fits this two-formula
extension. The matching Julia syntax and route are available only in the
development candidate and have been exercised with matched local source
checkouts. One separate ordinary correlated q2 intercept-slope slice has
narrow candidate test coverage; its contract and boundaries follow below.
Other correlated blocks and structured effects remain outside this
SD-regression slice.

The live Julia bridge check uses matched local candidate source checkouts. It
covers fitting and public point outputs, including group-level SD extraction,
fresh-data prediction, and save/reload. It also checks recovery of one seeded
intercept/slope truth at 300 groups, and checks that an SD slope keeps its
canonical target through one profile interval and a three-refit
parametric-bootstrap smoke test. Together with the direct Julia candidate
random-slope fit and independent integral checks, these are bounded recovery
and output checks. They do not establish release support, recovery across a
grid, interval reliability, coverage, or a calibrated uncertainty method.
Those remain open alongside other distribution families, same-data numerical
parity for the correlated q2 route, and structured effects.

### Correlated Bernoulli q2 block

One unlabelled logit Bernoulli `(1 + x | id)` block has separate fixed-effect
SD-formula coverage for its intercept and numeric slope in the native TMB
branch and the development Julia candidate. The candidate requires matched
local drmTMB and DRM.jl source checkouts; it is not present in the current
shared/released DRM.jl companion. This is a narrow tested slice, not general
cross-engine parity. Its contract is

```text
log(tau[g, k]) = W[g, k] alpha[k]
b[g] ~ Normal(0, D[g] R D[g])
D[g] = diag(tau[g, 0], tau[g, 1])
R = [[1, rho], [rho, 1]]
rho = tanh(eta_rho)
```

The correlation `rho` is constant across groups. A formula may target either
member or both; an untargeted member keeps its constant SD.

The native R selectors are
`sd(id, dpar = "mu", coef = "(Intercept)")` and
`sd(id, dpar = "mu", coef = "x")`. The development Julia candidate DSL uses
`sd(id, coef(intercept))` and `sd(id, coef(x))`. Native TMB and the
development Julia candidate have focused checks for the two-target likelihood
against independent quadrature, partial-target fitting, covariance
reconstruction, and simulator transforms; the candidate also has a slope-only
bootstrap-refit check. The Julia objective is still non-finite at Fisher-z
`20`. A live R-to-Julia smoke test with matched local candidate source
checkouts covers fitting, target extraction, group-SD prediction, and exact
save/reload preservation for one synthetic dataset. It emitted a
singular-Hessian warning and does not establish reliable standard errors,
release support, or same-data engine parity. No interval calibration is
established.
This evidence does not cover other response families, structured providers,
labelled or higher-dimensional blocks, random effects inside the SD formula,
or predictor-dependent correlation.

### Ordinary and phylogenetic Bernoulli intercepts

Native TMB permits an ordinary random intercept and a phylogenetic random
intercept in the same Bernoulli location predictor. Their latent contributions
are independent, and either or both SDs may have predictor-dependent formulas:

```text
logit(p_ig) = X_ig beta + b_g + a_s
b_g ~ Normal(0, tau_g^2)
a ~ Normal(0, D K D)
log(tau_g) = W_g alpha
log(D_ss) = Z_s gamma
```

For example, with groups `id` nested within phylogenetic tips `species`, use
`bf(y ~ x + (1 | id) + phylo(1 | species, tree = tree), sd(id) ~ w,
sd(species, level = "phylogenetic") ~ z)`. Each SD predictor must be constant
within its own latent group. The two target names remain distinct in coefficient
extraction, prediction, and stored fits. A seeded nested-group simulation
recovers both positive SD slopes in one fit and tests target-specific prediction,
binary response simulation, and save/reload. This is point-recovery evidence
for one design, not interval calibration or broad identifiability evidence.
Constant-SD equivalence is also tested for the combined model. Julia
joint-provider parity is not established.

## NB2 Ordinary-Intercept Slice

Native TMB also supports predictor-dependent SDs for ordinary NB2 location
intercepts when the response and predictors are complete:

```text
y_ig ~ NB2(mu_ig, sigma)
log(mu_ig) = X_ig beta + b_g
b_g = sd_g u_g,   u_g ~ Normal(0, 1)
log(sd_g) = W_g alpha
```

For example, `bf(count ~ treatment + (1 | site), sigma ~ 1, sd(site) ~
habitat)` lets habitat predict between-site variation on the log link scale.
The NB2 overdispersion parameter `sigma` remains distinct from the latent
intercept SD. The `habitat` value must be constant within each site.

The ordinary NB2 slice requires complete data and an ordinary, unstructured,
independent scalar `mu` intercept. A separate native TMB slice supports one q1
animal location intercept with `sd(id, level = "animal") ~ z`, using pedigree,
covariance `A`, or precision `Ainv` input. The intercept slice requires complete
data and does not combine with ordinary random effects, zero inflation,
correlated blocks, or a random effect on `sigma`. Both SD formulas
accept fixed-effect terms; random-effect bars, offsets and structured terms in
the SD formula are rejected. The ordinary and animal routes have synthetic
point-recovery tests and constant-SD equivalence checks. The animal route also
checks group-level SD predictions and rejects predictors that vary within an
animal. These checks are not a coverage study and do not establish calibrated
uncertainty or Julia parity.

A separate native NB2 sigma-endpoint slice allows one independent random
intercept on `sigma` to have a group-predictor-dependent SD:

```r
bf(count ~ x, sigma ~ 1 + (1 | site),
   sd(site, dpar = "sigma") ~ habitat)
```

Here `habitat` predicts the SD of the latent site effect added to
`log(sigma)`. The NB2 overdispersion parameter remains on its existing link
scale. This route requires complete data, fixed-effect `mu`, and one
unstructured, independent `sigma` random intercept; in non-inflated NB2 it does
not combine with other random or structured effects or a predictor-dependent
`mu` random-effect SD. The SD predictor must be constant within each site.
The focused synthetic test checks coefficient recovery, group-level SD
prediction, the conditional `sigma` link contribution, constant-SD
equivalence, and rejection of within-site predictor variation. These are
point-fit checks, not interval-calibration evidence or Julia parity.

The native zero-inflated NB2 route also admits one ordinary `sigma` random
intercept with a predictor-dependent SD, while `mu` and `zi` remain fixed
effects:

```r
bf(count ~ x, sigma ~ 1 + (1 | site), zi ~ 1,
   sd(site, dpar = "sigma") ~ habitat)
```

This route requires complete data and a habitat value that is constant within
each site. It does not combine with `mu` random effects, structured effects,
or a second random-effect target. The focused synthetic test checks SD
coefficient recovery, named group-SD prediction, the conditional `sigma` link,
constant-SD likelihood equivalence, and refusal of within-site predictor
variation. This is point-fit evidence, not interval calibration or Julia
parity.

The native LogNormal route supports one independent numeric random slope on
the residual `sigma` predictor when its coefficient has a matching SD formula:

```r
bf(y ~ 1, sigma ~ 1 + (0 + x | site),
   sd(site, dpar = "sigma", coef = "x") ~ habitat)
```

Here `habitat` predicts the SD of the latent slope added to `log(sigma)`. The
route requires complete data, fixed-effect `mu`, one `sigma` slope, and a
`habitat` value that is constant within each site. A sigma slope without the
matching SD formula remains refused. The synthetic test checks point recovery,
coefficient targeting, and group-level SD prediction. It does not establish
interval calibration or Julia parity.

Native NB2 also supports one unlabelled animal location slope-only coefficient,
`animal(0 + x | id, pedigree = pedigree)`, with `sigma ~ 1` and
`sd(id, level = "animal") ~ z`. This single-coefficient route uses the same
group-level SD surface as the intercept route. It requires complete data and
does not combine with other random effects, zero inflation, random `sigma`
effects, or a multi-coefficient structured block. A seeded independent
synthetic test checks recovery of the SD slope, named group predictions,
constant-SD likelihood equivalence, and rejection of `z` that varies within
animal. Interval calibration and Julia parity remain unverified.

## Structured Direct-SD Targets

The univariate `sd_phylo(species)` target is implemented as the first
structured Family B direct-SD model. Bivariate `sd_phylo1(species)` and
`sd_phylo2(species)` are implemented for matching phylogenetic location effects
in `mu1` and `mu2`. The exact native Gamma coordinate-spatial q1 intercept also accepts `sd(site, level = "spatial") ~ z`. Native Binomial mesh routes admit intercept and coefficient-specific slope SD regression across logit, probit, and cloglog links. The slope route has focused point-recovery and workflow checks, not interval coverage or Julia parity. These
direct-SD models are not scalar replacements for every fitted `log_sd_phylo`
parameter.

Native TMB also supports one exact crossed Bernoulli configuration with a
phylogenetic q1 intercept and a coordinate-spatial q1 intercept in the same
model. Each field has its own group-level SD formula, for example
`sd(species, level = "phylogenetic") ~ z_tree` and
`sd(site, level = "spatial") ~ z_site`. Its synthetic point-fit test checks
both coefficient trends, group SD predictions, the combined conditional
predictor, simulation, structured-effect extraction, and save/reload. This
does not establish other pairs, other Binomial links, Julia parity, or
interval calibration.

A future generic alias could spell the same target as
`sd(species, level = "phylogenetic") ~ z_species`. The current implemented
`sd_phylo()` name is deliberately explicit: it tells users that the SD surface
scales a tree-induced covariance, not an ordinary independent grouping factor.
This mirrors the future `corpair(..., level = "phylogenetic", ...)` grammar
without requiring a breaking rename now.

In the scalar phylogenetic likelihood, the latent species effects are coupled
by a Brownian-motion tree precision:

```text
a ~ MVN(0, sigma_phylo^2 A)
```

The fitted `sd_phylo()` quantity is the tip-level SD of the phylogenetic
location effect:

```text
tau_l = exp(W_l alpha_phylo)
v_aug ~ MVN(0, A_aug)
a_l = tau_l v_tip,l
Cov(a_tip) = D_tip A_tip D_tip
```

Here `W_l` is the species-level design matrix from
`sd_phylo(species) ~ z_species`, `D_tip = diag(tau_l)`, and `A_tip` is the
phylogenetic relationship matrix among observed tree tips. The implementation
should use a non-centred base tree effect: the sparse augmented precision still
defines `v_aug`, while only the observed tip contribution is multiplied by the
species-specific `tau_l`. Internal nodes do not receive user-facing SD
predictors. This avoids inventing ancestral covariates and still gives the
intended marginal tip covariance `D_tip A_tip D_tip`.

The right-hand side of `sd_phylo(species) ~ z_species` must be constant within
species after the model's complete-case filtering, just like ordinary
`sd(id) ~ z_group`. When the formula is present, it replaces the scalar
`log_sd_phylo` parameter for that target; it does not add a second phylogenetic
SD layer. The intercept-only case `sd_phylo(species) ~ 1` is tested against the
current constant-SD phylogenetic location model and gives the same marginal
likelihood with a non-centred TMB parameterization.

This Family B direct-SD model stays separate from Family A q=4 models. Do not
combine `sd_phylo(species) ~ z_species` with a matching labelled q=4
`phylo(1 | p | species, tree = tree)` block across `mu1`, `mu2`, `sigma1`, and
`sigma2`. That q=4 block estimates a constant joint covariance among latent
location and scale effects; `sd_phylo()` models predictor-dependent location
random-effect SDs.

The implementation accepts univariate `sd_phylo(species) ~ z_species` only
when the `mu` formula contains one intercept-only
`phylo(1 | species, tree = tree)` term. It builds a species-level model matrix
with one row per observed tree tip, rejects predictors that vary within
species, maps the scalar `log_sd_phylo` parameter out for that target, and
reports fitted values through `coef()`, `predict()`, `sdpars`, `summary()`, and
`profile_targets()`. `check_drm()` reports a `phylo_direct_sd_model` diagnostic
row for each univariate or bivariate `sd_phylo*()` endpoint, including species
replication, fitted SD range, and the maximum fitted species-SD ratio, because
weak replication or a numerically invalid SD surface can make direct-SD
interpretation misleading even when fixed effects are available.

Bivariate phylogenetic direct-SD syntax is implemented with response-specific
names:

```r
bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ w1,
  sigma2 = ~ w2,
  rho12 = ~ context,
  sd_phylo1(species) ~ z1,
  sd_phylo2(species) ~ z2
)
```

The design target is still Family B and still location-only. `sd_phylo1()`
models the SD surface of the `mu1` phylogenetic location effect and
`sd_phylo2()` models the SD surface of the `mu2` phylogenetic location effect.
They do not target residual `sigma1`, residual `sigma2`, phylogenetic
random effects inside scale formulas, or q=4 location-scale endpoint SDs.

The bivariate base effect should use one shared tree and one constant
phylogenetic location-location correlation. With species-level design matrices
`W1` and `W2`,

```text
tau1_l = exp(W1_l alpha_1)
tau2_l = exp(W2_l alpha_2)
[v1_aug, v2_aug] ~ tree-correlated unit base effect with corr rho_phylo
a1_l = tau1_l v1_tip,l
a2_l = tau2_l v2_tip,l
Cov(a1_l, a1_m) = tau1_l A_lm tau1_m
Cov(a2_l, a2_m) = tau2_l A_lm tau2_m
Cov(a1_l, a2_m) = rho_phylo tau1_l A_lm tau2_m
```

This means `sd_phylo1()` and `sd_phylo2()` replace the scalar phylogenetic SD
parameters for their matching location endpoints, while `rho_phylo` remains a
latent phylogenetic location-location correlation reported by `corpairs()`.
Residual `rho12` remains the within-observation coscale parameter. The
implementation allows one or both response-specific direct-SD formulas; if only
one is supplied, the other endpoint keeps its scalar phylogenetic SD.
For `summary(fit)$covariance`, a direct-SD endpoint is summarized by the median
fitted species SD because the true phylogenetic covariance varies across
species pairs as `rho_phylo tau1_l A_lm tau2_m`.

Unsupported combinations should fail before optimization:

- `sd_phylo1()` or `sd_phylo2()` without matching bivariate `mu1`/`mu2`
  phylogenetic location terms;
- group or tree mismatches between `mu1`, `mu2`, and the direct-SD target;
- use beside an all-four q=4 `mu1`/`mu2`/`sigma1`/`sigma2` phylogenetic block
  for the same species level;
- any `sd_sigma1()`, `sd_sigma2()`, or scale-random-effect SD target.

## Selector and key contract

This section fixes what `sd(group, level =, dpar =, coef =, block =)` means and
how it names a fitted parameter. It records the G1 review condition C2
(`docs/dev-log/general-sd-regression/g1-joint-contract-review-20261101.md`,
section 1). Parser: `parse_sd_lhs()` in `R/parse-formula.R`; resolver:
`drm_resolve_sd_target()` in `R/random-effect-targets.R`. Tests:
`tests/testthat/test-sd-selector-contract.R`.

Identity versus key.

- The identity of a latent coefficient is the tuple (group, level, `dpar`,
  `coef`, `block`). The resolver matches on this tuple and either returns one
  member or aborts with the list of candidates.
- The public key is a string, and it is the user's spelling. `format_sd_lhs_dpar()`
  writes only the selectors the user supplied, always in the order `dpar`,
  `coef`, `block`. Call order does not matter: `sd(id, coef = "x", dpar = "mu")`
  and `sd(id, dpar = "mu", coef = "x")` give one key, and `group = id` gives the
  same key as the unnamed `id`.
- The key is therefore not canonicalised. `sd(id) ~ w` and
  `sd(id, coef = "(Intercept)") ~ w` name the same latent coefficient but are
  two keys (`"sd(id)"` and `"sd(id, coef = \"(Intercept)\")"`). They fit the
  same model, and each key works only in the fit that used that spelling. This
  is a documented property, not a bug: a script that adds a second same-group
  SD formula must switch to `coef =` spellings and re-key its `coef()`,
  `predict()` and profile targets. Canonicalising to the longest spelling would
  rename existing fitted coefficients, so it is deferred and not implemented.
- Structured keys are the exception. For `sd_phylo`, `sd_animal`, `sd_relmat`
  and `sd_spatial`, selectors and `level` are parsed but stripped from the key
  (`R/parse-formula.R`, end of `parse_sd_lhs()`), so `sd(id, level = "animal")`
  and `sd(id, level = "animal", coef = "x")` both give `"sd_animal(id)"`. The
  admitted q2 builders (Gamma, Beta, Binomial) re-key their entries with
  `dpar = "mu", coef = ...`, so such a key can change when a second formula is
  added.

The `level = "group"` alias rule. `level = "group"` is the internal label of an
ordinary (unstructured) random effect in the identity map. It is not a public
spelling and `sd(id, level = "group")` is refused. An ordinary term is selected
by omitting `level`. Accepted public levels are `"phylogenetic"`,
`"phylogenetic_interaction"`, `"spatial"`, `"animal"` and `"relmat"`. If this
alias is ever exposed, it must select the ordinary term only and must give the
same key as the spelling without `level`.

`block` is reserved. It is parsed and checked against the fitted block label,
but every admitted ordinary route requires an unlabelled block, and the labelled
Gamma q2 route selects by `coef`. A `block` selector therefore has no admitted
live use and currently only improves error messages.

Prediction. `predict(fit, dpar = key)` matches `key` exactly against
`names(fit$coefficients)`. Partial matching was removed because SD keys share
long prefixes and a typo could resolve to a different SD formula. A prefix, a
vector, `NA` or a non-string aborts with the available names.
`coef.drmTMB()` and `fixef()` still use `match.arg()` and so still partial-match;
this is recorded as a known limit and is not part of C2.

## Multiple Random-Effect Scale Components

When there are several random-effect components, each scale formula must name
its target:

```text
mu_i = X_mu[i, ] beta_mu + b_site[site_i] + b_species[species_i]
b_site[k] = sd_mu_site,k u_site,k
b_species[l] = sd_mu_species,l u_species,l
log(sd_mu_site,k) = W_site[k, ] alpha_site
log(sd_mu_species,l) = W_species[l, ] alpha_species
```

Implemented R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | site) + (1 | species),
    sigma ~ x2,
    sd(site) ~ x3,
    sd(species) ~ 1
  ),
  family = gaussian(),
  data = dat
)
```

The parser must reject ambiguous shorthand. For example, if `id` has both a
random intercept and a random slope, then `sd(id) ~ x1` is ambiguous because it
does not say whether the intercept SD or slope SD is being modelled.

Explicit selectors are accepted when the selected family route supports the
target shape. For example, native complete-data Student-t accepts an
explicitly selected ordinary location intercept or independent slope; the
skew-normal route accepts an intercept or one independent location slope:

```r
sd(id, dpar = "mu", coef = "(Intercept)") ~ x1
sd(id, dpar = "mu", coef = "x1") ~ x2
```

The same selector fields are used by the shared resolver for other admitted
families. They do not make every coefficient shape available: predictor-
dependent independent random-slope SDs are currently limited to the separately
checked Poisson, Bernoulli, Gamma, NB2, Lognormal, Student-t, and skew-normal
routes. Selector support does not admit correlated or structured targets by
itself.

Target support depends on the family adapter. Gaussian supports multiple
distinct ordinary `mu` intercept targets; selected native Bernoulli and Poisson
routes support one independent numeric slope in addition to their documented
intercepts; native Student-t supports one independent numeric location slope
in addition to its intercept; skew-normal supports one such location slope as
an SD target. The development Julia candidate also supports
one separate Student-t intercept or slope SD route with fixed `sigma ~ 1` and
`nu ~ 1`; it requires a paired local source checkout and is absent from current
shared/released DRM.jl. Selected native NB2 supports its documented scalar
intercept and independent-slope cells. Native lognormal supports its
documented scalar intercept and one complete-data independent numeric
location-slope SD target with fixed-effect `sigma`; correlated blocks and
structured providers remain outside this slice. A separate complete-data
LogNormal route admits one independent `sigma` random intercept with
`sd(id, dpar = "sigma") ~ predictors` and fixed-effect `mu`; that formula
models the SD of the latent effect on `log(sigma)`, not residual `sigma`.
The native Gaussian route admits one ordinary `sigma` random intercept or one
independent numeric random slope with that syntax. For a slope, select its
coefficient explicitly, for example
`sd(id, dpar = "sigma", coef = "z") ~ w` with
`sigma ~ 1 + (0 + z | id)`. It requires complete unaggregated data,
fixed-effect `mu`, no other random or structured effects, and predictors
constant within the grouping factor. The formula models variation in the
latent `log(sigma)` coefficient, not residual `sigma`. Julia parity and
interval calibration remain open. Other non-location
endpoint/family combinations remain unsupported. The current Student-t and
skew-normal cells require complete responses. A family-specific target
resolver checks identity first, then the adapter applies its own
coefficient-shape and data fences.

## Random Slopes

Random slopes add separate group-level scale quantities:

```text
mu_ij = X_mu[ij, ] beta_mu + b_0j + x1_ij b_1j
[b_0j, b_1j]' ~ MVN(0, Sigma_id)
Sigma_id =
  [sd0_j^2,          rho_re sd0_j sd1_j;
   rho_re sd0_j sd1_j, sd1_j^2]
```

In early implementations, `rho_re` should remain a constant group-level
correlation. Predictor-dependent correlation formulae should be reserved for
residual `rho12` until simulation evidence supports more complex group-level
correlation models.

Targeted random-slope SD syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 + x1 | id),
    sigma ~ x2,
    sd(id, dpar = "mu", coef = "(Intercept)") ~ x3,
    sd(id, dpar = "mu", coef = "x1") ~ x3
  ),
  family = gaussian(),
  data = dat
)
```

The first validated non-Gaussian slope cells are the ordinary independent
Poisson and Bernoulli routes. Native Bernoulli also supports distinct
coefficient-specific SD formulas for separate independent terms on one group;
Julia parity for that shape remains open. This does not admit a correlated
intercept-slope SD model or arbitrary family/backend combinations.

## Bivariate Boundary

For bivariate models:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
Omega_i[1,2] = rho12_i sigma1_i sigma2_i
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = 0.999999 * tanh(eta_rho12_i)
```

Matching implemented fixed-effect syntax:

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

`rho12` is residual response-response correlation. It is not the correlation
between random intercepts, random slopes, or random scale effects. Those
belong to group-level covariance blocks and should be extracted separately.

The implemented bivariate direct-SD syntax targets location random effects
only:

```text
mu1_i = X_mu1[i, ] beta_mu1 + b1[id_i]
mu2_i = X_mu2[i, ] beta_mu2 + b2[id_i]
[u1_j, u2_j]' ~ Normal([0, 0]', R_group)
b1_j = sd_mu1_id,j u1_j
b2_j = sd_mu2_id,j u2_j
log(sd_mu1_id,j) = W1_id[j, ] alpha1
log(sd_mu2_id,j) = W2_id[j, ] alpha2
```

Matching implemented R syntax:

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

`sd1(id)` targets the `mu1` location random-intercept SD and `sd2(id)` targets
the `mu2` location random-intercept SD. Their predictors must be constant
within `id`, just like univariate `sd(id)`. They do not target residual
`sigma1`, residual `sigma2`, or random effects inside the scale formulas.

## Implementation Rules

The implemented `sd(group) ~ x` and bivariate `sd1(group) ~ x` / `sd2(group) ~
x` paths should:

1. support Gaussian models first;
2. target one or more distinct unlabelled univariate Gaussian `mu` random
   intercepts such as `(1 | id)` and `(1 | site)`, with family-specific scalar
   coefficient targets admitted only after separate validation;
3. target labelled bivariate Gaussian location random intercepts through
   `sd1(group)` for `mu1` and `sd2(group)` for `mu2`;
4. reject unsupported random slopes, correlated blocks, duplicate targets,
   mismatched grouping factors, and names such as `sd_sigma1()` / `sd_sigma2()`;
5. require right-hand-side predictors to be constant within target groups;
6. use a non-centered TMB parameterization with standardized `u_j`;
7. replace each targeted scalar `log_sd_mu` with a group-level linear
   predictor such as `W_id alpha_id`;
8. keep residual `sigma` and residual-scale random effects independent of the
   `sd(group)` scale model;
9. add simulation recovery and malformed-input tests before user docs call the
   syntax implemented.

## Test Contract

Tests for the first implementation should include:

- a moderate recovery case for `log(sd_id,j) = alpha_0 + alpha_1 x_j`;
- a multi-target case such as `sd(id) ~ x_id` plus `sd(site) ~ x_site`;
- a near-constant scale case with `alpha_1 = 0`;
- a large scale-slope case that checks positivity and convergence;
- a factor predictor on the `sd(id)` right-hand side;
- rejection when the target random effect is absent;
- rejection when the target is ambiguous because `id` has multiple random
  coefficients;
- rejection when an `sd(id)` predictor varies within `id`;
- a comparator smoke test against `lme4` when `alpha_1 = 0`, because that case
  reduces to a homoscedastic random-intercept model.

Long simulations should explore group count, within-group replication,
unbalanced sampling, sparse groups, and boundary standard deviations.

## Native Bernoulli Relatedness-Matrix Intercept

The native R/TMB Bernoulli route also supports one intercept-only
`relmat(1 | group, K = K)` term with a group-level predictor-dependent SD:

```r
bf(
  y ~ x + relmat(1 | group, K = K),
  sd(group, level = "relmat") ~ z
)
```

The fitted covariance is `D K D`, where `D` contains the group-specific SDs
`exp(W alpha)` and `K` is the supplied relationship matrix. `z` must be
constant within each retained group. This is one native Bernoulli intercept
cell; it does not establish Julia parity, other response families, correlated
coefficient blocks, or general structured-effect support. Its seeded synthetic
test checks recovery of both SD coefficients and the fitted group-SD surface,
public group-level SD predictions, and marginal Bernoulli simulation. This is
point-recovery evidence for one design, not interval calibration.

## Native Bernoulli Animal-Model Intercept and Slope

The native R/TMB Bernoulli route supports one unlabelled q1 animal intercept
with a predictor-dependent SD. It also supports one animal slope-only
coefficient with the ordinary constant SD or with a group-level SD regression.
For the predictor-dependent slope, write:

```r
bf(
  y ~ x + animal(0 + x | id, A = A),
  sd(id, level = "animal") ~ z
)
```

The animal coefficient has covariance `D A D`, where `D` contains
`exp(W alpha)` and `A` is the supplied relationship matrix. The model keeps
the existing matrix scaling. Each SD predictor must be constant within its
retained animal ID. The slope-only route uses complete responses, one
unlabelled animal coefficient, and no additional random-effect terms. Its
seeded synthetic check exercises coefficient and name-keyed group-SD
predictions, marginal simulation, profile-target construction, save/reload,
recovery of a nonzero SD slope, equivalence to the constant-SD animal-slope
fit, and rejection of within-ID predictor variation. The intercept and slope
checks are native Bernoulli point-recovery cells. They do not establish Julia
parity, pedigree or precision-matrix parity under these SD formulas, other
response families, interval calibration, or coverage.

## Native Bernoulli Animal Intercept and Slope with Separate SD Regressions

The native R/TMB Binomial route supports one unlabelled animal intercept and
numeric slope with a separate predictor-dependent SD for each coefficient:

```r
bf(
  y ~ x + animal(1 + x | id, A = A),
  sd(id, level = "animal", coef = "(Intercept)") ~ z0,
  sd(id, level = "animal", coef = "x") ~ z1
)
```

The route also accepts a supplied precision matrix with `Ainv = Q`, or a
pedigree table. The coefficient fields are independent; each supplied animal
matrix keeps its existing scale, and each SD predictor must be constant within
animal ID. This route requires complete, unweighted 0/1 responses, one
intercept and one numeric slope, and no additional random effects. It supports
logit, probit, and cloglog links. Fixed-seed synthetic tests check recovery
under all three links and selected output and simulation workflows. They
establish point-recovery evidence for those designs, not interval coverage or
Julia parity.

## Native Poisson Animal-Model Intercept

The native R/TMB Poisson route also supports one complete-data q1
`animal(1 | id, A = A)` intercept with a predictor-dependent SD:

```r
bf(
  count ~ x + animal(1 | id, A = A),
  sd(id, level = "animal") ~ z
)
```

Its covariance is `D A D`; the supplied relationship matrix and its scaling
are preserved, and `z` must be constant within each animal ID. The seeded
synthetic check uses a non-invariant interleaved covariance order and checks
SD-slope recovery, group-level predictions, simulation, save/reload, and
constant-SD equivalence. This establishes one native Poisson point-recovery
cell. A separate native precision-input test fits the same q1 animal intercept
with `animal(1 | id, Ainv = Q)`, using `Q = solve(A)` for the synthetic
relationship covariance. It checks point recovery, group-SD prediction, and
constant-SD equivalence. This does not cover pedigree-built inputs, other
animal effect shapes, Julia parity, or interval calibration. A third native
test uses a nontrivial synthetic pedigree and compares the sparse pedigree fit
with data generated from its dense additive relationship matrix. It checks
point recovery, group-SD predictions keyed by animal name, and constant-SD
equivalence. Output labels follow the structured group registry; callers can
match predictions by name even when pedigree and factor-level orders differ.

## Native SD Routes Admitted on 2026-11-01

These routes are native R/TMB only. None has Julia parity, interval
calibration, or a coverage claim; each has fixed-fixture point-fit checks, and
the evidence differs by route. All use complete responses and a predictor that
is constant within its group. Oracle means a dense or exact likelihood computed
independently at the fitted values; "equivalence" means the constant-SD fit
reproduces the plain fit and `predict()` equals `exp(W alpha)`.

| Family | Route | Evidence |
|---|---|---|
| Gaussian | unlabelled correlated `(1 + x \| id)` with `coef`-selected SDs (or the slope alone) | per-group multivariate-normal oracle; equivalence; q3 stays refused |
| Gaussian | same-group `(1 \| id) + (0 + x \| id)` with `coef`-selected SDs | exact oracle; equivalence |
| Gaussian | `relmat()` and coordinate `spatial()` intercepts | dense oracle; animal slope-only already worked |
| Gaussian | `mu` intercept with a `sigma` intercept or slope, each with an SD formula | dense Laplace oracle; equivalence |
| Poisson | same-group pair and crossed intercepts, separate SDs | exact Laplace oracle |
| Poisson | slope-only `phylo()` and `relmat()` (`K` and `Q`) | dense Laplace oracle; these shapes also fit without `sd()` |
| Poisson | one ordinary plus one q1 `relmat()`, `animal()` or `phylo()` intercept, no `zi` | dense Laplace oracle; shape also fits without `sd()` |
| Poisson | coordinate `spatial()` intercept and slope-only | no oracle; equivalence, nesting, prediction identity only |
| Poisson | `animal(0 + x \| id)` with `Ainv` or `pedigree` | likelihood equals the `A =` fit; equivalence; no independent oracle yet |
| Poisson | `phylo_interaction()` intercept and slope-only, pair-level SD | dense Laplace oracle over the Kronecker pair field; `test-poisson-batch5-sd-regression.R` |
| NB2 | `relmat()` and coordinate `spatial()` intercepts | dense Laplace oracle |
| NB2 | slope-only `phylo()` and `relmat()` | dense Laplace oracle; shapes also fit without `sd()`; marginal simulation refused |
| NB2 | one ordinary intercept plus one `relmat()` (`K`, `Q`), `animal()` (`A`, `Ainv`) or `phylo()` intercept, separate SDs; crossed ordinary intercepts | dense Laplace oracle; `test-nbinom2-batch5-sd-regression.R` (150 expectations) |
| NB2 | independent same-group pair | equivalence and prediction identity in the regression file; the `coef`-selected form has the oracle in the Gamma, NB2 row below |
| Gamma | crossed intercepts on distinct groups; ordinary plus `relmat()` intercepts | dense Laplace oracle; crossed slopes and chains of three or more terms refused |
| Gamma | one ordinary `(1 \| g)` plus one q1 `animal()` (`A`, `Ainv`), `phylo()` or `spatial()` intercept, separate SDs | dense Laplace oracle with non-unit-diagonal `K` in shuffled order; `test-gamma-iid-structured-sd-regression.R` |
| Gamma, NB2 | same-group `(1 \| id) + (0 + x \| id)` with `coef`-selected SDs on different predictors | dense Laplace oracle at the fitted point, 1e-4 absolute; `test-nbinom2-gamma-same-group-sd-oracle.R` |
| Gamma | independent same-group pair | equivalence checks in the regression file; the oracle row above covers the `coef`-selected form; recovery weak at 50 groups |
| Poisson | plain independent slope `(0 + x \| id)` with `zi ~ 1`, no `sd()` formula | per-cluster quadrature oracle and equality with the constant-SD fit, one synthetic dataset; `test-zi-poisson-plain-slope.R`; correlated `(1 + x \| id)` with `zi` stays refused |
| Gamma | labelled `animal(1 + x \| p \| id)` correlated q2 | joint-objective oracle at 1e-6 with five emulated bugs and a raw non-unit-diagonal `A` case in shuffled order (`test-gamma-animal-q2-correlated-sd.R`); loose 0.4 recovery band, no calibration; no base nesting fit, no simulate-refit identity, `rho` bound `0.999999` (ordinary blocks `0.99999999`); constant-loading near-aliasing with identical non-constant SD designs is documented, not fenced (design 03) |

Not admitted: NB2 `sigma`-side phylogenetic SD (held for a decision, because it
opens the public base route `sigma ~ phylo(1 | sp)`). NB2 spatial slope-only
was admitted on 2026-11-01 (`test-nbinom2-spatial-slope-sd-regression.R`, dense
Laplace oracle).
Gamma ordinary plus animal, phylo or spatial intercepts moved to the admitted
table above on 2026-11-01. Beside an ordinary intercept, Gamma still refuses a
second ordinary intercept, an ordinary correlated block, a `sigma` random
effect, missing responses, a structured slope, and `sd(g)` alone beside a
structured term. Missing implementation here is not a claim of
non-identifiability.

Two test-only checks add alignment and covariance-scale evidence for structured
SD routes, without changing any route's status.
`tests/testthat/test-structured-sd-asymmetric-alignment.R` fits five routes
(Poisson spatial, NB2 relmat, NB2 spatial, Gaussian relmat, Gaussian spatial)
with irregular coordinates or a dense, non-Toeplitz, unequal-diagonal kernel, all
supplied in a different shuffled order from the data levels. The fitted
log-likelihood matches a hand-built by-name oracle to relative 1e-6 (observed
about 1e-13). A positional reading of the kernel would move the oracle by 0.67
to 28 log-likelihood units, so the check can fail; the Poisson spatial margin
(0.67) is the smallest. `tests/testthat/test-structured-sd-nonunit-k-and-missing.R`
uses non-unit-diagonal `K` (NB2 and Gaussian relmat, binomial animal with `A`
and `Ainv`, and an inbred pedigree) against oracles built from the unconverted
`K`; each fit differs from the `cov2cor(K)` oracle by more than 0.05, so an
accidental correlation conversion would be caught. The same file pins that
slope-only structured SD under `miss_control(response = "include")` is refused
for Poisson and NB2 on all seven routes probed. Oracles are evaluated at the
fitted parameters, so they check the likelihood surface and not the optimiser.
Native TMB only; no Julia parity, no calibration, one fixture per route.

### What the extractors return for a predictor-dependent SD (G1 C5 audit, 2026-11-01)

This records what each public surface returns today. It is an audit of
existing behaviour, not a new contract, and it comes before any marginal-SD
name is introduced (condition C5 of
`docs/dev-log/general-sd-regression/g1-joint-contract-review-20261101.md`).

| Surface | Result for `sd(id) ~ w` or a structured SD key | Citation |
| --- | --- | --- |
| `predict(fit, dpar = "sd(...)")` | Per-group multiplier `exp(W beta)` on the latent effect, after the likelihood's soft clamp. `type = "link"` is the clamped log value, `type = "response"` is its exponential. Without `newdata`, one value per fitted group named by level. With `newdata`, one value per row (rows are group-level rows), named by `rownames(newdata)`. For a structured effect the value multiplies the supplied kernel as given and is never `multiplier * sqrt(C_gg)`. A `newdata` row has no kernel node, so it is a population multiplier. | `predict_random_scale_dpar()`, `R/methods.R:7035-7095`; roxygen `R/methods.R:2993-3006`; pinned by `tests/testthat/test-sd-predict-semantics.R` |
| `predict_parameters(fit, dpar = "sd(...)")` | The same per-group multiplier, one row per group (or per `newdata` row), because it calls `predict()` per `dpar`. No average and no marginal SD. Intervals are refused: `conf.status = "newdata_required"` without `newdata`, `"wald_unavailable"` with it. | `R/predict-parameters.R:150`, `444-452` |
| `predict_parameters()` row labels, no `newdata` | Group levels for `mu` and `phylo` SD keys only. For the `sigma` and second structured (`phylo2`) SD keys the registry lookup is skipped and rows are labelled `"1"`, `"2"`, and so on. This is a labelling gap, not a value error, and is left as is. | `R/predict-parameters.R:684`, `666` |
| `VarCorr()` | Not defined. drmTMB exports no `VarCorr` method, so there is nothing to return for an SD-regression fit; the call is a refusal by absence (`NAMESPACE` has no entry). | `NAMESPACE`, `R/*.R` (no match) |
| `fit$sdpars` | Named per-group vectors of the clamped multiplier, one vector per SD key. This is the stored form that `predict()` is checked against. | `sd_mu_group_values()` and siblings, `R/drmTMB.R:26973-27060` |
| `summary()` derived rows (bivariate phylo `corpairs()` SD columns) | The only average anywhere: for a direct-SD phylo endpoint the reported SD is the median of the per-group multipliers, labelled `sd:<dpar>:(median)`. | `phylo_mu_sd_summary()`, `R/methods.R:1602-1611`, used at `1511-1520` |

Consequences for naming. No surface returns the marginal SD
`multiplier * sqrt(C_gg)`. For `phylo()` the kernel is unit-diagonal by
construction, so the multiplier is the marginal SD; for `animal()` and
`relmat()` with a non-unit diagonal, and for mesh spatial, it is not. A new
public marginal-SD accessor must therefore (1) take the kernel diagonal from
the stored kernel rather than assume 1, (2) say which group set it covers
(fitted groups only, since a new group has no `C_gg`), and (3) not reuse the
name `predict()` or the `"sd"` rows of `summary()`, which already mean the
multiplier. Any median or mean over groups, as in the `corpairs()` columns
above, is a summary of multipliers and must keep the `(median)` label.

## Kernel scaling by provider and engine (G1 condition C3, 2026-11-01)

The SD multiplier `s_g` scales a latent effect with covariance `s_g C_gh s_h`,
so the marginal SD of node `g` is `s_g sqrt(C_gg)`. Whether `C_gg = 1` depends
on the provider and the engine. The table states what each route does, read
from source; it is not a measurement. Native rows come from
`docs/dev-log/general-sd-regression/g1-joint-contract-review-20261101.md`
(section 3) and the cited code. Julia rows come from the sibling worktree
`../general-sd-julia` (head `70dbf564e`) and have not been re-run here.

| Provider | Native TMB `C_gg` | Julia `C_gg` |
|---|---|---|
| `phylo()` | 1 by construction (ultrametric tree divided by height, `R/formula-markers.R:190-215`) | normalised (`normalize = kind !== :animal`) |
| `animal()` with `A`, `Ainv` or pedigree | raw, `A_gg` (1 plus inbreeding) | Gamma and Poisson: raw (`gamma.jl:147`, `685`; `poisson.jl:244`, `266`, `566`). NB2: rescaled to a correlation matrix (`negbinomial.jl:81-84`) |
| `relmat()` with `K` or `Q` | raw, `K_gg` or `(Q^-1)_gg` | Gamma: normalised (`normalize = kind !== :animal`, `gamma.jl:147`). Stated explicitly here because the programme invariant only says "established conventions" |
| coordinate `spatial()` | `1 + 1e-6` (fixed diagonal jitter, `R/drmTMB.R:17359-17379`) | not reviewed |
| mesh `spatial()` | raw sparse GMRF; no constant marginal SD (`R/drmTMB.R:25916-25925`) | not reviewed |
| `phylo_interaction()` | not verified | not reviewed |

Consequences. Native `relmat()` and `animal()` fits keep the supplied scale, so
for a non-unit diagonal the multiplier and the marginal SD differ by
`sqrt(C_gg)`. `predict(dpar = "sd(...)")` returns the multiplier. Under
`engine = "julia"`, an NB2 animal fit with a non-unit-diagonal `A` has a
different latent covariance from the native fit of the same formula. SD
coefficients shift by about `log sqrt(A_gg)` per node, and the intercept
absorbs the average, so slopes can look equal while the intercept differs.

The 2026-10-24 decision (`LOOP/lanes/general-sd-regression/GOAL.md`) moved Julia
Gamma animal to the supplied raw `A`. The Julia Gamma animal simulator already
follows it (`R/julia-simulate.R:307-309` keeps the raw matrix), and the
`simulate()` roxygen has been corrected to say so. The 2026-10-22 Poisson line
in `.unlazy/general-sd-regression/GATES.md` ("Julia normalizes `A`") is
superseded.

### Open parity row: NB2 animal kernel scaling

| Route | Native | Julia | Status |
|---|---|---|---|
| NB2 animal intercept with SD formula, non-unit-diagonal `A` | raw `A` | `A` rescaled to a correlation matrix | OPEN. A real engine mismatch, not a convention. It needs either a Julia change to raw `A` or a documented refusal of non-unit-diagonal `A` under `engine = "julia"`. Neither is done. |

### Status of the existing native-versus-Julia tolerance

The Gamma q2 native-versus-Julia comparison
(`tests/testthat/test-gamma-animal-q2-nonunit-kernel-parity.R`) compares SD
coefficients and group SDs at relative tolerance 0.25 and needs a live Julia.
It is a smoke check that the raw-`A` route runs and agrees to within gross
error. It is not a tight check of the scaling decision. This slice adds no live
Julia parity test; a tight non-unit-diagonal native-versus-Julia test remains
unwritten.

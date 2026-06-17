# Phase 19 Comparator Matrix

This note is the consolidated comparator plan for Phase 19 (#60). It maps each
fitted `drmTMB` surface to the external package(s) that can fit a comparable
model, names the matched scale and the conversion needed to compare estimates
honestly, and marks the surfaces where no faithful comparator exists. The reader
is the contributor preparing the comparator demonstration and the project owner
deciding which comparisons go into the paper.

It does not run the fits. Running comparators needs a machine with `glmmTMB`,
`brms`, `metafor`, `betareg`, `gamlss`, `ordinal`, and related packages
installed; this note is the design that makes those runs mechanical and keeps
scale conversions correct. It builds on the comparator-boundary decisions in
`docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md`
and the Tweedie comparator contract in `docs/design/126-...`.

## Principles

1. **One-off shared datasets, not a second Monte Carlo.** Phase 19 reuses a
   small set of representative simulated or tutorial datasets from Phase 18 and
   fits each model once per package. Repeated simulation is a separate decision.
2. **Convert before comparing.** `drmTMB` reports the public `sigma`. Most
   comparators report a dispersion, precision, size, or variance instead. Every
   comparison must state the conversion and compare on one matched scale. The
   conversions are tabulated below.
3. **No implied one-to-one comparator.** Several `drmTMB` surfaces (residual
   `rho12`, modelled `sigma`, structured location-scale covariance) have no
   exact comparator. Those rows compare the closest available model and state
   what differs, rather than pretending equivalence.
4. **Reproducible timing.** Record package versions, platform, core count, seed,
   and model options with every timing number.

## Scale-Conversion Reference

`drmTMB` uses `sigma` (and `sigma1`/`sigma2`) as the public scale parameter.
Internal-to-comparator conversions:

| Family | `drmTMB` public | Internal mapping | Typical comparator scale | Conversion to compare |
| --- | --- | --- | --- | --- |
| `gaussian()` | residual SD `sigma` | `log(sigma)` linear predictor | `glmmTMB` dispersion / `gamlss` `sigma` | `gamlss` `sigma` is the SD directly; `glmmTMB` reports residual variance — compare `sigma^2` |
| `student()` | `sigma`, `nu` | `nu = 2 + exp(eta_nu)` (df) | `gamlss` `TF`, `brms` `student` | match `nu` to df; `sigma` to scale |
| `lognormal()` | `sigma` on `log(y)` | identity `mu` on `log(y)` | `glmmTMB`/`lm` on `log(y)` | compare on the log scale; `sigma` is the log-scale SD |
| `Gamma(link="log")` | `sigma` | shape `= 1 / sigma^2` | `glmmTMB`/`glm` Gamma shape or dispersion | `shape = 1/sigma^2`; `glm` dispersion `= sigma^2` |
| `tweedie()` | `sigma`, `nu` | `phi = sigma^2`, `nu = 1 + plogis(eta_nu)` power | `glmmTMB::tweedie` (dispersion, power) | `phi = sigma^2`; power matches `nu` (see doc 126 for weights/offset boundary) |
| `beta()` | `sigma` | precision `phi = 1 / sigma^2` | `betareg`/`glmmTMB` beta precision `phi` | `phi = 1/sigma^2` |
| `beta_binomial()` | `sigma` | precision `phi = 1/sigma^2`, row trials | `glmmTMB` betabinomial | match precision; align trials column |
| `stats::binomial()` | event probability `mu` | logit-mean only; row trials from 0/1 or `cbind(success, failure)` | base `stats::glm()` binomial | compare coefficients, standard errors, `logLik`, AIC, and BIC directly |
| `nbinom2()` | `sigma` | size `= 1 / sigma^2` | `glmmTMB::nbinom2` / `MASS::glm.nb` theta | `theta (size) = 1/sigma^2` |
| `meta_V(V=V)` | fixed/random means, heterogeneity | known `V` added to residual | `metafor::rma.mv` with `V` | `V` is input data in both; compare heterogeneity `tau^2` notation explicitly |

## Comparator Matrix

| `drmTMB` surface | Comparator package(s) | Matched target | What cannot be matched |
| --- | --- | --- | --- |
| Gaussian location-scale (`mu`, `sigma ~ x`) | `glmmTMB` (dispformula), `gamlss` (NO) | location + modelled scale | base `lm`/`glmmTMB` without dispformula cannot model `sigma ~ x` |
| Gaussian `mu` random intercepts/slopes | `glmmTMB`, `lme4` | RE SDs, fixed effects | modelled `sigma` alongside RE not in `lme4` |
| Gaussian `sigma` random effects | `gamlss` (random terms) | scale RE SD | few packages fit random effects in the scale |
| Residual `rho12` (bivariate) | `brms` (multivariate), `MCMCglmm` | residual response-response correlation | predictor-dependent `rho12 ~ x` has essentially no frequentist comparator |
| Bivariate covariance blocks (`corpairs()`) | `brms`, `MCMCglmm` | group-level cross-response correlations | matching `drmTMB` labelled-block semantics exactly is approximate |
| `meta_V(V=V)` | `metafor::rma.mv` | pooled mean, heterogeneity | keep `V` as known input; compare `tau^2` notation |
| Poisson `mu` (RE) | `glmmTMB`, `lme4` | counts, RE SD | — |
| NB2 (`mu`, `sigma`) | `glmmTMB::nbinom2`, `MASS::glm.nb` | mean, overdispersion (`theta=1/sigma^2`) | `glm.nb` has no RE |
| Zero-inflated/hurdle counts | `glmmTMB` (ziformula) | ZI/hurdle probability | — |
| `beta()` | `betareg`, `glmmTMB` | mean, precision (`phi=1/sigma^2`) | `betareg` has no RE; use `glmmTMB` for RE |
| `beta_binomial()` | `glmmTMB` (betabinomial) | mean, precision, trials | — |
| `stats::binomial()` fixed-effect | `stats::glm()` | event probability, fixed logit coefficients, likelihood constants | no random effects, no modelled scale, no Julia bridge promotion in the first slice |
| `lognormal()` / `Gamma(link="log")` | `glmmTMB`, base `glm` | mean, dispersion | compare lognormal on the log scale |
| `tweedie()` | `glmmTMB::tweedie` | mean, power, dispersion | weights/offsets out of first pass (doc 126) |
| `cumulative_logit()` | `ordinal::clm`, `MASS::polr`, `brms` | cutpoints, location | scale/discrimination not modelled here |
| Phylogenetic `mu` | `MCMCglmm`, `brms` (phylo), `phylolm`, `phyr` | phylogenetic SD / signal | Bayesian comparators differ in prior; `phylolm` is fixed-effect only |
| Coordinate-spatial `mu` | `spaMM`, `INLA` | spatial field | `drmTMB` coordinate fields vs SPDE/Matern differ in parameterization |
| `animal()` / `relmat()` | `MCMCglmm`, `ASReml`, `brms` | additive-genetic variance, heritability | ASReml is licensed; MCMCglmm/brms are Bayesian |
| `skew_normal()` fixed-effect | `gamlss` (SN1/SN2), `sn` package | response mean, response SD, residual slant | `drmTMB` uses public moment parameters, so comparators must map native location/scale/skewness to `mu = E[y]`, `sigma = SD[y]`, and `nu` before comparing estimates |

## Executed Comparator Artifacts

The first banked Phase 19 artifact is the plain binomial fixed-effect
`stats::glm()` parity bundle:

```text
docs/dev-log/comparator-results/2026-06-16-binomial-glm-parity/
```

It uses the Phase 18 `binomial_fixed_effect` writer with both supported
response encodings, `n = 320`, `n_rep = 3`, and seed `20260616`. The artifact
contains aggregate, replicate, manifest, failure-ledger, Wald-interval,
Wald-coverage, and `stats::glm()` parity CSV tables plus a README with SHA,
R/package versions, platform, seed, and interpretation label. In that parity
bundle, the largest absolute `drmTMB` versus `stats::glm()` coefficient
difference is `1.894251e-11`; the largest standard-error difference is
`6.393821e-08`; the largest absolute `logLik` difference is `2.728484e-12`;
and the largest absolute AIC/BIC difference is `5.456968e-12`.

This is a parity artifact only. It does not support interval-calibration,
speed, random-effect, structured-effect, bivariate, mixed-response, or Julia
bridge claims.

## Definition Of Done For Phase 19

Per #60: a comparator matrix (this note), one-off shared datasets, model fits on
matched scales, timing summaries with full provenance, and a clear statement of
where a comparator cannot fit the same distributional parameter, covariance
structure, or known-covariance route. The matrix above fixes the mapping and the
conversions. The plain binomial GLM parity row is now banked; the remaining
work is to run and audit the other comparator fits on a machine with the
required comparator packages and record those results in a Phase 19 article or
design note.

The first executable comparator artifact for plain binomial is the Phase 18
`binomial_fixed_effect` lane. It writes a `binomial-fe-glm-parity.csv` table
with maximum absolute coefficient, standard-error, `logLik`, AIC, and BIC
differences between `drmTMB` and `stats::glm()` for the two supported response
encodings. That table is a parity artifact, not a speed benchmark or interval
calibration claim.

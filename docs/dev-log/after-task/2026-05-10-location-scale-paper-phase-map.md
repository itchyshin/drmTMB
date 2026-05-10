# After Task: Location-Scale Paper Phase Map

## Goal

Map the models in Nakagawa et al.'s location-scale paper and companion tutorial
onto the current drmTMB roadmap, including what can be run now, what needs new
implementation, and where glmmTMB or brms comparisons require parameter-scale
care.

Primary sources checked:

- https://doi.org/10.1111/2041-210x.70203
- https://ayumi-495.github.io/Eco_location-scale_model/
- https://github.com/Ayumi-495/Eco_location-scale_model
- https://github.com/daniel1noble/individual_differences

## Model Map

| Tutorial or paper target | Comparator code in the tutorial | drmTMB status | Roadmap phase | Quality gate before claiming parity |
|---|---|---|---|---|
| Gaussian fixed-effect location-scale model for adult tarsus | `glmmTMB(log(AdTarsus) ~ Sex * Treatment, dispformula = ~ Sex * Treatment, family = gaussian)` and matching `brms` `sigma ~ ...` model | implemented now | Phase 7/8 validation | Add a local replication script and compare log-likelihood, `mu` coefficients, and `sigma` predictions. Keep drmTMB's public API on `sigma`, matching brms-style syntax and the local `glmmTMB` Gaussian check where `exp(dispformula linear predictor)` matched residual SD. When the paper interprets predictability as variance, report the derived `sigma^2` beside `sigma`. |
| Gaussian model with `mu` random intercepts and fixed-effect residual scale | `glmmTMB(lnSMI ~ RANK + (1 | NEST) + (1 | WORKYEAR), dispformula = ~ RANK, family = gaussian)` | implemented now if the current Gaussian random-effect and `sigma` paths pass the real-data comparator | Phase 7/8 validation | Compare likelihood and fixed effects against glmmTMB, then square `sigma` predictions for variance-scale predictability interpretation. Add deterministic checks for row filtering and group levels. |
| Double-hierarchical Gaussian location-scale model with correlated `mu` and `sigma` nest effects | `brms::bf(log(SMI) ~ RANK + (1 | q | NEST) + (1 | WORKYEAR), sigma ~ RANK + (1 | q | NEST) + (1 | WORKYEAR))` | partially supported only without the cross-parameter `mu`/`sigma` covariance; full model not implemented | Phase 11 | Implement labelled covariance blocks spanning `mu` and `sigma`, expose correlation pairs outside residual `rho12`, then add simulation recovery and brms comparator checks. |
| Negative-binomial location-scale count model with `mu` random intercepts | `glmmTMB(frequency ~ condition + sex + (1 | species) + (1 | id), dispformula = ~ condition + sex, family = nbinom2)` | fixed-effect NB2 exists; NB2 random effects are not implemented | Phase 8 then Phase 11 | Add NB2 random effects, verify glmmTMB parameterization, then compare estimates and log-likelihood on the preference-count data. |
| COM-Poisson location-scale count model | `glmmTMB(..., dispformula = ~ condition + sex, family = compois(link = "log"))` | not implemented | Phase 8 | Add a documented COM-Poisson parameter-link contract, independent likelihood checks, simulation recovery, and glmmTMB comparator tests for over- and under-dispersion. |
| Zero-one-inflated beta model for continuous proportions with boundary values | `brms::zero_one_inflated_beta()` with `zoi`, `coi`, and optional `phi` formulas plus a `Pool` random intercept | not implemented; strict beta is implemented, boundary 0/1 values remain out of scope for `beta()` | Phase 9 | Decide public names for boundary parameters, add zero/one boundary likelihood tests, then compare against brms on posterior-compatible summaries rather than exact ML equality. |
| Small simulation appendix for sample mean and SD bias | direct simulation, no fitted likelihood | can be reproduced now as an educational vignette or test-support note | Phase 8 documentation | Keep this as tutorial support, not a package feature claim. |

## brms Translation Lessons

The `daniel1noble/individual_differences` repository is the most direct
translation from the O'Dea, Noble, and Nakagawa worked example into brms
formula syntax. The public GitHub clone contains the rendered article and the
main `individual_differences.Rmd`; the data and saved model objects are
referenced as OSF downloads rather than stored in the GitHub repository.

The brms examples establish six concrete comparator shapes for drmTMB:

| Individual-difference target | brms pattern | drmTMB implication |
|---|---|---|
| Personality only | `bf(aggression ~ sex + age.Z + (1 | id))` | Already close to implemented univariate Gaussian `mu` random intercepts. |
| Personality and predictability | `bf(aggression ~ sex + age.Z + (1 | p | id), sigma ~ sex + age.Z + (1 | p | id))` | Requires a labelled covariance block spanning `mu` and `sigma` intercepts. Current drmTMB has separate `mu` random effects and Gaussian residual-scale random intercepts, but not their covariance. |
| Personality and plasticity | `bf(aggression ~ sex + age.Z + (1 + age.Z | p | id))` | Current drmTMB supports one Gaussian `mu` random slope; this is the nearest implemented individual-difference slice. |
| Personality, plasticity, and predictability | `bf(aggression ~ sex + age.Z + (1 + age.Z | q | id), sigma ~ sex + age.Z + (1 | q | id))` | This is the univariate full DHGLM MVP: one group-level block containing `mu` intercept, `mu` slope, and `sigma` intercept. |
| Bivariate personality | two formulas, each `bf(trait ~ sex + age.Z + (1 | q | id))`, added in one `brm()` call | Phase 11 should add bivariate group-level `mu1`/`mu2` covariance before attempting bivariate DHGLM. |
| Bivariate personality, plasticity, and predictability | two formulas, each `bf(trait ~ sex + age.Z + (1 + age.Z | z | id), sigma ~ sex + age.Z + (1 | z | id))`, added in one `brm()` call | This is the richest individual-difference target: a covariance block across two trait intercepts, two trait slopes, and two trait `sigma` intercepts. It is the acceptance-test horizon, not the first implementation step. |

The translation also records the derived quantities we should eventually expose
or teach in drmTMB examples:

- `Rp_m` and `CV_m` for mean/personality variation;
- `Rp_var` and `CV_var` for predictability variation;
- personality-plasticity associations from intercept-slope correlations;
- personality-predictability associations as sign-reversed correlations between
  mean-model intercepts and dispersion-model intercepts;
- plasticity-predictability associations from slope magnitudes and
  sign-reversed dispersion intercepts;
- bivariate behavioural, plasticity, and predictability syndromes from
  between-trait correlations.

The sign convention matters: larger residual variance means less
predictability, so the brms translation sign-reverses dispersion intercepts
when reporting personality-predictability and some plasticity-predictability
associations. A future drmTMB `corpairs()` or individual-differences helper
should make that convention explicit instead of silently returning raw
correlations on the `sigma`/variance scale.

The brms translation does not implement a residual `rho12` or coscale formula.
That is an important drmTMB opportunity, not a gap to copy. The paper's
group-level correlations describe between-individual covariance among
personality, plasticity, and predictability terms. drmTMB's bivariate Gaussian
`rho12` describes residual within-observation correlation after
response-specific location and scale models. The package should keep those
correlation levels in separate namespaces and teach both: `rho12` for
residual/coscale association, and labelled group-level covariance blocks for
individual-difference correlations.

## Timing Estimate

These are engineering-hour estimates from the current codebase state, not
calendar promises.

| Work block | Earliest start | Estimated focused hours | Notes |
|---|---:|---:|---|
| Set up a local replication harness using the tutorial GitHub data and code | after current Phase 9 checks close | 2-4 | Pull data, write drmTMB formulas, record glmmTMB/brms targets, and define comparator tolerances. |
| Reproduce Gaussian model 1 and model 2 with drmTMB and glmmTMB comparators | after harness | 4-8 | Mostly validation work; the important risk is scale-parameter mapping. |
| Full brms-style double-hierarchical Gaussian model | after Phase 11 design starts | 18-35 for a univariate MVP; 35-60 for robust docs/tests | First target should match `bf(y ~ x + (1 + x | q | id), sigma ~ x + (1 | q | id))`. Needs covariance blocks spanning `mu` and `sigma`, extractor design, simulation recovery, sign-aware association summaries, and careful optimizer diagnostics. |
| Bivariate brms-style double-hierarchical individual-difference model | after univariate MVP and bivariate `mu` covariance are stable | 40-80 | Acceptance horizon is two traits with one labelled block spanning both traits' `mu` intercepts, `mu` slopes, and `sigma` intercepts. This should wait until univariate DHGLM and bivariate `mu` random effects are tested. |
| NB2 random-effect comparator examples | after Gaussian comparator harness | 8-16 for first random-effect NB2 path | Current NB2 path is fixed-effect only. |
| COM-Poisson family and comparator | after NB2 random-effect path or as a separate Phase 8 slice | 12-24 | Needs parameterization decisions and numerical stability checks. |
| Zero-one-inflated beta examples | after Phase 9 boundary contract | 14-28 | Needs `zoi`/`coi` naming, boundary likelihood tests, and a brms-oriented comparator strategy. |

## Consistency Audit

The map stays inside drmTMB's one-response and two-response scope. The
double-hierarchical model is a univariate Gaussian model with multiple
distributional parameters and group-level covariance; it is not a
higher-dimensional multivariate model. Residual `rho12` remains reserved for
bivariate residual correlation, not for group-level `mu`/`sigma` covariance.

Scale vocabulary needs explicit checks before every external comparison.
The public drmTMB grammar should stay on `sigma`, matching brms-style
distributional syntax and the current project terminology. Biological terms
such as predictability and malleability are often interpreted on the variance
scale, so tutorials and comparator harnesses should report derived `sigma^2`
when that is the paper-facing estimand.

The O'Dea, Noble, and Nakagawa supplementary information explicitly contrasts
dispersion models based on residual standard deviations with dispersion models
based on residual variances, notes that residual standard deviation is the
default when fitting DHGLMs in `brms`, and gives the conversion between the two
log-scale parameterizations: fixed-effect/log-mean terms multiply by 2 when
moving from log SD to log variance, while corresponding variance components
multiply by 4. Local checks on this machine were consistent with treating
Gaussian `glmmTMB` 1.1.11 `dispformula` predictions as residual SD, whereas
`metafor` 4.8-0 location-scale `alpha` coefficients exponentiate to `tau^2`.
The replication harness should therefore record the package-native parameter,
the drmTMB `sigma` parameter, and the derived variance interpretation side by
side.

## Known Limitations

- I did not yet run the tutorial data through drmTMB.
- Wiley's article page is the publication target, but the companion tutorial
  and GitHub repository provided the runnable model formulas for this map.
- The timing estimates assume we finish the current Phase 9 documentation,
  pkgdown, and check loop first.
- The scale/variance distinction has been checked against the O'Dea et al.
  supplementary information, but public tutorial language should still show the
  `sigma` and `sigma^2` conversion explicitly so users do not have to infer it.

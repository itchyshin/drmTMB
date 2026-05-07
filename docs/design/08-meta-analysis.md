# Meta-Analysis Design

Meta-analysis in `drmTMB` is regression with known sampling covariance. It is
not a separate response family.

## Current Status

The current Gaussian location-scale MVP fits diagonal known-variance
meta-analysis models. Full and block-diagonal covariance matrices remain
planned.

## Implemented Diagonal MVP Syntax

```r
drmTMB(
  bf(
    yi ~ moderator + meta_known_V(V = vi),
    sigma ~ moderator
  ),
  family = gaussian(),
  data = dat
)
```

The response is on the left-hand side. `meta_known_V(V = vi)` supplies known
sampling variance and should not repeat the response name.

## Known Covariance Input

The first fitting implementation supports diagonal known sampling variance:

- `V = vi`, where `vi` is a data column or vector of known sampling variances;
- one non-negative variance per retained response row;
- independent known sampling errors conditional on the model.

The current implementation also accepts a diagonal matrix and extracts its
diagonal. Later implementations may allow:

- a diagonal matrix;
- a block-diagonal sparse matrix;
- a full covariance matrix.

The parser should treat `meta_known_V()` as a covariance marker, not as an
ordinary predictor column.

The API should be explicit that `vi` contains variances. If users have standard
errors, they should supply squared values.

## Unknown Heterogeneity

The public API uses `sigma` consistently:

```r
bf(
  yi ~ moderator + meta_known_V(V = V),
  sigma ~ moderator
)
```

In meta-analysis writing, this `sigma` corresponds to the extra heterogeneity
SD often called `tau`. We should explain that translation in documentation but
avoid a second `tau ~` grammar.

For the diagonal MVP, the implemented likelihood is:

```text
yi_i ~ Normal(mu_i, sqrt(vi_i + sigma_i^2))
mu_i = X_mu beta_mu
log(sigma_i) = X_sigma beta_sigma
```

## Heterogeneous Heterogeneity

Location-scale meta-analysis is a central use case:

```r
bf(
  yi ~ moderator + meta_known_V(V = vi),
  sigma ~ moderator
)
```

This follows the idea that categorical and continuous moderators can explain
between-study heterogeneity, not only average effect size.

Example interpretation: if the `sigma` slope for a binary moderator is `-0.4`,
then the extra heterogeneity SD is multiplied by `exp(-0.4) = 0.67` for the
moderator group, after adding the known sampling variance `vi`.

## Multiple Variance Components

Some meta-analyses require more than one unknown scale component:

```r
bf(
  yi ~ moderator + meta_known_V(V = V) + (1 | study) + (1 | species),
  sd(study) ~ moderator,
  sd(species) ~ 1
)
```

This is not a residual `sigma` model with random effects inside it. It is a
model with separate random-effect scale components.

This stage is planned after the diagonal known-variance fixed-effect path and
after ordinary random effects are implemented and tested.

## Implementation Caveats

- Do not introduce `meta_gaussian()`; meta-analysis remains
  `family = gaussian()`.
- Do not introduce `tau ~` grammar; document the translation from `sigma` to
  meta-analysis terminology instead.
- The diagonal MVP rejects unsupported full-matrix and block-matrix input until
  those likelihood paths exist.
- Row alignment matters: `vi` must be subset in the same way as the response
  and model matrices after missing-data handling.
- The diagonal path has simulation recovery tests with known `V`.

## Initial Implementation Order

1. Diagonal known sampling variance plus unknown residual `sigma`.
2. Full or sparse known covariance matrix plus unknown diagonal `sigma`.
3. Random intercept meta-regression.
4. Multiple random-effect scale components.
5. Bivariate meta-analysis with known within-study covariance.

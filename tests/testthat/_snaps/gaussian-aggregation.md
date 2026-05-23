# Gaussian aggregation rejects unsupported first-slice models

    Code
      drmTMB(bf(y ~ habitat + (1 | id), sigma ~ 1), data = dat, control = drm_control(
        aggregate_gaussian = TRUE))
    Condition
      Error in `validate_gaussian_aggregation_gaussian()`:
      ! Gaussian aggregation is not implemented with ordinary random effects yet.
      i Use a fixed-effect Gaussian model first, or set `aggregate_gaussian = FALSE`.

---

    Code
      drmTMB(bf(y ~ habitat + meta_V(V = v), sigma ~ 1), data = dat, control = drm_control(
        aggregate_gaussian = TRUE))
    Condition
      Error in `validate_gaussian_aggregation_gaussian()`:
      ! Gaussian aggregation is not implemented with known sampling covariance yet.
      i Refit without `meta_V()` or set `aggregate_gaussian = FALSE`.

---

    Code
      drmTMB(bf(y ~ habitat + phylo(1 | id, tree = tree), sigma ~ 1), data = dat,
      control = drm_control(aggregate_gaussian = TRUE))
    Condition
      Error in `validate_gaussian_aggregation_gaussian()`:
      ! Gaussian aggregation is not implemented with structured random effects yet.
      i Fit the phylogenetic, spatial, animal, or relatedness model without row aggregation in this phase.

---

    Code
      drmTMB(bf(y ~ habitat, sigma ~ 1), data = dat, weights = rep(c(1, 2),
      length.out = nrow(dat)), control = drm_control(aggregate_gaussian = TRUE))
    Condition
      Error in `drm_validate_gaussian_aggregation_weights()`:
      ! Gaussian aggregation currently requires unit likelihood weights.
      i Fit without `aggregate_gaussian = TRUE`, or remove `weights` until weighted sufficient statistics are implemented.

---

    Code
      drmTMB(bf(y ~ habitat, sigma ~ 1), data = dat, control = drm_control(
        aggregate_gaussian = TRUE, sparse_fixed = TRUE))
    Condition
      Error in `validate_gaussian_aggregation_gaussian()`:
      ! Gaussian aggregation cannot be combined with sparse fixed-effect matrices yet.
      i Use either `aggregate_gaussian = TRUE` or `sparse_fixed = TRUE`, but not both in this phase.

---

    Code
      drmTMB(bf(y ~ habitat), family = poisson(), data = transform(dat, y = as.integer(
        abs(y) * 10) + 1L), control = drm_control(aggregate_gaussian = TRUE))
    Condition
      Error in `drmTMB()`:
      ! Gaussian aggregation is implemented only for univariate Gaussian models in this phase.
      i Use `family = gaussian()` with a fixed-effect `mu` formula, or set `aggregate_gaussian = FALSE`.

---

    Code
      drmTMB(drm_formula(mu1 = y ~ habitat, mu2 = y2 ~ habitat, sigma1 = ~1, sigma2 = ~
      1, rho12 = ~1), family = c(gaussian(), gaussian()), data = transform(dat, y2 = y +
        0.1), control = drm_control(aggregate_gaussian = TRUE))
    Condition
      Error in `drmTMB()`:
      ! Gaussian aggregation is implemented only for univariate Gaussian models in this phase.
      i Use `family = gaussian()` with a fixed-effect `mu` formula, or set `aggregate_gaussian = FALSE`.


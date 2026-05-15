# sparse fixed-effect parity helper checks beta length

    Code
      drmTMB:::drm_sparse_fixed_parity(terms, dat, beta = 1)
    Condition
      Error in `drmTMB:::drm_sparse_fixed_parity()`:
      ! `beta` must have length equal to the design-matrix column count.

# sparse fixed-effect fitting rejects unsupported first-slice models

    Code
      drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), data = dat, control = drm_control(
        sparse_fixed = TRUE))
    Condition
      Error in `validate_sparse_fixed_gaussian()`:
      ! Sparse fixed-effect matrices are not implemented with ordinary random effects yet.
      i Use a fixed-effect Gaussian location model first, or set `sparse_fixed = FALSE`.

---

    Code
      drmTMB(bf(y ~ x, sigma ~ x), data = dat, control = drm_control(sparse_fixed = TRUE))
    Condition
      Error in `validate_sparse_fixed_gaussian()`:
      ! Sparse fixed-effect matrices currently require intercept-only `sigma`.
      i Use `sigma = ~ 1` or set `sparse_fixed = FALSE`.

---

    Code
      drmTMB(bf(y ~ x), family = poisson(), data = transform(dat, y = rpois(12, 2)),
      control = drm_control(sparse_fixed = TRUE))
    Condition
      Error in `drmTMB()`:
      ! Sparse fixed-effect matrices are implemented only for univariate Gaussian models in this phase.
      i Use `family = gaussian()` with a fixed-effect `mu` formula, or set `sparse_fixed = FALSE`.


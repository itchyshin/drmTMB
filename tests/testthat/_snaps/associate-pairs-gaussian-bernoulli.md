# Gaussian x Bernoulli association fences unsupported public methods

    Code
      rho12(association_fit)
    Condition
      Error in `rho12()`:
      ! `rho12()` is defined for `biv_gaussian()` fits, not mixed pair associations.
      i Use `association()` for the Arc 6.1 latent-normal estimand.

---

    Code
      vcov(association_fit)
    Condition
      Error in `vcov()`:
      ! `vcov()` is unavailable for Arc 6.1 frozen-margin association estimates.
      i A later Arc must validate two-stage sandwich or bootstrap uncertainty.

---

    Code
      confint(association_fit)
    Condition
      Error in `confint()`:
      ! Confidence intervals are unavailable for Arc 6.1 frozen-margin association estimates.
      i A later Arc must validate two-stage uncertainty before `confint()` is available.

---

    Code
      quantile(association_fit)
    Condition
      Error in `quantile()`:
      ! Quantiles are unavailable for Arc 6.1 frozen-margin association estimates.

---

    Code
      update(association_fit)
    Condition
      Error in `update()`:
      ! Frozen-margin association objects cannot be updated.
      i Refit declared margins separately, then construct a new `associate_pairs()` object.

---

    Code
      emmeans::recover_data(association_fit)
    Condition
      Error in `mth()`:
      ! emmeans is unavailable for Arc 6.1 frozen-margin association estimates.

---

    Code
      predict(association_fit, newdata = data.frame(x = 0))
    Condition
      Error in `predict()`:
      ! Arc 6.1 association predictions are defined only for frozen analysis rows.
      i New-data association prediction needs a separate validated Arc.

---

    Code
      associate_pairs(fits$gaussian, fits$binary, kernel = latent_normal(),
      association = ~x)
    Condition
      Error in `drm_pair_validate_intercept_only()`:
      ! Arc 6.1 supports only `association = ~ 1`.
      i Association slopes require a later Arc and separate identification review.

---

    Code
      associate_pairs(fits$gaussian, fits$binary)
    Condition
      Error in `associate_pairs()`:
      ! Supply an explicit `kernel = latent_normal()` declaration.

---

    Code
      associate_pairs(fits$gaussian, fits$binary, kernel = latent_normal())
    Condition
      Error in `associate_pairs()`:
      ! Supply `association = ~ 1`; Arc 6.1 has no implicit association model.

# Gaussian x Bernoulli association rejects different rows and trials

    Code
      associate_pairs(fits$gaussian, binary_other, kernel = latent_normal(),
      association = ~1)
    Condition
      Error in `drm_pair_validate_shared_data()`:
      ! The two margins must be fitted on identical complete analysis data in identical row order.
      i Refit both margins after constructing one complete-pair analysis data set.

---

    Code
      associate_pairs(trial_gaussian, trial_fit, kernel = latent_normal(),
      association = ~1)
    Condition
      Error in `drm_pair_validate_bernoulli()`:
      ! Arc 6.1 requires literal 0/1 Bernoulli data fitted with `binomial(link = "logit")`.
      i Binomial trials and weights-as-trials require a later pair contract.


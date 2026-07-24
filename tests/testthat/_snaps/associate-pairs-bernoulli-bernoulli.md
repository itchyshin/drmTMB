# Bernoulli x Bernoulli diagnostics and fences are explicit

    Code
      rho12(association_fit)
    Condition
      Error in `rho12()`:
      ! `rho12()` is defined for `biv_gaussian()` fits, not mixed pair associations.
      i Use `association()` for the Arc 6 latent-normal estimand.

---

    Code
      vcov(association_fit)
    Condition
      Error in `vcov()`:
      ! `vcov()` is unavailable for Arc 6 frozen-margin association estimates.
      i A later Arc must validate two-stage sandwich or bootstrap uncertainty.

---

    Code
      confint(association_fit)
    Condition
      Error in `confint()`:
      ! Confidence intervals are unavailable for Arc 6 frozen-margin association estimates.
      i A later Arc must validate two-stage uncertainty before `confint()` is available.

---

    Code
      predict(association_fit, newdata = data.frame(x = 0))
    Condition
      Error in `predict()`:
      ! Arc 6 association predictions are defined only for frozen analysis rows.
      i New-data association prediction needs a separate validated Arc.

---

    Code
      associate_pairs(fits$binary_1, fits$binary_1, kernel = latent_normal(),
      association = ~1)
    Condition
      Error in `associate_pairs()`:
      ! Arc 6 requires two distinct response variables.


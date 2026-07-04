#' Bivariate Gaussian response family
#'
#' `biv_gaussian()` defines a two-response Gaussian distribution with formulas
#' for both locations, both residual standard deviations, and residual
#' correlation `rho12`. The residual-correlation link is recorded as
#' `"atanh_guarded"` because fitted response-scale correlations use
#' `rho12 = 0.999999 * tanh(eta_rho12)`.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' biv_gaussian()
biv_gaussian <- function() {
  structure(
    list(
      name = "biv_gaussian",
      family = "biv_gaussian",
      n_response = 2L,
      dpars = c("mu1", "mu2", "sigma1", "sigma2", "rho12"),
      links = c(
        mu1 = "identity",
        mu2 = "identity",
        sigma1 = "log",
        sigma2 = "log",
        rho12 = "atanh_guarded"
      )
    ),
    class = "drm_family"
  )
}

#' Student-t response family
#'
#' `student()` defines a one-response Student-t distribution with formulas for
#' location `mu`, residual scale `sigma`, and degrees of freedom `nu`.
#'
#' Here `sigma` is the Student-t **scale**, not the response standard deviation.
#' The density is the location-scale t evaluated at `z = (y - mu) / sigma`, so the
#' standard deviation of `y` is `SD[y] = sigma * sqrt(nu / (nu - 2))` for `nu > 2`
#' and is strictly larger than `sigma` (about 73% larger at `nu = 3`, shrinking to
#' `sigma` as `nu -> Inf`). This is the one implemented family whose public
#' `sigma` is a scale rather than `SD[y]`: the location-scale t has no closed-form
#' standard-deviation parameterization, and both `drmTMB` and its `DRM.jl` twin
#' fit `sigma` as the scale.
#'
#' The `nu` parameter uses a log link with a lower bound of 2:
#' `nu = 2 + exp(eta_nu)`. This keeps the fitted distribution in the
#' finite-variance region (`nu > 2`) while still allowing heavy tails. The lower
#' bound is a deliberate design choice, not a standard-deviation requirement: it
#' guarantees a finite variance and a well-defined `SD[y]`. The model therefore
#' **cannot** represent the very heavy tails of `nu <= 2` (for example a
#' Cauchy-like `nu = 1`); data that genuinely need `nu <= 2` would require lifting
#' the floor, which is not implemented. `check_drm()` warns when the fitted `nu`
#' approaches the boundary at 2, where the slant of the likelihood in `nu` is
#' weakly identified.
#' Ordinary `mu` random intercepts and independent numeric slopes such as
#' `(1 | id)` and `(0 + x | id)` are supported in the first Student-t
#' mixed-model slice; correlated slopes, `sigma` random effects, and `nu`
#' random effects remain separate planned gates.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' student()
student <- function() {
  structure(
    list(
      name = "student",
      family = "student",
      n_response = 1L,
      dpars = c("mu", "sigma", "nu"),
      links = c(mu = "identity", sigma = "log", nu = "logm2")
    ),
    class = "drm_family"
  )
}

#' Skew-normal response family
#'
#' `skew_normal()` defines a one-response skew-normal distribution with
#' formulas for location `mu`, residual standard deviation `sigma`, and
#' residual slant `nu`.
#'
#' The first implementation is fixed-effect and univariate:
#' `mu = eta_mu`, `log(sigma) = eta_sigma`, and `nu = eta_nu`. The likelihood
#' transforms internally to the native Azzalini location `xi`, scale `omega`,
#' and slant `alpha = nu`, but user-facing methods keep the public moment
#' parameterization: [fitted()] returns `E[y] = mu`, [stats::sigma()] returns
#' `SD[y] = sigma`, and `predict(..., dpar = "nu")` returns the residual slant.
#' Positive `nu` gives right-skewed residuals, negative `nu` gives left-skewed
#' residuals, and `nu = 0` reduces to the Gaussian location-scale likelihood.
#'
#' Random effects, `sigma` or `nu` random effects, `sd(group)` scale formulas,
#' structured effects, known sampling covariance, bivariate skew-normal models,
#' residual `rho12`, and latent `skew(id)` syntax remain planned but
#' unsupported in this first slice.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' skew_normal()
skew_normal <- function() {
  structure(
    list(
      name = "skew_normal",
      family = "skew_normal",
      n_response = 1L,
      dpars = c("mu", "sigma", "nu"),
      links = c(mu = "identity", sigma = "log", nu = "identity")
    ),
    class = "drm_family"
  )
}

#' Lognormal response family
#'
#' `lognormal()` defines a one-response positive continuous distribution with
#' formulas for log-location `mu` and log-scale `sigma`.
#'
#' The model is defined on the log response scale:
#' `log(y) ~ Normal(mu, sigma^2)`. The fitted distributional parameter `mu` is
#' therefore the mean of `log(y)`, not the arithmetic mean of `y`.
#' Ordinary `mu` random intercepts and independent numeric slopes such as
#' `(1 | id)` and `(0 + x | id)` are supported in the first
#' positive-continuous mixed-model slice.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' lognormal()
lognormal <- function() {
  structure(
    list(
      name = "lognormal",
      family = "lognormal",
      n_response = 1L,
      dpars = c("mu", "sigma"),
      links = c(mu = "identity", sigma = "log")
    ),
    class = "drm_family"
  )
}

#' Tweedie response family
#'
#' `tweedie()` defines a one-response Tweedie compound Poisson-Gamma
#' distribution for non-negative continuous responses with exact zeros.
#'
#' The first implemented contract is fixed-effect and univariate:
#' `log(mu) = eta_mu`, `log(sigma) = eta_sigma`,
#' `nu = 1 + plogis(eta_nu)`, `phi = sigma^2`, `E[y] = mu`, and
#' `Var(y) = sigma^2 * mu^nu`, with `1 < nu < 2`. The public `sigma`
#' parameter is therefore the square root of the usual Tweedie dispersion
#' `phi`. Random effects, predictor-dependent `nu`, bivariate Tweedie models,
#' structured effects, zero-inflation aliases, and hurdle aliases remain
#' planned but unsupported in this first slice.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' tweedie()
tweedie <- function() {
  structure(
    list(
      name = "tweedie",
      family = "tweedie",
      n_response = 1L,
      dpars = c("mu", "sigma", "nu"),
      links = c(mu = "log", sigma = "log", nu = "logit12")
    ),
    class = "drm_family"
  )
}

#' Beta response family
#'
#' `beta()` defines a one-response distribution for continuous proportions
#' strictly inside `(0, 1)`, with formulas for mean `mu` and scale `sigma`.
#'
#' The implemented contract is
#' `logit(mu) = eta_mu`, `log(sigma) = eta_sigma`, and internal precision
#' `phi = 1 / sigma^2`. Larger `sigma` therefore means more variation around
#' the mean, not more precision.
#' Ordinary unlabelled random intercepts and independent numeric slopes such as
#' `(1 | id)` and `(0 + x | id)` may enter the logit-`mu` predictor; `sigma`
#' remains fixed-effect in this first slice.
#'
#' This helper masks [base::beta()] when `drmTMB` is attached. Use
#' `base::beta()` for the mathematical beta function.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' beta()
beta <- function() {
  structure(
    list(
      name = "beta",
      family = "beta",
      n_response = 1L,
      dpars = c("mu", "sigma"),
      links = c(mu = "logit", sigma = "log")
    ),
    class = "drm_family"
  )
}

#' Zero-one beta response family
#'
#' `zero_one_beta()` defines a one-response distribution for continuous
#' proportions on `[0, 1]` when exact zeroes or ones are structural outcomes
#' rather than binomial denominator outcomes.
#'
#' The implemented fixed-effect contract is `logit(mu) = eta_mu`,
#' `log(sigma) = eta_sigma`, `logit(zoi) = eta_zoi`, and
#' `logit(coi) = eta_coi`. Here `zoi` is the probability that an observation
#' is exactly 0 or 1, and `coi` is the conditional probability of an exact 1
#' given that the observation is on the boundary. Interior observations follow
#' the same beta mean-scale contract as [beta()], with internal precision
#' `phi = 1 / sigma^2`.
#'
#' `fitted()` returns the unconditional response mean
#' `(1 - zoi) * mu + zoi * coi`. Random effects, structured effects, covariance
#' blocks, and denominator syntax are not implemented for this first fixed-
#' effect slice.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' zero_one_beta()
zero_one_beta <- function() {
  structure(
    list(
      name = "zero_one_beta",
      family = "zero_one_beta",
      n_response = 1L,
      dpars = c("mu", "sigma", "zoi", "coi"),
      links = c(mu = "logit", sigma = "log", zoi = "logit", coi = "logit")
    ),
    class = "drm_family"
  )
}

#' Beta-binomial response family
#'
#' `beta_binomial()` defines a one-response denominator-aware distribution for
#' successes out of known trials. Use it with two-column count responses such as
#' `bf(cbind(successes, failures) ~ x, sigma ~ z)`, where
#' `trials_i = successes_i + failures_i`.
#'
#' The implemented contract is `logit(mu) = eta_mu`,
#' with optional ordinary unlabelled `mu` random intercepts,
#' `log(sigma) = eta_sigma`, and internal beta precision
#' `phi = 1 / sigma^2`. Conditional on a latent success probability
#' `p_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)`, the observed successes
#' follow `Binomial(trials_i, p_i)`. Larger `sigma` means more extra-binomial
#' variation around the mean probability.
#'
#' The first mixed-model slice supports ordinary `mu` random intercepts and
#' independent numeric slopes such as
#' `bf(cbind(successes, failures) ~ x + (1 | id) + (0 + x | id),
#' sigma ~ z)`. Correlated slopes, labelled covariance blocks, `sigma` random
#' effects, `zoi`/`coi`, `meta_V(V = V)`, phylogenetic or spatial terms,
#' bivariate beta-binomial models, and a `successes/trials` response alias are
#' planned but not implemented.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' beta_binomial()
beta_binomial <- function() {
  structure(
    list(
      name = "beta_binomial",
      family = "beta_binomial",
      n_response = 1L,
      dpars = c("mu", "sigma"),
      links = c(mu = "logit", sigma = "log")
    ),
    class = "drm_family"
  )
}

#' Cumulative logit ordinal response family
#'
#' `cumulative_logit()` defines a one-response ordinal model for ordered
#' categories. The first implemented path uses a location formula `mu ~ ...`
#' and ordered cutpoints with a fixed latent logistic scale. The location
#' intercept is dropped internally, as in standard cumulative-link models,
#' because a free location intercept and free cutpoints are not jointly
#' identifiable.
#'
#' The implemented contract is
#' `Pr(y_i <= k) = logit^-1(theta_k - mu_i)`, with
#' `mu_i = X_mu[i, ] beta_mu` and
#' `theta[1] < theta[2] < ... < theta[K - 1]`. `fitted()` returns the expected
#' ordered-category score, `sum_k k * Pr(y_i = k)`. Ordinal scale or
#' discrimination formulas are planned but not exposed in this first
#' implementation.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' cumulative_logit()
cumulative_logit <- function() {
  structure(
    list(
      name = "cumulative_logit",
      family = "cumulative_logit",
      n_response = 1L,
      dpars = c("mu"),
      links = c(mu = "identity")
    ),
    class = "drm_family"
  )
}

#' Negative binomial 2 response family
#'
#' `nbinom2()` defines a one-response count distribution with formulas for the
#' mean `mu` and overdispersion scale `sigma`.
#'
#' The implemented contract is
#' `log(mu) = eta_mu`, `log(sigma) = eta_sigma`, and
#' `Var(y) = mu + sigma^2 * mu^2`. Thus larger `sigma` means greater
#' extra-Poisson variation. Internally this is equivalent to the usual NB2
#' size parameter `size = 1 / sigma^2`. Ordinary non-zero-inflated NB2 models
#' also support first-slice random intercepts on the log-`sigma` predictor,
#' such as `bf(count ~ x, sigma ~ z + (1 | id))`; NB2 `sigma` slopes,
#' structured `sigma` effects, and zero-inflated NB2 `sigma` random effects
#' remain planned.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' nbinom2()
nbinom2 <- function() {
  structure(
    list(
      name = "nbinom2",
      family = "nbinom2",
      n_response = 1L,
      dpars = c("mu", "sigma"),
      links = c(mu = "log", sigma = "log")
    ),
    class = "drm_family"
  )
}

#' Zero-truncated negative binomial 2 response family
#'
#' `truncated_nbinom2()` defines a one-response positive-count distribution
#' with formulas for the untruncated NB2 mean `mu` and overdispersion scale
#' `sigma`.
#'
#' Adding `hu ~ predictors` to the model formula fits the corresponding hurdle
#' NB2 model: `hu` is the probability of a hurdle zero, and nonzero counts are
#' drawn from the zero-truncated NB2 component.
#'
#' The implemented contract is
#' `log(mu) = eta_mu`, `log(sigma) = eta_sigma`, and the count response is
#' distributed as NB2 conditional on being greater than zero. The untruncated
#' NB2 variance is `Var(y) = mu + sigma^2 * mu^2`, with internal
#' `size = 1 / sigma^2`.
#'
#' Ordinary zero-truncated NB2 models support first-slice random intercepts and
#' independent numeric slopes in the log-mean predictor, such as
#' `bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z)`. Hurdle NB2 random
#' effects, correlated zero-truncated slopes, structured effects, and
#' overdispersion-side random effects remain planned.
#'
#' @return A `drm_family` object.
#' @export
#'
#' @examples
#' truncated_nbinom2()
truncated_nbinom2 <- function() {
  structure(
    list(
      name = "truncated_nbinom2",
      family = "truncated_nbinom2",
      n_response = 1L,
      dpars = c("mu", "sigma"),
      links = c(mu = "log", sigma = "log")
    ),
    class = "drm_family"
  )
}

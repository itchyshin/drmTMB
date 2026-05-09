#' Bivariate Gaussian response family
#'
#' `biv_gaussian()` defines a two-response Gaussian distribution with formulas
#' for both locations, both residual standard deviations, and residual
#' correlation `rho12`. The residual-correlation link is recorded as
#' `"atanh_guarded"` because fitted response-scale correlations use
#' `rho12 = 0.99999999 * tanh(eta_rho12)`.
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
#' The `nu` parameter uses a log link with a lower bound of 2:
#' `nu = 2 + exp(eta_nu)`. This keeps the fitted distribution in the
#' finite-variance region while still allowing heavy tails.
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

#' Lognormal response family
#'
#' `lognormal()` defines a one-response positive continuous distribution with
#' formulas for log-location `mu` and log-scale `sigma`.
#'
#' The model is defined on the log response scale:
#' `log(y) ~ Normal(mu, sigma^2)`. The fitted distributional parameter `mu` is
#' therefore the mean of `log(y)`, not the arithmetic mean of `y`.
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

#' Beta response family
#'
#' `beta()` defines a one-response distribution for continuous proportions
#' strictly inside `(0, 1)`, with formulas for mean `mu` and scale `sigma`.
#'
#' The implemented contract is
#' `logit(mu) = eta_mu`, `log(sigma) = eta_sigma`, and internal precision
#' `phi = 1 / sigma^2`. Larger `sigma` therefore means more variation around
#' the mean, not more precision.
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

#' Negative binomial 2 response family
#'
#' `nbinom2()` defines a one-response count distribution with formulas for the
#' mean `mu` and overdispersion scale `sigma`.
#'
#' The implemented contract is
#' `log(mu) = eta_mu`, `log(sigma) = eta_sigma`, and
#' `Var(y) = mu + sigma^2 * mu^2`. Thus larger `sigma` means greater
#' extra-Poisson variation. Internally this is equivalent to the usual NB2
#' size parameter `size = 1 / sigma^2`.
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
#' The implemented contract is
#' `log(mu) = eta_mu`, `log(sigma) = eta_sigma`, and the count response is
#' distributed as NB2 conditional on being greater than zero. The untruncated
#' NB2 variance is `Var(y) = mu + sigma^2 * mu^2`, with internal
#' `size = 1 / sigma^2`.
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

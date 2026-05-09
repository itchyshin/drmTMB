#' Bivariate Gaussian response family
#'
#' `biv_gaussian()` defines a two-response Gaussian distribution with formulas
#' for both locations, both residual standard deviations, and residual
#' correlation `rho12`.
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
        rho12 = "atanh"
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

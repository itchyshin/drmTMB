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

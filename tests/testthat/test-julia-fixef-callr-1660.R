# #1660 — fixef() on drmTMB_julia inside a callr subprocess after pkgload,
# mirroring live Julia family tests that attach nothing but hit a masked generic.

julia_callr_fixef_result <- function() {
  # The child must load the same drmTMB this suite is testing: the source tree
  # under devtools::test() (pkgload), the installed copy under R CMD check or
  # covr, where callr inherits .libPaths().
  dev_path <- if (pkgload::is_dev_package("drmTMB")) {
    getNamespaceInfo("drmTMB", "path")
  }
  callr::r(
    function(dev_path) {
      if (is.null(dev_path)) {
        loadNamespace("drmTMB")
      } else {
        pkgload::load_all(dev_path, compile = FALSE, export_all = FALSE, quiet = TRUE)
      }
      result <- list(
        coef_names = c("mu_(Intercept)", "mu_x"),
        coefficients = c(0.2, 0.3),
        vcov = diag(c(0.01, 0.01)),
        loglik = -3,
        aic = 12,
        bic = 13,
        df = 2L,
        nobs = 8L,
        converged = TRUE,
        fitted = rep(0, 8L),
        residuals = rep(0, 8L),
        sigma = 1,
        corpairs = list()
      )
      form <- drmTMB::bf(y ~ x)
      fit <- drmTMB:::new_drmTMB_julia(
        result = result,
        call = quote(drmTMB(form, data = dat, engine = "julia")),
        formula = form,
        family = stats::gaussian(),
        data = data.frame(y = rnorm(8), x = rnorm(8)),
        family_type = "gaussian"
      )
      invisible(library(nlme))
      drmTMB::fixef(fit)
    },
    args = list(dev_path = dev_path),
    show = FALSE
  )
}

test_that("fixef() on drmTMB_julia works in a callr subprocess (#1660)", {
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  ans <- julia_callr_fixef_result()
  expect_type(ans, "list")
  expect_true("mu" %in% names(ans))
  expect_equal(unname(ans$mu["(Intercept)"]), 0.2)
})

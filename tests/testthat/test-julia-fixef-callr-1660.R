# #1660 — fixef() on drmTMB_julia inside a callr subprocess after pkgload,
# mirroring live Julia family tests that attach nothing but hit a masked generic.

julia_callr_fixef_result <- function() {
  if (!requireNamespace("callr", quietly = TRUE)) {
    return(list(ok = FALSE, skip = "callr not installed"))
  }
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = FALSE)
  if (!file.exists(file.path(pkg, "DESCRIPTION"))) {
    return(list(ok = FALSE, skip = "source tree unavailable"))
  }
  callr::r(
    function(pkg) {
      pkgload::load_all(pkg, compile = FALSE, export_all = FALSE, quiet = TRUE)
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
    args = list(pkg = pkg),
    show = FALSE
  )
}

test_that("fixef() on drmTMB_julia works in a callr subprocess (#1660)", {
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("nlme")
  ans <- julia_callr_fixef_result()
  expect_type(ans, "list")
  expect_true("mu" %in% names(ans))
  expect_equal(unname(ans$mu["(Intercept)"]), 0.2)
})
# #1891: Wald confint() warns and marks conf.status when a limit is non-finite
# on a degenerate fit.

test_that("wald confint warns on non-finite sigma limit for degenerate NB2 (#1891)", {
  set.seed(11)
  d <- data.frame(y = stats::rnbinom(60, mu = 2, size = 5), x = stats::rnorm(60))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = d, family = nbinom2())
  expect_identical(convergence_status(fit), "degenerate")
  ci <- NULL
  expect_warning(
    ci <- stats::confint(fit, method = "wald"),
    class = "drmTMB_wald_nonfinite_warning"
  )
  sigma_row <- ci[ci$parm == "sigma", , drop = FALSE]
  expect_equal(sigma_row$conf.status, "wald_nonfinite")
  expect_false(is.finite(sigma_row$upper))
})
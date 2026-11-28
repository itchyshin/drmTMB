# #1892: logLik(), AIC(), and BIC() warn when convergence_status() is not converged
# but still return the same finite values.

boundary_re_fit <- function() {
  set.seed(20261016)
  g <- factor(rep(seq_len(8), each = 25))
  u <- stats::rnorm(nlevels(g), sd = 0.8)
  fit <- drmTMB(
    bf(y ~ x + (1 | g), sigma ~ 1),
    data = data.frame(
      y = stats::rnorm(length(g), sd = 0.4) + u[g],
      x = stats::rnorm(length(g)),
      g = g
    )
  )
  fit$sdpars$mu[[1L]] <- 1e-8
  fit
}

test_that("logLik/AIC/BIC warn on boundary fit but return finite values (#1892)", {
  fit <- boundary_re_fit()
  expect_identical(convergence_status(fit), "boundary")
  ll_before <- as.numeric(fit$logLik)
  expect_warning(ll <- stats::logLik(fit), class = "drmTMB_ic_convergence_warning")
  expect_equal(as.numeric(ll), ll_before)
  expect_warning(a <- AIC(fit), class = "drmTMB_ic_convergence_warning")
  expect_equal(a, as.numeric(-2 * ll + 2 * attr(ll, "df")))
  expect_warning(b <- BIC(fit), class = "drmTMB_ic_convergence_warning")
  expect_equal(b, as.numeric(-2 * ll + log(fit$nobs) * attr(ll, "df")))
})

test_that("logLik/AIC/BIC warn on degenerate NB2 fit (#1892)", {
  set.seed(11)
  d <- data.frame(y = stats::rnbinom(60, mu = 2, size = 5), x = stats::rnorm(60))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = d, family = nbinom2())
  expect_identical(convergence_status(fit), "degenerate")
  expect_warning(as.numeric(stats::logLik(fit)), "degenerate")
  expect_warning(AIC(fit), "degenerate")
  expect_warning(BIC(fit), "degenerate")
})
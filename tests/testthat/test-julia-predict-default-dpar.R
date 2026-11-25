# predict() with dpar = NULL must default to the location parameter "mu" on
# the Julia bridge, as the native engine does, whatever order the engine
# lists its coefficient blocks in. A hurdle NB2 bridge fit lists "hu" first.
test_that("bridge predict() default dpar is mu when hu is listed first", {
  result <- list(
    coef_names = c("hu_(Intercept)", "mu_(Intercept)", "mu_x", "sigma_(Intercept)"),
    coefficients = c(0.3, 0.1, 0.4, -0.2),
    vcov = diag(c(0.01, 0.02, 0.03, 0.04)),
    loglik = -12.5, aic = 33, bic = 35, df = 4L, nobs = 6L,
    converged = TRUE, fitted = seq_len(6), residuals = rep(0.1, 6),
    sigma = rep(0.8, 6), corpairs = list()
  )
  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(bf(y ~ x, sigma ~ 1, hu ~ 1), family = truncated_nbinom2(),
                        data = dat, engine = "julia")),
    formula = bf(y ~ x, sigma ~ 1, hu ~ 1),
    family = truncated_nbinom2(),
    data = data.frame(y = seq_len(6), x = seq_len(6)),
    family_type = "truncated_nbinom2"
  )
  expect_identical(names(fit$coefficients)[[1L]], "hu")
  expect_equal(predict(fit), predict(fit, dpar = "mu"))
  expect_equal(predict(fit, newdata = data.frame(x = 1)),
               predict(fit, newdata = data.frame(x = 1), dpar = "mu"))
})

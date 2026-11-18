test_that("the Bernoulli Laplace oracle rejects missing failure counts", {
  fixture <- binomial_sd_fixture(groups = 4L, repeats = 3L)$data
  fixture$failure <- NULL

  expect_error(
    binomial_sd_laplace_oracle(
      fixture,
      beta = c("(Intercept)" = -0.3, x = 0.6),
      alpha = c("(Intercept)" = log(0.8), w = 0.5)
    ),
    "failure"
  )
})

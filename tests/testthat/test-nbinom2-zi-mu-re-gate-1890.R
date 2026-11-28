test_that("ZINB refuses mu random intercept when sigma has no RE", {
  set.seed(11261126)
  M <- 8
  ne <- 12
  id <- factor(rep(seq_len(M), each = ne))
  n <- length(id)
  x <- stats::rnorm(n)
  mu <- exp(0.3 + 0.2 * x)
  y <- stats::rnbinom(n, mu = mu, size = 4)
  y[stats::runif(n) < 0.12] <- 0L
  dat <- data.frame(y = y, x = x, id = id)

  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1, zi ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "Only the exact zero-inflated NB2"
  )

  expect_no_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1 + (1 | id), zi ~ 1),
      family = nbinom2(),
      data = dat,
      control = drm_control(optimizer = list(iter.max = 80, eval.max = 80))
    )
  )
})
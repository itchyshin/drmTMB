# #1572: R's `offset()` cannot be marshalled to DRM.jl (it needs a fixed,
# non-estimated coefficient). drmTMB refuses it in R, before Julia starts,
# with a next step worded by drmTMB. The native log-2 identity is the bar the
# refusal points users to.

offset_test_data <- function() {
  set.seed(202610167L)
  n_g <- 20L
  per <- 10L
  n <- n_g * per
  g <- factor(rep(sprintf("g%02d", seq_len(n_g)), each = per))
  x <- rnorm(n)
  effort <- runif(n, 0.5, 2.5)
  off <- log(effort)
  u <- rnorm(n_g, 0, 0.35)
  eta <- 0.25 + 0.40 * x + u[as.integer(g)]
  y <- rpois(n, lambda = effort * exp(eta))
  data.frame(y, x, off, g)
}

test_that("engine = 'julia' refuses offset() in R before Julia starts", {
  d <- offset_test_data()
  # If this reached JuliaCall it would error with a different class (or skip
  # setup); the classed R refusal must come first.
  expect_error(
    drmTMB(bf(y ~ x + offset(off)), family = poisson(link = "log"),
           data = d, engine = "julia"),
    class = "drmTMB_julia_offset_unsupported"
  )
  expect_error(
    drmTMB(bf(y ~ x + offset(off) + (1 | g)), family = poisson(link = "log"),
           data = d, engine = "julia"),
    "engine = \"tmb\""
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + offset(off)), family = nbinom2(),
           data = d, engine = "julia"),
    class = "drmTMB_julia_offset_unsupported"
  )
})

test_that("native offset() shifts the log-link intercept by log(2) exactly", {
  skip_if_not_installed("TMB")
  d <- offset_test_data()
  f0 <- drmTMB(bf(y ~ x + offset(off)), family = poisson(link = "log"), data = d)
  d2 <- d
  d2$off <- d2$off + log(2)
  f1 <- drmTMB(bf(y ~ x + offset(off)), family = poisson(link = "log"), data = d2)
  b0 <- coef(f0, dpar = "mu")
  b1 <- coef(f1, dpar = "mu")
  expect_equal(unname(b1[1L]), unname(b0[1L]) - log(2), tolerance = 1e-6)
  expect_equal(unname(b1[-1L]), unname(b0[-1L]), tolerance = 1e-6)
  expect_equal(as.numeric(logLik(f1)), as.numeric(logLik(f0)), tolerance = 1e-6)
})

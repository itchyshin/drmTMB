# Batch 26 (lane sa) companion to test-gaussian-correlated-q2-sd.R.
# The exact multivariate-normal marginal (base R, per group) is evaluated at
# the fitted parameters with the two SD vectors built BY HAND from the
# coefficients (the existing test uses predict()). The two SD selectors use
# different predictors (w0 continuous, w1 two-valued). Tolerance 1e-6 relative
# on logLik; each emulated bug must move the oracle by more than 0.1:
# swapped selector predictors, swapped intercept/slope SD vectors, reversed
# SD vector, and a flipped rho sign.
# Scope: likelihood agreement at the fitted parameters only.

b26sa_q2_fixture <- function(groups = 120L, repeats = 10L, seed = 20261901L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- sample(rep(c(-1, 1), length.out = groups))
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  tau0 <- exp(-0.45 + 0.4 * w_group)
  tau1 <- exp(-0.85 - 0.35 * v_group)
  b0 <- tau0 * z0
  b1 <- tau1 * (0.4 * z0 + sqrt(1 - 0.4^2) * z1)
  gi <- as.integer(id)
  y <- -0.2 + 0.55 * x + b0[gi] + b1[gi] * x + 0.5 * stats::rnorm(length(id))
  list(data = data.frame(y = y, x = x, w0 = rep(w_group, each = repeats),
                         w1 = rep(v_group, each = repeats), id = id),
       w_group = w_group, v_group = v_group)
}

b26sa_q2_loglik <- function(data, beta, sd0, sd1, rho, sigma) {
  sum(vapply(seq_along(sd0), function(g) {
    rows <- which(as.integer(data$id) == g)
    x <- data$x[rows]
    Z <- cbind(1, x)
    S <- diag(c(sd0[[g]], sd1[[g]])) %*% matrix(c(1, rho, rho, 1), 2L) %*%
      diag(c(sd0[[g]], sd1[[g]]))
    R <- chol(Z %*% S %*% t(Z) + diag(sigma^2, length(rows)))
    r <- backsolve(R, data$y[rows] - (beta[[1L]] + beta[[2L]] * x),
                   transpose = TRUE)
    -0.5 * length(rows) * log(2 * pi) - sum(log(diag(R))) - 0.5 * sum(r^2)
  }, numeric(1L)))
}

test_that("Gaussian correlated q2 SDs with distinct selectors: exact oracle and bug sensitivity", {
  skip_on_cran()
  fx <- b26sa_q2_fixture()
  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1,
       sd(id, coef = "(Intercept)") ~ w0, sd(id, coef = "x") ~ w1),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  c0 <- stats::coef(fit, 'sd(id, coef = "(Intercept)")')
  c1 <- stats::coef(fit, 'sd(id, coef = "x")')
  expect_named(c0, c("(Intercept)", "w0"))
  expect_named(c1, c("(Intercept)", "w1"))
  curve <- function(co, z) unname(exp(co[[1L]] + co[[2L]] * z))
  beta <- unname(stats::coef(fit, "mu"))
  rho <- unname(fit$corpars$mu[[1L]])
  sigma <- exp(unname(stats::coef(fit, "sigma"))[[1L]])
  ev <- function(sd0, sd1, r = rho) {
    b26sa_q2_loglik(fx$data, beta, sd0, sd1, r, sigma)
  }
  sd0 <- curve(c0, fx$w_group)
  sd1 <- curve(c1, fx$v_group)
  ll <- as.numeric(stats::logLik(fit))
  expect_equal(ll, ev(sd0, sd1), tolerance = 1e-6)
  expect_lt(abs(ll - ev(sd0, sd1)), 1e-4)
  bugs <- c(
    swapped_selector_predictors = ev(curve(c0, fx$v_group),
                                     curve(c1, fx$w_group)),
    swapped_sd_vectors = ev(sd1, sd0),
    reversed_intercept_sd = ev(rev(sd0), sd1),
    reversed_slope_sd = ev(sd0, rev(sd1)),
    rho_sign_flipped = ev(sd0, sd1, -rho)
  )
  for (nm in names(bugs)) expect_gt(abs(ll - bugs[[nm]]), 0.1, label = nm)
})

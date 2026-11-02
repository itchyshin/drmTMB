# Batch 26 (lane sa) companion to test-gaussian-sigma-endpoint-mixes-sd.R,
# case (b) rows (mu:I and sigma:I on the SAME group). The existing case (b)
# uses the same predictor `w` for both SD formulas, so a selector swap is
# undetectable. Here the mu SD uses `w` and the sigma SD uses a different
# predictor `u` (a shuffled, nearly uncorrelated vector). Oracle: dense joint
# Laplace in base R with SD vectors computed by hand from the coefficients;
# logLik tolerance 1e-4. Emulated bugs (selector swap, reversed SD vectors,
# swapped coefficient sets) must move the oracle by more than 0.1.
# Scope: likelihood agreement at the fitted parameters only.

b26sa_gse_fixture <- function(seed = 20261801L, n_id = 40L, n_each = 25L) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(sprintf("id%02d", (seq_len(n) - 1L) %/% n_each + 1L))
  w_id <- seq(-1, 1, length.out = n_id)
  u_id <- sample(w_id)
  gi <- as.integer(id)
  a <- stats::rnorm(n_id, sd = exp(log(0.5) + 0.8 * w_id))
  b <- stats::rnorm(n_id, sd = exp(log(0.45) - 0.8 * u_id))
  x <- stats::rnorm(n)
  y <- 0.2 + 0.5 * x + a[gi] + stats::rnorm(n, sd = exp(log(0.5) + b[gi]))
  list(data = data.frame(y = y, x = x, id = id, w = w_id[gi], u = u_id[gi]),
       w_id = w_id, u_id = u_id)
}

b26sa_gse_oracle <- function(fit, fx, sd_mu, sd_sg) {
  d <- fx$data
  ni <- nlevels(d$id)
  Ii <- b26sa_indicator(as.integer(d$id), ni)
  b26sa_gauss_laplace(
    y = d$y, X = cbind(1, d$x), beta = unname(stats::coef(fit, "mu")),
    s0 = unname(stats::coef(fit, "sigma"))[[1L]], V = rep(0, nrow(d)),
    Zm = cbind(Ii, matrix(0, nrow(d), ni)),
    Zs = cbind(matrix(0, nrow(d), ni), Ii),
    P = diag(c(1 / sd_mu^2, 1 / sd_sg^2)),
    logdet_cov = sum(log(sd_mu^2)) + sum(log(sd_sg^2))
  )
}

test_that("same-group mu and sigma intercept SDs with different predictors: oracle and selector-swap sensitivity", {
  skip_on_cran()
  fx <- b26sa_gse_fixture()
  expect_lt(abs(stats::cor(fx$w_id, fx$u_id)), 0.5)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id),
       sd(id) ~ w, sd(id, dpar = "sigma") ~ u),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(fit$sdpars, c("sd(id)", 'sd(id, dpar = "sigma")'),
               ignore.order = TRUE)
  cm <- stats::coef(fit, "sd(id)")
  cs <- stats::coef(fit, 'sd(id, dpar = "sigma")')
  expect_named(cm, c("(Intercept)", "w"))
  expect_named(cs, c("(Intercept)", "u"))
  curve <- function(co, z) unname(exp(co[[1L]] + co[[2L]] * z))
  sd_mu <- curve(cm, fx$w_id)
  sd_sg <- curve(cs, fx$u_id)
  base <- b26sa_gse_oracle(fit, fx, sd_mu, sd_sg)
  expect_lt(base$max_grad, 1e-8)
  expect_gt(base$min_eig, 0)
  ll <- as.numeric(stats::logLik(fit))
  expect_lt(abs(ll - base$loglik), 1e-4)
  bugs <- c(
    selector_swap = b26sa_gse_oracle(fit, fx, curve(cm, fx$u_id),
                                     curve(cs, fx$w_id))$loglik,
    swapped_coefficient_sets = b26sa_gse_oracle(fit, fx, curve(cs, fx$w_id),
                                                curve(cm, fx$u_id))$loglik,
    reversed_mu_sd = b26sa_gse_oracle(fit, fx, rev(sd_mu), sd_sg)$loglik,
    reversed_sigma_sd = b26sa_gse_oracle(fit, fx, sd_mu, rev(sd_sg))$loglik
  )
  for (nm in names(bugs)) expect_gt(abs(ll - bugs[[nm]]), 0.1, label = nm)
})

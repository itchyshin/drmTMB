test_that("Gaussian independent random-slope SD regression is recovered", {
  set.seed(20261024L)
  n_group <- 120L
  n_repeat <- 12L
  group <- factor(rep(seq_len(n_group), each = n_repeat))
  x_within <- rep(seq(-1.5, 1.5, length.out = n_repeat), n_group)
  w_group <- seq(-1, 1, length.out = n_group)
  w <- w_group[as.integer(group)]
  alpha <- c(`(Intercept)` = log(0.5), w = 0.5)
  slope_sd <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  random_slope <- slope_sd * stats::rnorm(n_group)
  y <- 0.2 + 0.35 * x_within +
    random_slope[as.integer(group)] * x_within +
    0.4 * stats::rnorm(length(group))
  dat <- data.frame(y, x = x_within, w, id = group)

  fit <- drmTMB(
    bf(
      y ~ x + (0 + x | id),
      sigma ~ 1,
      sd(id, coef = "x") ~ w
    ),
    family = stats::gaussian(),
    data = dat
  )
  target <- 'sd(id, coef = "x")'
  fitted_sd <- predict(fit, dpar = target)
  simulated <- simulate(fit, nsim = 1L, seed = 20261025L)
  fit_constant <- drmTMB(
    bf(
      y ~ x + (0 + x | id),
      sigma ~ 1,
      sd(id, coef = "x") ~ 1
    ),
    family = stats::gaussian(),
    data = dat
  )
  fit_existing <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1),
    family = stats::gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit, dpar = target), names(alpha))
  expect_lt(abs(unname(coef(fit, dpar = target)[["w"]] - alpha[["w"]])), 0.4)
  expect_equal(length(fitted_sd), n_group)
  expect_true(all(is.finite(fitted_sd) & fitted_sd > 0))
  expect_gt(stats::cor(log(fitted_sd), log(slope_sd)), 0.6)
  expect_equal(nrow(simulated), nrow(dat))
  expect_true(all(is.finite(simulated[[1L]])))
  expect_equal(as.numeric(logLik(fit_constant)),
               as.numeric(logLik(fit_existing)), tolerance = 1e-8)
  expect_equal(unname(predict(fit_constant, dpar = target)),
               rep(exp(unname(coef(fit_constant, dpar = target)[[1L]])), n_group),
               tolerance = 1e-8)
  # The unlabelled correlated q2 block is now admitted (exact-likelihood
  # evidence lives in test-gaussian-correlated-q2-sd.R); it must still fit
  # here and keep the selected slope SD target.
  q2_fit <- drmTMB(
    bf(
      y ~ x + (1 + x | id),
      sigma ~ 1,
      sd(id, coef = "x") ~ w
    ),
    family = stats::gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(q2_fit$opt$convergence, 0L)
  expect_true(target %in% names(q2_fit$sdpars))
})

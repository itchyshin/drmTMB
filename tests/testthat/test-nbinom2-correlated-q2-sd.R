nbinom2_correlated_q2_sd_fixture <- function(groups = 140L, repeats = 28L,
                                              seed = 20261027L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  w0_group <- seq(-1, 1, length.out = groups)
  w1_group <- sample(rep(c(-1, 1), length.out = groups))
  w0 <- rep(w0_group, each = repeats)
  w1 <- rep(w1_group, each = repeats)
  rho <- 0.35
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  sd0 <- exp(-0.35 + 0.35 * w0_group)
  sd1 <- exp(-0.75 - 0.30 * w1_group)
  b0 <- sd0 * z0
  b1 <- sd1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  eta <- -0.15 + 0.50 * x + b0[as.integer(id)] + b1[as.integer(id)] * x
  sigma <- exp(-0.55)
  data <- data.frame(
    count = stats::rnbinom(length(id), size = 1 / sigma^2, mu = exp(eta)),
    x = x, w0 = w0, w1 = w1, id = id
  )
  list(
    data = data,
    w0_group = w0_group,
    w1_group = w1_group,
    truth = c(intercept_sd_slope = 0.35, random_slope_sd_slope = -0.30,
              rho = rho)
  )
}

test_that("NB2 correlated q2 admits predictor-dependent coefficient SDs", {
  sim <- nbinom2_correlated_q2_sd_fixture()
  dat <- sim$data
  target0 <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  target1 <- 'sd(id, dpar = "mu", coef = "x")'
  formula <- bf(
    count ~ x + (1 + x | id), sigma ~ 1,
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x") ~ w1
  )
  fit <- drmTMB(
    formula, family = nbinom2(), data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_identical(fit$model$random$mu$n_terms, 2L)
  expect_identical(fit$model$random$mu$n_cors, 1L)
  expect_named(fit$sdpars, c(target0, target1))
  expect_lt(abs(coef(fit, target0)[["w0"]] -
                  sim$truth[["intercept_sd_slope"]]), 0.30)
  expect_lt(abs(coef(fit, target1)[["w1"]] -
                  sim$truth[["random_slope_sd_slope"]]), 0.30)
  expect_true(is.finite(unname(fit$corpars$mu[[1L]])))
  expect_lt(abs(unname(fit$corpars$mu[[1L]])), 1)

  pred0 <- predict(fit, dpar = target0, newdata = data.frame(w0 = sim$w0_group))
  pred1 <- predict(fit, dpar = target1, newdata = data.frame(w1 = sim$w1_group))
  expect_equal(length(pred0), nlevels(dat$id))
  expect_equal(length(pred1), nlevels(dat$id))
  expect_true(all(is.finite(c(pred0, pred1))))

  constant <- drmTMB(
    bf(
      count ~ x + (1 + x | id), sigma ~ 1,
      sd(id, dpar = "mu", coef = "(Intercept)") ~ 1,
      sd(id, dpar = "mu", coef = "x") ~ 1
    ),
    family = nbinom2(), data = dat,
    control = drm_control(se = FALSE)
  )
  ordinary <- drmTMB(
    bf(count ~ x + (1 + x | id), sigma ~ 1),
    family = nbinom2(), data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)
})

nbinom2_sigma_sd_regression_dgp <- function(
  n_id = 240L,
  n_each = 40L,
  seed = 20261024L
) {
  set.seed(seed)
  group_w <- seq(-1, 1, length.out = n_id)
  tau <- exp(log(0.55) + 0.4 * group_w)
  b_sigma <- stats::rnorm(n_id, sd = tau)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  mu <- exp(0.5 - 0.18 * x)
  sigma <- exp(-0.6 + b_sigma[as.integer(id)])
  count <- stats::rnbinom(n, size = 1 / sigma^2, mu = mu)
  list(
    data = data.frame(
      count = count,
      x = x,
      w = group_w[as.integer(id)],
      id = id
    ),
    truth = c("(Intercept)" = log(0.55), w = 0.4),
    group_w = stats::setNames(group_w, levels(id))
  )
}

test_that("NB2 sigma random-intercept SD can depend on a group predictor", {
  sim <- nbinom2_sigma_sd_regression_dgp()
  fit <- drmTMB(
    bf(
      count ~ x,
      sigma ~ 1 + (1 | id),
      sd(id, dpar = "sigma") ~ w
    ),
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 600, iter.max = 600)
  )

  target <- 'sd(id, dpar = "sigma")'
  estimate <- coef(fit, dpar = target)
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(estimate, names(sim$truth))
  expect_true(all(abs(unname(estimate) - unname(sim$truth)) < 0.25))
  expect_true(all(is.finite(vcov(fit, dpar = target))))

  expected_sd <- exp(estimate[[1L]] + estimate[[2L]] * sim$group_w)
  expect_equal(
    unname(predict(fit, dpar = target)),
    unname(expected_sd),
    tolerance = 1e-10
  )
  expect_named(predict(fit, dpar = target), names(sim$group_w))

  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  sigma_re <- drmTMB:::sigma_random_effect_contribution(fit, dpar = "sigma")
  expect_equal(sigma_link, fixed_sigma + sigma_re, tolerance = 1e-8)
  expect_equal(sigma(fit), exp(sigma_link), tolerance = 1e-8)
})

test_that("constant NB2 sigma SD regression matches the existing fit", {
  sim <- nbinom2_sigma_sd_regression_dgp(
    n_id = 36L,
    n_each = 18L,
    seed = 20261025L
  )
  legacy <- drmTMB(
    bf(count ~ x, sigma ~ 1 + (1 | id)),
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 600, iter.max = 600)
  )
  constant <- drmTMB(
    bf(
      count ~ x,
      sigma ~ 1 + (1 | id),
      sd(id, dpar = "sigma") ~ 1
    ),
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 600, iter.max = 600)
  )

  expect_equal(legacy$opt$convergence, 0)
  expect_equal(constant$opt$convergence, 0)
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(legacy)),
    tolerance = 1e-5
  )
  expect_equal(
    unname(coef(constant, dpar = 'sd(id, dpar = "sigma")')),
    unname(log(legacy$sdpars$sigma)),
    tolerance = 1e-4
  )
})

test_that("NB2 sigma SD predictors must be constant within group", {
  sim <- nbinom2_sigma_sd_regression_dgp(n_id = 8L, n_each = 4L)
  sim$data$w <- seq_len(nrow(sim$data))

  expect_error(
    drmTMB(
      bf(
        count ~ x,
        sigma ~ 1 + (1 | id),
        sd(id, dpar = "sigma") ~ w
      ),
      family = nbinom2(),
      data = sim$data
    ),
    "constant within"
  )
})

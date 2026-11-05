nbinom2_sigma_slope_sd_data <- function(
  n_id = 180L,
  n_each = 36L,
  seed = 20261025L
) {
  set.seed(seed)
  group_w <- seq(-1, 1, length.out = n_id)
  tau <- exp(log(0.45) + 0.35 * group_w)
  b_sigma <- stats::rnorm(n_id, sd = tau)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  z <- stats::rnorm(n)
  x <- stats::rnorm(n)
  mu <- exp(0.45 - 0.15 * x)
  sigma <- exp(-0.55 + z * b_sigma[as.integer(id)])
  count <- stats::rnbinom(n, size = 1 / sigma^2, mu = mu)
  list(
    data = data.frame(
      count = count,
      x = x,
      z = z,
      w = group_w[as.integer(id)],
      id = id
    ),
    truth = c("(Intercept)" = log(0.45), w = 0.35),
    group_w = stats::setNames(group_w, levels(id))
  )
}

test_that("NB2 sigma random-slope SD can depend on a group predictor", {
  sim <- nbinom2_sigma_slope_sd_data()
  fit <- drmTMB(
    bf(
      count ~ x,
      sigma ~ 1 + (0 + z | id),
      sd(id, dpar = "sigma", coef = "z") ~ w
    ),
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 800, iter.max = 800)
  )

  target <- 'sd(id, dpar = "sigma", coef = "z")'
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
})

test_that("constant NB2 sigma slope SD matches the existing fit", {
  sim <- nbinom2_sigma_slope_sd_data(
    n_id = 48L,
    n_each = 20L,
    seed = 20261026L
  )
  legacy <- drmTMB(
    bf(count ~ x, sigma ~ 1 + (0 + z | id)),
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 800, iter.max = 800)
  )
  constant <- drmTMB(
    bf(
      count ~ x,
      sigma ~ 1 + (0 + z | id),
      sd(id, dpar = "sigma", coef = "z") ~ 1
    ),
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 800, iter.max = 800)
  )

  expect_equal(legacy$opt$convergence, 0)
  expect_equal(constant$opt$convergence, 0)
  expect_equal(
    as.numeric(logLik(constant)),
    as.numeric(logLik(legacy)),
    tolerance = 1e-5
  )
  expect_equal(
    unname(coef(constant, dpar = 'sd(id, dpar = "sigma", coef = "z")')),
    unname(log(legacy$sdpars$sigma)),
    tolerance = 1e-4
  )
})

test_that("NB2 sigma slope SD predictor must be constant within group", {
  sim <- nbinom2_sigma_slope_sd_data(n_id = 8L, n_each = 4L)
  sim$data$w <- seq_len(nrow(sim$data))

  expect_error(
    drmTMB(
      bf(
        count ~ x,
        sigma ~ 1 + (0 + z | id),
        sd(id, dpar = "sigma", coef = "z") ~ w
      ),
      family = nbinom2(),
      data = sim$data
    ),
    "constant within"
  )
})

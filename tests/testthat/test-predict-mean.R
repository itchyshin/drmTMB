new_predict_mean_data <- function(n = 300, seed = 20261025) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  dat$ylog <- exp(0.3 + 0.4 * dat$x + 0.5 * stats::rnorm(n))
  mu <- exp(0.6 + 0.3 * dat$x)
  zi <- stats::plogis(-0.8 + 0.4 * dat$z)
  dat$count_zi <- ifelse(stats::runif(n) < zi, 0L, stats::rpois(n, mu))
  dat$count_h <- ifelse(
    stats::runif(n) < zi,
    0L,
    stats::qnbinom(
      stats::runif(n, stats::dnbinom(0, size = 2, mu = mu), 1),
      size = 2,
      mu = mu
    )
  )
  latent <- 0.8 * dat$x + stats::rlogis(n)
  dat$score <- as.integer(cut(latent, c(-Inf, -1, 0.3, 1.5, Inf)))
  dat
}

test_that("predict(type = 'mean') returns E[Y] for lognormal fits", {
  dat <- new_predict_mean_data()
  fit <- drmTMB(bf(ylog ~ x, sigma ~ 1), family = lognormal(), data = dat)
  nd <- data.frame(x = c(-0.5, 0, 0.5))

  mu <- predict(fit, newdata = nd, dpar = "mu")
  sigma <- predict(fit, newdata = nd, dpar = "sigma")
  expect_equal(predict(fit, newdata = nd, type = "mean"), exp(mu + sigma^2 / 2))
  expect_equal(predict(fit, type = "mean"), unname(fitted(fit)))
  # type = "response" is unchanged: still the log-scale mu.
  expect_equal(predict(fit, newdata = nd, type = "response"), mu)
  expect_false(isTRUE(all.equal(
    predict(fit, newdata = nd, type = "mean"),
    predict(fit, newdata = nd, type = "response")
  )))
})

test_that("predict(type = 'mean') returns E[Y] for zero-inflated fits", {
  dat <- new_predict_mean_data()
  fit_p <- drmTMB(
    bf(count_zi ~ x, zi ~ z),
    family = stats::poisson(link = "log"),
    data = dat
  )
  nd <- data.frame(x = c(-0.5, 0.5), z = c(0, 1))
  mu <- predict(fit_p, newdata = nd, dpar = "mu")
  zi <- predict(fit_p, newdata = nd, dpar = "zi")
  expect_equal(predict(fit_p, newdata = nd, type = "mean"), (1 - zi) * mu)
  expect_equal(predict(fit_p, type = "mean"), unname(fitted(fit_p)))
  expect_equal(predict(fit_p, newdata = nd, dpar = "mu"), mu)

  fit_nb <- drmTMB(
    bf(count_zi ~ x, sigma ~ 1, zi ~ z),
    family = nbinom2(),
    data = dat
  )
  expect_equal(fit_nb$model$model_type, "zi_nbinom2")
  mu_nb <- predict(fit_nb, newdata = nd, dpar = "mu")
  zi_nb <- predict(fit_nb, newdata = nd, dpar = "zi")
  expect_equal(predict(fit_nb, newdata = nd, type = "mean"), (1 - zi_nb) * mu_nb)
  expect_equal(predict(fit_nb, type = "mean"), unname(fitted(fit_nb)))
})

test_that("predict(type = 'mean') returns E[Y] for hurdle fits", {
  dat <- new_predict_mean_data()
  fit <- drmTMB(
    bf(count_h ~ x, sigma ~ 1, hu ~ z),
    family = truncated_nbinom2(),
    data = dat
  )
  expect_equal(fit$model$model_type, "hurdle_nbinom2")
  nd <- data.frame(x = c(-0.5, 0.5), z = c(0, 1))
  mu <- predict(fit, newdata = nd, dpar = "mu")
  sigma <- predict(fit, newdata = nd, dpar = "sigma")
  hu <- predict(fit, newdata = nd, dpar = "hu")
  expect_equal(
    predict(fit, newdata = nd, type = "mean"),
    hurdle_nbinom2_mean(mu, sigma, hu)
  )
  expect_equal(predict(fit, type = "mean"), unname(fitted(fit)))
})

test_that("predict(type = 'mean') returns the expected score for cumulative_logit", {
  dat <- new_predict_mean_data()
  fit <- drmTMB(bf(score ~ x), family = cumulative_logit(), data = dat)
  nd <- data.frame(x = c(-1, 0, 1))
  prob <- ordinal_category_probabilities(fit, newdata = nd)
  expect_equal(
    predict(fit, newdata = nd, type = "mean"),
    as.vector(prob %*% seq_len(ncol(prob)))
  )
  expect_equal(predict(fit, type = "mean"), unname(fitted(fit)))
})

test_that("predict(type = 'mean') refuses dpar and leaves other types alone", {
  dat <- new_predict_mean_data()
  fit <- drmTMB(bf(ylog ~ x, sigma ~ 1), family = lognormal(), data = dat)
  expect_error(
    predict(fit, dpar = "mu", type = "mean"),
    "does not take"
  )
  expect_equal(
    predict(fit, type = "link"),
    predict(fit, dpar = "mu", type = "link")
  )
})

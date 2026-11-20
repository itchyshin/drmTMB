# Issue #1315: opt-in basic (reflected) bootstrap interval.

test_that("bootstrap_basic_interval reflects quantiles about the seed estimate", {
  target <- data.frame(
    transformation = "linear_predictor", estimate = 1, link_estimate = 1
  )
  draws <- data.frame(estimate = seq(0, 1, length.out = 101), link_estimate = NA_real_)
  probs <- c(0.025, 0.975)
  q <- stats::quantile(draws$estimate, probs, names = FALSE, type = 8)
  expect_equal(drmTMB:::bootstrap_basic_interval(draws, target, probs), 2 - rev(q))
  expect_gt(
    drmTMB:::bootstrap_basic_interval(draws, target, probs)[[1L]],
    drmTMB:::bootstrap_percentile_interval(draws, target, probs)[[1L]]
  )
})

test_that("basic interval on an exp-linked target stays positive", {
  target <- data.frame(
    transformation = "exp", estimate = exp(-0.5), link_estimate = -0.5
  )
  set.seed(2)
  link <- stats::rnorm(200, -0.6, 0.2)
  draws <- data.frame(estimate = exp(link), link_estimate = link)
  out <- drmTMB:::bootstrap_basic_interval(draws, target, c(0.025, 0.975))
  expect_true(all(out > 0))
  expect_lt(out[[1L]], out[[2L]])
})

test_that("confint(method = 'bootstrap') accepts bootstrap_interval", {
  set.seed(1)
  d <- data.frame(x = stats::rnorm(60))
  d$y <- 0.3 + 0.5 * d$x + stats::rnorm(60) * exp(0.1 * d$x)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d)
  pct <- confint(fit, parm = "fixef:sigma:(Intercept)", method = "bootstrap", R = 30, seed = 1)
  bas <- confint(fit, parm = "fixef:sigma:(Intercept)", method = "bootstrap", R = 30, seed = 1,
                 bootstrap_interval = "basic")
  expect_identical(bas$conf.status, "bootstrap")
  expect_true(all(is.finite(c(bas$lower, bas$upper))) && bas$lower < bas$upper)
  expect_false(isTRUE(all.equal(pct$lower, bas$lower)))
  expect_error(
    confint(fit, parm = "fixef:sigma:(Intercept)", method = "bootstrap", R = 30,
            bootstrap_interval = "bca")
  )
})

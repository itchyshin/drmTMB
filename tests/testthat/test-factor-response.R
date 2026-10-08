# #1481: a factor (or ordered) response must not be fitted as integer level
# codes. Binomial already refuses. These builders used to coerce with
# as.numeric() or to die inside is.finite()/round() with a base-R message.

factor_response_data <- function(ordered_response = FALSE) {
  set.seed(1)
  n <- 40
  d <- data.frame(x = stats::rnorm(n))
  labels <- sample(c("3", "7", "12"), n, TRUE)
  d$y <- if (ordered_response) ordered(labels) else factor(labels)
  d$y1 <- d$y
  d$y2 <- factor(sample(c("3", "7", "12"), n, TRUE))
  d
}

expect_factor_response_error <- function(expr) {
  expect_error(expr, "not a factor")
}

test_that("continuous builders reject a factor response and name the column", {
  d <- factor_response_data()
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = stats::gaussian(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = student(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = skew_normal(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = stats::Gamma(link = "log"), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = d)
  )
  err <- expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = stats::gaussian(), data = d),
    "not a factor"
  )
  expect_match(conditionMessage(err), "y", fixed = TRUE)
})

test_that("an ordered factor is rejected by the same continuous builders", {
  d <- factor_response_data(ordered_response = TRUE)
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = stats::gaussian(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = student(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = skew_normal(), data = d)
  )
})

test_that("count builders reject a factor response before round()", {
  d <- factor_response_data()
  expect_factor_response_error(
    drmTMB(bf(y ~ x), family = stats::poisson(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d)
  )
  expect_factor_response_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = truncated_nbinom2(), data = d)
  )
})

test_that("bivariate builders reject a factor response before coding it", {
  d <- factor_response_data()
  expect_factor_response_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1,
        sigma2 = ~ 1,
        rho12 = ~ 1
      ),
      family = biv_gaussian(),
      data = d
    )
  )
  expect_factor_response_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1,
        sigma2 = ~ 1,
        rho12 = ~ 1
      ),
      family = biv_lognormal(),
      data = d
    )
  )
  expect_factor_response_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1,
        sigma2 = ~ 1,
        nu = ~ 1,
        rho12 = ~ 1
      ),
      family = biv_student(),
      data = d
    )
  )
})

test_that("the Julia bridge rejects a factor response and still allows cumulative_logit", {
  d <- factor_response_data()
  expect_error(
    drm_julia_reject_factor_responses(
      d,
      bf(y ~ x, sigma ~ 1),
      "gaussian"
    ),
    "not a factor"
  )
  expect_error(
    drm_julia_reject_factor_responses(
      d,
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1,
        sigma2 = ~ 1,
        rho12 = ~ 1
      ),
      "biv_gaussian"
    ),
    "not a factor"
  )
  ordered_score <- data.frame(
    score = ordered(d$y),
    x = d$x
  )
  expect_silent(
    drm_julia_reject_factor_responses(
      ordered_score,
      bf(score ~ x),
      "cumulative_logit"
    )
  )
})

test_that("a numeric Gaussian response still fits", {
  set.seed(1)
  n <- 30
  x <- stats::rnorm(n)
  d <- data.frame(y = 0.2 + 0.4 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = stats::gaussian(), data = d)
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0L)
})

# Issue #1481: Gaussian, Student-t, and skew-normal must not model factor
# level codes as the response.

factor_response_data <- function() {
  set.seed(1)
  n <- 40
  data.frame(
    x = rnorm(n),
    y = factor(sample(c("3", "7", "12"), n, TRUE))
  )
}

test_that("gaussian refuses a factor response and names y", {
  d <- factor_response_data()
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), data = d, family = gaussian()),
    regexp = "\\by\\b",
    class = "drmTMB_factor_response"
  )
})

test_that("student and skew-normal refuse a factor response", {
  d <- factor_response_data()
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ 1),
      data = d,
      family = student()
    ),
    class = "drmTMB_factor_response"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ 1),
      data = d,
      family = skew_normal(),
      control = drm_control(se = FALSE)
    ),
    class = "drmTMB_factor_response"
  )
})

test_that("an ordered factor response is refused too", {
  d <- factor_response_data()
  d$y <- as.ordered(d$y)
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), data = d, family = gaussian()),
    class = "drmTMB_factor_response"
  )
})

test_that("a numeric gaussian response still fits", {
  set.seed(1)
  d <- data.frame(y = rnorm(40), x = rnorm(40))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = d,
    family = gaussian(),
    control = drm_control(se = FALSE)
  )
  expect_true(is_converged(fit))
  expect_false(is.factor(d$y))
})

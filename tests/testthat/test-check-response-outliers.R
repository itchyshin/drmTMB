response_outlier_data <- function(sentinel = NULL, n = 400L, n_bad = 40L) {
  set.seed(11)
  x <- stats::rnorm(n)
  y <- 1 + 0.5 * x + exp(-0.4 + 0.43 * x) * stats::rnorm(n)
  if (!is.null(sentinel)) {
    y[sample(n, n_bad)] <- sentinel
  }
  data.frame(x = x, y = y)
}

response_outlier_row <- function(fit) {
  chk <- check_drm(fit)
  chk[chk$check == "response_residual_outliers", , drop = FALSE]
}

test_that("A-5: a sentinel-damaged response is flagged by check_drm (Dinnage audit, #1335)", {
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = response_outlier_data(sentinel = -5)
  )
  row <- response_outlier_row(fit)
  expect_equal(nrow(row), 1L)
  expect_identical(row$status, "warning")
  expect_match(row$value, "n=400; n_beyond_3=")
  expect_match(row$message, "sentinel")
  expect_false(attr(check_drm(fit), "ok"))
})

test_that("a clean response keeps the response-outlier row ok (#1335)", {
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = response_outlier_data()
  )
  row <- response_outlier_row(fit)
  expect_identical(row$status, "ok")
  expect_true(attr(check_drm(fit), "ok"))
})

test_that("the response-outlier row is reproducible and leaves the RNG alone (#1335)", {
  set.seed(3)
  dat <- data.frame(x = stats::rnorm(200))
  dat$y <- stats::rpois(200, exp(0.3 + 0.2 * dat$x))
  fit <- drmTMB(bf(y ~ x), family = poisson(), data = dat)
  set.seed(99)
  before <- .Random.seed
  first <- response_outlier_row(fit)
  expect_identical(.Random.seed, before)
  expect_identical(response_outlier_row(fit), first)
  expect_identical(first$status, "ok")
})

test_that("the response-outlier row is skipped when quantile residuals fail (#1335)", {
  local_mocked_bindings(
    drm_quantile_residuals = function(...) stop("not available"),
    .package = "drmTMB"
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = response_outlier_data(n = 40L)
  )
  expect_null(check_response_residual_outliers(fit))
})

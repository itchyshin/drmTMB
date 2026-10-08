# #1460: qq/worm order statistics used to drop non-finite quantile residuals
# (u = 0 or 1) with no count. The finite points stay on the reduced grid;
# the omission is warned and recorded.

test_that("non-finite quantile residuals are counted and still omitted", {
  z <- matrix(
    c(-Inf, -1, NA, 0, 1, Inf, 0.2, NA, -Inf, 0.4, NA, NA),
    ncol = 2L
  )
  # testthat edition 3 returns the warning condition from expect_warning(),
  # not the data frame, so keep the table in this assignment.
  qd <- NULL
  expect_warning(
    qd <- drm_quantile_residual_qq_from_matrix(z),
    class = "drmTMB_quantile_residual_warning"
  )
  expect_equal(attr(qd, "n_nonfinite_quantile_residuals"), 3L)
  expect_true(all(is.finite(qd$sample)))
  sim1 <- qd[qd$sim == 1L, , drop = FALSE]
  expect_equal(sim1$sample, c(-1, 0, 1))
  expect_equal(sim1$rank, 1:3)
  expect_equal(sim1$theoretical, stats::qnorm(stats::ppoints(3)))
  expect_equal(nrow(qd[qd$sim == 2L, , drop = FALSE]), 2L)
})

test_that("missing-response NA rows do not raise the non-finite count", {
  z <- c(NA_real_, -0.5, 0.5, NA_real_)
  qd <- expect_no_warning(drm_quantile_residual_qq_from_matrix(z))
  expect_equal(attr(qd, "n_nonfinite_quantile_residuals"), 0L)
  expect_equal(qd$sample, c(-0.5, 0.5))
})

test_that("unequal non-finite drops use a common theoretical grid", {
  col_long <- c(-2, -1, 0, 1, 2)
  col_short <- c(-Inf, -0.5, 0.5, Inf, NA_real_)
  z <- cbind(col_long, col_short)
  qd <- NULL
  expect_warning(
    qd <- drm_quantile_residual_qq_from_matrix(z),
    class = "drmTMB_quantile_residual_warning"
  )
  sim1 <- qd[qd$sim == 1L, , drop = FALSE]
  sim2 <- qd[qd$sim == 2L, , drop = FALSE]
  expect_equal(sim1$theoretical, stats::qnorm(stats::ppoints(5)))
  expect_equal(sim2$theoretical, stats::qnorm(stats::ppoints(2)))

  envelope <- drm_adequacy_envelope(qd, "sample")
  grid <- stats::qnorm(stats::ppoints(2))
  expect_equal(envelope$theoretical, grid)
  expect_equal(nrow(envelope), 2L)
  interpolated_long <- stats::approx(
    sim1$theoretical,
    sim1$sample,
    xout = grid,
    rule = 1
  )$y
  expect_equal(envelope$ymin, pmin(interpolated_long, sim2$sample))
  expect_equal(envelope$ymax, pmax(interpolated_long, sim2$sample))
  expect_false(isTRUE(all.equal(envelope$theoretical, sim1$theoretical[1:2])))
})

test_that("the QQ subtitle names a positive omission count", {
  data <- data.frame(theoretical = 0, sample = 0, deviation = 0)
  expect_false(grepl("omitted", drm_adequacy_qq_subtitle("base", data), fixed = TRUE))
  attr(data, "n_nonfinite_quantile_residuals") <- 2L
  note <- drm_adequacy_qq_subtitle("base", data)
  expect_match(note, "2 non-finite residuals omitted", fixed = TRUE)
  expect_match(note, "^base", perl = TRUE)
})

test_that("a finite Gaussian QQ table does not warn", {
  set.seed(20260712)
  n <- 40
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = stats::gaussian(), data = dat)
  qd <- expect_no_warning(drm_quantile_residual_qq_data(fit))
  expect_equal(attr(qd, "n_nonfinite_quantile_residuals"), 0L)
  expect_equal(nrow(qd), n)
})

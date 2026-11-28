# Coverage for R/marginal-parameters.R aggregation helpers not hit by fit tests.

test_that("marginalise_parameter_predictions() collapses rows by group columns", {
  f <- drmTMB:::marginalise_parameter_predictions
  pred <- data.frame(
    dpar = rep(c("mu", "sigma"), each = 4L),
    component = rep(c("location", "distributional-scale"), each = 4L),
    type = "response",
    habitat = rep(c("reef", "sand"), times = 4L),
    estimate = c(1, 3, 2, 6, 0.5, 0.7, 1.5, 2.5),
    stringsAsFactors = FALSE
  )

  out <- f(pred, by = "habitat")
  expect_equal(nrow(out), 4L)
  expect_true(all(out$n == 2L))
  expect_equal(out$conf.status, rep("not_requested", 4L))
  expect_equal(out$interval_source, rep("not_available", 4L))
  reef_mu <- out$estimate[out$dpar == "mu" & out$habitat == "reef"]
  sand_mu <- out$estimate[out$dpar == "mu" & out$habitat == "sand"]
  expect_equal(reef_mu, mean(c(1, 2)))
  expect_equal(sand_mu, mean(c(3, 6)))
  reef_sigma <- out$estimate[out$dpar == "sigma" & out$habitat == "reef"]
  expect_equal(reef_sigma, sqrt(mean(c(0.5^2, 1.5^2))))
})

test_that("marginalise_parameter_predictions() treats multiple by columns as a joint key", {
  pred <- data.frame(
    dpar = "mu",
    component = "location",
    type = "link",
    g = c("a", "a", "b"),
    t = c(1L, 2L, 1L),
    estimate = c(0, 2, 5),
    stringsAsFactors = FALSE
  )
  out <- drmTMB:::marginalise_parameter_predictions(pred, by = c("g", "t"))
  expect_equal(nrow(out), 3L)
  expect_equal(out$estimate[out$g == "a" & out$t == 1L], 0)
  expect_equal(out$estimate[out$g == "a" & out$t == 2L], 2)
  expect_equal(out$estimate[out$g == "b" & out$t == 1L], 5)
})
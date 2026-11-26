# A one-level fixed-effect factor must abort in drmTMB and name the column,
# before model.matrix()'s contrasts error (#1731). A factor that still has
# two or more levels present in the data keeps the existing fit.

test_that("one-level factor predictor aborts and names the column (#1731)", {
  d <- data.frame(y = stats::rnorm(12), f = factor(rep("a", 12)))
  err <- expect_error(
    drmTMB(bf(y ~ f), data = d, family = gaussian(), control = drm_control(se = FALSE)),
    class = "drmTMB_one_level_factor"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "f", fixed = TRUE)
  expect_false(grepl("contrasts can be applied", msg, fixed = TRUE))

  d$y <- stats::rpois(12, 2)
  err_pois <- expect_error(
    drmTMB(bf(y ~ f), data = d, family = poisson(), control = drm_control(se = FALSE)),
    class = "drmTMB_one_level_factor"
  )
  expect_match(conditionMessage(err_pois), "f", fixed = TRUE)
  expect_false(grepl("contrasts can be applied", conditionMessage(err_pois), fixed = TRUE))
})

test_that("unused levels that leave one level abort and name the column (#1731)", {
  d <- data.frame(
    y = stats::rnorm(12),
    f = factor(rep("a", 12), levels = c("a", "b"))
  )
  err <- expect_error(
    drmTMB(bf(y ~ f), data = d, family = gaussian(), control = drm_control(se = FALSE)),
    class = "drmTMB_one_level_factor"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "f", fixed = TRUE)
  expect_match(msg, "a", fixed = TRUE)
  expect_false(grepl("contrasts can be applied", msg, fixed = TRUE))
})

test_that("a one-value character predictor aborts and names the column (#1731)", {
  d <- data.frame(y = stats::rnorm(12), f = rep("a", 12))
  err <- expect_error(
    drmTMB(bf(y ~ f), data = d, family = gaussian(), control = drm_control(se = FALSE)),
    class = "drmTMB_one_level_factor"
  )
  expect_match(conditionMessage(err), "f", fixed = TRUE)
})

test_that("a two-level factor still fits (#1731)", {
  d <- data.frame(
    y = stats::rnorm(20),
    g = factor(rep(c("a", "b"), each = 10))
  )
  fit <- drmTMB(
    bf(y ~ g, sigma ~ 1),
    data = d,
    family = gaussian(),
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit, "drmTMB")
  expect_equal(nobs(fit), 20L)
})

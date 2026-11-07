test_that("hurdle NB2 SD predictors must vary across positive-count groups", {
  dat <- data.frame(
    y = c(1, 2, 3, 2, 0, 0, 0, 0),
    id = factor(rep(c("a", "b", "c", "d"), each = 2)),
    z = rep(c(-1, -1, 1, 1), each = 2)
  )
  formula <- bf(
    y ~ 1 + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ z
  )

  expect_error(
    drmTMB(formula, family = truncated_nbinom2(), data = dat),
    "positive counts"
  )
})

test_that("drmTMB() refuses meta_V() passed in ... (#1900)", {
  dat <- data.frame(
    yi = c(0.82, 0.11, -0.05, 0.44, -0.31),
    x = c(-0.4, -0.1, 0, 0.2, 0.5),
    vi = c(0.04, 0.02, 0.03, 0.01, 0.50)
  )
  err <- expect_error(
    drmTMB(
      bf(yi ~ x, sigma ~ 1),
      data = dat,
      family = gaussian(),
      meta_V(V = dat$vi)
    ),
    class = "drmTMB_formula_marker_dots_error"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "meta_V")
  expect_match(msg, "bf")
  expect_match(msg, "weights|\\.\\.\\.")
})

test_that("drmTMB() refuses namespace-qualified meta_V() in ... (#1900)", {
  dat <- data.frame(
    yi = c(0.82, 0.11),
    vi = c(0.04, 0.02)
  )
  err <- expect_error(
    drmTMB(
      bf(yi ~ 1, sigma ~ 1),
      data = dat,
      family = gaussian(),
      drmTMB::meta_V(V = dat$vi)
    ),
    class = "drmTMB_formula_marker_dots_error"
  )
  expect_match(conditionMessage(err), "meta_V")
})
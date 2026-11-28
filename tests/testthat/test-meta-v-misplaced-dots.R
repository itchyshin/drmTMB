# #1900: meta_V(V = ...) in drmTMB(...) is dropped silently because the marker
# returns NULL; refuse it from the matched call before `...` is evaluated.

test_that("drmTMB() refuses meta_V() outside bf() (#1900)", {
  dat <- data.frame(
    yi = c(0.82, 0.11, -0.05, 0.44, -0.31),
    x = c(-0.4, -0.1, 0.0, 0.2, 0.5),
    vi = c(0.04, 0.02, 0.03, 0.01, 0.50)
  )

  err <- expect_error(
    drmTMB(
      bf(yi ~ x, sigma ~ 1),
      data = dat,
      family = gaussian(),
      meta_V(V = dat$vi)
    ),
    class = "drmTMB_misplaced_meta_v_error"
  )
  expect_match(conditionMessage(err), "meta_V")

  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = vi), sigma ~ 1),
    data = dat,
    family = gaussian()
  )
  expect_s3_class(fit, "drmTMB")
})

test_that("drmTMB() refuses namespace-qualified meta_V() outside bf()", {
  dat <- data.frame(
    yi = 0.1,
    vi = 0.01
  )
  expect_error(
    drmTMB(
      bf(yi ~ 1, sigma ~ 1),
      data = dat,
      family = gaussian(),
      drmTMB::meta_V(V = dat$vi)
    ),
    class = "drmTMB_misplaced_meta_v_error"
  )
})

test_that("drmTMB() refuses meta_known_V() outside bf()", {
  dat <- data.frame(yi = 0.1, vi = 0.01)
  expect_error(
    drmTMB(
      bf(yi ~ 1, sigma ~ 1),
      data = dat,
      family = gaussian(),
      meta_known_V(V = dat$vi)
    ),
    class = "drmTMB_misplaced_meta_v_error"
  )
})
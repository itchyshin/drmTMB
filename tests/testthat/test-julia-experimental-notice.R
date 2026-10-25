# #1328 (Dinnage audit Md-K): `engine = "julia"` stays exported but is fenced as
# experimental. The first call in a session says so once; later calls are
# silent. The bridge is stubbed, so no Julia is needed.

test_that("engine = 'julia' emits one experimental notice per session", {
  state <- drmTMB:::drm_julia_setup_state
  old <- state$experimental_noticed
  withr::defer(state$experimental_noticed <- old)
  state$experimental_noticed <- NULL

  testthat::local_mocked_bindings(
    drmTMB_julia_bridge = function(...) "stub-fit",
    .package = "drmTMB"
  )
  dat <- data.frame(y = c(1, 2, 3, 4), x = c(0, 1, 0, 1))

  first <- testthat::capture_messages(
    out1 <- drmTMB::drmTMB(drmTMB::bf(y ~ x), data = dat, engine = "julia")
  )
  expect_identical(out1, "stub-fit")
  expect_length(first, 1L)
  expect_match(first, "experimental")

  second <- testthat::capture_messages(
    drmTMB::drmTMB(drmTMB::bf(y ~ x), data = dat, engine = "julia")
  )
  expect_length(second, 0L)
})

test_that("the default engine = 'tmb' never emits the experimental notice", {
  state <- drmTMB:::drm_julia_setup_state
  old <- state$experimental_noticed
  withr::defer(state$experimental_noticed <- old)
  state$experimental_noticed <- NULL

  dat <- data.frame(y = c(1.1, 2.3, 2.9, 4.2, 5.1, 5.8), x = 1:6)
  msgs <- testthat::capture_messages(
    suppressWarnings(drmTMB::drmTMB(drmTMB::bf(y ~ x), data = dat))
  )
  expect_false(any(grepl("experimental", msgs)))
  expect_null(state$experimental_noticed)
})

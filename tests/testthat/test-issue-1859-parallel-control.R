test_that("drm_control(parallel = FALSE) lists allowed parallel values", {
  err <- NULL
  tryCatch(
    drm_control(parallel = FALSE),
    error = function(e) err <<- conditionMessage(e)
  )
  expect_type(err, "character")
  expect_match(err, "must be one of")
  expect_match(err, "none")
  expect_match(err, "multicore")
  expect_match(err, "cluster")
  expect_no_match(err, "'arg' must be NULL or a character vector")
})
# Coverage: optimizer preset ladder and attempt bookkeeping in R/drmTMB.R.

test_that("drm_optimizer_attempt_specs stops at custom optimizers", {
  ctl <- drm_control(optimizer_preset = "default")
  specs <- drmTMB:::drm_optimizer_attempt_specs(ctl)
  expect_length(specs, 3L)
  expect_equal(vapply(specs, `[[`, "", "preset"), c("default", "careful", "robust"))
  custom <- drm_control(
    optimizer_preset = "careful",
    optimizer = list(iter.max = 777L)
  )
  one <- drmTMB:::drm_optimizer_attempt_specs(custom)
  expect_length(one, 1L)
  expect_equal(one[[1L]]$preset, "careful")
})

test_that("drm_optimizer_attempt_row and frame round-trip fields", {
  row <- drmTMB:::drm_optimizer_attempt_row(
    attempt = 2L,
    preset = "careful",
    control = list(iter.max = 100L),
    status = "ok",
    convergence = 0L,
    message = NA_character_,
    objective = 12.5,
    elapsed_sec = 0.42,
    selected = TRUE,
    optimizer = "nlminb"
  )
  expect_equal(row$attempt, 2L)
  expect_equal(row$optimizer, "nlminb")
  expect_equal(row$objective, 12.5)
  expect_true(row$selected)
  frame <- drmTMB:::drm_optimizer_attempts_frame(list(row, NULL))
  expect_equal(nrow(frame), 1L)
  rec <- drmTMB:::drm_optimizer_selected_record(frame)
  expect_equal(rec$attempt, 2L)
  expect_true(rec$retried)
  expect_equal(rec$control$iter.max, 100L)
})

test_that("drm_optimizer_attempts_frame drops null rows", {
  r1 <- drmTMB:::drm_optimizer_attempt_row(
    1L, "default", list(), "ok", 0L, NA, 1, 0.1, TRUE
  )
  frame <- drmTMB:::drm_optimizer_attempts_frame(list(NULL, r1, NULL))
  expect_equal(nrow(frame), 1L)
  expect_equal(rownames(frame), "1")
})
# Training-design helpers in R/julia-joint-methods.R (not covered by open PRs).

test_that("drm_julia_joint_binary_data encodes Bernoulli levels", {
  dat <- data.frame(z = c("a", "b", NA, "a"))
  out <- drmTMB:::drm_julia_joint_binary_data(dat, "z", c("a", "b"))
  expect_type(out$z, "double")
  expect_equal(out$z[c(1, 2, 4)], c(0, 1, 0))
  expect_true(is.na(out$z[3]))
  expect_error(
    drmTMB:::drm_julia_joint_binary_data(dat, "missing", c("a", "b")),
    "newdata"
  )
  expect_error(
    drmTMB:::drm_julia_joint_binary_data(dat, "z", c("only")),
    "binary-level"
  )
})

test_that("drm_julia_joint_training_design_data handles bernoulli and ordinal", {
  bern <- data.frame(z = c(0, 1, NA))
  out_b <- drmTMB:::drm_julia_joint_training_design_data(
    bern, "z", "bernoulli", c("a", "b")
  )
  expect_true(is.numeric(out_b$z))
  expect_false(any(is.na(out_b$z)))

  ord <- data.frame(cat = c("low", "high", NA))
  out_o <- drmTMB:::drm_julia_joint_training_design_data(
    ord, "cat", "ordinal", c("low", "mid", "high")
  )
  expect_s3_class(out_o$cat, "ordered")
  expect_equal(levels(out_o$cat), c("low", "mid", "high"))

  bad <- data.frame(z = c("not", "numeric"))
  expect_error(
    drmTMB:::drm_julia_joint_training_design_data(bad, "z", "gaussian", NULL),
    "numeric modelled predictor"
  )
})

test_that("drm_julia_joint_training_design_data recurses over variables", {
  dat <- data.frame(
    z1 = c(0, 1),
    z2 = c(1, 0)
  )
  multi <- drmTMB:::drm_julia_joint_training_design_data(
    dat, c("z1", "z2"), "bernoulli", c("a", "b")
  )
  expect_true(is.numeric(multi$z1))
  expect_true(is.numeric(multi$z2))
  expect_identical(nrow(multi), 2L)
})
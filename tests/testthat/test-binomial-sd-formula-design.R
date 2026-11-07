test_that("binomial SD formulas preserve factor, numeric, and interaction coding", {
  dat <- binomial_sd_fixture(groups = 24L, repeats = 4L)$data
  group_ids <- levels(dat$id)
  group_band <- factor(
    rep(c("control", "treated"), each = length(group_ids) / 2L),
    levels = c("control", "treated")
  )
  group_z <- seq(-1.2, 1.2, length.out = length(group_ids))
  group_index <- match(as.character(dat$id), group_ids)
  dat$band <- group_band[group_index]
  dat$z <- group_z[group_index]

  spec <- drm_build_binomial_spec(
    bf(y ~ x + (1 | id), sd(id) ~ band * z),
    dat
  )
  Z <- spec$random_scale$mu$X_list[["sd(id)"]]
  group_data <- data.frame(band = group_band, z = group_z)
  expected <- stats::model.matrix(~ band * z, data = group_data)

  expect_identical(colnames(Z), colnames(expected))
  expect_equal(unname(Z), unname(expected))

  alpha <- c(-0.7, 0.2, 0.3, -0.15)
  treated <- as.numeric(group_band == "treated")
  expected_sd <- exp(-0.7 + 0.2 * treated + 0.3 * group_z - 0.15 * treated * group_z)
  expect_equal(unname(drop(Z %*% alpha)), unname(log(expected_sd)))

  dat$band <- as.character(dat$band)
  dat$band[1L] <- "treated"
  dat$band <- factor(dat$band, levels = c("control", "treated"))
  expect_error(
    drm_build_binomial_spec(bf(y ~ x + (1 | id), sd(id) ~ band * z), dat),
    "constant within"
  )
})

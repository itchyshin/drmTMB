test_that("NB2 ordinary intercept SD assembles group-level predictor rows", {
  sim <- poisson_sd_fixture(groups = 12L, repeats = 4L)
  spec <- drm_build_nbinom2_spec(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    sim$data
  )

  expect_identical(spec$model_type, "nbinom2")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$n_models, 1L)
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
    sim$w_group
  )
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
  expect_identical(spec$dpars, c("mu", "sigma", "sd(id)"))
})

test_that("NB2 ordinary intercept SD keeps its narrow admission boundary", {
  sim <- poisson_sd_fixture(groups = 12L, repeats = 4L)
  zi_spec <- drm_build_nbinom2_spec(
    bf(y ~ x + (1 | id), sigma ~ 1, zi ~ 1, sd(id) ~ w),
    sim$data
  )
  expect_identical(zi_spec$model_type, "zi_nbinom2")
  expect_identical(zi_spec$random_scale$mu$dpars, "sd(id)")

  dat <- sim$data
  dat$w[1L] <- dat$w[1L] + 0.2
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w), dat
    ),
    "constant within"
  )

  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w + (1 | id)),
      sim$data
    ),
    "unsupported model terms"
  )
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ offset(w)),
      sim$data
    ),
    "offset"
  )
})

test_that("NB2 ordinary independent-slope SD maps the slope and SD rows", {
  sim <- poisson_sd_fixture(groups = 12L, repeats = 6L)
  spec <- drm_build_nbinom2_spec(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id) ~ w),
    sim$data
  )

  expect_identical(spec$model_type, "nbinom2")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$n_models, 1L)
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_equal(unname(spec$tmb_data$mu_re_value[, 1L]), sim$data$x)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
})

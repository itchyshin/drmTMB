truncated_nbinom2_sd_assembly_data <- function(groups = 12L, repeats = 4L) {
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  data.frame(
    count = rep(seq_len(4L), length.out = length(group)),
    x = stats::rnorm(length(group)),
    w = w_group[group],
    id = factor(group)
  )
}

test_that("truncated NB2 SD regression assembles one ordinary mu intercept", {
  dat <- truncated_nbinom2_sd_assembly_data()
  spec <- drm_build_truncated_nbinom2_spec(
    bf(count ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    dat
  )

  expect_identical(spec$model_type, "truncated_nbinom2")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$coef,
                   "(Intercept)")
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
    seq(-1, 1, length.out = 12L)
  )
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
  expect_null(spec$map$beta_sd_mu)
  par <- spec$start
  par$beta_sd_mu <- c(-0.3, 0.2)
  expect_equal(
    split_tmb_parameters(par, spec)[["sd(id)"]],
    c("(Intercept)" = -0.3, w = 0.2)
  )
})

test_that("truncated NB2 SD regression can target one independent mu slope", {
  dat <- truncated_nbinom2_sd_assembly_data()
  spec <- drm_build_truncated_nbinom2_spec(
    bf(
      count ~ x + (0 + x | id),
      sigma ~ 1,
      sd(id, coef = "x") ~ w
    ),
    dat
  )

  expect_identical(spec$model_type, "truncated_nbinom2")
  expect_equal(spec$random$mu$n_re, nlevels(dat$id))
  expect_identical(spec$random_scale$mu$dpars, "sd(id, coef = \"x\")")
  expect_identical(
    spec$random_scale$mu$re_sd_row0,
    seq_len(spec$random$mu$n_re) - 1L
  )
  expect_equal(
    unname(spec$random_scale$mu$X_list[[spec$random_scale$mu$dpars]][, "w"]),
    seq(-1, 1, length.out = 12L)
  )
})

test_that("truncated NB2 SD regression rejects unsupported first-slice designs", {
  dat <- truncated_nbinom2_sd_assembly_data()
  expect_error(
    drm_build_truncated_nbinom2_spec(
      bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ 1, sd(id) ~ w),
      dat
    ),
    "one ordinary.*intercept"
  )

  varying <- dat
  varying$w[[2L]] <- varying$w[[2L]] + 0.1
  expect_error(
    drm_build_truncated_nbinom2_spec(
      bf(count ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
      varying
    ),
    "varies within id level"
  )

  expect_error(
    drm_build_truncated_nbinom2_spec(
      bf(count ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
      dat,
      missing = miss_control(response = "include")
    ),
    "requires complete responses"
  )
})

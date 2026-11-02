tweedie_sd_assembly_data <- function(groups = 12L, repeats = 4L) {
  id_index <- rep(seq_len(groups), each = repeats)
  group_w <- seq(-1, 1, length.out = groups)
  data.frame(
    y = abs(sin(seq_along(id_index) / 4)) + 0.1,
    x = cos(seq_along(id_index) / 5),
    w = group_w[id_index],
    id = factor(id_index)
  )
}

test_that("Tweedie ordinary intercept SD assembles group predictor rows", {
  dat <- tweedie_sd_assembly_data()
  spec <- drm_build_tweedie_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w), dat
  )

  expect_identical(spec$model_type, "tweedie")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$coef,
                   "(Intercept)")
  expect_equal(unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
               seq(-1, 1, length.out = 12L))
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
})

test_that("Tweedie ordinary slope SD targets the random slope", {
  dat <- tweedie_sd_assembly_data()
  spec <- drm_build_tweedie_ls_spec(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, coef = "x") ~ w),
    dat
  )

  expect_identical(spec$random$mu$coef_names, "x")
  expect_identical(spec$random_scale$mu$dpars, "sd(id, coef = \"x\")")
  expect_identical(
    spec$random_scale$mu$target_identity[["sd(id, coef = \"x\")"]]$coef,
    "x"
  )
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id, coef = \"x\")"]][, "w"]),
    seq(-1, 1, length.out = 12L)
  )
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_length(spec$start$beta_sd_mu, 2L)
})

test_that("Tweedie SD regression keeps the one-term boundary", {
  dat <- tweedie_sd_assembly_data()
  expect_no_error(
    drm_build_tweedie_ls_spec(
      bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
         sd(id, coef = "x") ~ w), dat
    )
  )
  expect_error(
    drm_build_tweedie_ls_spec(
      bf(y ~ x + (1 + x | id), sigma ~ 1, nu ~ 1, sd(id) ~ w), dat
    ),
    "Unsupported random-effect term"
  )
  expect_error(
    drm_build_tweedie_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w + (1 | id)), dat
    ),
    "unsupported model terms"
  )
  dat$w[[1L]] <- dat$w[[1L]] + 0.25
  expect_error(
    drm_build_tweedie_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w), dat
    ),
    "constant within"
  )
  dat$y[[1L]] <- NA_real_
  expect_error(
    drm_build_tweedie_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w),
      dat,
      missing = miss_control(response = "include")
    ),
    "requires complete responses"
  )
})

skew_normal_sd_assembly_data <- function(groups = 10L, repeats = 3L) {
  group_index <- rep(seq_len(groups), each = repeats)
  group_w <- seq(-1, 1, length.out = groups)
  data.frame(
    y = sin(seq_along(group_index) / 3),
    x = cos(seq_along(group_index) / 5),
    w = group_w[group_index],
    id = factor(group_index)
  )
}

test_that("skew-normal ordinary intercept SD assembles target metadata", {
  dat <- skew_normal_sd_assembly_data()
  spec <- drm_build_skew_normal_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w), dat
  )

  expect_identical(spec$model_type, "skew_normal")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$coef,
                   "(Intercept)")
  expect_equal(unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
               seq(-1, 1, length.out = 10L))
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_length(spec$start$beta_sd_mu, 2L)
})

test_that("skew-normal independent slope SD assembles target metadata", {
  dat <- skew_normal_sd_assembly_data()
  spec <- drm_build_skew_normal_ls_spec(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, coef = "x") ~ w),
    dat
  )

  key <- 'sd(id, coef = "x")'
  expect_identical(spec$random_scale$mu$dpars, key)
  expect_identical(spec$random_scale$mu$target_identity[[key]]$coef, "x")
  expect_equal(unname(spec$random_scale$mu$X_list[[key]][, "w"]),
               seq(-1, 1, length.out = 10L))
  expect_length(spec$random_scale$mu$re_sd_row0, 10L)
  expect_length(spec$start$beta_sd_mu, 2L)
})

test_that("skew-normal SD target selectors and fences are explicit", {
  dat <- skew_normal_sd_assembly_data()
  selected <- drm_build_skew_normal_ls_spec(bf(
    y ~ x + (1 | id), sigma ~ 1, nu ~ 1,
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w
  ), dat)
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  expect_identical(selected$random_scale$mu$target_identity[[key]]$coef,
                   "(Intercept)")

  expect_error(
    drm_build_skew_normal_ls_spec(
      bf(y ~ x + (1 + x | id), sigma ~ 1, nu ~ 1,
         sd(id, coef = "x") ~ w),
      dat
    ),
    "Only independent.*random intercepts and slopes are implemented"
  )
  expect_error(
    drm_build_skew_normal_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w + (1 | id)), dat
    ),
    "unsupported model terms"
  )
})

test_that("skew-normal rejects structured SD formulas it cannot fit", {
  dat <- skew_normal_sd_assembly_data()

  expect_error(
    drm_build_skew_normal_ls_spec(
      bf(
        y ~ x + (1 | id), sigma ~ 1, nu ~ 1,
        sd(id, level = "animal") ~ w
      ),
      dat
    ),
    "Skew-normal.*animal.*SD"
  )
})

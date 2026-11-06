gamma_sd_assembly_data <- function(groups = 12L, repeats = 4L, seed = 20261023L) {
  set.seed(seed)
  id_index <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  data.frame(
    y = exp(0.2 + 0.25 * rnorm(length(id_index))),
    x = rnorm(length(id_index)),
    w = w_group[id_index],
    id = factor(id_index)
  )
}

test_that("Gamma ordinary intercept SD assembles group predictor rows", {
  dat <- gamma_sd_assembly_data()
  spec <- drm_build_gamma_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w), dat
  )

  expect_identical(spec$model_type, "gamma")
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

test_that("Gamma SD regression maps an independent slope to group SD rows", {
  dat <- gamma_sd_assembly_data()
  slope_spec <- drm_build_gamma_ls_spec(
    bf(y ~ 1 + (0 + x | id), sigma ~ 1, sd(id) ~ w), dat
  )

  expect_identical(slope_spec$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  expect_identical(slope_spec$random_scale$mu$target_identity[["sd(id)"]]$coef,
                   "x")
  expect_equal(unname(slope_spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
               seq(-1, 1, length.out = 12L))
  expect_identical(slope_spec$random_scale$mu$re_sd_row0,
                   seq_len(slope_spec$random$mu$n_re) - 1L)
  expect_equal(as.numeric(slope_spec$random$mu$value[, 1L]), dat$x)

  expect_error(
    drm_build_gamma_ls_spec(
      bf(y ~ x + (1 + x | id), sigma ~ 1, sd(id) ~ w), dat
    ),
    "Unsupported random-effect term"
  )
  expect_error(
    drm_build_gamma_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w + (1 | id)), dat
    ),
    "unsupported model terms"
  )
  dat$w[[1L]] <- dat$w[[1L]] + 0.25
  expect_error(
    drm_build_gamma_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w), dat
    ),
    "constant within"
  )
})

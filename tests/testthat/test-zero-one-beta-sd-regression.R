zero_one_beta_sd_assembly_data <- function(groups = 12L, repeats = 4L) {
  group <- rep(seq_len(groups), each = repeats)
  predictor <- seq(-1, 1, length.out = groups)
  response <- rep(c(0, 1, 0.25, 0.75), length.out = length(group))
  data.frame(
    prop = response,
    w = predictor[group],
    id = factor(group)
  )
}

test_that("zero-one beta location SD regression assembles an intercept target", {
  dat <- zero_one_beta_sd_assembly_data()
  spec <- drm_build_zero_one_beta_spec(
    bf(prop ~ 1 + (1 | id), sd(id) ~ w),
    dat
  )

  expect_identical(spec$model_type, "zero_one_beta")
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
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
  par <- spec$start
  par$beta_sd_mu <- c(0.15, 0.25)
  expect_equal(
    split_tmb_parameters(par, spec)[["sd(id)"]],
    c("(Intercept)" = 0.15, w = 0.25)
  )
})

test_that("zero-one beta SD regression rejects unsupported mixed designs", {
  dat <- zero_one_beta_sd_assembly_data()
  expect_error(
    drm_build_zero_one_beta_spec(
      bf(prop ~ 1 + (1 | id), sigma ~ 1 + (1 | id), sd(id) ~ w),
      dat
    ),
    "sigma.*combined with other random effects"
  )

  varying <- dat
  varying$w[[2L]] <- varying$w[[2L]] + 0.1
  expect_error(
    drm_build_zero_one_beta_spec(
      bf(prop ~ 1 + (1 | id), sd(id) ~ w),
      varying
    ),
    "varies within id level"
  )

  expect_error(
    drm_build_zero_one_beta_spec(
      bf(prop ~ 1 + (1 | id), sd(id) ~ w),
      dat,
      missing = miss_control(response = "include")
    ),
    "requires complete responses"
  )
})

test_that("zero-one beta rejects structured SD formulas it cannot fit", {
  dat <- zero_one_beta_sd_assembly_data()

  expect_error(
    drm_build_zero_one_beta_spec(
      bf(prop ~ 1 + (1 | id), sd(id, level = "animal") ~ w),
      dat
    ),
    "Zero-one beta.*animal.*SD"
  )
})

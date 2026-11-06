cumulative_logit_sd_assembly_data <- function(groups = 10L, repeats = 4L) {
  group <- rep(seq_len(groups), each = repeats)
  levels <- c("low", "middle", "high")
  score <- ordered(rep(levels, length.out = length(group)), levels = levels)
  w_group <- seq(-1, 1, length.out = groups)
  data.frame(
    score = score,
    x = stats::rnorm(length(group)),
    w = w_group[group],
    id = factor(group)
  )
}

test_that("cumulative-logit SD regression assembles one ordinary mu intercept", {
  dat <- cumulative_logit_sd_assembly_data()
  spec <- drm_build_cumulative_logit_spec(
    bf(score ~ x + (1 | id), sd(id) ~ w),
    dat
  )

  expect_identical(spec$model_type, "cumulative_logit")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$coef,
                   "(Intercept)")
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
    seq(-1, 1, length.out = 10L)
  )
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
  expect_null(spec$map$beta_sd_mu)
  par <- spec$start
  par$beta_sd_mu <- c(-0.4, 0.2)
  expect_equal(
    split_tmb_parameters(par, spec)[["sd(id)"]],
    c("(Intercept)" = -0.4, w = 0.2)
  )
})

test_that("cumulative-logit SD regression rejects unsupported first-slice designs", {
  dat <- cumulative_logit_sd_assembly_data()
  expect_error(
    drm_build_cumulative_logit_spec(
      bf(score ~ x + (1 | id) + (0 + x | id), sd(id) ~ w),
      dat
    ),
    "one ordinary.*random intercept"
  )

  varying <- dat
  varying$w[[2L]] <- varying$w[[2L]] + 0.1
  expect_error(
    drm_build_cumulative_logit_spec(
      bf(score ~ x + (1 | id), sd(id) ~ w),
      varying
    ),
    "varies within id level"
  )

  expect_error(
    drm_build_cumulative_logit_spec(
      bf(score ~ x + (1 | id), sd(id) ~ w),
      dat,
      missing = miss_control(response = "include")
    ),
    "requires complete responses"
  )
})

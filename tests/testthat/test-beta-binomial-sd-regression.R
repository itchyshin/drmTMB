beta_binomial_sd_assembly_data <- function(groups = 8L, repeats = 5L) {
  group_index <- rep(seq_len(groups), each = repeats)
  group_w <- seq(-1, 1, length.out = groups)
  mu <- stats::plogis(-0.2 + 0.3 * group_w[group_index])
  trials <- rep(12L, length(group_index))
  successes <- stats::rbinom(length(group_index), trials, mu)
  data.frame(
    success = successes,
    failure = trials - successes,
    x = seq_along(group_index) / length(group_index),
    w = group_w[group_index],
    id = factor(group_index)
  )
}

test_that("Beta-binomial ordinary-intercept SD assembles a group-level design", {
  dat <- beta_binomial_sd_assembly_data()
  spec <- drm_build_beta_binomial_spec(
    bf(cbind(success, failure) ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    dat
  )

  expect_identical(spec$model_type, "beta_binomial")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_equal(unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
               seq(-1, 1, length.out = 8L))
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
  expect_identical(spec$dpars, c("mu", "sigma", "sd(id)"))
})

test_that("Beta-binomial SD design rejects within-group predictor variation", {
  dat <- beta_binomial_sd_assembly_data()
  dat$w <- seq_len(nrow(dat))
  expect_error(
    drm_build_beta_binomial_spec(
      bf(cbind(success, failure) ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
      dat
    ),
    "varies within id level"
  )
})

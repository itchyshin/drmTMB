test_that("binomial SD models carry the group design through TMB assembly", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  spec <- drm_build_binomial_spec(bf(y ~ x + (1 | id), sd(id) ~ w), dat)

  expect_equal(spec$random_scale$mu$n_models, 1L)
  expect_equal(spec$dpars, c("mu", "sd(id)"))
  expect_equal(colnames(spec$random_scale$mu$X_list[["sd(id)"]]),
               c("(Intercept)", "w"))
  expect_equal(colnames(spec$random_scale$mu$X),
               c("sd(id):(Intercept)", "sd(id):w"))
  expect_equal(nrow(spec$random_scale$mu$X), nlevels(dat$id))
  expect_equal(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
})

test_that("binomial SD covariates participate in row filtering and validation", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  dat$w[dat$id == levels(dat$id)[1L]] <- NA_real_
  spec <- drm_build_binomial_spec(bf(y ~ x + (1 | id), sd(id) ~ w), dat)
  expect_equal(nrow(spec$data), nrow(dat) - 4L)
  expect_equal(nrow(spec$random_scale$mu$X), nlevels(dat$id) - 1L)

  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  dat$w[1L] <- dat$w[1L] + 0.1
  expect_error(
    drm_build_binomial_spec(bf(y ~ x + (1 | id), sd(id) ~ w), dat),
    "constant within"
  )
})

test_that("binomial SD models require an unambiguous matching intercept", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  expect_error(
    drm_build_binomial_spec(bf(y ~ x, sd(id) ~ w), dat),
    "No random-effect term matches"
  )
  expect_error(
    drm_build_binomial_spec(bf(y ~ x + (1 + x | id), sd(id) ~ w), dat),
    "Ambiguous|intercept"
  )
})

test_that("grouped binomial SD models retain trial counts", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L, trials = 5L)$data
  spec <- drm_build_binomial_spec(
    bf(cbind(y, failure) ~ x + (1 | id), sd(id) ~ w), dat
  )
  expect_equal(spec$trials, rep(5, nrow(dat)))
  expect_equal(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$random_scale$mu$dpars, "sd(id)")
})

test_that("registered SD targets are recognized independently of family labels", {
  object <- list(model = list(model_type = "binomial", random_scale = list(
    mu = list(n_models = 1L, dpars = "sd(id)"),
    phylo = list(n_models = 0L, dpars = character())
  )))
  expect_true(is_random_scale_dpar(object, "sd(id)"))
  expect_false(is_random_scale_dpar(object, "sd(other)"))
  expect_equal(drm_dpar_link(object, "sd(id)"), "log")
  object$model$random_scale <- NULL
  expect_false(is_random_scale_dpar(object, "sd(id)"))
})

lognormal_sd_assembly_data <- function(groups = 8L, repeats = 3L) {
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  data.frame(
    y = exp(0.25 + 0.4 * sin(seq_along(group) / 3)),
    x = seq(-1, 1, length.out = length(group)),
    z = cos(seq_along(group) / 4),
    w = w_group[group],
    id = factor(group),
    species = factor(rep(paste0("s", seq_len(4L)), length.out = length(group)),
                     levels = paste0("s", seq_len(4L)))
  )
}

test_that("lognormal ordinary intercept SD assembles group metadata", {
  dat <- lognormal_sd_assembly_data()
  spec <- drm_build_lognormal_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w), dat
  )

  expect_identical(spec$model_type, "lognormal")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$n_models, 1L)
  expect_equal(unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
               seq(-1, 1, length.out = nlevels(dat$id)))
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))

  # Direct random-effect SD regression adds a separate scale predictor while
  # leaving the residual sigma regression and its ordinary likelihood design.
  expect_equal(colnames(spec$X$sigma), c("(Intercept)", "z"))
  expect_identical(spec$random$sigma$n_terms, 0L)
  expect_length(spec$start$beta_sigma, 2L)
  expect_true(is.null(spec$map$beta_sigma) || !all(is.na(spec$map$beta_sigma)))
})

test_that("lognormal SD supports the common explicit mu and intercept selectors", {
  dat <- lognormal_sd_assembly_data()
  selected <- drm_build_lognormal_ls_spec(bf(
    y ~ x + (1 | id), sigma ~ z,
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w
  ), dat)
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'

  expect_identical(selected$random_scale$mu$dpars, key)
  expect_identical(selected$random_scale$mu$target_identity[[key]]$dpar, "mu")
  expect_identical(selected$random_scale$mu$target_identity[[key]]$coef,
                   "(Intercept)")
  expect_identical(selected$random_scale$mu$re_sd_row0,
                   seq_len(selected$random$mu$n_re) - 1L)
})

test_that("lognormal SD formula accepts a constant scale", {
  dat <- lognormal_sd_assembly_data()
  constant <- drm_build_lognormal_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ 1), dat
  )
  expect_identical(constant$random_scale$mu$n_models, 1L)
  expect_equal(ncol(constant$random_scale$mu$X), 1L)
  expect_true(all(constant$random_scale$mu$X[, 1L] == 1))
})

test_that("lognormal SD covariates must be constant within group", {
  dat <- lognormal_sd_assembly_data()
  dat$w[1L] <- dat$w[1L] + 0.2
  expect_error(drm_build_lognormal_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w), dat
  ), "constant within")
})

test_that("first lognormal SD slice rejects sigma RE, structured effects, and mi", {
  dat <- lognormal_sd_assembly_data()
  expect_error(drm_build_lognormal_ls_spec(bf(
    y ~ x + (1 | id), sigma ~ z + (1 | id), sd(id) ~ w
  ), dat), "cannot be combined with `mu` random effects")

  if (requireNamespace("ape", quietly = TRUE)) {
    tree <- ape::read.tree(text = "(s1:1,s2:1,s3:1,s4:1);")
    expect_error(drm_build_lognormal_ls_spec(bf(
      y ~ x + (1 | id) + phylo(1 | species, tree = tree),
      sigma ~ z, sd(id) ~ w
    ), dat), "ordinary and structured")
  }

  dat$x_mi <- as.numeric(dat$x > 0)
  dat$x_mi[c(2L, 8L)] <- NA_real_
  expect_error(drm_build_lognormal_ls_spec(
    bf(y ~ z + mi(x_mi) + (1 | id), sigma ~ z, sd(id) ~ w),
    dat,
    impute = list(x_mi = impute_model(x_mi ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  ), "fixed-effect.*only")
})

zi_poisson_sd_assembly_data <- function(groups = 24L, repeats = 8L) {
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  data.frame(
    y = rep(0:3, length.out = length(group)),
    x = rep(seq(-1, 1, length.out = repeats), groups),
    w = w_group[group],
    id = factor(group)
  )
}

test_that("zero-inflated Poisson SD regression assembles an ordinary mu intercept", {
  dat <- zi_poisson_sd_assembly_data()
  spec <- drm_build_poisson_spec(
    bf(y ~ 1 + (1 | id), zi ~ 1, sd(id) ~ w),
    dat
  )

  expect_identical(spec$model_type, "zi_poisson")
  expect_equal(spec$random$mu$n_re, nlevels(dat$id))
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$coef,
                   "(Intercept)")
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true("u_mu" %in% spec$random_names)
  expect_true(all(is.finite(spec$start$beta_zi)))
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
    seq(-1, 1, length.out = nlevels(dat$id))
  )
})

test_that("zero-inflated Poisson SD predictors must be constant within groups", {
  dat <- zi_poisson_sd_assembly_data()
  dat$w[[1L]] <- dat$w[[1L]] + 0.25

  expect_error(
    drm_build_poisson_spec(
      bf(y ~ 1 + (1 | id), zi ~ 1, sd(id) ~ w),
      dat
    ),
    "varies within id"
  )
})

test_that("zero-inflated Poisson SD regression assembles a selected mu slope", {
  dat <- zi_poisson_sd_assembly_data()

  spec <- drm_build_poisson_spec(
    bf(y ~ 1 + (0 + x | id), zi ~ 1,
       sd(id, dpar = "mu", coef = "x") ~ w),
    dat
  )
  sd_target <- names(spec$random_scale$mu$target_identity)[[1L]]

  expect_identical(spec$model_type, "zi_poisson")
  expect_equal(spec$random$mu$n_re, nlevels(dat$id))
  expect_identical(spec$random_scale$mu$target_identity[[sd_target]]$dpar, "mu")
  expect_identical(spec$random_scale$mu$target_identity[[sd_target]]$coef, "x")
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_equal(
    unname(spec$random_scale$mu$X_list[[sd_target]][, "w"]),
    seq(-1, 1, length.out = nlevels(dat$id))
  )
})

test_that("zero-inflated Poisson does not admit an unscaled mu slope", {
  dat <- zi_poisson_sd_assembly_data()

  expect_error(
    drm_build_poisson_spec(bf(y ~ 1 + (0 + x | id), zi ~ 1), dat),
    "support one ordinary Poisson.*intercept"
  )
})

test_that("zero-inflated Poisson reports the effective clamped log SD", {
  dat <- zi_poisson_sd_assembly_data()
  fit <- suppressWarnings(drmTMB(
    bf(y ~ 1 + (1 | id), zi ~ 1, sd(id) ~ w),
    family = stats::poisson(link = "log"), data = dat,
    control = drm_control(se = FALSE, logsigma_clamp = c(-2, 2))
  ))

  p <- fit$tmb_state$last.par.best
  beta_index <- which(names(p) == "beta_sd_mu")
  expect_length(beta_index, 2L)
  p[beta_index] <- c(4, 0)
  fit$coefficients[["sd(id)"]] <- c(4, 0)

  report <- fit$obj$report(p)
  eta <- as.vector(fit$model$random_scale$mu$X_list[["sd(id)"]] %*% c(4, 0))
  effective_log_sd <- drm_softclamp_log_sd(eta, fit$model$tmb_data)
  expect_true(any(eta > 2))
  expect_equal(as.numeric(report$log_sd_mu_group), effective_log_sd,
               tolerance = 1e-10)
  expect_equal(as.numeric(report$sd_mu_group), exp(effective_log_sd),
               tolerance = 1e-10)
  expect_equal(as.numeric(predict(fit, dpar = "sd(id)", type = "link")),
               effective_log_sd, tolerance = 1e-10)
  expect_equal(as.numeric(predict(fit, dpar = "sd(id)", type = "response")),
               exp(effective_log_sd), tolerance = 1e-10)
})

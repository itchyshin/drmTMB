hurdle_nbinom2_sd_bridge_fixture <- function(n_group = 8L, n_each = 4L) {
  group <- factor(rep(seq_len(n_group), each = n_each))
  w_group <- seq(-1, 1, length.out = n_group)
  data.frame(
    count = rep(c(0, 1, 2, 3), length.out = length(group)),
    x = rep(seq(-1.5, 1.5, length.out = n_each), n_group),
    w = rep(w_group, each = n_each),
    z = rep(w_group, each = n_each),
    id = group
  )
}

hurdle_nbinom2_sd_bridge_recovery_data <- function(kind, seed) {
  set.seed(seed)
  n_group <- 100L
  n_each <- 20L
  group_index <- rep(seq_len(n_group), each = n_each)
  z_group <- seq(-1, 1, length.out = n_group)
  z <- z_group[group_index]
  x <- stats::rnorm(length(group_index))
  w <- stats::rnorm(length(group_index))
  alpha <- c(`(Intercept)` = -1.0, z = 0.35)
  random_effect <- exp(alpha[[1L]] + alpha[[2L]] * z_group) *
    stats::rnorm(n_group)
  if (identical(kind, "intercept")) {
    mu <- exp(0.55 - 0.2 * x + random_effect[group_index])
    formula <- bf(
      count ~ x + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ z
    )
    target <- "sd(id)"
  } else {
    mu <- exp(0.65 * x + random_effect[group_index] * x)
    formula <- bf(
      count ~ 0 + x + (0 + x | id), sigma ~ 1, hu ~ 1,
      sd(id, coef = "x") ~ z
    )
    target <- 'sd(id, coef = "x")'
  }
  sigma <- 0.55
  size <- 1 / sigma^2
  hurdle_zero <- stats::runif(length(group_index)) < stats::plogis(-0.9)
  p0 <- stats::dnbinom(0, size = size, mu = mu)
  positive_probability <- p0 + stats::runif(length(group_index)) * (1 - p0)
  positive_probability <- pmax(positive_probability, p0 + .Machine$double.eps)
  count <- stats::qnbinom(positive_probability, size = size, mu = mu)
  count[hurdle_zero == 1L] <- 0L
  list(
    data = data.frame(
      count = count, x = x, w = w, z = z,
      id = factor(group_index)
    ),
    formula = formula,
    target = target,
    alpha = alpha
  )
}

test_that("Hurdle NB2 Julia fence admits only matched ordinary mu SD routes", {
  dat <- hurdle_nbinom2_sd_bridge_fixture()
  intercept <- bf(
    count ~ x + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ z
  )
  slope <- bf(
    count ~ 0 + x + (0 + x | id), sigma ~ 1, hu ~ 1,
    sd(id, coef = "x") ~ z
  )

  expect_invisible(drmTMB:::drm_julia_refuse_fe_only_random_effects(
    intercept, "truncated_nbinom2", data = dat
  ))
  expect_invisible(drmTMB:::drm_julia_refuse_fe_only_random_effects(
    slope, "truncated_nbinom2", data = dat
  ))

  wrong_target <- bf(
    count ~ 0 + x + (0 + x | id), sigma ~ 1, hu ~ 1,
    sd(other, coef = "x") ~ z
  )
  expect_error(
    drmTMB:::drm_julia_refuse_fe_only_random_effects(
      wrong_target, "truncated_nbinom2", data = dat
    ),
    "fixed-effect.*route"
  )

  extra_bar <- bf(
    count ~ x + (1 | id) + (1 | other), sigma ~ 1, hu ~ w,
    sd(id) ~ z
  )
  expect_error(
    drmTMB:::drm_julia_refuse_fe_only_random_effects(
      extra_bar, "truncated_nbinom2", data = dat
    ),
    "fixed-effect.*route"
  )
})

test_that("Hurdle NB2 SD target labels match Julia's single sd block", {
  dat <- hurdle_nbinom2_sd_bridge_fixture()
  formulas <- list(
    bf(count ~ x + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ z),
    bf(count ~ 0 + x + (0 + x | id), sigma ~ 1, hu ~ 1,
       sd(id, coef = "x") ~ z)
  )

  for (form in formulas) {
    labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
      formula = form,
      data = dat,
      env = environment(),
      family_type = "truncated_nbinom2"
    )
    expect_identical(labels$sd, c("(Intercept)", "z"))
    expect_false(any(grepl("^sdtarget_", names(labels))))
  }
})

test_that("Hurdle NB2 intercept and slope SD routes bridge to Julia", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (i in seq_along(c("intercept", "slope"))) {
    kind <- c("intercept", "slope")[[i]]
    sim <- hurdle_nbinom2_sd_bridge_recovery_data(
      kind, seed = if (kind == "intercept") 20261021L else 20261023L
    )
    fit_tmb <- drmTMB(
      sim$formula, family = truncated_nbinom2(), data = sim$data,
      engine = "tmb"
    )
    fit_julia <- drmTMB(
      sim$formula, family = truncated_nbinom2(), data = sim$data,
      engine = "julia"
    )
    tmb_sd <- coef(fit_tmb, dpar = sim$target)
    julia_sd <- coef(fit_julia, dpar = sim$target)

    expect_true(is_converged(fit_tmb))
    expect_true(is_converged(fit_julia))
    expect_identical(fit_julia$model$model_type, "hurdle_nbinom2")
    expect_named(tmb_sd, c("(Intercept)", "z"))
    expect_named(julia_sd, names(tmb_sd))
    expect_gt(unname(tmb_sd[["z"]]), 0)
    expect_gt(unname(julia_sd[["z"]]), 0)
    expect_lt(abs(unname(tmb_sd[["z"]] - sim$alpha[["z"]])), 0.55)
    expect_lt(abs(unname(julia_sd[["z"]] - sim$alpha[["z"]])), 0.8)
    expect_lt(abs(unname(julia_sd[["z"]] - tmb_sd[["z"]])), 0.8)

    tmb_group_sd <- predict(fit_tmb, dpar = sim$target)
    julia_group_sd <- predict(fit_julia, dpar = sim$target)
    expect_length(tmb_group_sd, nlevels(sim$data$id))
    expect_length(julia_group_sd, nlevels(sim$data$id))
    expect_true(all(tmb_group_sd > 0))
    expect_true(all(julia_group_sd > 0))
  }
})

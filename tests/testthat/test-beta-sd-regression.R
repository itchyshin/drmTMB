beta_sd_fixture <- function(groups = 12L, repeats = 4L) {
  id <- factor(rep(seq_len(groups), each = repeats))
  z_group <- seq(-1, 1, length.out = groups)
  z <- z_group[as.integer(id)]
  x <- rep(c(-0.5, 0.5), length.out = length(id))
  data.frame(
    y = stats::qbeta(
      stats::runif(length(id), 0.1, 0.9),
      shape1 = 3,
      shape2 = 4
    ),
    id = id,
    x = x,
    z = z
  )
}

test_that("Beta ordinary scalar SD assembles group-level predictor rows", {
  dat <- beta_sd_fixture()
  spec <- drm_build_beta_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z),
    dat
  )

  expect_identical(spec$model_type, "beta")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id)"]][, "z"]),
    unique(dat$z)
  )
  expect_identical(
    spec$random_scale$mu$re_sd_row0,
    seq_len(spec$random$mu$n_re) - 1L
  )
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
  expect_identical(spec$dpars, c("mu", "sigma", "sd(id)"))
})

test_that("Beta ordinary slope SD targets the random slope", {
  dat <- beta_sd_fixture()
  spec <- drm_build_beta_ls_spec(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id, coef = "x") ~ z),
    dat
  )

  expect_identical(spec$random$mu$coef_names, "x")
  expect_identical(spec$random_scale$mu$dpars, "sd(id, coef = \"x\")")
  expect_equal(
    unname(spec$random_scale$mu$X_list[[spec$random_scale$mu$dpars]][, "z"]),
    unique(dat$z)
  )
  expect_identical(
    spec$random_scale$mu$re_sd_row0,
    seq_len(spec$random$mu$n_re) - 1L
  )
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
})

test_that("Beta ordinary SD keeps its first-slice boundary", {
  dat <- beta_sd_fixture()
  dat$z[1L] <- dat$z[1L] + 0.2
  expect_error(
    drm_build_beta_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z),
      dat
    ),
    "constant within"
  )

  dat <- beta_sd_fixture()
  expect_error(
    drm_build_beta_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z + (1 | id)),
      dat
    ),
    "unsupported model terms"
  )

  dat$other <- factor(rep(seq_len(6L), length.out = nrow(dat)))
  expect_error(
    drm_build_beta_ls_spec(
      bf(y ~ x + (0 + x | id) + (1 | other), sigma ~ 1,
         sd(id, coef = "x") ~ z),
      dat
    ),
    "one ordinary.*slope"
  )
})

test_that("Beta ordinary random-intercept SD regression recovers independent truth", {
  skip_on_cran()
  set.seed(20261024L)
  n_group <- 36L
  n_per_group <- 10L
  group_id <- rep(seq_len(n_group), each = n_per_group)
  id_levels <- sprintf("group%02d", seq_len(n_group))
  id <- factor(id_levels[group_id], levels = id_levels)
  z_group <- stats::setNames(seq(-1, 1, length.out = n_group), id_levels)
  z <- unname(z_group[as.character(id)])
  x <- rep(seq(-1, 1, length.out = n_per_group), times = n_group)
  sd_true <- exp(log(0.45) + 0.5 * z_group)
  b <- stats::rnorm(n_group, sd = sd_true)
  eta <- -0.2 + 0.45 * x + b[group_id]
  mu <- stats::plogis(eta)
  sigma <- 0.25
  phi <- 1 / sigma^2
  dat <- data.frame(
    y = stats::rbeta(length(mu), shape1 = mu * phi, shape2 = (1 - mu) * phi),
    id = id,
    x = x,
    z = z
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z),
    family = beta_family(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd(id)")[["z"]] - 0.5), 0.3)
  sd_prediction <- predict(fit, dpar = "sd(id)")
  expect_setequal(names(sd_prediction), id_levels)
  expected_sd <- exp(
    coef(fit, "sd(id)")[["(Intercept)"]] +
      coef(fit, "sd(id)")[["z"]] * z_group[names(sd_prediction)]
  )
  expect_equal(unname(sd_prediction), unname(expected_sd), tolerance = 1e-10)
})

test_that("Beta ordinary independent-slope SD regression recovers independent truth", {
  skip_on_cran()
  set.seed(20261025L)
  n_group <- 40L
  n_per_group <- 10L
  group_id <- rep(seq_len(n_group), each = n_per_group)
  id_levels <- sprintf("slopegroup%02d", seq_len(n_group))
  id <- factor(id_levels[group_id], levels = id_levels)
  z_group <- stats::setNames(seq(-1, 1, length.out = n_group), id_levels)
  z <- unname(z_group[as.character(id)])
  x <- rep(seq(-1, 1, length.out = n_per_group), times = n_group)
  sd_true <- exp(log(0.4) + 0.45 * z_group)
  b_slope <- stats::rnorm(n_group, sd = sd_true)
  eta <- -0.2 + 0.45 * x + b_slope[group_id] * x
  mu <- stats::plogis(eta)
  sigma <- 0.25
  phi <- 1 / sigma^2
  dat <- data.frame(
    y = stats::rbeta(length(mu), shape1 = mu * phi, shape2 = (1 - mu) * phi),
    id = id,
    x = x,
    z = z
  )
  target <- 'sd(id, coef = "x")'

  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id, coef = "x") ~ z),
    family = beta_family(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, target), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, target)[["z"]] - 0.45), 0.3)
  sd_prediction <- predict(fit, dpar = target)
  expect_setequal(names(sd_prediction), id_levels)
  expected_sd <- exp(
    coef(fit, target)[["(Intercept)"]] +
      coef(fit, target)[["z"]] * z_group[names(sd_prediction)]
  )
  expect_equal(unname(sd_prediction), unname(expected_sd), tolerance = 1e-10)
})

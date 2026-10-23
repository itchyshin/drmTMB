joint_missing_prepare_data <- function() {
  data.frame(
    y = c(0.4, 0.7, NA, NA, 1.0, 1.3, 1.6, 1.9),
    x = c(-0.6, NA, 0.1, NA, 0.5, 0.8, 1.1, 1.4),
    z = c(-1.0, -0.7, -0.4, -0.1, 0.2, 0.5, 0.8, 1.1),
    f = factor(c("a", "b", "a", "b", "a", "b", "a", "b"))
  )
}

test_that("classed missing controls do not bypass engine validation", {
  dat <- joint_missing_prepare_data()
  raw <- miss_control(response = "include", predictor = "model")
  raw$engine <- "em"
  expect_error(drmTMB:::drm_julia_joint_prepare(
    bf(y ~ mi(x) + z, sigma ~ 1), gaussian(), dat,
    impute = list(x = x ~ z), missing = raw), "reserved")
})

test_that("subtraction cannot hide modelled covariates or invalid raw controls", {
  dat <- joint_missing_prepare_data()
  dat$y <- seq_len(nrow(dat)) / 10
  prepare <- function(formula, missing = miss_control(predictor = "model")) {
    drmTMB:::drm_julia_joint_prepare(formula, gaussian(), dat,
      impute = list(x = x ~ z), missing = missing)
  }
  expect_error(prepare(bf(y ~ mi(x) + I(y^2) - 1, sigma ~ 1)), "modelled variables")
  expect_error(prepare(bf(y ~ mi(x) + I(x^2) - 1, sigma ~ 1)), "modelled variables")
  raw <- miss_control(predictor = "model")
  raw$engine <- "em"
  expect_error(prepare(bf(y ~ mi(x) + z, sigma ~ 1), raw), "reserved")
  raw$engine <- "laplace"
  raw$response <- c("drop", "include")
  expect_error(prepare(bf(y ~ mi(x) + z, sigma ~ 1), raw), "single")
  expect_silent(prepare(bf(y ~ mi(x) + z - 1, sigma ~ 1)))
})

test_that("joint Julia preparation serializes all four response/predictor masks", {
  dat <- joint_missing_prepare_data()
  prepared <- drmTMB:::drm_julia_joint_prepare(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = gaussian(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = drm_control(),
    impute = list(x = x ~ z),
    missing = miss_control(response = "include", predictor = "model")
  )

  payload <- prepared$payload
  expect_identical(payload$schema, "joint_missing_v1")
  expect_identical(payload$predictor, "gaussian")
  expect_identical(payload$variable, "x")
  expect_equal(payload$original_row, seq_len(nrow(dat)))
  expect_equal(payload$observed_y, c(TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE))
  expect_equal(payload$observed_x, c(TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE))
  expect_equal(
    sort(unique(paste(payload$observed_y, payload$observed_x))),
    c("FALSE FALSE", "FALSE TRUE", "TRUE FALSE", "TRUE TRUE")
  )
  expect_true(is.matrix(payload$X_mu))
  expect_true(is.matrix(payload$X_sigma))
  expect_true(is.matrix(payload$X_predictor))
  expect_true(is.numeric(payload$y))
  expect_true(is.numeric(payload$x))
  expect_equal(payload$mu_names[[payload$mu_col]], "mi(x)")
  expect_identical(payload$options, list(g_tol = 1e-8))
})

test_that("joint Julia preparation preserves factor coding and a non-last mi column", {
  dat <- joint_missing_prepare_data()
  prepared <- drmTMB:::drm_julia_joint_prepare(
    bf(y ~ mi(x) + f, sigma ~ 1),
    family = gaussian(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = drm_control(),
    impute = list(x = x ~ z),
    missing = miss_control(response = "include", predictor = "model")
  )

  payload <- prepared$payload
  expect_lt(payload$mu_col, ncol(payload$X_mu))
  expect_identical(payload$mu_names[[payload$mu_col]], "mi(x)")
  expect_true(any(grepl("^fb$", payload$mu_names)))
  expect_equal(ncol(payload$X_mu), 3L)
})

test_that("joint Julia preparation preserves native response-drop retained rows", {
  dat <- joint_missing_prepare_data()
  prepared <- drmTMB:::drm_julia_joint_prepare(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = gaussian(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = drm_control(),
    impute = list(x = x ~ z),
    missing = miss_control(predictor = "model")
  )

  payload <- prepared$payload
  expect_equal(payload$original_row, c(1L, 2L, 5L, 6L, 7L, 8L))
  expect_equal(prepared$spec$missing_data$original_row, payload$original_row)
  expect_true(all(payload$observed_y))
  expect_equal(sum(!payload$observed_x), 1L)
})

test_that("joint Julia preparation admits the fixed Bernoulli predictor route", {
  dat <- joint_missing_prepare_data()
  dat$x <- factor(
    c("no", NA, "yes", NA, "no", "yes", "yes", "no"),
    levels = c("no", "yes")
  )
  prepared <- drmTMB:::drm_julia_joint_prepare(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = gaussian(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = drm_control(),
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(response = "include", predictor = "model")
  )

  expect_identical(prepared$payload$predictor, "bernoulli")
  expect_true(all(prepared$payload$x[prepared$payload$observed_x] %in% c(0, 1)))
})

test_that("joint Julia preparation rejects unsupported exogenous and control neighbours", {
  dat <- joint_missing_prepare_data()
  args <- list(
    formula = bf(y ~ z + mi(x), sigma ~ 1),
    family = gaussian(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = drm_control(),
    impute = list(x = x ~ z),
    missing = miss_control(response = "include", predictor = "model")
  )

  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, modifyList(args, list(
      impute = list(x = x ~ y)
    ))),
    "modelled variables"
  )
  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, modifyList(args, list(
      control = drm_control(se = FALSE)
    ))),
    "default"
  )
  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, modifyList(args, list(
      weights_missing = rep(1, nrow(dat))
    ))),
    "weights"
  )
  random_args <- args
  random_args$formula <- bf(y ~ z + mi(x) + (1 | f), sigma ~ 1)
  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, random_args),
    "random"
  )
  sigma_mi_args <- args
  sigma_mi_args$formula <- bf(y ~ z + mi(x), sigma ~ mi(x))
  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, sigma_mi_args),
    "location"
  )
  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, modifyList(args, list(
      REML = TRUE
    ))),
    "REML"
  )

  complete_y <- dat
  complete_y$y <- seq_len(nrow(complete_y)) / 10
  complete_args <- args
  complete_args$data <- complete_y
  bare_x_args <- complete_args
  bare_x_args$formula <- bf(y ~ z + mi(x) + I(x^2), sigma ~ 1)
  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, bare_x_args),
    "modelled variables"
  )
  sigma_y_args <- complete_args
  sigma_y_args$formula <- bf(y ~ z + mi(x), sigma ~ I(y^2))
  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, sigma_y_args),
    "modelled variables"
  )
  same_variable_args <- complete_args
  same_variable_args$formula <- bf(x ~ z + mi(x), sigma ~ 1)
  expect_error(
    do.call(drmTMB:::drm_julia_joint_prepare, same_variable_args),
    "response itself"
  )
})

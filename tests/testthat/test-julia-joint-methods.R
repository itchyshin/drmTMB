joint_methods_prepared <- function() {
  dat <- data.frame(
    y = c(0.3, 0.7, NA, 1.1, 1.4, 1.8, 2.0, NA),
    x_var = c(-0.5, NA, 0.1, 0.4, NA, 0.9, 1.2, 1.4),
    z_score = c(-1.0, -0.6, -0.2, 0.1, 0.3, 0.6, 0.9, 1.1),
    habitat_type = factor(c("a", "b", "a", "b", "a", "b", "a", "b"))
  )
  list(
    data = dat,
    prepared = drmTMB:::drm_julia_joint_prepare(
      bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score),
      family = gaussian(),
      data = dat,
      env = environment(),
      weights_missing = TRUE,
      control = drm_control(),
      impute = list(x_var = x_var ~ z_score),
      missing = miss_control(response = "include", predictor = "model")
    )
  )
}

joint_methods_result <- function(prepared) {
  payload <- prepared$payload
  predictor_block <- paste0("mi_", payload$variable)
  blocks <- c(
    rep("mu", length(payload$mu_names)),
    rep("sigma", length(payload$sigma_names)),
    rep(predictor_block, length(payload$predictor_names)),
    if (identical(payload$predictor, "gaussian")) paste0("logsd_mi_", payload$variable)
  )
  terms <- c(
    payload$mu_names,
    payload$sigma_names,
    payload$predictor_names,
    if (identical(payload$predictor, "gaussian")) "log_sd"
  )
  theta <- seq_along(blocks) / 10
  if (identical(payload$predictor, "gaussian")) theta[[length(theta)]] <- log(1.5)
  V <- diag(seq_along(theta) / 100)
  V[1L, length(theta)] <- V[length(theta), 1L] <- 0.01
  n <- length(payload$y)
  std_error <- rep(NaN, n)
  std_error[!payload$observed_x] <- seq_len(sum(!payload$observed_x)) / 4
  list(
    schema = "joint_missing_result_v1",
    coef_names = paste0(blocks, "_", terms),
    coefficients = theta,
    vcov = V,
    vcov_names = paste0(blocks, "_", terms),
    coefficient_blocks = blocks,
    coefficient_terms = terms,
    loglik = -12.3,
    aic = 34.6,
    bic = 39.1,
    df = length(theta),
    nobs = n,
    converged = TRUE,
    iterations = 7L,
    fitted = seq_len(n) / 3,
    residuals = rep(0.1, n),
    sigma = exp(seq_len(n) / 20),
    corpairs = list(),
    dpars = list(),
    optimizer_status = "converged",
    covariance_status = "observed_information_inverse",
    original_row = payload$original_row,
    observed_y = payload$observed_y,
    observed_x = payload$observed_x,
    imputation = list(
      variable = rep("x_var", n),
      original_row = payload$original_row,
      model_row = seq_len(n),
      observed = payload$observed_x,
      estimate = seq_len(n) / 10,
      std_error = std_error,
      source = ifelse(
        payload$observed_x, "observed",
        if (identical(payload$predictor, "gaussian")) "conditional_mode" else "conditional_probability"
      ),
      uncertainty_status = rep("ok", n),
      se_available = !payload$observed_x
    )
  )
}

joint_methods_bernoulli_prepared <- function() {
  dat <- data.frame(
    y = c(0.3, 0.7, NA, 1.1, 1.4, 1.8, 2.0, NA),
    x_var = factor(
      c("no", NA, "yes", "no", NA, "yes", "yes", "no"),
      levels = c("no", "yes")
    ),
    z_score = c(-1.0, -0.6, -0.2, 0.1, 0.3, 0.6, 0.9, 1.1),
    habitat_type = factor(c("a", "b", "a", "b", "a", "b", "a", "b"))
  )
  list(
    data = dat,
    prepared = drmTMB:::drm_julia_joint_prepare(
      bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score),
      family = gaussian(),
      data = dat,
      env = environment(),
      weights_missing = TRUE,
      control = drm_control(),
      impute = list(x_var = impute_model(x_var ~ z_score, family = binomial())),
      missing = miss_control(response = "include", predictor = "model")
    )
  )
}

joint_methods_character_level_prepared <- function(predictor = c("gaussian", "bernoulli")) {
  predictor <- match.arg(predictor)
  dat <- data.frame(
    y = c(0.3, 0.7, 1.1, 1.4, 1.8, 2.0),
    x_var = c(-0.5, NA, 0.1, 0.4, 0.9, 1.2),
    z_score = c(-1.0, -0.6, -0.2, 0.1, 0.6, 1.1),
    group_char = c("common", "rare", "common", "common", "common", "common")
  )
  if (identical(predictor, "bernoulli")) {
    dat$x_var <- c("no", NA_character_, "yes", "no", "yes", "no")
  }
  impute_formula <- if (identical(predictor, "bernoulli")) {
    impute_model(x_var ~ z_score, family = binomial())
  } else {
    x_var ~ z_score
  }
  list(
    data = dat,
    prepared = drmTMB:::drm_julia_joint_prepare(
      bf(y ~ mi(x_var) + group_char, sigma ~ z_score),
      family = gaussian(),
      data = dat,
      env = environment(),
      weights_missing = TRUE,
      control = drm_control(),
      impute = list(x_var = impute_formula),
      missing = miss_control(response = "include", predictor = "model")
    )
  )
}

test_that("joint Julia result preserves explicit blocks and transforms Gaussian predictor SD", {
  fixture <- joint_methods_prepared()
  result <- joint_methods_result(fixture$prepared)
  fit <- drmTMB:::drm_julia_joint_result(
    result, fixture$prepared, quote(joint_fit),
    bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score), gaussian()
  )

  expect_s3_class(fit, "drmTMB_julia_joint")
  expect_identical(class(fit)[1:2], c("drmTMB_julia_joint", "drmTMB_julia"))
  expect_named(fit$coefficients, c("mu", "sigma", "mi_x_var", "sigma_mi_x_var"))
  expect_equal(fit$coefficients$sigma_mi_x_var[["x_var"]], 1.5)
  expect_equal(fit$vcov["sigma_mi_x_var:x_var", "sigma_mi_x_var:x_var"], 0.08 * 1.5^2)
  expect_equal(fit$vcov["mu:(Intercept)", "sigma_mi_x_var:x_var"], 0.01 * 1.5)
  expect_equal(fit$joint$raw_theta[["logsd_mi_x_var_log_sd"]], log(1.5))
  expect_equal(nobs(fit), sum(fixture$prepared$payload$observed_y))
  expect_true(is_converged(fit))
  summary_fit <- drmTMB:::summary.drmTMB_julia_joint(fit)
  sd_row <- summary_fit$coefficients$dpar == "sigma_mi_x_var"
  expect_true(all(is.na(summary_fit$coefficients$statistic[sd_row])))
  expect_true(all(is.na(summary_fit$coefficients$p.value[sd_row])))
  ci <- drmTMB:::confint.drmTMB_julia_joint(fit)
  ci_sd <- ci$tmb_parameter == "sigma_mi_x_var:x_var"
  expect_identical(ci$scale[ci_sd], "response")
  expect_identical(ci$transformation[ci_sd], "exp")
  expect_equal(ci$lower[ci_sd], exp(log(1.5) - qnorm(.975)*sqrt(.08)), tolerance=1e-12)
  expect_equal(ci$upper[ci_sd], exp(log(1.5) + qnorm(.975)*sqrt(.08)), tolerance=1e-12)
  # Natural covariance remains delta-method covariance; only interval construction
  # uses the underlying log coordinate, matching native R's positive-scale target.
  subset <- drmTMB:::confint.drmTMB_julia_joint(fit,parm=c("sigma_mi_x_var:x_var","mu:(Intercept)"))
  expect_equal(subset$lower, c(ci$lower[ci_sd], ci$lower[ci$tmb_parameter=='mu:(Intercept)']))
})

test_that("joint Julia imputed returns the native eight-column contract", {
  fixture <- joint_methods_prepared()
  fit <- drmTMB:::drm_julia_joint_result(
    joint_methods_result(fixture$prepared), fixture$prepared, quote(joint_fit),
    bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score), gaussian()
  )

  missing_rows <- drmTMB:::imputed.drmTMB_julia_joint(fit)
  expect_named(
    missing_rows,
    c("variable", "original_row", "model_row", "observed", "estimate", "std_error", "source", "uncertainty_status")
  )
  expect_equal(nrow(missing_rows), sum(!fixture$prepared$payload$observed_x))
  expect_true(all(is.na(missing_rows$std_error) | is.finite(missing_rows$std_error)))
  all_rows <- drmTMB:::imputed.drmTMB_julia_joint(fit, include_observed = TRUE)
  expect_equal(nrow(all_rows), length(fixture$prepared$payload$x))
  expect_true(all(is.na(drmTMB:::imputed.drmTMB_julia_joint(fit, se = FALSE)$std_error)))
  expect_error(drmTMB:::imputed.drmTMB_julia_joint(fit, variable = "other"), "Unknown")
})

test_that("joint Julia prediction, summary, and confidence intervals use the joint contract", {
  fixture <- joint_methods_prepared()
  fit <- drmTMB:::drm_julia_joint_result(
    joint_methods_result(fixture$prepared), fixture$prepared, quote(joint_fit),
    bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score), gaussian()
  )

  expect_equal(drmTMB:::predict.drmTMB_julia_joint(fit), joint_methods_result(fixture$prepared)$fitted)
  expect_equal(drmTMB:::predict.drmTMB_julia_joint(fit, dpar = "sigma"), joint_methods_result(fixture$prepared)$sigma)
  fresh <- fixture$data[c(1L, 4L), , drop = FALSE]
  fresh$x_var <- c(-0.2, 0.5)
  expect_length(drmTMB:::predict.drmTMB_julia_joint(fit, newdata = fresh), 2L)
  expect_length(drmTMB:::predict.drmTMB_julia_joint(fit, newdata = fresh, dpar = "sigma", type = "link"), 2L)
  expect_error(drmTMB:::predict.drmTMB_julia_joint(fit, dpar = "mi_x_var"), "mu and sigma")

  summary_fit <- drmTMB:::summary.drmTMB_julia_joint(fit)
  expect_true(any(summary_fit$coefficients$dpar == "sigma_mi_x_var"))
  ci <- drmTMB:::confint.drmTMB_julia_joint(fit)
  expect_true(all(ci$method == "wald"))
  expect_error(drmTMB:::confint.drmTMB_julia_joint(fit, method = "profile"), "not implemented")
  expect_error(drmTMB:::summary.drmTMB_julia_joint(fit, level = 1.2), "level")
})

test_that("joint Julia Bernoulli prediction preserves fitted level coding", {
  fixture <- joint_methods_bernoulli_prepared()
  fit <- drmTMB:::drm_julia_joint_result(
    joint_methods_result(fixture$prepared), fixture$prepared, quote(joint_fit),
    bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score), gaussian()
  )
  factor_data <- fixture$data[c(1L, 3L), , drop = FALSE]
  character_data <- factor_data
  character_data$x_var <- as.character(character_data$x_var)
  numeric_data <- factor_data
  numeric_data$x_var <- c(0, 1)
  expect_equal(
    drmTMB:::predict.drmTMB_julia_joint(fit, newdata = factor_data),
    drmTMB:::predict.drmTMB_julia_joint(fit, newdata = numeric_data)
  )
  expect_equal(
    drmTMB:::predict.drmTMB_julia_joint(fit, newdata = character_data),
    drmTMB:::predict.drmTMB_julia_joint(fit, newdata = numeric_data)
  )
  unknown_data <- factor_data
  unknown_data$x_var <- factor(c("no", "other"), levels = c("no", "yes", "other"))
  expect_error(
    drmTMB:::predict.drmTMB_julia_joint(fit, newdata = unknown_data),
    "unknown binary predictor level"
  )
  sigma_only <- data.frame(z_score = c(-0.5, 0.5))
  expected_sigma <- exp(0.4 + 0.5 * sigma_only$z_score)
  expect_equal(
    drmTMB:::predict.drmTMB_julia_joint(fit, newdata = sigma_only, dpar = "sigma"),
    expected_sigma
  )
})

test_that("joint Julia retains character levels that occur only with missing modelled x", {
  for (predictor in c("gaussian", "bernoulli")) {
    fixture <- joint_methods_character_level_prepared(predictor)
    fit <- drmTMB:::drm_julia_joint_result(
      joint_methods_result(fixture$prepared), fixture$prepared, quote(joint_fit),
      bf(y ~ mi(x_var) + group_char, sigma ~ z_score), gaussian()
    )
    newdata <- data.frame(
      x_var = if (identical(predictor, "gaussian")) 0.25 else "no",
      z_score = 0.2,
      group_char = "rare"
    )
    value <- drmTMB:::predict.drmTMB_julia_joint(fit, newdata = newdata)
    expected <- if (identical(predictor, "gaussian")) 0.45 else 0.4
    expect_equal(value, expected)
    unknown <- newdata
    unknown$group_char <- "unseen"
    expect_error(
      drmTMB:::predict.drmTMB_julia_joint(fit, newdata = unknown),
      "new level|factor"
    )
  }
})

test_that("joint Julia covariance failure hides Wald uncertainty", {
  fixture <- joint_methods_prepared()
  result <- joint_methods_result(fixture$prepared)
  result$covariance_status <- "hessian_not_positive_definite"
  result$imputation$std_error[] <- NaN
  result$imputation$se_available[] <- FALSE
  result$imputation$uncertainty_status[] <- "sdreport_non_pd_hessian"
  fit <- drmTMB:::drm_julia_joint_result(
    result, fixture$prepared, quote(joint_fit),
    bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score), gaussian()
  )
  summary_fit <- drmTMB:::summary.drmTMB_julia_joint(fit, level = 0.9)
  expect_true(all(is.na(summary_fit$coefficients$std.error)))
  expect_true(all(is.na(summary_fit$coefficients$statistic)))
  ci <- drmTMB:::confint.drmTMB_julia_joint(fit)
  expect_true(all(ci$conf.status == "unavailable"))
})

test_that("joint Julia accepts an all-missing failed Hessian covariance without Wald inference", {
  fixture <- joint_methods_prepared()
  result <- joint_methods_result(fixture$prepared)
  result$covariance_status <- "hessian_unavailable"
  result$vcov[,] <- NaN
  result$imputation$std_error[] <- NaN
  result$imputation$se_available[] <- FALSE
  result$imputation$uncertainty_status[] <- "sdreport_failed"
  fit <- drmTMB:::drm_julia_joint_result(
    result, fixture$prepared, quote(joint_fit),
    bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score), gaussian()
  )
  expect_false(fit$uncertainty$se)
  expect_true(all(is.na(drmTMB:::summary.drmTMB_julia_joint(fit)$coefficients$std.error)))
  expect_true(all(drmTMB:::confint.drmTMB_julia_joint(fit)$conf.status == "unavailable"))
})

test_that("joint Julia rejects lossy row identifiers and non-binary masks", {
  fixture <- joint_methods_prepared()
  bad_id <- joint_methods_result(fixture$prepared)
  bad_id$original_row[[1L]] <- 1.5
  expect_error(
    drmTMB:::drm_julia_joint_result(
      bad_id, fixture$prepared, quote(joint_fit),
      bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score), gaussian()
    ),
    "integer row IDs"
  )
  bad_mask <- joint_methods_result(fixture$prepared)
  bad_mask$observed_y[[1L]] <- 2
  expect_error(
    drmTMB:::drm_julia_joint_result(
      bad_mask, fixture$prepared, quote(joint_fit),
      bf(y ~ mi(x_var) + habitat_type, sigma ~ z_score), gaussian()
    ),
    "TRUE/FALSE or 0/1"
  )
})
